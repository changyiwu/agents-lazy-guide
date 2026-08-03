---
title: 'AI Agent 懶人包 #01：連接 Gemini Notebook（原 NotebookLM）'
date: '2026-08-02'
type: 懶人包
version: v1.0
status: 合併版（實作後更新）
tags:
  - 懶人包
  - Gemini-Notebook
  - NotebookLM
  - MCP
---

# 懶人包 #01：連接 Gemini Notebook（原 NotebookLM）

> 版本：v1.0（合併版，對應 nlm 0.9.4）
> 更新日期：2026-08-02
> 適用：Claude Code / Codex / OpenCode / Antigravity

> 📌 **本懶人包可獨立執行**：會自動檢查並安裝所需工具。

---

## ⚠️ 先講更名這件事

Google 在 **2026-07-16** 把 **NotebookLM 更名為 Gemini Notebook**。這是純換名字：
`notebooklm.google.com` 仍可用、舊分享連結自動轉址、筆記本不用搬移。

**重點是——所有你要打的指令一個字都沒改。** 套件作者只改了 repo 名稱，套件本身維持原名：

| 項目 | 名稱 | 有沒有改 |
|------|------|---------|
| 產品名 | Gemini Notebook（原 NotebookLM） | ✅ 改了 |
| GitHub repo | `jacob-bd/gemini-notebook-mcp-cli` | ✅ 改了（舊網址會轉址） |
| PyPI 套件名 | `notebooklm-mcp-cli` | ❌ 沒改 |
| CLI 指令 | `nlm` | ❌ 沒改 |
| MCP 執行檔 | `notebooklm-mcp` | ❌ 沒改 |
| 認證目錄 | `~/.notebooklm-mcp-cli` | ❌ 沒改 |

> 看到下面指令裡還是 `notebooklm`，不要以為是漏改的 —— **那才是對的**。
> **不要自行把這些技術名稱改成尚未發布的名稱**，會變成不存在的套件或指令。

---

## 這份懶人包會幫你做什麼？

讓你的 AI Agent 直接操控 Gemini Notebook：

- 建立 notebook、上傳資料來源
- 產生教學簡報（Slide Deck，可匯出 .pptx）
- 產生資訊圖表、音訊／影片概覽、心智圖、測驗與閃卡
- 成品自動下載到電腦裡的指定資料夾

---

## 原理說明

```
AI Agent ←(MCP 協定)→ notebooklm-mcp（翻譯官）←(Google 登入)→ Gemini Notebook
```

`notebooklm-mcp-cli` 安裝後提供**兩個不同用途的程式**：

- **`nlm`** —— 登入、診斷、直接操作的命令列工具
- **`notebooklm-mcp`** —— 給 agent 連線用的 stdio MCP server

**為什麼需要翻譯官？** Gemini Notebook 沒有官方 API，Google 沒開放程式直接呼叫。
這個工具是用「模擬瀏覽器操作」的方式，假裝是你在點網頁。

**什麼是 MCP？** Model Context Protocol，AI agent 跟外部工具溝通的標準接口，
就像手機的 USB-C —— 只要工具支援 MCP，agent 就能插上去用。

一句話：你跟 agent 講中文，agent 叫 `notebooklm-mcp` 去點 Gemini Notebook 的網頁，
成品自動下載到你電腦的資料夾。

> ⚠️ **這是非 Google 官方工具**，使用 Gemini Notebook 的內部 API，Google 更新介面後可能失效。
> 適合個人與實驗用途。**不要把認證資料、筆記本 ID 清單或個人匯出檔提交到 GitHub。**

---

## 先備條件

- [ ] AI Agent 已安裝且能正常使用
- [ ] 有 Google 帳號（用來登入 Gemini Notebook）
- [ ] Python 3.11 以上，或已安裝 `uv`
- [ ] 電腦有網路連線

---

## 完成標準

- [ ] `nlm --version` 正常，且版本 **≥ 0.9.3**
- [ ] `nlm login --check` 與 `nlm doctor` 顯示已認證
- [ ] `nlm` 與 `notebooklm-mcp` 兩個執行檔都存在
- [ ] MCP server 已註冊到你的 agent，且**只有一個** Gemini Notebook server
- [ ] 重啟 agent 後能列出筆記本清單（即使是空的）

