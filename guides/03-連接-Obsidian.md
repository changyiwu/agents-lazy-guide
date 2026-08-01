---
title: 'AI Agent 懶人包 #03：連接 Obsidian 第二大腦'
date: '2026-08-02'
type: 懶人包
version: v1.0
status: 合併版（實作後更新）
tags:
  - 懶人包
  - Obsidian
  - MCP
  - 第二大腦
---

# 懶人包 #03：連接 Obsidian 第二大腦

> 版本：v1.0（合併版）
> 更新日期：2026-08-02
> 適用：Claude Code / Codex / OpenCode / Antigravity

> 📌 **本懶人包可獨立執行**：會自動檢查並安裝所需工具。
> 已經有 Obsidian vault 的人可以直接從**階段二**開始。

---

## 這份懶人包會幫你做什麼？

給你的 AI Agent 裝上「第二大腦」，完成後 agent 可以：

- 讀取你 Obsidian 筆記庫裡的所有筆記
- 幫你搜尋、新增、編輯筆記
- 記住你的教學紀錄、素材、想法，變成專屬助理

> 💡 **不需要在 Obsidian 裡安裝任何外掛。** MCPVault 直接讀寫 vault 資料夾的檔案，
> 不經過 Obsidian app，**Obsidian 沒開著也能運作**。

---

## 先備條件

- [ ] AI Agent 已安裝且能正常使用
- [ ] Node.js 已安裝（MCPVault 需要）—— 沒裝也沒關係，階段二會處理
- [ ] 電腦有網路連線
- [ ] （只有要新建 vault 才需要）Google 帳號，用於 Google Drive 同步

---

## 完成標準

- [ ] 已確認主要 vault 的完整路徑，且該資料夾內有 `.obsidian`
- [ ] 已選定連線方式（資料夾授權 / MCPVault）
- [ ] MCP 設定寫入正確的檔案，且未破壞其他 server
- [ ] 重啟 agent 後**讀取驗證**成功
- [ ] （選用）寫入驗證成功，測試筆記已依指示處理

---

## 執行原則（給 AI Agent）

一次只做一個步驟，完成後再繼續。並且：

- **找到多個 vault 時，列出候選路徑讓使用者選擇，不自行猜測。**
- **只搜尋使用者指定的範圍**，不要從整顆磁碟遞迴掃描。
- 安裝 Node.js 或 MCPVault 前先詢問（全域 npm 安裝會修改使用者環境）。
- 修改任何設定檔前先讀取原內容，**只新增或更新目標區塊，不覆蓋其他設定**。
- 建立測試筆記前先詢問；刪除測試筆記時再次確認，**不可自行刪除**。
- **只授權必要的 vault**，不要把整個使用者家目錄交給 MCP。
- **不讀取或回傳與任務無關的私人筆記。**
- 批次搬移、覆蓋或刪除筆記前，**先列出範圍並取得同意**。
- 不把 API Key、token、密碼寫進筆記。
- **不把 vault 實體路徑、私人筆記或附件提交到公開 repo。**

---

# 階段一：準備 Obsidian Vault

> 已經有在用的 vault 就跳過整個階段一，直接到階段二。

## 步驟零：環境檢查

1. **確認作業系統**（Windows / macOS / Linux）
2. **確認網路連線正常**
3. **檢查 Node.js**：`node --version`
   > ⚠️ **Windows 重要提醒**：某些 agent 的 bash 環境可能找不到 `node`，即使已安裝。
   > 先試 `node --version`；失敗再試
   > `export PATH="/c/Program Files/nodejs:$PATH" && node --version`；
   > 仍失敗才視為未安裝。安裝後，後續 node/npm/npx 指令都要先加上那段 `export`（僅 Windows bash）。
