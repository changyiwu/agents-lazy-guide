#Requires -Version 5.1
# ★ 本檔必須保留 UTF-8 BOM。Windows PowerShell 5.1 讀「無 BOM 的 UTF-8」會當成 ANSI，
#   檔內中文全部亂碼並在解析階段就失敗（PowerShell 7 兩者皆可）。用編輯器另存時請確認 BOM 還在。
<#
.SYNOPSIS
    把 agents-lazy-guide 的通用 Skills 安裝到指定 AI Agent 的全域技能目錄。

.DESCRIPTION
    來源只有一份（skills/<編號-slug>/），frontmatter 的 name 已經是含前綴的安裝名（agent-<slug>）。
    本腳本原封不動複製到各 agent 的全域目錄，只驗證 name 等於 agents.json 的 <prefix><slug>，
    不改寫任何內容 —— 這樣副本與原始檔逐位元組相同，sync-skills 的 hash 比對才會過。

.PARAMETER Agent
    claude / codex / opencode / antigravity / all

.PARAMETER Topic
    要安裝的主題，可傳 slug（github）或帶編號的資料夾名（02-github）。省略＝全部。

.PARAMETER Force
    目標已存在時覆蓋。預設不覆蓋，只回報「已存在」。

.PARAMETER ListOnly
    只列出將要做什麼，不實際寫入。

.EXAMPLE
    .\scripts\install.ps1 -Agent claude -Topic github

.EXAMPLE
    .\scripts\install.ps1 -Agent all -ListOnly
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('claude', 'codex', 'opencode', 'antigravity', 'all')]
    [string]$Agent,

    [string[]]$Topic,

    [switch]$Force,

    [switch]$ListOnly
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ConfigPath = Join-Path $RepoRoot 'agents.json'

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "找不到差異表：$ConfigPath"
}

$Config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