---

## 執行原則（給 AI Agent）

- 安裝、登入、修改 agent 設定前**逐步說明並取得同意**。
- **瀏覽器登入必須由使用者本人完成。**
- 修改任何 MCP 設定檔一律用**合併流程**（見下），不得覆蓋既有其他 server。
- 建立測試 notebook 前先確認；刪除前再次詢問。
- 只回報筆記本數量或連線結果，**不要把完整清單寫進 repo**。
- 不要提交登入憑證。

---

## 步驟零：環境檢查

1. **確認作業系統**（Windows / macOS / Linux）
2. **確認網路連線正常**
3. **檢查 uv**：`uv --version`（沒有的話步驟一會裝）
4. **檢查 Python**：3.11 以上（走 uv 的話由 uv 處理）

---

## 步驟一：安裝 uv（如果沒裝）

**Windows（PowerShell）**

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

**macOS / Linux**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

---

## 步驟二：安裝 Gemini Notebook MCP CLI

安裝或更新會修改使用者層級的 uv tool，**執行前先取得同意**。

**方式 A：uv（獨立環境，推薦）**

```bash
uv tool install notebooklm-mcp-cli
```

**方式 B：pip（全域安裝）**

```bash
pip install notebooklm-mcp-cli
```

已安裝時改用更新：

```bash
uv tool upgrade notebooklm-mcp-cli
```

> ⚠️ **版本不得低於 0.9.3**，才支援 `notebook.google.com` 與 `notebook.cloud.google.com` 新網域。
> 新安裝或更新時使用可取得的最新版。

**驗證兩個執行檔都存在**（它們用途不同，缺一不可）：

```bash
nlm --version
```

- Windows：`Get-Command nlm, notebooklm-mcp -All`（或 `where.exe nlm`、`where.exe notebooklm-mcp`）
- macOS / Linux：`which nlm`、`which notebooklm-mcp`

> 🔧 找不到 `nlm` 或 `notebooklm-mcp`：執行 `uv tool update-shell` 後重開終端機；
> 仍失敗再檢查 `uv tool dir --bin` 的路徑是否已加入 PATH。
>
> 🔧 出現 `uv trampoline failed to canonicalize script path`：
> 先用 `Get-Command nlm -All` 確認命中的是舊 shim，取得同意後執行
> `uv tool install --force notebooklm-mcp-cli` 修復。

---

## 步驟三：登入 Google 帳號

登入會開啟瀏覽器並**在本機保存認證資料**，執行前先說明並取得同意。

```bash
nlm login
```

> 🖐️ **需要手動操作**：瀏覽器會開啟 Google 登入頁，請使用者登入自己的 Google 帳號。
> 登入成功後 CLI 會自動擷取認證 —— 這不是要求使用者手動貼 cookie。

驗證：

```bash
nlm login --check
nlm doctor
```

> 認證儲存位置：`~/.notebooklm-mcp-cli/profiles/default/`
>
> 🔧 Windows 終端顯示編碼錯誤時，在同一個 PowerShell 視窗執行：
> ```powershell
> $env:PYTHONIOENCODING = 'utf-8'
> nlm doctor
> ```

---

## 步驟四：註冊 MCP server