4. **檢查 npx**：`npx --version`
5. **檢查 Obsidian 是否已安裝**
6. **檢查同步工具**（要用 Google Drive 才需要）：
   - Windows：確認 `G:\` 或 `C:\Users\[使用者]\Google Drive\` 是否存在
   - macOS：確認 `~/Library/CloudStorage/GoogleDrive-*/` 是否存在

## 步驟一：安裝 Obsidian

> 🖐️ **需要手動操作**：
> 1. 到 https://obsidian.md 下載安裝檔
> 2. 執行安裝
> 3. **先不要開啟 Obsidian**，等下一步建好資料夾再開

## 步驟二：安裝 Google Drive 桌面版（選用）

Google Drive 桌面版會在電腦上建立同步資料夾，vault 存在這裡就能自動同步到雲端，換電腦也不會遺失。

> 🖐️ **需要手動操作**：
>
> **下載與安裝**
> 1. 前往 https://www.google.com/drive/download/
> 2. 點「下載電腦版雲端硬碟」
> 3. 執行 `GoogleDriveSetup.exe`，一路「下一步」
>
> **登入與設定**
> 4. 安裝完會自動開啟登入畫面，用 Google 帳號登入
> 5. 系統匣（右下角）會出現雲朵圖示
> 6. 點雲朵 → 齒輪 ⚙ → 「偏好設定」
> 7. 選擇同步方式：
>    - **串流檔案**（預設，推薦）—— 檔案存雲端，需要時才下載
>    - **鏡射檔案** —— 全部下載到本機（佔空間但可離線）
>
> **確認位置**
> 8. 檔案總管左側會出現「Google Drive」磁碟機（通常 `G:\`）
>    - Windows：`G:\我的雲端硬碟\` 或 `G:\My Drive\`
>    - macOS：`~/Library/CloudStorage/GoogleDrive-你的信箱/My Drive/`
> 9. 等同步完成（雲朵圖示顯示 ✅）

## 步驟三：建立 Vault 資料夾

> 🖐️ 詢問使用者想要的 vault 名稱（建議：`secondbrain`）

在同步資料夾內建立：

```
Google Drive/
  └── [vault名稱]/          ← 這就是 Obsidian 的 vault
      ├── 教學素材/
      ├── 影片筆記/
      ├── 每日筆記/
      └── Templates/
```

記錄 vault 的**完整路徑**，後續步驟會用到。

## 步驟四：用 Obsidian 開啟 Vault

> 🖐️ **需要手動操作**：
> 1. 開啟 Obsidian
> 2. 選「Open folder as vault」（開啟資料夾作為筆記庫）
> 3. 選擇剛建立的 vault 資料夾
> 4. Obsidian 會開啟並顯示空的筆記庫

### 同步方案比較

| 方案 | 差異 |
|------|------|
| **Google Drive**（本懶人包預設，免費） | vault 建在 Google Drive 資料夾內 |
| **Obsidian Sync**（付費 $4/月） | vault 建在任意位置，Obsidian 內設定同步 |
| **iCloud**（macOS / iOS） | vault 建在 iCloud Drive 資料夾內 |
| **OneDrive** | vault 建在 OneDrive 資料夾內 |

> 差別只在 vault 資料夾的位置，**MCP 連接方式完全相同**。

---

# 階段二：連接 MCP

## 步驟五：確認主要 Vault 路徑

**先直接問使用者**：

> 你的 Obsidian 筆記本放在哪裡？如果不知道，我可以幫你找。

常見位置：

| 同步方式 | 常見路徑 |
|---|---|
| Google Drive | `G:\我的雲端硬碟\<vault>` |
| OneDrive | `C:\Users\<你>\OneDrive\文件\<vault>` |
| 本機文件 | `C:\Users\<你>\Documents\<vault>` |
| Obsidian Sync | 使用者自選的本機資料夾 |

使用者不知道時，**在限定範圍內**搜尋含 `.obsidian` 的資料夾：

```powershell
$roots = @(
  "$env:USERPROFILE\OneDrive",
  "$env:USERPROFILE\Documents",
  "$env:USERPROFILE\Desktop",
  "G:\我的雲端硬碟",
  "G:\My Drive"
)

$roots |
  Where-Object { Test-Path -LiteralPath $_ } |
  ForEach-Object {
    Get-ChildItem -LiteralPath $_ -Recurse -Directory -Force -ErrorAction SilentlyContinue |
      Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName ".obsidian") } |
      Select-Object -ExpandProperty FullName
  }
