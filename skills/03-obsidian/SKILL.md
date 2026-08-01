---
name: obsidian
description: 連接 Obsidian vault，讓 agent 讀寫第二大腦筆記（MCPVault 或資料夾授權）。說「連接 Obsidian」「設定 Obsidian vault」時載入。
---

# 連接 Obsidian 第二大腦

完整教學見 `guides/03-連接-Obsidian.md`（含 Obsidian 與 Google Drive 的安裝流程）。

**不需要在 Obsidian 裡裝任何外掛**：MCPVault 直接讀寫 vault 資料夾的檔案，
Obsidian 沒開著也能運作。

## 步驟

1. **確認 vault**：先直接問使用者完整路徑。不知道時**只在限定範圍**搜尋含 `.obsidian` 的資料夾
   （`$env:USERPROFILE\OneDrive`、`\Documents`、`G:\我的雲端硬碟` 等），不要掃整顆磁碟。
   找到多個候選要列出讓使用者選，不自行猜測。確認條件：資料夾存在 + 內含 `.obsidian`
   + **使用者確認是他日常真正使用的主要 vault**。
2. **選連線方式**：
   - **資料夾授權** — 不需安裝，但受目前可寫範圍限制。先做唯讀驗證
     （`Test-Path -LiteralPath`、`Get-ChildItem | Select-Object -First 10`）。
   - **MCPVault** — 跨專案穩定讀寫，需 Node.js 與 MCP 設定。
   兩者可並存；**需求已被其中一種滿足時，不必強迫安裝另一種**。
3. **取得 MCPVault**（走 MCP 才需要）：先檢查 `node --version`、`npm.cmd --version`，
   缺少時詢問後裝 LTS。多數 agent 用全域安裝 + 完整路徑
   （`npm install -g @bitbonsai/mcpvault`，Windows 用 `npm.cmd`；
   路徑用 `where.exe mcpvault` 或 `npm.cmd prefix -g` 找），
   OpenCode 直接在設定用 `npx -y @bitbonsai/mcpvault@latest` 免安裝。
   *為什麼要完整路徑*：用 `npx` 當 command 時，Windows 可能因 PATH 問題找不到它。
4. **寫入 MCP 設定**：依 agent（見下），一律用合併流程。
5. **重啟 agent**（完全關閉，不只關視窗），設定正確的話重啟一次就夠。
6. **驗證**：唯讀列出 vault 根目錄 → 搜尋已知筆記 → 取得同意後建立測試筆記 →
   讀回確認編碼與路徑正確 → **詢問**保留或刪除。

## 依 agent 的 MCP 設定

| Agent | 設定檔 | 路徑跳脫 |
|---|---|---|
| Claude Code | `~/.claude.json` 最上層，或專案 `.mcp.json` | JSON，Windows 用**正斜線** |
| Codex | `~/.codex/config.toml` `[mcp_servers.obsidian]` | TOML，反斜線寫 `\\` |
| OpenCode | `~/.config/opencode/opencode.json` 的 `mcp` | JSON，反斜線寫 `\\` 或用正斜線 |
| Antigravity | `~/.gemini/config/mcp_config.json` 的 `.mcpServers.obsidian` | JSON，反斜線寫 `\\` |

- **Claude Code**：**不可寫進 `settings.json`** —— schema 不接受 `mcpServers`，會報
  `Unrecognized field: mcpServers`。`claude mcp add` 在桌面版可能不可用（沒有 CLI）。
  用專案層 `.mcp.json` 時，還要在 `.claude/settings.local.json` 加
  `{"enabledMcpjsonServers":["obsidian"]}`。
  寫入後**用 Node 的 `fs.existsSync` 讀回驗證** `command` 與 `args[0]` 都存在
  —— 不要用 PowerShell `Get-Content`（預設非 UTF-8，中文會變亂碼誤判檔案不存在）。
- **Codex**：先讀取 `~/.codex/AGENTS.md` 並合併 vault 固定路徑區塊（不覆蓋其他規則）。
  **`AGENTS.md` 只讓 Codex 知道位置，不等於讀寫權限** —— 權限來自資料夾授權或 MCP。
  設定可用 GUI（MCP servers → Add server，選 STDIO）、手動 TOML 或 `codex mcp add`。
  加 `startup_timeout_sec = 20`、`tool_timeout_sec = 60`。
- **OpenCode**：`{"type":"local","command":["npx","-y","@bitbonsai/mcpvault@latest","<VAULT_PATH>"],"enabled":true}`。
  不得覆蓋既有 MCP 或 permission 設定。用 `opencode mcp list` 驗證。
- **Antigravity**：先解析並**備份**（帶時間戳）→ 只合併 `.mcpServers.obsidian` →
  同名先顯示差異取得同意 → 寫入後再解析驗證。

## 安全規則

- **只授權必要的 vault**，不把整個使用者家目錄交給 MCP。
- **不讀取或回傳與任務無關的私人筆記。**
- 批次搬移、覆蓋或刪除筆記前，先列出範圍並取得同意。
- 建立測試筆記前先詢問；**不可自行刪除**，刪除前再次確認。
- 全域 npm 安裝會修改使用者環境，執行前先取得同意。
- 不把 vault 實體路徑、私人筆記、附件或 Local REST API key 提交到公開 repo 或寫進回報。

## 工具沒出現時的排查

1. 確認設定寫在正確的檔案（Claude Code 特別容易寫錯成 `settings.json`）
2. 把 `command` 與 `args[0]` 讀回來，確認兩個路徑都真的存在
3. 手動測試 server：`echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | mcpvault "<VAULT_PATH>"`
   —— 有回傳工具清單代表 mcpvault 正常，問題在 agent 的設定讀取
4. 完全重啟 agent

## 復原

依 agent 移除 MCP 設定（保留其他 server 並重新解析驗證）→
必要時 `npm.cmd uninstall -g @bitbonsai/mcpvault`。
**移除 MCP 不會刪除 vault**，測試筆記需另外確認後處理。

## 回報

Vault 完整路徑、`.obsidian` 是否存在、連線方式、MCPVault 取得方式與版本、
MCP 設定檔路徑、連線狀態、讀取／寫入驗證結果、測試筆記處理方式、
（Codex）全域 `AGENTS.md` 狀態。