function Resolve-HomePath {
    param([string]$Path)
    if ($Path -like '~*') {
        return Join-Path $HOME ($Path.Substring(1).TrimStart('/', '\'))
    }
    return $Path
}

function Get-SkillFrontmatterName {
    <#
        讀出第一個 frontmatter 區塊裡的 name:。
        找不到 frontmatter 時視為錯誤（SKILL.md 一定要有）。
    #>
    param(
        [Parameter(Mandatory)][string]$Content
    )

    $lines = $Content -split "`r?`n"
    if ($lines.Count -lt 2 -or $lines[0].Trim() -ne '---') {
        throw 'SKILL.md 開頭沒有 frontmatter（第一行必須是 ---）'
    }

    $closeIndex = -1
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { $closeIndex = $i; break }
    }
    if ($closeIndex -lt 0) {
        throw 'SKILL.md 的 frontmatter 沒有結束的 ---'
    }

    for ($i = 1; $i -lt $closeIndex; $i++) {
        if ($lines[$i] -match '^\s*name\s*:\s*(.+?)\s*$') {
            return $Matches[1].Trim('"', "'")
        }
    }

    throw 'SKILL.md 的 frontmatter 沒有 name:'
}

# ---- 決定要處理哪些 agent ----
$agentKeys = if ($Agent -eq 'all') {
    $Config.agents.PSObject.Properties.Name
} else {
    @($Agent)
}

# ---- 決定要處理哪些主題 ----
$allTopics = @($Config.topics | Where-Object { $_.skillDir })
if ($Topic) {
    $selected = foreach ($t in $Topic) {
        $match = $allTopics | Where-Object {
            $_.slug -eq $t -or (Split-Path -Leaf $_.skillDir) -eq $t -or $_.no -eq $t
        }
        if (-not $match) { throw "未知的主題：$t（可用：$($allTopics.slug -join ', ')）" }
        $match
    }
    $topics = @($selected)
} else {
    $topics = $allTopics
}

$results = [System.Collections.Generic.List[object]]::new()

foreach ($key in $agentKeys) {
    $agentDef = $Config.agents.$key
    $detectDir = Resolve-HomePath $agentDef.detectDir
    $skillsDir = Resolve-HomePath $agentDef.skillsDir

    # 目錄不存在＝這台電腦沒裝那個工具，略過即可，不建目錄、不算錯誤
    if (-not (Test-Path -LiteralPath $detectDir)) {
        $results.Add([pscustomobject]@{
            Agent  = $agentDef.displayName
            Skill  = '(整個 agent)'
            Status = '跳過'
            Path   = $detectDir
            Note   = '這台電腦未安裝此工具'
        })
        continue
    }

    foreach ($topicDef in $topics) {
        $srcDir = Join-Path $RepoRoot $topicDef.skillDir
        $skillName = "$($agentDef.prefix)$($topicDef.slug)"
        $destDir = Join-Path $skillsDir $skillName

        if (-not (Test-Path -LiteralPath $srcDir)) {
            $results.Add([pscustomobject]@{
                Agent = $agentDef.displayName; Skill = $skillName
                Status = '略過'; Path = $destDir; Note = "來源尚未建立：$($topicDef.skillDir)"
            })
            continue
        }

        $srcSkill = Join-Path $srcDir 'SKILL.md'
        if (-not (Test-Path -LiteralPath $srcSkill)) {
            $results.Add([pscustomobject]@{
                Agent = $agentDef.displayName; Skill = $skillName
                Status = '失敗'; Path = $destDir; Note = '來源缺少 SKILL.md'
            })
            continue
        }

        # 安裝名以來源 frontmatter 的 name 為準，只驗證它等於 agents.json 的 <prefix><slug>
        try {
            $srcName = Get-SkillFrontmatterName -Content (Get-Content -LiteralPath $srcSkill -Raw -Encoding UTF8)
        } catch {
            $results.Add([pscustomobject]@{
                Agent = $agentDef.displayName; Skill = $skillName
                Status = '失敗'; Path = $destDir; Note = $_.Exception.Message
            })
            continue
        }
        if ($srcName -ne $skillName) {
            $results.Add([pscustomobject]@{
                Agent = $agentDef.displayName; Skill = $skillName
                Status = '失敗'; Path = $destDir
                Note = "來源 name 是 $srcName，應為 $skillName（改來源 SKILL.md，不要靠安裝時改寫）"
            })
            continue
        }

        $exists = Test-Path -LiteralPath $destDir
        if ($exists -and -not $Force) {
            $results.Add([pscustomobject]@{
                Agent = $agentDef.displayName; Skill = $skillName
                Status = '已存在'; Path = $destDir; Note = '要更新請加 -Force'
            })
            continue
        }

        if ($ListOnly) {
            $results.Add([pscustomobject]@{
                Agent = $agentDef.displayName; Skill = $skillName
                Status = if ($exists) { '將覆蓋' } else { '將安裝' }
                Path = $destDir; Note = "原樣複製，name 已是 $skillName"
            })
            continue
        }

        try {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null

            # 全部原樣複製（含 SKILL.md），副本與原始檔逐位元組相同
            Get-ChildItem -LiteralPath $srcDir -Force | ForEach-Object {
                Copy-Item -LiteralPath $_.FullName -Destination $destDir -Recurse -Force
            }

            $results.Add([pscustomobject]@{
                Agent = $agentDef.displayName; Skill = $skillName
                Status = if ($exists) { '已更新' } else { '已安裝' }
                Path = $destDir; Note = ''
            })
        } catch {
            $results.Add([pscustomobject]@{
                Agent = $agentDef.displayName; Skill = $skillName
                Status = '失敗'; Path = $destDir; Note = $_.Exception.Message
            })
        }
    }
}

$results | Format-Table -AutoSize Agent, Skill, Status, Note

$failed = @($results | Where-Object Status -eq '失敗')
if ($failed.Count -gt 0) {
    Write-Host ''
    Write-Host "有 $($failed.Count) 項失敗，詳見上表。" -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host '完成。安裝路徑請見上表 Path 欄（加 -Verbose 可看完整路徑）。' -ForegroundColor Green
$results | Where-Object Status -in '已安裝', '已更新', '將安裝', '將覆蓋' | ForEach-Object {
    Write-Verbose $_.Path
}