```

**確認條件**：資料夾存在 → 內含 `.obsidian` → **使用者確認這是他日常真正使用的主要 vault**。

找到多個候選時列出來讓使用者選，不要自己挑。

---

## 步驟六：選擇連線方式

| 方式 | 適合情況 | 特性 |
|---|---|---|
| **A. 工作區／資料夾授權** | 主要在目前工作區直接改 Markdown | 不需額外安裝，但受目前可寫範圍限制 |
| **B. MCPVault** | 希望從不同專案穩定搜尋、讀寫 vault | 需要 Node.js 與 MCP 設定，提供專門的筆記工具 |

兩種可以並存。**只要讀寫需求已由其中一種滿足，不必為了完成清單強迫安裝另一種。**

### 方式 A：工作區／資料夾授權

在 agent 中把 vault 開成工作區，或加入允許讀寫的資料夾範圍。

先做唯讀驗證：

```powershell
Test-Path -LiteralPath "<VAULT_PATH>"
Get-ChildItem -LiteralPath "<VAULT_PATH>" -Force | Select-Object -First 10 Name
```

需要寫入測試時先取得同意，建立一篇清楚命名的測試筆記並讀回內容，完成後詢問保留或刪除。

若從其他專案無法存取，代表授權範圍不足 —— 調整授權，或改用方式 B。

### 方式 B：MCPVault

**B-1. 檢查 Node.js**

```powershell
node --version
npm.cmd --version
```

沒有的話詢問後安裝 LTS：`winget install --id OpenJS.NodeJS.LTS --exact`

> 🔧 `npm` 被 PowerShell 執行原則阻擋 → 改用 `npm.cmd`。

**B-2. 取得 MCPVault**

兩種做法，依 agent 選（見「[依你的 Agent](#依你的-agent)」）：

- **全域安裝**（Claude Code / Codex / Antigravity）：
  ```bash
  npm install -g @bitbonsai/mcpvault      # Windows 用 npm.cmd
  ```
  找出執行檔實際路徑：`where.exe mcpvault`（或 `which mcpvault`）、`npm.cmd prefix -g`。
  Windows 常見位置：`C:\Users\<你>\AppData\Roaming\npm\mcpvault.cmd`

- **免全域安裝**（OpenCode）：設定裡直接用
  `["npx", "-y", "@bitbonsai/mcpvault@latest", "<VAULT_PATH>"]`

> ⚠️ **為什麼多數 agent 要全域安裝＋完整路徑？**
> 用 `npx` 當 MCP command 啟動時，Windows 可能因 PATH 問題導致 agent 找不到 npx。
> 全域安裝後寫完整路徑最穩。

**B-3. 寫入 MCP 設定** —— 見「依你的 Agent」。

---

## 步驟七：重啟 Agent 並驗證

> 🖐️ **需要手動操作**：完全關閉 agent（不只關視窗），然後重新開啟。
> 設定若已正確寫入，**重啟一次就夠**。

**驗證順序：**

1. **唯讀測試**：列出 vault 根目錄，或取得 vault 統計
2. **搜尋測試**：搜尋一個已知的筆記標題
3. **寫入測試（先取得同意）**：建立測試筆記
   - 路徑：`測試筆記.md`
   - 內容：「這是 AI Agent 透過 MCP 自動建立的筆記。連接成功！」
   - 含 frontmatter：title、date
4. **讀回驗證**：確認編碼與路徑正確（中文沒有變亂碼）
5. **詢問**保留或刪除測試筆記

### 工具沒出現時的排查

1. 確認設定寫在**正確的檔案**（見「依你的 Agent」，Claude Code 特別容易寫錯）
2. **把 `command` 和 `args[0]` 讀回來驗證**，確認兩個路徑都真的存在
3. 確認 vault 路徑確實存在且可存取
4. 在終端機手動測試 MCP server 能不能啟動：
   ```bash
   echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | mcpvault "<VAULT_PATH>"
   ```
   回傳 JSON 工具清單 → mcpvault 正常，問題在 agent 的設定讀取
5. 再次完全重啟 agent

---

## 依你的 Agent

| Agent | MCP 設定檔 | 取得 MCPVault |
|---|---|---|
| Claude Code | `~/.claude.json`（或專案 `.mcp.json`） | 全域安裝 + 完整路徑 |
| Codex | `~/.codex/config.toml` | 全域安裝 + 完整路徑 |
| OpenCode | `~/.config/opencode/opencode.json` | `npx -y @latest`，免安裝 |
| Antigravity | `~/.gemini/config/mcp_config.json` | 全域安裝 + 完整路徑 |

### Claude Code

> ⚠️ **不要寫進 `settings.json`。** 現行 Claude Code 的設定檔 schema **不接受 `mcpServers`**，
> 寫進 `~/.claude/settings.json` 或 `.claude/settings.local.json` 會被擋下並報
> `Unrecognized field: mcpServers`。
>
> ⚠️ `claude mcp add` 在**桌面版可能無法使用**（找不到 `claude` CLI）。有 CLI 的話：
> `claude mcp add obsidian -- npx @bitbonsai/mcpvault <VAULT_PATH>`

**位置 1：使用者層（所有專案都生效）** —— `~/.claude.json` 的**最上層**
（這個檔案通常已存在且內容很多，**保留原有內容，只新增這段**）：

```json
{
  "mcpServers": {
    "obsidian": {
      "command": "C:/Users/[使用者]/AppData/Roaming/npm/mcpvault.cmd",
      "args": ["C:/Users/[使用者]/我的雲端硬碟/[vault名稱]"]
    }
  }
}
```

macOS / Linux 通常不需要完整路徑，直接用 `mcpvault`：

```json
{
  "mcpServers": {
    "obsidian": {
      "command": "mcpvault",
      "args": ["/Users/[使用者]/Library/CloudStorage/GoogleDrive-xxx/My Drive/[vault名稱]"]
    }
  }
}
```

**位置 2：專案層（只在該工作目錄生效）** —— 新建 `[工作目錄]/.mcp.json`，格式相同。

> 專案層還需要授權才會載入，在 `[工作目錄]/.claude/settings.local.json` 加入：
> ```json
> { "enabledMcpjsonServers": ["obsidian"] }
> ```
> （`enabledMcpjsonServers` 是合法欄位，`mcpServers` 不是。）

> ⚠️ **Windows 路徑請用正斜線**（`C:/Users/...`）。雙反斜線經過 shell 或腳本處理時容易被吃掉
> （`\npm` 會變成換行字元），中文路徑尤其容易變亂碼。
>
> 寫完務必**讀回來驗證**：
> ```bash
> node -e "const o=require('C:/Users/[使用者]/.claude.json').mcpServers.obsidian; const fs=require('fs'); console.log(o.command, fs.existsSync(o.command)); console.log(o.args[0], fs.existsSync(o.args[0]))"
> ```
> 兩行都要顯示 `true`。
>
> ⚠️ **不要用 PowerShell 的 `Get-Content` 驗證含中文的路徑** —— 它預設不是以 UTF-8 讀檔，
> 中文會變亂碼導致 `Test-Path` 誤報「檔案不存在」。改用 Node 的 `fs.existsSync`。

### Codex

Codex Desktop、CLI 與 IDE 擴充**共用 `~/.codex/config.toml`**（受信任的專案也可用 `.codex/config.toml`）。

**先讓 Codex 記得 vault 在哪** —— 讀取既有 `~/.codex/AGENTS.md`（Windows：`C:\Users\<你>\.codex\AGENTS.md`），
確認後合併這段，不覆蓋其他規則：

```markdown
## Obsidian 筆記本固定路徑

