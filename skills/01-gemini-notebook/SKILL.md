---
name: gemini-notebook
description: 連接 Gemini Notebook（原 NotebookLM）MCP，讓 agent 讀寫 Google 筆記本並產生簡報、圖表、音訊。說「連接 Gemini Notebook」「連接 NotebookLM」時載入。
---

# 連接 Gemini Notebook（原 NotebookLM）

完整教學見 `guides/01-連接-Gemini-Notebook.md`。

> 產品 2026-07-16 由 NotebookLM 更名為 Gemini Notebook，但 PyPI 套件 `notebooklm-mcp-cli`、
> CLI `nlm`、MCP 執行檔 `notebooklm-mcp`、認證目錄 `~/.notebooklm-mcp-cli` **全部沿用舊名**。
> 指令照打即可，**不要自行改成尚未發布的名稱**。
>
> 這是非 Google 官方工具，使用內部 API，並在本機保存登入認證。不要提交憑證、筆記本 ID 清單或匯出檔。

## 步驟

1. **檢查** `uv --version`，缺少時先詢問再安裝。
2. **安裝**：`uv tool install notebooklm-mcp-cli`（已安裝改 `uv tool upgrade`）。
   **版本不得低於 0.9.3**（新網域支援）。修改使用者層級 uv tool 前先取得同意。
3. **驗證兩個執行檔都存在**（用途不同，缺一不可）：`nlm --version`；
   Windows `Get-Command nlm, notebooklm-mcp -All`，macOS/Linux `which nlm`、`which notebooklm-mcp`。
   找不到 → `uv tool update-shell` 後重開終端機，再查 `uv tool dir --bin` 是否在 PATH。
   出現 `uv trampoline failed to canonicalize script path` → 取得同意後 `uv tool install --force notebooklm-mcp-cli`。
4. **登入**：說明會開啟瀏覽器並在本機保存認證後，執行 `nlm login`，
   再用 `nlm login --check` 與 `nlm doctor` 驗證。瀏覽器登入必須由使用者本人完成。
5. **註冊 MCP**：依 agent 選做法（見下）。註冊前先檢查是否已有舊的 Gemini Notebook server，
   **同一時間只保留一個**，有衝突先顯示差異並取得同意再移除舊的。
6. **建立本地資料夾**：`Documents/GeminiNotebook/` 下建 slides、infographics、audio、video、
   docs、sheets、mindmaps、quizzes。已有舊的 `Documents/NotebookLM/` 就繼續用，不必改名。
7. **重啟 agent** 後驗證能列出筆記本清單（即使是空的）。只回報數量，不要把完整清單寫進 repo。
8. **功能測試**：建立明確標記為測試的 notebook（建立前先確認），完成後**詢問**是否刪除。

## 依 agent 的 MCP 註冊

| Agent | 設定檔 | Server 名 | 自動設定 |
|---|---|---|---|
| Claude Code | `~/.claude.json`（或專案 `.mcp.json`） | `notebooklm` | ❌ 桌面版失敗 |
| Codex | `~/.codex/config.toml` | `notebooklm-mcp` | ⚠️ 需 CLI |
| OpenCode | `~/.config/opencode/opencode.json` | `notebooklm` | ✅ `nlm setup add opencode` |
| Antigravity | `~/.gemini/config/mcp_config.json` | `gemini-notebook` | ❌ 路徑不符，勿用 |

- **Claude Code**：`nlm setup add claude-code` 在桌面版一定失敗（沒有 `claude` CLI），
  且它建議寫進 `settings.json` 是**錯的** —— 現行 schema 不接受 `mcpServers`。
  手動寫入 `~/.claude.json` 最上層：`{"mcpServers":{"notebooklm":{"command":"<notebooklm-mcp 路徑>","args":["--transport","stdio"]}}}`。
  路徑用 `nlm doctor` 查。
- **Codex**：三種 Codex 共用 `~/.codex/config.toml`。GUI（設定 → Integrations & MCP → Add server）、
  手動 `[mcp_servers.notebooklm-mcp]` + `command = "notebooklm-mcp"` + `startup_timeout_sec = 60.0`
  + `tool_timeout_sec = 120.0`，或 `codex mcp add notebooklm-mcp -- notebooklm-mcp`。
  **section 名必須是 `mcp_servers`**（底線、複數），寫錯會被靜默忽略。
- **OpenCode**：`nlm setup add opencode` 即可。失敗才手動編 `opencode.json` 的 `mcp` 區塊，
  command 指向 **`notebooklm-mcp` 不是 `nlm`**。用 `opencode mcp list` 驗證。
- **Antigravity**：**不要用 `nlm setup add antigravity`** —— 它顯示 `~/.gemini/antigravity/mcp_config.json`，
  但 IDE 2.0 實際讀 `~/.gemini/config/mcp_config.json`。手動合併 `.mcpServers.gemini-notebook`。

**不要執行 `nlm skill install <agent>`**（會多裝一份上游 Skill，MCP 連線不需要）。
**`nlm mcp` 已失效**，不可使用。

## 修改設定檔的合併流程

1. 先讀取並確認現有 JSON／TOML 合法
2. 寫入前建立帶時間戳的備份
3. **只新增或更新該一個 server**，保留其他 server，不得覆蓋整份設定
4. 同名已存在時先顯示差異並取得同意
5. 寫入後再次解析驗證

## 安全規則

- 安裝、登入、修改 agent 設定前逐步說明並取得同意。
- 瀏覽器登入必須由使用者完成，不要求手動貼 cookie。
- 建立測試 notebook 前先確認，刪除前再次詢問。
- 不提交登入憑證、筆記本 ID 清單或個人匯出檔。

## 復原

依 agent 移除 MCP 設定（保留其他 server 並重新驗證檔案）→
`uv tool uninstall notebooklm-mcp-cli` → `nlm logout`。
刪除本機 profile（`~/.notebooklm-mcp-cli/`）前先列出影響並取得同意。

## 回報

套件版本（需 ≥ 0.9.3）、兩個執行檔是否存在、登入狀態、MCP server 名稱與連線狀態、
筆記本讀取測試（僅數量）、測試 notebook 處理結果。
