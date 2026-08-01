---
name: firebase
description: 連接 Firebase MCP，讓 agent 操作 Cloud Firestore、Auth、Storage。說「連接 Firebase」「設定 Firebase」時載入。
---

# 連接 Firebase 資料庫

完整教學見 `guides/04-連接-Firebase.md`。

🛡️ **本流程不建立、不修改、不部署任何 Firestore 安全規則**，也不執行 `firebase init`。
規則由使用者自行在 Firebase Console 設定；要 agent 協助改規則須明確要求（見末段）。

## 步驟

1. **檢查環境**：`node --version`；Windows 用 **`npx.cmd --version`**
   （PowerShell 執行原則會擋 `npx.ps1`；`npm` 同理改 `npm.cmd`）。
2. **列出專案**：`npx.cmd -y firebase-tools@latest projects:list`。
   **已有專案先讓使用者選，不要自動建立新的。**
   `npx -y` 會下載並執行最新版套件，首次執行前先回報套件名稱並取得同意。
3. **登入**：`npx.cmd -y firebase-tools@latest login`。
   **必須在互動式終端執行**；在 agent 對話中卡住時，請使用者自己開 cmd/PowerShell 跑一次。
4. **建立本機專案設定**（讓 `firestore_*` 工具生效）：在專案資料夾放
   `firebase.json`（空 `{}` 即可）與 `.firebaserc`（`{"projects":{"default":"<專案 ID>"}}`）。
   **資料夾已有這些檔案或安全規則時，先讀取並保留，不要覆蓋。**
   沒有 `firebase.json` 時不要猜測專案 context，也不要自行 `firebase init`。
5. **註冊 MCP**：依 agent（見下）。務必指定專案目錄（`--dir <絕對路徑>` 或 `cwd`），
   否則只會載入核心工具。可用 `--only auth,firestore,storage` 限縮範圍。
6. **重啟 agent**（完全關閉再開），然後**唯讀驗證**：回報專案目錄、登入帳號、
   Active Project ID，再列出 Firestore 集合。**三者必須一致。**
   只有核心工具時，先修正 `cwd`/`--dir` 或呼叫
   `firebase_update_environment(project_dir=...)`（此呼叫不需重啟），再重試。
7. **（選用）寫入測試**：另外取得同意後，用**含日期時間的唯一文件 ID**新增 →
   讀回 → **只刪除該測試文件** → 再讀確認不存在 → 回報清理結果。

## 依 agent 的 MCP 設定

| Agent | 設定檔 | 要點 |
|---|---|---|
| Claude Code | `~/.claude.json` 或專案 `.mcp.json` | **不可寫 `settings.json`** |
| Codex | `~/.codex/config.toml` | `command = "npx.cmd"` + `cwd` |
| OpenCode | `~/.config/opencode/opencode.json` | `--dir` + `--only` |
| Antigravity | `~/.gemini/config/mcp_config.json` | 合併流程 + 備份 |

- **Claude Code**：`claude mcp add firebase --scope user -- npx -y firebase-tools@latest mcp`；
  桌面版沒有 CLI 時手動寫入 `~/.claude.json`（`{"mcpServers":{"firebase":{"command":"<firebase.cmd 路徑>","args":["mcp"]}}}`）。
  寫進 `settings.json` 會報 `Unrecognized field: mcpServers`。
  已全域安裝 firebase-tools 時，指向 `firebase.cmd` 比 `npx -y ...@latest` 快也穩。
- **Codex**：GUI（Integrations & MCP → Add server，Args 含 `--dir`）、
  手動 `[mcp_servers.firebase]`（`command = "npx.cmd"`、`cwd` 用 **TOML 單引號**寫 Windows 路徑、
  `startup_timeout_sec = 60`、`tool_timeout_sec = 120`、`default_tools_approval_mode = "writes"`），
  或 `codex mcp add`。改完設定要**完整重開** Codex。
  CLI 顯示 `Access is denied` 時改走 GUI 或手動編輯。
- **OpenCode**：`{"type":"local","command":["npx","-y","firebase-tools@latest","mcp","--dir","<絕對路徑>","--only","auth,firestore,storage"],"enabled":true}`。
  先問清楚：要連哪個目錄？是否已有 `firebase.json`？只需要哪些服務？
  用 `opencode mcp list` 驗證。**不要把 CRUD、部署或 `firebase init` 當成連線測試。**
- **Antigravity**：先解析並**備份**（帶時間戳）→ 只合併 `.mcpServers.firebase` →
  同名先顯示差異取得同意 → 寫入後再解析驗證。**預設只做唯讀查詢。**

## 安全規則

- 連線流程不自動建立 Firebase 專案、不 `firebase init`、不部署或修改安全規則。
- 預設只做唯讀；寫入資料、建立服務、部署都要另外取得同意。
- **Admin SDK／service account 憑證不可公開。** 前端 Firebase Config（apiKey 等）可以公開。
- `.firebaserc` 含專案 ID，公開前先確認。
- 學生正式資料只存**班級代號與座號，不存真名**；示範用假資料。

## 要改安全規則時（須明確要求）

1. 先用 `firebase_get_security_rules` 讀出目前線上規則給使用者看
2. 確認要改成什麼、影響哪些集合，**顯示差異**並取得同意
3. 才 `npx.cmd -y firebase-tools@latest deploy --only firestore:rules`
4. 課堂 Demo 的公開白名單，**結束後還原為預設拒絕**並再次確認後部署

絕不自動覆蓋既有規則。

## 常見陷阱

- `collection_path` 不能含尾巴 `/`（寫 `wordcloud_words` 不要 `wordcloud_words/`）
- `firestore_add_document` 要傳物件格式（`fields.message.stringValue`），不要包成 JSON 字串
- `firestore_query_collection` 回 `read_time cannot be in the future` → 改用
  `firestore_get_document` / `firestore_list_documents` 驗證，必要時重啟 MCP
- 讀 Google Drive 專案資料夾出現 sandbox 權限錯誤 → 需使用者授權，不要判定檔案壞掉

## 復原

依 agent 移除 MCP 設定（保留其他 server 並重新驗證）→
`npx.cmd -y firebase-tools@latest logout` / `login` 重登。
**移除 MCP 不會刪除 Firebase 專案或雲端資料。**

## 回報

firebase-tools 版本、登入帳號、專案數量、Active Project ID、專案目錄、功能限制範圍、
MCP 連線狀態、`firestore_*` 是否載入、唯讀驗證結果、寫入測試與清理結果、
安全規則是否變動、初始化是否執行。