主要 Obsidian Vault：

`<VAULT_PATH>`

當我說「Obsidian」、「Secondbrain」、「我的筆記本」或「第二大腦」時，預設指這個資料夾。

涉及筆記整理時，先讀取 Vault 根目錄的 `AGENTS.md`；實際讀寫透過已授權的資料夾或 Obsidian MCP。
```

> ⚠️ **`AGENTS.md` 只讓 Codex 知道 vault 在哪裡，不會自動取得讀寫權限。**
> 真正的讀寫能力來自工作區／資料夾授權或 MCP。

**再加入 MCP 設定**（三選一）：GUI 的 **MCP servers → Add server**（選 STDIO）、
手動編輯 `~/.codex/config.toml`、或 `codex mcp add`。

```toml
[mcp_servers.obsidian]
command = "C:\\Users\\<你>\\AppData\\Roaming\\npm\\mcpvault.cmd"
args = ["<VAULT_PATH>"]
startup_timeout_sec = 20
tool_timeout_sec = 60
```

> ⚠️ **TOML 裡的 Windows 路徑反斜線要寫成 `\\`**（跟 Claude Code 的 JSON 慣例不同）。
> 只新增或更新 `[mcp_servers.obsidian]`，不要覆蓋其他 server。

CLI 形式：

```powershell
codex mcp add obsidian -- "C:\Users\<你>\AppData\Roaming\npm\mcpvault.cmd" "<VAULT_PATH>"
```

**重啟**：Desktop 在 MCP 設定中 Restart 或完全關閉重開；IDE 用 Restart extension / Reload Window；
CLI 結束 session 再啟動。先用 `codex mcp list` 檢查。

### OpenCode

**不需要全域安裝 mcpvault。** 編輯 `~/.config/opencode/opencode.json`，安全合併：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "obsidian": {
      "type": "local",
      "command": ["npx", "-y", "@bitbonsai/mcpvault@latest", "<VAULT_PATH>"],
      "enabled": true
    }
  }
}
```