**這一步四個 agent 的做法完全不同，請跳到文末「[依你的 Agent](#依你的-agent)」照做。**

不論走哪一條路，共通規則：

> ⚠️ **同一時間只能有一個 Gemini Notebook server。**
> 註冊前先檢查是否已有舊的 `notebooklm` 或 `notebooklm-mcp` server，
> 有的話先顯示新舊差異、取得同意後移除舊的，避免兩個 server 同時暴露重複工具互相衝突。

> ⚠️ **`nlm mcp` 這個指令已經失效**，不可再使用。MCP command 一律用 `notebooklm-mcp`。

> ⚠️ **不要執行 `nlm skill install <agent>`。** 它會額外裝一份上游 Skill
> （例如 `~/.config/opencode/skills/nlm-skill/`），MCP 連線根本不需要它。
> 先前已裝的話可用 `nlm skill uninstall <agent>` 移除。

### 修改 MCP 設定檔的合併流程（通用）

需要手動編輯設定檔時，一律照這個流程，**不要拿範例覆蓋整份既有設定**：

1. 檔案已存在時，先讀取並確認目前 JSON／TOML 合法
2. 寫入前建立**帶時間戳的備份**，例如 `mcp_config.json.bak-20260802-120000`
3. **只新增或更新該一個 server 的區塊**，保留其他 server
4. 同名 server 已存在時，先顯示差異並取得更新同意
5. 寫入後**再次解析驗證**檔案仍合法

---

## 步驟五：建立本地資料夾

在「文件」資料夾下建立：

```
Documents/
  └── GeminiNotebook/
      ├── slides/          ← 簡報（Slide Deck，可匯出 .pptx）
      ├── infographics/    ← 資訊圖表（多種風格可選）
      ├── audio/           ← 音訊概覽（Audio Overview）
      ├── video/           ← 影片概覽（Cinematic / Explainer / Brief）
      ├── docs/            ← Google 文件匯出（Reports、Notes）
      ├── sheets/          ← Google 試算表匯出（Data Tables）
      ├── mindmaps/        ← 心智圖（Mind Map）
      └── quizzes/         ← 測驗與閃卡（Quiz、Flashcards）
```

Windows PowerShell 可直接執行：

```powershell
$root = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'GeminiNotebook'
'slides','infographics','audio','video','docs','sheets','mindmaps','quizzes' |
    ForEach-Object { New-Item -ItemType Directory -Force -Path (Join-Path $root $_) | Out-Null }
```

建立完成後告知使用者完整路徑。

> 📌 之前照舊版懶人包建過 `Documents/NotebookLM/` 的人：**那個資料夾繼續用就好**，
> 不需要改名（純粹是本機存放位置，跟工具運作無關）。

---

## 步驟六：重啟 Agent 並驗證

> 🖐️ **需要手動操作**：完全關閉你的 agent（不只是關視窗），然後重新開啟。
> 各 agent 的重啟方式見「依你的 Agent」。

重新開啟後：

1. 先在終端機執行 `nlm login --check` 確認認證仍有效
2. 對 agent 說「列出我的 Gemini Notebook 筆記本清單」
3. 能成功列出（即使是空的）→ 連接成功

---

## 步驟七：功能測試

1. 建立一個明確標記為測試的 notebook，名稱「測試筆記本」（**建立前先確認**）
2. 確認建立成功
3. **詢問使用者**是否刪除這個測試筆記本
4. 告知：「✅ 全部完成！你的 AI agent 已成功連接 Gemini Notebook。」

---

## 依你的 Agent

各 agent 的 MCP 設定檔位置與註冊方式：

| Agent | 設定檔 | Server 名稱 | 自動設定可用？ |
|---|---|---|---|
| Claude Code | `~/.claude.json` | `notebooklm` | ❌ 桌面版會失敗 |
| Codex | `~/.codex/config.toml` | `notebooklm-mcp` | ⚠️ 只有裝 CLI 才行 |
| OpenCode | `~/.config/opencode/opencode.json` | `notebooklm` | ✅ `nlm setup add opencode` |
| Antigravity | `~/.gemini/config/mcp_config.json` | `gemini-notebook` | ❌ 路徑不符，勿用 |

> `nlm setup add` 內建支援多種 agent，`nlm setup add --help` 可看完整清單
> （claude-code、gemini、github-copilot、cursor、windsurf、cline、antigravity、opencode、json），
> 另有 `nlm setup add all` 互動式偵測。**但不是每一個都能用，見下方各 agent 說明。**
>
> `nlm doctor` 的「AI Tool Configurations」只列出它**偵測得到**的工具，
> 沒列出不代表不能設定。

### Claude Code

```bash
nlm setup add claude-code
```

> ⚠️ **這一步在桌面版一定會失敗。** `nlm setup` 是靠呼叫 `claude` CLI 寫設定的，
> 桌面版沒有 CLI，會顯示 `Warning: 'claude' command not found in PATH`，
> 並建議你手動加到 `~/.claude/settings.json` —— **那個建議是錯的**，
> 現行 Claude Code 的 settings schema 不接受 `mcpServers`，寫進去會被擋下。

改為手動寫入 **`~/.claude.json`** 的最上層（保留檔案原有內容，只新增這段）：

```json
{
  "mcpServers": {
    "notebooklm": {
      "command": "C:/Users/[使用者]/.local/bin/notebooklm-mcp.EXE",
      "args": ["--transport", "stdio"]
    }
  }
}
```

macOS / Linux 的 command 通常是 `~/.local/bin/notebooklm-mcp`。
路徑用 `nlm doctor` 查（它會直接印出實際位置）。`--transport stdio` 是預設值，省略亦可。

也可以寫在專案根目錄的 `.mcp.json`。**就是不能寫 `settings.json`。**

**重啟**：完全關閉 Claude Code 再開啟。

### Codex

三種 Codex（Desktop / IDE 擴充 / CLI）**共用 `~/.codex/config.toml`**，做一次三邊都吃到。
任選一條路：

**方法 A：Desktop GUI（最推薦）**

1. 開 Codex Desktop → 設定 → **Integrations & MCP**
2. 點 **Add server**
3. 填 Name：`notebooklm-mcp`、Command：`notebooklm-mcp`、Args：留空
4. 儲存

**方法 B：手動編輯 `~/.codex/config.toml`**

```toml
[mcp_servers.notebooklm-mcp]
command = "notebooklm-mcp"
startup_timeout_sec = 60.0
tool_timeout_sec = 120.0
```

> 路徑：Windows `C:\Users\<你>\.codex\config.toml`，macOS/Linux `~/.codex/config.toml`。檔案不存在就新建。
> Desktop 可從「設定 → Integrations & MCP → Open config.toml」直接開啟。
>
> ⚠️ **Section 名稱必須是 `mcp_servers`**（底線、複數）。
> 寫成 `mcp-servers` 或 `mcpservers`，Codex 會**靜默忽略**，不會報錯。

**方法 C：CLI（只給有裝 CLI 的人）**

```bash
codex mcp list
codex mcp add notebooklm-mcp -- notebooklm-mcp
codex mcp get notebooklm-mcp
```

若 `codex mcp list` 已顯示舊的 `notebooklm`，先確認它是不是同一套服務，
改名或 `codex mcp remove notebooklm` 後再新增。**不要讓新舊兩個並存。**

**重啟**：Desktop 完全結束 app（不只關視窗）再開；IDE 用 Reload Window
（`Cmd/Ctrl+Shift+P` → Reload Window）；CLI `exit` 後重新 `codex`。
Desktop 可在 Integrations & MCP 面板看到 `notebooklm-mcp` 顯示 ✅ 連線中。

### OpenCode

直接用自動設定即可：

```bash
nlm setup add opencode
```

> 📌 舊版（0.6.x）需要手動編輯 `opencode.json`，0.8.x 起已不需要。
> **不要執行 `nlm skill install opencode`** —— 它會額外建立
> `~/.config/opencode/skills/nlm-skill/`，MCP 連線不需要。

自動設定失敗時，才手動編輯 `~/.config/opencode/opencode.json`，
把 command 指向 **`notebooklm-mcp`（不是 `nlm`）**：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "notebooklm": {
      "type": "local",
      "command": ["<notebooklm-mcp 完整路徑>"],
      "enabled": true
    }
  }
}
```

合併既有 JSON，不得覆蓋其他設定。

**驗證**：`opencode mcp list`，再重啟 OpenCode。

### Antigravity

> ⚠️ **不要執行 `nlm setup add antigravity`。**
>
> 先用唯讀命令看上游工具認為設定檔在哪：
>
> ```bash
> nlm setup list
> ```
>
> 截至 `notebooklm-mcp-cli 0.9.4`，它顯示的是 `~/.gemini/antigravity/mcp_config.json`，
> **但 Antigravity 2.0 桌面 App 實際讀取的是 `~/.gemini/config/mcp_config.json`**，兩者不同。
> 未來版本若修正，也必須先確認它明確顯示正確路徑，才能在取得同意後使用自動設定。
>
> 同樣不需要 `nlm skill install antigravity`。

在 Antigravity 的 MCP 管理介面新增 server，或依「合併流程」編輯
`~/.gemini/config/mcp_config.json`，**只新增或更新 `.mcpServers.gemini-notebook`**：

```json
{
  "mcpServers": {
    "gemini-notebook": {
      "command": "notebooklm-mcp",
      "args": []
    }
  }
}
```

若舊的 `.mcpServers.notebooklm` 或 `.mcpServers.notebooklm-mcp` 已存在，
先顯示新舊差異，取得同意後移除舊 key。

**重啟**：完全重啟 Antigravity（結束 App 再開，不只關視窗），確認 `gemini-notebook` 顯示已連線
（執行命令仍是 `notebooklm-mcp`）。

---

## 完成！接下來你可以這樣用

| 你說的話 | Gemini Notebook 會做的事 | 存放位置 |
|----------|-------------------|---------|
| 「幫我用這份 PDF 建一個 notebook」 | 建立 notebook + 上傳 PDF | — |
| 「幫我產生教學簡報」 | 生成 Slide Deck（可匯出 .pptx） | `slides/` |
| 「幫我做一張資訊圖表」 | 生成 Infographic | `infographics/` |
| 「幫我產生音訊概覽（Podcast）」 | 生成 Audio Overview | `audio/` |
| 「幫我產生影片概覽」 | 生成 Video Overview | `video/` |
| 「幫我產生報告並匯出成文件」 | 生成 Report → Google Docs | `docs/` |
| 「幫我做數據表格並匯出試算表」 | 生成 Data Table → Google Sheets | `sheets/` |
| 「幫我產生心智圖」 | 生成 Mind Map | `mindmaps/` |
| 「幫我出測驗題 / 閃卡」 | 生成 Quiz / Flashcards | `quizzes/` |

---

## 如果失敗，如何重來

對你的 agent 說：

> 「Gemini Notebook 懶人包執行失敗了，幫我清除之前的設定，重新跑一次。」

**復原步驟：**

1. **移除 MCP 設定**（依 agent）：
   - Claude Code：`nlm setup remove claude-code`，或手動從 `~/.claude.json` 移除 `notebooklm`
   - Codex：Desktop 設定面板刪除／手動移除 `[mcp_servers.notebooklm-mcp]` 段／`codex mcp remove notebooklm-mcp`
   - OpenCode：`nlm setup remove opencode`（曾裝過 nlm-skill 才需要 `nlm skill uninstall opencode`）
   - Antigravity：從 `~/.gemini/config/mcp_config.json` 移除 `gemini-notebook`，保留其他 server，寫入後再解析驗證
2. **移除工具**：`uv tool uninstall notebooklm-mcp-cli`（或 `pip uninstall notebooklm-mcp-cli`）
3. **清除登入**：`nlm logout`，或 `nlm login profile delete default --confirm`
4. **刪除本機 profile 前先列出影響並取得同意**（目錄：`~/.notebooklm-mcp-cli/`）
5. 確認環境乾淨後，從步驟零重新開始

> 移除舊的 `notebooklm` server 前，先確認它不是其他工具在用。

---

## 完成回報格式

```text
套件版本：<nlm --version>（需 ≥ 0.9.3）
執行檔：nlm ✅ / notebooklm-mcp ✅
登入狀態：成功 / 失敗（nlm login --check、nlm doctor）
MCP server 名稱：<依 agent>
Agent MCP 連線：已連線 / 失敗
筆記本讀取測試：成功（<數量> 本）/ 未執行
測試 notebook：未建立 / 保留 / 已依指示刪除
```

---

## 常見問題

| 問題 | 解法 |
|------|------|
| `nlm: command not found` | 重開終端機；`uv tool update-shell`；確認 `uv tool dir --bin` 已加入 PATH |
| `uv: command not found` | Windows 重開 PowerShell；macOS/Linux 執行 `source ~/.bashrc` 或 `source ~/.zshrc` |
| 找不到 `notebooklm-mcp` | 同上。注意它和 `nlm` 是兩個不同執行檔，都要存在 |
| `uv trampoline failed to canonicalize script path` | `Get-Command nlm -All` 確認舊 shim，取得同意後 `uv tool install --force notebooklm-mcp-cli` |
| 登入後 `nlm doctor` 顯示未認證 | 重新執行 `nlm login`，確認瀏覽器登入成功 |
| `doctor` 說 cookies 正常，但 MCP 回 `Authentication expired` | cookies 會過期而 doctor 看不出來。執行 `nlm login` 重新認證，再呼叫 `refresh_auth` 讓 MCP 重載憑證，不必重啟 agent |
| 瀏覽器沒有自動開啟 | 手動開啟瀏覽器登入 Google，或試 `nlm login --manual` |
| 指令裡怎麼還是 `notebooklm`？ | 正常。產品改名但套件名、CLI、執行檔都沒改（見開頭對照表） |
| **Claude Code** 看不到工具 | 確認設定寫在 `~/.claude.json` 而非 `settings.json`，並完全關閉再重啟 |
| **Claude Code** `Unrecognized field: mcpServers` | 你寫錯檔案了。要放 `~/.claude.json` 或專案的 `.mcp.json`，不能放 `settings.json` |
| **Claude Code** `nlm setup add claude-code` 找不到 `claude` 指令 | 桌面版沒有 CLI，屬正常。改手動寫入 `~/.claude.json` |
| **Codex** 設定改了沒生效 | section 名稱要 `mcp_servers`（底線、複數），寫錯會被靜默忽略 |
| **Codex** 第一次啟動 MCP 超過 30 秒 | 加入 `startup_timeout_sec = 60.0` 與 `tool_timeout_sec = 120.0` |
| **Codex** `codex mcp` 指令找不到 | 沒裝 CLI，用 Desktop GUI 或手動編輯 config.toml |
| **OpenCode** 看不到工具 | 0.8.x 直接 `nlm setup add opencode`；再用 `opencode mcp list` 確認 |
| **Antigravity** 設定沒生效 | 確認寫的是 `~/.gemini/config/mcp_config.json`，不是 `nlm setup list` 顯示的 `~/.gemini/antigravity/` 路徑 |
| 同時看到兩組相似工具 | 移除舊的 server，只保留一個 |
| 舊教學使用 `nlm mcp` | 該命令已不存在，MCP command 改用 `notebooklm-mcp` |
| `ModuleNotFoundError: No module named 'notebooklm_tools'` | 舊版 exe 問題，0.8.8 已修復。`nlm doctor` 確認實際路徑，必要時升級或改用 pip 版 |
| Windows 上指令格式錯誤 | 用 PowerShell 或 Git Bash，別用 CMD |
| `nlm setup list` 在 Windows 顯示亂碼 | 已知 cp950 編碼問題，不影響功能。可設 `$env:PYTHONIOENCODING = 'utf-8'` |

---

## 更新紀錄

| 日期 | 版本 | 更新內容 |
|------|------|---------|
| 2026-08-02 | v1.0 | 合併版：整併四份 #01，MCP 註冊四種做法收進「依你的 Agent」，補上通用合併流程 |
| 2026-08-03 | v1.1 | 「AntiGravity IDE 2.0」正名為 **Antigravity 2.0 桌面 App**（非 IDE），設定檔路徑結論不變 |

---

## 相關連結

- [gemini-notebook-mcp-cli GitHub](https://github.com/jacob-bd/gemini-notebook-mcp-cli)（舊網址會自動轉址）
- [Google 官方更名公告](https://workspaceupdates.googleblog.com/2026/07/notebooklm-now-gemini-notebook.html)
- [Gemini Notebook 官方說明](https://support.google.com/gemininotebook/)
- [Codex MCP 官方文件](https://developers.openai.com/codex/mcp)
- [懶人包索引](../README.md)
