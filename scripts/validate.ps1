#Requires -Version 5.1
# ★ 本檔必須保留 UTF-8 BOM（理由同 scripts/install.ps1）。
#   Windows PowerShell 5.1 讀「無 BOM 的 UTF-8」會當成 ANSI，檔內中文全部亂碼、解析階段就失敗。
<#
.SYNOPSIS
    驗證 agents-lazy-guide 的結構、命名、編碼與文件一致性。

.DESCRIPTION
    一切以 agents.json 為準，腳本本身不硬編碼任何主題名、技能名或 agent 名 ——
    新增主題只要照規則補進 agents.json 與三處清單，這支腳本不必改。

    檢查項目：
      1. agents.json 可解析、四個 agent 的 prefix 必須相同
      2. topics 與 guides/、skills/ 雙向對齊（沒有孤兒檔、沒有缺檔、章號不重複）
      3. 三處清單同步（agents.json topics / README.md / INSTALL.md）
      4. SKILL.md 的 frontmatter：name == <prefix><slug>、格式合法、description 不得提特定 agent
      5. SKILL.md 行數（目標 120／上限 150，見 TEMPLATE.md）
      6. 附屬檔規則：不可命名 SKILL.md、不可有 frontmatter
      7. 根目錄不可出現 SKILL.md（否則 npx skills 會把整個 repo 當成單一 Skill）
      8. 必要發布檔存在；scripts/*.ps1 必須有 UTF-8 BOM
      9. 文字衛生：Unicode 取代字元、行尾空白、檔尾多餘空行
     10. 疑似金鑰／token 外洩
     11. Markdown 相對連結有效、json 範例區塊可解析
     12. PowerShell 語法可解析、Python 可解析且 --help 正常
     13. install.ps1 -Agent all -ListOnly 冒煙測試

.PARAMETER Strict
    把警告也視為失敗（CI 想更嚴格時使用）。

.EXAMPLE
    .\scripts\validate.ps1

.EXAMPLE
    .\scripts\validate.ps1 -Strict
#>
[CmdletBinding()]
param(
    [switch]$Strict
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$Failures = [System.Collections.Generic.List[string]]::new()
$Warnings = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([Parameter(Mandatory)][string]$Message)
    $Failures.Add($Message)
}

function Add-Warning {
    param([Parameter(Mandatory)][string]$Message)
    $Warnings.Add($Message)
}

function Get-RelativePath {
    param([Parameter(Mandatory)][string]$Path)
    if ($Path.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $Path.Substring($Root.Length).TrimStart('\', '/').Replace('\', '/')
    }
    return $Path.Replace('\', '/')
}

function Resolve-RepoPath {
    <# agents.json 一律用 / 當分隔符，這裡轉成本機路徑 #>
    param([Parameter(Mandatory)][string]$RelativePath)
    return (Join-Path $Root ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar))
}

function Get-Frontmatter {
    <#
        取出第一個 frontmatter 區塊的內容。沒有就回傳 $null。
        刻意與 install.ps1 的 Get-SkillFrontmatterName 用同一套判斷（第一行必須是 ---）。
    #>
    param([Parameter(Mandatory)][string]$Content)

    $lines = $Content -split "`r?`n"
    if ($lines.Count -lt 2 -or $lines[0].Trim() -ne '---') { return $null }
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') {
            return ($lines[1..($i - 1)] -join "`n")
        }
    }
    return $null
}

# ============================================================
# 1. agents.json
# ============================================================
$ConfigPath = Join-Path $Root 'agents.json'
if (-not (Test-Path -LiteralPath $ConfigPath)) {
    Write-Host '致命錯誤：找不到 agents.json（唯一的差異來源），無法繼續。' -ForegroundColor Red
    exit 1
}

try {
    $Config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    Write-Host "致命錯誤：agents.json 無法解析：$($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$AgentKeys = @($Config.agents.PSObject.Properties.Name)
if ($AgentKeys.Count -lt 1) {
    Add-Failure 'agents.json 的 agents 區塊是空的'
}

$Prefixes = @()
foreach ($key in $AgentKeys) {
    $agentDef = $Config.agents.$key
    foreach ($field in @('displayName', 'detectDir', 'skillsDir', 'prefix')) {
        if (-not ($agentDef.PSObject.Properties.Name -contains $field) -or -not $agentDef.$field) {
            Add-Failure "agents.$key 缺少欄位：$field"
        }
    }
    if ($agentDef.PSObject.Properties.Name -contains 'prefix') {
        $Prefixes += $agentDef.prefix
    }
}

# 核心規則：前綴必須四家相同，否則 OpenCode 多路掃描會出現多份同主題技能
$DistinctPrefixes = @($Prefixes | Select-Object -Unique)
if ($DistinctPrefixes.Count -gt 1) {
    Add-Failure "四個 agent 的 prefix 必須完全相同，目前有 $($DistinctPrefixes.Count) 種：$($DistinctPrefixes -join ', ')"
}
$Prefix = if ($DistinctPrefixes.Count -ge 1) { $DistinctPrefixes[0] } else { '' }

$Topics = @($Config.topics)
if ($Topics.Count -lt 1) {
    Add-Failure 'agents.json 的 topics 是空的'
}

# ============================================================
# 2. topics 與 guides/、skills/ 雙向對齊
# ============================================================
$ExpectedGuides = @()
$ExpectedSkillDirs = @()

foreach ($topic in $Topics) {
    $slug = $topic.slug
    if (-not $slug) {
        Add-Failure "topics 有一筆缺少 slug（no=$($topic.no)）"
        continue
    }
    if ($slug -notmatch '^[a-z0-9-]{1,64}$') {
        Add-Failure "topic slug 不合法（只能小寫英數與連字號、1-64 字元）：$slug"
    }

    if ($topic.guide) {
        $ExpectedGuides += $topic.guide
        if (-not (Test-Path -LiteralPath (Resolve-RepoPath $topic.guide))) {
            Add-Failure "topics[$slug].guide 指向不存在的檔案：$($topic.guide)"
        }
    }

    if (-not $topic.skillDir) {
        Add-Failure "topics[$slug] 缺少 skillDir"
        continue
    }
    $ExpectedSkillDirs += $topic.skillDir
    $skillDirPath = Resolve-RepoPath $topic.skillDir
    if (-not (Test-Path -LiteralPath $skillDirPath)) {
        Add-Failure "topics[$slug].skillDir 不存在：$($topic.skillDir)"
        continue
    }
    if (-not (Test-Path -LiteralPath (Join-Path $skillDirPath 'SKILL.md'))) {
        Add-Failure "技能資料夾缺少 SKILL.md：$($topic.skillDir)"
    }
}

# 章號重複（install-all 這類沒有章號的項目不參與比對）
$NumberedTopics = @($Topics | Where-Object { $_.no -and $_.no -match '^\d{2}$' })
foreach ($group in ($NumberedTopics | Group-Object no | Where-Object { $_.Count -gt 1 })) {
    Add-Failure "章號重複：$($group.Name) -> $(($group.Group | ForEach-Object { $_.slug }) -join ', ')"
}

# guides/ 底下不該有沒登記的檔案
$GuidesDir = Join-Path $Root 'guides'
if (Test-Path -LiteralPath $GuidesDir) {
    foreach ($file in (Get-ChildItem -LiteralPath $GuidesDir -File -Filter '*.md')) {
        $rel = Get-RelativePath $file.FullName
        if ($ExpectedGuides -notcontains $rel) {
            Add-Failure "guides/ 有未登記進 agents.json 的檔案：$rel"
        }
    }
}

# skills/ 底下不該有沒登記的資料夾
$SkillsDir = Join-Path $Root 'skills'
if (Test-Path -LiteralPath $SkillsDir) {
    foreach ($dir in (Get-ChildItem -LiteralPath $SkillsDir -Directory)) {
        $rel = Get-RelativePath $dir.FullName
        if ($ExpectedSkillDirs -notcontains $rel) {
            Add-Failure "skills/ 有未登記進 agents.json 的資料夾：$rel"
        }
    }
}

# ============================================================
# 3. 三處清單同步（agents.json topics / README.md / INSTALL.md）
# ============================================================
$ReadmePath = Join-Path $Root 'README.md'
$InstallPath = Join-Path $Root 'INSTALL.md'

if (Test-Path -LiteralPath $ReadmePath) {
    $ReadmeText = Get-Content -LiteralPath $ReadmePath -Raw -Encoding UTF8
    foreach ($topic in $Topics) {
        if ($topic.title -and -not $ReadmeText.Contains($topic.title)) {
            Add-Failure "README.md 的清單缺少主題：$($topic.title)"
        }
    }
}

if (Test-Path -LiteralPath $InstallPath) {
    $InstallText = Get-Content -LiteralPath $InstallPath -Raw -Encoding UTF8
    foreach ($topic in $Topics) {
        if (-not $topic.skillDir) { continue }
        if (-not $InstallText.Contains($topic.skillDir)) {
            Add-Failure "INSTALL.md 的清單缺少技能來源路徑：$($topic.skillDir)"
        }
        $installName = "$Prefix$($topic.slug)"
        if (-not $InstallText.Contains($installName)) {
            Add-Failure "INSTALL.md 的清單缺少安裝名：$installName"
        }
    }
}

# ============================================================
# 4-6. SKILL.md 的 frontmatter、行數與附屬檔規則
# ============================================================
$AgentDisplayNames = @()
foreach ($key in $AgentKeys) {
    if ($Config.agents.$key.PSObject.Properties.Name -contains 'displayName') {
        $AgentDisplayNames += $Config.agents.$key.displayName
    }
}

foreach ($topic in $Topics) {
    if (-not $topic.skillDir) { continue }
    $skillDirPath = Resolve-RepoPath $topic.skillDir
    $skillPath = Join-Path $skillDirPath 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillPath)) { continue }

    $rel = Get-RelativePath $skillPath
    $content = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
    $frontmatter = Get-Frontmatter -Content $content

    if ($null -eq $frontmatter) {
        Add-Failure "SKILL.md 缺少 frontmatter（第一行必須是 ---）：$rel"
        continue
    }

    $expectedName = "$Prefix$($topic.slug)"
    $nameMatch = [regex]::Match($frontmatter, '(?m)^\s*name\s*:\s*(?<name>.+?)\s*$')
    if (-not $nameMatch.Success) {
        Add-Failure "SKILL.md 的 frontmatter 沒有 name：$rel"
    } else {
        $actualName = $nameMatch.Groups['name'].Value.Trim('"', "'")
        if ($actualName -notmatch '^[a-z0-9-]{1,64}$') {
            Add-Failure "SKILL.md 的 name 不合法（只能小寫英數與連字號、1-64 字元）：$rel -> $actualName"
        }
        if ($actualName -ne $expectedName) {
            Add-Failure "SKILL.md 的 name 與 agents.json 不一致：$rel -> $actualName，應為 $expectedName"
        }
    }

    $descMatch = [regex]::Match($frontmatter, '(?m)^\s*description\s*:\s*(?<desc>.+)$')
    if (-not $descMatch.Success) {
        Add-Failure "SKILL.md 的 frontmatter 沒有 description：$rel"
    } else {
        # 專案規則：description 不得提到特定 agent 名稱（內容四家通用）
        foreach ($displayName in $AgentDisplayNames) {
            if ($descMatch.Groups['desc'].Value -match [regex]::Escape($displayName)) {
                Add-Failure "SKILL.md 的 description 不應提到特定 agent（$displayName）：$rel"
            }
        }
    }

    # 行數：TEMPLATE.md 訂目標 120／上限 150
    $lineCount = ($content -split "`r?`n").Count
    if ($content.EndsWith("`n")) { $lineCount -= 1 }
    if ($lineCount -gt 150) {
        Add-Failure "SKILL.md 超過 150 行上限（$lineCount 行）：$rel"
    } elseif ($lineCount -gt 120) {
        Add-Warning "SKILL.md 超過 120 行目標（$lineCount 行，上限 150）：$rel"
    }

    # 附屬檔：不可命名 SKILL.md、不可有 frontmatter
    foreach ($extra in (Get-ChildItem -LiteralPath $skillDirPath -Recurse -File -Filter '*.md')) {
        if ($extra.FullName -eq $skillPath) { continue }
        $extraRel = Get-RelativePath $extra.FullName
        if ($extra.Name -eq 'SKILL.md') {
            Add-Failure "附屬檔不可命名為 SKILL.md（會被掃成另一個技能）：$extraRel"
            continue
        }
        if ($null -ne (Get-Frontmatter -Content (Get-Content -LiteralPath $extra.FullName -Raw -Encoding UTF8))) {
            Add-Failure "附屬檔不可有 frontmatter（會被掃成另一個技能）：$extraRel"
        }
    }
}

# ============================================================
# 7-8. repo 結構與必要發布檔
# ============================================================
if (Test-Path -LiteralPath (Join-Path $Root 'SKILL.md')) {
    Add-Failure '根目錄不可出現 SKILL.md（npx skills 會把整個 repo 當成單一 Skill，入口請用 INSTALL.md）'
}

$EntryFile = 'INSTALL.md'
if ($Config.PSObject.Properties.Name -contains 'repoRules') {
    if ($Config.repoRules.PSObject.Properties.Name -contains 'entryFile') {
        $EntryFile = $Config.repoRules.entryFile
    }
}
foreach ($required in @($EntryFile, 'README.md', 'AGENTS.md', 'TEMPLATE.md', 'LICENSE', '.gitattributes', 'scripts/install.ps1')) {
    if (-not (Test-Path -LiteralPath (Resolve-RepoPath $required))) {
        Add-Failure "缺少必要檔案：$required"
    }
}

# scripts/ 底下的 PowerShell 一律要 UTF-8 BOM（5.1 讀無 BOM 的 UTF-8 會當成 ANSI）
$ScriptsDir = Join-Path $Root 'scripts'
if (Test-Path -LiteralPath $ScriptsDir) {
    foreach ($ps1 in (Get-ChildItem -LiteralPath $ScriptsDir -File -Filter '*.ps1')) {
        $bytes = [System.IO.File]::ReadAllBytes($ps1.FullName)
        if ($bytes.Length -lt 3 -or $bytes[0] -ne 0xEF -or $bytes[1] -ne 0xBB -or $bytes[2] -ne 0xBF) {
            Add-Failure "PowerShell 腳本缺少 UTF-8 BOM（5.1 會把中文當 ANSI 讀而解析失敗）：$(Get-RelativePath $ps1.FullName)"
        }
    }
}

# ============================================================
# 9-11. 逐檔檢查：文字衛生、敏感資料、連結、JSON 範例
# ============================================================
$TextExtensions = @('.md', '.ps1', '.psd1', '.py', '.json', '.yml', '.yaml')
$SpecialTextNames = @('.gitignore', '.gitattributes', 'LICENSE', '.platform-ok')
$ExcludedDirs = @('.git', 'node_modules', '.venv', '__pycache__', 'comfyui')

$SelfRelative = Get-RelativePath $PSCommandPath

$TextFiles = Get-ChildItem -LiteralPath $Root -Recurse -File | Where-Object {
    $relPath = Get-RelativePath $_.FullName
    $segments = @($relPath.Split('/'))
    $inExcluded = $false
    if ($segments.Count -gt 1) {
        foreach ($segment in $segments[0..($segments.Count - 2)]) {
            if ($ExcludedDirs -contains $segment) { $inExcluded = $true; break }
        }
    }
    (-not $inExcluded) -and ($_.Extension -in $TextExtensions -or $_.Name -in $SpecialTextNames)
}

$SecretPattern = '(sk-[A-Za-z0-9_-]{20,}|AIza[0-9A-Za-z_-]{20,}|gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|-----BEGIN [A-Z ]+PRIVATE KEY-----)'

foreach ($file in $TextFiles) {
    $rel = Get-RelativePath $file.FullName
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    if ($null -eq $text) { continue }

    if ($text.Contains([char]0xFFFD)) {
        Add-Failure "發現 Unicode 取代字元（檔案編碼可能不是 UTF-8）：$rel"
    }
    if ($text -match '(?m)[\t ]+$') {
        Add-Failure "發現行尾空白：$rel"
    }
    if ($text -match '(\r?\n){2,}$') {
        Add-Failure "檔案末尾有多餘空白行：$rel"
    }
    if ($text.Length -gt 0 -and -not $text.EndsWith("`n")) {
        Add-Warning "檔案結尾缺少換行：$rel"
    }

    # 本檔自己帶有偵測用的樣式字串，排除以免自我誤報
    if ($rel -ne $SelfRelative -and $text -match $SecretPattern) {
        Add-Failure "發現疑似金鑰或 token：$rel"
    }

    if ($file.Extension -ne '.md') { continue }

    # Markdown 相對連結
    foreach ($match in [regex]::Matches($text, '\[[^\]]*\]\((?<target>[^)\s]+)')) {
        $target = $match.Groups['target'].Value.Trim('<', '>')
        $withoutAnchor = $target.Split('#')[0]
        if (-not $withoutAnchor -or $withoutAnchor -match '^(?:https?://|mailto:|/)') { continue }
        $resolved = Join-Path $file.DirectoryName ([uri]::UnescapeDataString($withoutAnchor))
        if (-not (Test-Path -LiteralPath $resolved)) {
            Add-Failure "失效的 Markdown 連結：$rel -> $target"
        }
    }

    # json 範例區塊必須可解析（本 repo 滿是 MCP 設定範例，壞掉會讓使用者貼錯）
    foreach ($block in [regex]::Matches($text, '(?ms)^```json\s*\r?\n(?<json>.*?)\r?\n```[ \t]*$')) {
        $json = $block.Groups['json'].Value
        # 帶省略記號的示意片段不是完整 JSON，跳過
        if ($json -match '(\.\.\.|…)') { continue }
        try {
            $json | ConvertFrom-Json | Out-Null
        } catch {
            Add-Failure "Markdown 的 json 範例無法解析：$rel -> $($_.Exception.Message)"
        }
    }
}

# ============================================================
# 12. PowerShell 與 Python 可解析
# ============================================================
foreach ($ps1 in ($TextFiles | Where-Object { $_.Extension -eq '.ps1' })) {
    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($ps1.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
    foreach ($parseError in @($parseErrors)) {
        Add-Failure "PowerShell 語法錯誤：$(Get-RelativePath $ps1.FullName) -> $($parseError.Message)"
    }
}

$PythonFiles = @($TextFiles | Where-Object { $_.Extension -eq '.py' })
if ($PythonFiles.Count -gt 0) {
    $PythonCommand = $null
    $PythonPrefix = @()
    foreach ($candidate in @(
        [pscustomobject]@{ Name = 'python'; Prefix = @() },
        [pscustomobject]@{ Name = 'py'; Prefix = @('-3') }
    )) {
        $command = Get-Command $candidate.Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $command) { continue }
        & $command.Source @($candidate.Prefix) --version *> $null
        if ($LASTEXITCODE -eq 0) {
            $PythonCommand = $command.Source
            $PythonPrefix = @($candidate.Prefix)
            break
        }
    }

    if (-not $PythonCommand) {
        Add-Warning '這台電腦找不到可執行的 python 或 py -3，略過 Python 檢查（CI 上會執行）'
    } else {
        foreach ($py in $PythonFiles) {
            $pyRel = Get-RelativePath $py.FullName
            & $PythonCommand @PythonPrefix -c "import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text(encoding='utf-8'))" $py.FullName
            if ($LASTEXITCODE -ne 0) {
                Add-Failure "Python 語法錯誤：$pyRel"
                continue
            }
            & $PythonCommand @PythonPrefix $py.FullName --help *> $null
            if ($LASTEXITCODE -ne 0) {
                Add-Failure "Python 腳本 --help 失敗：$pyRel"
            }
        }
    }
}

# ============================================================
# 13. install.ps1 冒煙測試（-ListOnly 不寫入任何東西）
# ============================================================
$InstallerPath = Join-Path $Root 'scripts\install.ps1'
if (Test-Path -LiteralPath $InstallerPath) {
    $Shell = Get-Command 'powershell.exe' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $Shell) {
        $Shell = Get-Command 'pwsh' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    if (-not $Shell) {
        Add-Warning '找不到 powershell.exe 或 pwsh，略過 install.ps1 冒煙測試'
    } else {
        $previous = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $output = & $Shell.Source -NoProfile -ExecutionPolicy Bypass -File $InstallerPath -Agent all -ListOnly 2>&1
        $exitCode = $LASTEXITCODE
        $ErrorActionPreference = $previous
        if ($exitCode -ne 0) {
            Add-Failure "install.ps1 -Agent all -ListOnly 執行失敗（exit $exitCode）：$(($output | Out-String).Trim())"
        }
    }
}

# ============================================================
# 結果
# ============================================================
if ($Warnings.Count -gt 0) {
    Write-Host ''
    Write-Host "警告 $($Warnings.Count) 項：" -ForegroundColor Yellow
    foreach ($warning in $Warnings) {
        Write-Host "- $warning" -ForegroundColor Yellow
    }
}

if ($Strict -and $Warnings.Count -gt 0) {
    foreach ($warning in $Warnings) {
        Add-Failure "（-Strict）$warning"
    }
}

if ($Failures.Count -gt 0) {
    Write-Host ''
    Write-Host "驗證失敗，共 $($Failures.Count) 項：" -ForegroundColor Red
    foreach ($failure in $Failures) {
        Write-Host "- $failure" -ForegroundColor Red
    }
    exit 1
}

Write-Host ''
Write-Host '驗證通過：agents.json、主題對齊、三處清單、SKILL.md 命名與行數、附屬檔、發布檔、BOM、文字編碼、敏感資料、連結、JSON 範例、PowerShell、Python、安裝器模擬全部正常。' -ForegroundColor Green
exit 0