> ⚠️ Windows JSON 路徑中的反斜線必須寫成 `\\`（或改用正斜線）。
> **不得覆蓋既有的 MCP 或 permission 設定。**

**驗證**：`opencode mcp list`，再重啟 OpenCode。

### Antigravity

依「合併流程」編輯 `~/.gemini/config/mcp_config.json`：

1. 檔案已存在時，先用 `Get-Content -Raw | ConvertFrom-Json` 確認 JSON 合法
2. 寫入前建立**帶時間戳的備份**
3. **只新增或更新 `.mcpServers.obsidian`**，保留其他 server
4. 同名 server 已存在時先顯示差異並取得同意
5. 寫入後**再次解析驗證**

```json
{
  "mcpServers": {
    "obsidian": {
      "command": "C:\\Users\\<使用者>\\AppData\\Roaming\\npm\\mcpvault.cmd",
      "args": ["C:\\Users\\<使用者>\\Documents\\<vault>"]
    }
  }
}
```

> ⚠️ **實際 vault 路徑屬於本機設定**，不要複製回公開教學檔或 commit 到公開 repo。

**重啟**：完全重啟 AntiGravity，先做唯讀列出 vault 根目錄。

---

# 階段三：建立基礎知識結構（選用）

## 步驟八：建立 vault 的規則檔

在 vault 根目錄建立 agent 規則檔，每次對話都會自動讀取。
檔名依 agent 而定：Claude Code 用 `CLAUDE.md`，Codex / OpenCode / Antigravity 用 `AGENTS.md`
（Claude Code 也讀得到 `AGENTS.md`，可以兩份都放，或放一份再建橋接檔）。

> 🖐️ 詢問使用者：
> 1. 你教什麼科目？什麼年級？
> 2. 希望 agent 用什麼語言回答？
> 3. 有沒有其他偏好？（回答要簡潔、要附教學建議等）

範例結構：

```markdown
# 我的 Obsidian 第二大腦

## 關於我
- 我是[科目][年級]老師
- 這個 vault 是我的教學第二大腦

## 語言偏好
- 所有回應請使用繁體中文

## 工作規則
- 新增筆記時自動加上 frontmatter（title、date、tags）
- 搜尋筆記時優先搜尋教學素材相關內容
```

> 若 vault 根目錄已經有 `AGENTS.md`，**先讀取並遵守既有規則**，不要覆蓋。

## 步驟九：建立第一篇正式筆記

> 🖐️ 詢問使用者想建立什麼主題的第一篇筆記。

例如「本學期教學計畫」、「我的教學工具清單」，或任何他想記錄的內容。

---

## 完成！接下來你可以這樣用

| 你說的話 | Agent + Obsidian 會做的事 |
|----------|--------------------------|
| 「搜尋我的筆記有沒有跟 XXX 相關的」 | 用 BM25 搜尋 vault，回傳相關筆記 |
| 「幫我新增一篇筆記，紀錄今天的教學反思」 | 建立新筆記，含 frontmatter |
| 「幫我整理這篇筆記的重點」 | 讀取筆記並摘要 |
| 「幫我看 XXX 這篇筆記，延伸出教學點子」 | 讀取指定筆記，給出延伸建議 |
| 「幫我把今天的對話重點存到筆記」 | 整理對話並存入 vault |

---

## 進階：全文檢索（選用）

需要全文檢索、metadata 操作等進階功能時：

1. 在 Obsidian 安裝 **Local REST API** plugin
2. `pip install cli-anything-hub`
3. 執行 `cli-hub search obsidian` 確認目前 registry，再決定是否安裝

> ⚠️ **不要把 Local REST API key 寫進教學、Git 或對話回報。**

---

## 如果失敗，如何重來

對你的 agent 說：

> 「Obsidian 懶人包執行失敗了，幫我檢查哪裡出問題，重新處理。」

**復原步驟：**

1. **移除 MCP 設定**（依 agent）：
   - Claude Code：`claude mcp remove obsidian`；沒有 CLI 就手動刪除
     `~/.claude.json` 的 `mcpServers.obsidian`、專案的 `.mcp.json`、
     `.claude/settings.local.json` 的 `enabledMcpjsonServers`
   - Codex：移除 `~/.codex/config.toml` 的 `[mcp_servers.obsidian]`，或 `codex mcp remove obsidian`
   - OpenCode：移除 `opencode.json` 的 `mcp.obsidian`
   - Antigravity：從 `mcp_config.json` 移除 `obsidian`，保留其他 server，寫入後再解析驗證
2. **卸載 MCPVault**（有全域安裝才需要）：`npm.cmd uninstall -g @bitbonsai/mcpvault`
3. 從步驟五重新開始

> **移除 MCP 不會刪除 vault。** 任何測試筆記仍需另外確認後處理。

---

## 完成回報格式

```text
主要 Vault：<完整路徑>
.obsidian 存在：是 / 否
連線方式：資料夾授權 / MCPVault / 兩者
MCPVault 取得方式：全域安裝 <版本> / npx / 不適用
MCP 設定檔：<路徑>
MCP 連線：已連線 / 失敗
讀取驗證：成功 / 未執行 / 失敗
寫入驗證：成功 / 未執行 / 失敗
測試筆記：未建立 / 保留 / 已依指示刪除
（Codex）全域 AGENTS.md：已設定 / 未設定
```

---

## 常見問題

| 問題 | 解法 |
|------|------|
| 找不到 vault | 在限定範圍搜尋 `.obsidian`，找到多個要讓使用者選 |
| mcpvault 搜尋不到筆記 | 確認 vault 路徑正確；路徑有中文或空格要用引號包住 |
| Obsidian 需要裝外掛嗎？ | **不需要**。mcpvault 直接讀寫 vault 資料夾，不經過 Obsidian app |
| `npx: command not found` | 確認 Node.js 已安裝，重啟 agent |
| Windows bash 找不到 node | 新裝的 Node.js 可能不在 bash PATH，需 `export PATH="/c/Program Files/nodejs:$PATH"` |
| `npm` 被 PowerShell 執行原則阻擋 | 改用 `npm.cmd` |
| `where.exe mcpvault` 找不到 | 用 `npm.cmd prefix -g` 找全域安裝位置 |
| 重啟後工具仍不存在 | 設定檔的 `command` 要用**完整路徑**，不要只寫 `npx` |
| **Claude Code** `Unrecognized field: mcpServers` | 寫錯檔案。要放 `~/.claude.json` 或 `.mcp.json`，不能放 `settings.json` |
| **Claude Code** `claude: command not found` | 桌面版不一定有 CLI，改用手動寫入設定檔 |
| 設定寫了、重啟了，工具還是沒出現 | 把 `command` 與 `args[0]` 讀回來確認路徑沒被破壞。shell 處理 Windows 路徑時反斜線常被吃掉，中文也可能變亂碼。改用正斜線並寫成腳本檔 |
| 驗證中文路徑時 `Test-Path` 說檔案不存在 | PowerShell 的 `Get-Content` 預設不是 UTF-8，中文會變亂碼。改用 Node 的 `fs.existsSync` |
| 中文路徑顯示亂碼 | 用 UTF-8 重新讀取設定，並以實際工具測試為準 |
| **Codex** `AGENTS.md` 已寫路徑但仍不能讀寫 | `AGENTS.md` 只是告知位置。檢查工作區授權或 MCP 是否已連接 |
| 目前專案能讀、其他專案不能讀 | 檢查跨專案授權，或改用 MCPVault |
| Google Drive 同步衝突 | 避免在兩台裝置同時編輯同一篇筆記，等同步完成再操作 |

---

## 更新紀錄

| 日期 | 版本 | 更新內容 |
|------|------|---------|
| 2026-08-02 | v1.0 | 合併版：整併四份 Obsidian 懶人包，保留 Claude 版的 vault 建置階段與路徑踩坑、Codex 版的雙連線方式與 AGENTS.md、OpenCode 版的免安裝 npx、Antigravity 版的合併流程與安全規則 |

---

## 相關連結

- [mcpvault GitHub](https://github.com/bitbonsai/mcpvault)
- [Obsidian 官網](https://obsidian.md)
- [Codex MCP 官方文件](https://developers.openai.com/codex/mcp)
- [懶人包索引](../README.md)
