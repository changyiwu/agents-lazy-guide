---
title: 'AI Agent 懶人包 #04：連接 Firebase 資料庫'
date: '2026-08-02'
type: 懶人包
version: v1.0
status: 合併版（實作後更新）
tags:
  - 懶人包
  - Firebase
  - Firestore
  - MCP
---

# 懶人包 #04：連接 Firebase 資料庫

> 版本：v1.0（合併版）
> 更新日期：2026-08-02
> 適用：Claude Code / Codex / OpenCode / Antigravity

> 📌 **本懶人包可獨立執行**：會自動檢查並安裝所需工具。

---

## 這份懶人包會幫你做什麼？

讓你的 AI Agent 直接操控 Firebase 雲端資料庫（Cloud Firestore）：

- 用自然語言建立資料集合（不需要學程式）
- 新增、查詢、修改、刪除資料（透過 Firebase MCP 工具）
- 讓你做的網頁工具能「記住」資料（關掉瀏覽器再開，資料還在）
- 支援即時更新（學生輸入後，展示頁面馬上顯示）
- **千人研習也撐得住**（免費並發連線 100 萬）
- **永遠不會閒置暫停**

> 🛡️ **本懶人包不會建立、修改或部署任何 Firestore 安全規則。**
> 你專案現有的線上規則完全不會被動到。要改規則請見文末「[進階：部署安全規則](#進階部署安全規則選用)」。

---

## Firebase vs Supabase，該選哪個？

> ℹ️ 本系列**不提供 Supabase 懶人包**，下表只是給你判斷用的對照。

| 比較項目 | Supabase | Firebase（本懶人包） |
|---------|----------|---------------------|
| 資料庫類型 | SQL（像 Excel 表格） | NoSQL（像 JSON 文件） |
| 免費專案數 | 2 個 | 無限 |
| 閒置暫停 | 一週沒用會暫停 | **不會暫停** |
| **並發連線（免費版）** | **200** | **100 萬** |
| 即時更新 | 有 | 更強（onSnapshot 一行搞定） |
| MCP 工具 | 完整（execute_sql） | **完整**（list/query/add/update/delete + auth + messaging + storage） |

### 場景對照表

| 場景 | 規模 | 推薦 | 原因 |
|------|------|------|------|
| 第一次接觸資料庫的老師 | — | **Firebase** | 限制少、不會暫停、規模彈性大 |
| 班級成績記錄本 | 30 人 | **Firebase** | 不會暫停，MCP 可直接查 |
| 課堂 IRS、即時互動 | 30 人 | **Firebase** | onSnapshot 即時更新最簡單 |
| 即時文字雲、投票牆 | 不限 | **Firebase** | onSnapshot 即時更新 |
| **教師研習千人 IRS** | **1000 人** | **Firebase**（必選） | 並發 100 萬 vs Supabase 200 |
| 重度 SQL 統計分析 | — | Supabase | SQL JOIN / GROUP BY 強大 |
| 已經用 Supabase | — | 繼續用 | 沒必要換 |

---

## Firebase MCP 能做什麼？

| 類別 | 工具 | 用途 |
|------|------|------|
| 專案管理 | `firebase_list_projects`、`firebase_create_project` | 建立、列出專案 |
| App 管理 | `firebase_create_app`、`firebase_list_apps` | 建立 Web / iOS / Android app |
| SDK 設定 | `firebase_get_sdk_config` | 取得前端用的設定（apiKey 等） |
| 初始化 | `firebase_init` | 初始化 Firestore、Auth、Hosting |
| 安全規則 | `firebase_get_security_rules`、`firebase_validate_security_rules` | 查看 / 驗證規則（唯讀） |
| **Firestore CRUD** | `firestore_list_collections`、`firestore_query_collection`、`firestore_get_document`、`firestore_add_document`、`firestore_update_document`、`firestore_delete_document`、`firestore_list_documents` | **完整讀寫 Firestore** |
| Auth | `auth_get_users`、`auth_update_user` | Authentication 管理 |
| Messaging | `messaging_send_message` | FCM 推播 |
| Storage | `storage_get_object_download_url` | Cloud Storage 下載 |
| Realtime Database | `realtimedatabase_get_data`、`realtimedatabase_set_data` | RTDB 讀寫 |
| Remote Config | `remoteconfig_get_template`、`remoteconfig_update_template` | 遠端設定 |
| 文件查詢 | `developerknowledge_search_documents` | 查 Firebase 官方文件 |

> ⚠️ **`firestore_*` 工具不會一開始就出現。**
> Firebase MCP 啟動時只載入 `core` 與 `developerknowledge` 兩組工具；
> `firestore_*` 要等 MCP 偵測到**一個含 `firebase.json` 的專案目錄**才會註冊。
>
> 只看到 `firebase_list_projects` 之類、沒有任何 `firestore_*` 時，
> 用 `firebase_get_environment` 檢查；若顯示 `<NO CONFIG PRESENT>`，指定專案目錄：
>
> ```
> firebase_update_environment(project_dir="含 firebase.json 的資料夾路徑")
> ```
>
> 設定後 Firestore 工具會**立刻出現，不需要重啟 agent**。
>
> 這也是為什麼階段一的「建立本機專案設定」不能跳過 ——
> 就算你的 Google 帳號底下已經有 Firebase 專案，**沒有本機專案目錄一樣用不到 Firestore 工具**。

---

## 先備條件

- [ ] AI Agent 已安裝且能正常使用
- [ ] 已有 Google 帳號（Gmail 即可）
- [ ] 電腦有網路連線

---

## 完成標準

- [ ] `firebase-tools` 可用，且已成功 `login`
- [ ] `projects:list` 能列出專案
- [ ] MCP server 已註冊到你的 agent，且未破壞其他 server
- [ ] 重啟後**唯讀驗證**成功（專案目錄、Active Project ID、Firestore 集合三者一致）
- [ ] （選用）寫入測試成功，測試文件已清除

---

## 執行原則（給 AI Agent）

一次只做一個步驟，完成後再繼續。並且：

- **連線流程不會自動建立 Firebase 專案、不執行 `firebase init`、不部署任何安全規則。**
- 已有專案時**先列出讓使用者選擇**，不要自動建立新的。
- 資料夾已有 `firebase.json`、`.firebaserc` 或安全規則時，**先讀取並保留，不要覆蓋**。
- 沒有 `firebase.json` 時**不要猜測專案 context**，也不要自行 `firebase init`。
- **預設只做唯讀查詢。** 寫入資料、建立服務、部署規則都要另外取得同意。
- **不要把 CRUD、部署或 `firebase init` 當成連線測試。**
- 修改 MCP 設定檔一律用合併流程（備份 → 只改目標區塊 → 寫入後重新解析驗證）。
- `npx -y` 可能下載並執行最新版套件；首次執行或版本改變時，**先回報套件名稱並取得同意**。

---

# 階段一：建立 Firebase 專案

## 步驟零：環境檢查

1. **確認作業系統**（Windows / macOS / Linux）
2. **確認網路連線正常**
3. **檢查 Node.js**：`node --version`（未安裝時詢問後裝 LTS）
4. **檢查 npx**：Windows 用 **`npx.cmd --version`**

> ⚠️ **Windows 一律用 `npx.cmd`，不要用 `npx`。**
> PowerShell 的執行原則會擋掉 `npx.ps1`，報
> `npx.ps1 cannot be loaded because running scripts is disabled`。
> 同理，`npm` 被擋時改用 `npm.cmd`。

## 步驟一：選擇或建立 Firebase 專案

先列出目前帳號可用的專案：

```powershell
npx.cmd -y firebase-tools@latest projects:list
```

**已有專案就讓使用者選，不要自動建立新的。** 只有使用者明確要求新專案時：

> 🖐️ **需要手動操作**：
> 1. 開啟 https://console.firebase.google.com
> 2. 點「建立專案」
> 3. 專案名稱（建議 `my-teaching-tools` 或使用者自訂）
> 4. Google Analytics 可以不啟用（教學工具用不到）
> 5. 建立完成後**記下 Project ID**

## 步驟二：啟用 Cloud Firestore

> 🖐️ **需要手動操作**：
> 1. Firebase Console → 左側「Firestore Database」
> 2. 點「建立資料庫」
> 3. Standard 版即可
> 4. 位置：東亞建議 `asia-east1 (Taiwan)` 或 `asia-northeast1 (Tokyo)`
> 5. **安全性規則選「以正式版模式啟動」**（不要選測試模式！）
> 6. 點「建立」

> 💡 **為什麼選正式版模式？**
> - 測試模式預設「任何人可讀寫」，但 **30 天後規則自動失效**，網頁會壞掉
> - 正式版模式預設「全部禁止」，比較安全
> - 規則請自行在 Console 設定，本懶人包不會自動建立或部署

## 步驟三：建立本機專案設定（讓 MCP 工具生效）

> 🛡️ 這一步只是在本機放一個「專案指標」，讓 Firebase MCP 偵測得到專案、
> 把 `firestore_*` 工具開出來。**完全不動線上規則。**

先確認要把本機情境放在哪個資料夾。**資料夾已有這些檔案時，先讀取並保留，不要覆蓋。**

建立**兩個**檔案（沒有 `firestore.rules`，因為我們不碰規則）：

**1. `firebase.json`** —— 空設定即可，只為了讓 MCP 認得這是 Firebase 專案目錄

```json
{}
```

**2. `.firebaserc`** —— 指定預設專案

```json
{
  "projects": {
    "default": "[使用者的 Firebase 專案 ID]"
  }
}
```

> ⚠️ `.firebaserc` 含專案 ID，**公開前先確認**是否要一起提交。

確認目前指向的專案：

```powershell
npx.cmd -y firebase-tools@latest use
```

---

# 階段二：連接 MCP

## 步驟四：登入 Firebase CLI

```powershell
npx.cmd -y firebase-tools@latest login
```

> 🖐️ **需要手動操作**：瀏覽器會開啟 Google 登入頁，請使用者選擇帳號並授權。
>
> ⚠️ **`firebase login` 必須在互動式終端執行。**
> 在 agent 對話中有時會卡住 —— 這時請使用者自己打開 cmd / PowerShell 跑一次。

驗證：

```powershell
npx.cmd -y firebase-tools@latest projects:list
```

應該能看到你的專案。

## 步驟五：註冊 MCP server

**四個 agent 做法不同，請跳到「[依你的 Agent](#依你的-agent)」。**

共通要點：

- **指定專案目錄**（`--dir <絕對路徑>` 或 `cwd`）才會載入 `firestore_*` 工具
- 可用 `--only auth,firestore,storage` **限縮工具範圍**，只開你需要的
- 已全域安裝 `firebase-tools` 的話，直接指向執行檔比 `npx -y firebase-tools@latest` 好 ——
  後者每次啟動都重新解析套件，較慢也較容易失敗

## 步驟六：重啟 Agent 並唯讀驗證

> 🖐️ 完全關閉 agent 再重新開啟（各 agent 重啟方式見下）。

對 agent 說：

```text
請先回報 Firebase MCP 的專案目錄、登入帳號與目前專案 ID，
再唯讀列出 Firestore 資料庫與集合。不要新增、修改或刪除資料。
```

**必須確認三項一致：**

1. 專案目錄是剛建立或選定、且含 `firebase.json` 的資料夾
2. Active Project ID 是使用者選擇的專案
3. `firestore_*` 工具已載入

> 只看到核心工具（沒有 `firestore_*`）時：先修正 `cwd` 或 `--dir`，
> 或呼叫 `firebase_update_environment(project_dir=...)`，再重啟 agent。

## 步驟七：功能測試（選用）

**先完成唯讀測試。** 使用者另外同意寫入測試後才執行：

1. **使用包含日期時間的唯一文件 ID**，避免覆蓋既有資料
   （例如 `test_collection/mcp_test_20260802_1430`）
2. 新增一筆 `message`：「Firebase 連接測試成功」
3. 讀回同一份文件
4. **只刪除剛建立的那份測試文件**
5. 再讀一次，確認文件不存在
6. 回報所有動作與清理結果

> ⚠️ 不要刪除其他文件，也不要在連線測試中部署安全規則。

---

## 依你的 Agent

| Agent | MCP 設定檔 | Windows command |
|---|---|---|
| Claude Code | `~/.claude.json`（或專案 `.mcp.json`） | `firebase.cmd` 或 `npx` |
| Codex | `~/.codex/config.toml` | **`npx.cmd`** |
| OpenCode | `~/.config/opencode/opencode.json` | `npx` |
| Antigravity | `~/.gemini/config/mcp_config.json` | **`npx.cmd`** |

### Claude Code

有 CLI 時：

```bash
claude mcp add firebase --scope user -- npx -y firebase-tools@latest mcp
```

> ⚠️ **桌面版沒有 `claude` CLI 時**，手動寫入 `~/.claude.json` 的最上層
> （保留原有內容，只新增這段）。**不要寫進 `settings.json`** ——
> 現行 schema 不接受 `mcpServers`，會回 `Unrecognized field: mcpServers`：

```json
{
  "mcpServers": {
    "firebase": {
      "command": "C:/Users/[使用者]/AppData/Roaming/npm/firebase.cmd",
      "args": ["mcp"]
    }
  }
}
```

macOS / Linux 的 command 用 `firebase`，路徑可用 `which firebase` 查。

**讓 Firestore 工具出現**：重啟後呼叫
`firebase_update_environment(project_dir="含 firebase.json 的資料夾路徑")`。

**重啟**：完全關閉 Claude Code 桌面版再開啟。

### Codex

三種 Codex（Desktop / IDE / CLI）**共用 `~/.codex/config.toml`**。

**方法 A：Desktop GUI（推薦）**

1. 設定 → **Integrations & MCP** → **Add server**
2. Name：`firebase-<專案 ID>`
3. Command：Windows 填 **`npx.cmd`**；macOS / Linux 填 `npx`
4. Args：`-y`、`firebase-tools@latest`、`mcp`、`--dir`、`<含 firebase.json 的絕對路徑>`

**方法 B：手動編輯 `~/.codex/config.toml`**

```toml
[mcp_servers.firebase]
command = "npx.cmd"
cwd = 'C:\Users\<你>\.codex\firebase-projects\<專案 ID>'
args = ["-y", "firebase-tools@latest", "mcp"]
startup_timeout_sec = 60
tool_timeout_sec = 120
default_tools_approval_mode = "writes"
```

> `cwd` 必須指向含 `firebase.json` 與 `.firebaserc` 的資料夾。
> **Windows 路徑用 TOML 單引號**，可避免反斜線被誤判。
> 要同時連多個專案時，建立多個具名 MCP server，或改用專案內的 `.codex/config.toml`。

**方法 C：CLI**

```bash
codex mcp add firebase -- npx -y firebase-tools@latest mcp --dir "<含 firebase.json 的絕對路徑>"
```

> `codex` CLI 在 Windows 顯示 `Access is denied` 時，不要卡在 CLI ——
> 改用 GUI 或手動編輯 `config.toml`。

**重啟**：Desktop 完全結束 app 重開；IDE Reload Window；CLI `exit` 後重開。
**改完 `config.toml` 一定要完整重開**，只在同一輪對話重新搜尋不會載入新 server。

### OpenCode

可先用 `opencode mcp add` 的互動式流程。手動設定：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "firebase": {
      "type": "local",
      "command": [
        "npx", "-y", "firebase-tools@latest", "mcp",
        "--dir", "<專案絕對路徑>",
        "--only", "auth,firestore,storage"
      ],
      "enabled": true
    }
  }
}
```

依需求移除 `--dir` 或調整 `--only`，並**安全合併既有 JSON**。
只是要列出 Firebase 專案的話可以不指定 `--dir`；要操作特定 app 就用絕對路徑限制目錄。

**驗證**：`opencode mcp list`，重啟後說「請列出我的 Firebase 專案」。

> 💡 **先問清楚使用範圍**：要連哪個本機專案目錄？是否已有 `firebase.json`？
> 只需要哪些功能（auth / firestore / storage）？

### Antigravity

依合併流程編輯 `~/.gemini/config/mcp_config.json`：

1. 先用 `Get-Content -Raw | ConvertFrom-Json` 確認 JSON 合法
2. 寫入前建立**帶時間戳的備份**
3. **只新增或更新 `.mcpServers.firebase`**，保留其他 server
4. 同名已存在時先顯示差異並取得同意
5. 寫入後**再次解析驗證**

```json
{
  "mcpServers": {
    "firebase": {
      "command": "npx.cmd",
      "args": ["-y", "firebase-tools@latest", "mcp"]
    }
  }
}
```

要固定到特定專案，在 args 後加入 `"--dir", "C:\\path\\to\\firebase-project"`。

**重啟**：完全重啟 AntiGravity。**預設只做唯讀查詢**，寫入、建立服務或部署前另外確認。

---

## 完成！接下來你可以這樣用

| 你說的話 | Agent + Firebase 會做的事 |
|----------|-----------------------------|
| 「幫我做一個即時文字雲網頁，連接 Firebase」 | 產生前端 + 連接 Firestore + 即時更新 |
| 「幫我做一個課堂投票工具」 | 產生網頁 + 前端連 Firestore（規則由你在 Console 開放該集合） |
| 「幫我把這個工具推到 GitHub Pages」 | 上線（搭配 #02 GitHub 懶人包） |
| 「看一下我 Firestore 現在的規則」 | `firebase_get_security_rules` 讀出目前規則（唯讀，不修改） |
| 「查一下 wordcloud_words 有幾筆、列出最熱門的 5 個關鍵字」 | `firestore_query_collection` 撈資料統計 |
| 「幫我加一筆示範資料」 | `firestore_add_document` |
| 「刪掉所有測試資料」 | `firestore_delete_document` |
| 「幫我查 Firebase 官方文件有沒有 OOO 的做法」 | `developerknowledge_search_documents` |

> 💡 **資料操作的兩種方式**：
> - **網頁前端**：Firebase JS SDK（ESM import + `onSnapshot` 即時更新）
> - **Agent 用自然語言查**：透過 Firebase MCP 的 `firestore_*` 工具直接操作

---

## 進階：部署安全規則（選用）

> ⚠️ **預設流程完全不碰規則。** 這一節只有在使用者**明確要求**時才執行。
>
> **為什麼預設不自動部署？** 自動部署會用範本規則**整份覆蓋**你專案現有的規則，
> 很可能弄壞你既有的 app。

要 agent 協助改規則時，必須依序：

1. 先用 `firebase_get_security_rules` **讀出目前的線上規則給使用者看**
2. 跟使用者確認要改成什麼、影響哪些集合
3. **顯示規則差異**並取得明確同意
4. 才執行部署

課堂 Demo 的公開集合範例 —— 只有在使用者明確指定集合名稱、
確認資料不含學生姓名或敏感資料、並同意公開讀寫風險後才可加入：

```
match /wordcloud_words/{document} {
  allow read, write: if true;
}
```

部署：

```powershell
npx.cmd -y firebase-tools@latest deploy --only firestore:rules
```

> 🔒 **Demo 結束後，把規則還原為預設拒絕，再次確認後部署。**
> **不要把公開寫入規則留在正式服務** —— 正式使用要改成登入、班級碼或教師管理條件。

---

## 如果失敗，如何重來

對你的 agent 說：

> 「Firebase 懶人包執行失敗了，幫我檢查哪裡出問題，重新處理。」

**完全重置 MCP：**

- Claude Code：`claude mcp remove firebase`，或手動刪 `~/.claude.json` 的 `mcpServers.firebase`
- Codex：Desktop 設定刪除／手動刪 `[mcp_servers.firebase]` 段／`codex mcp remove firebase`
- OpenCode：移除 `opencode.json` 的 `mcp.firebase`
- Antigravity：從 `mcp_config.json` 移除 `firebase`，保留其他 server，寫入後再解析驗證

**重新登入：**

```powershell
npx.cmd -y firebase-tools@latest logout
npx.cmd -y firebase-tools@latest login
```

> **移除 MCP 設定不會刪除 Firebase 專案或雲端資料。**

---

## 完成回報格式

```text
firebase-tools：版本
登入帳號：<帳號>
專案清單：<數量> 個
Active Project ID：<ID>
專案目錄：未指定 / <完整路徑>（含 firebase.json）
功能限制：全部 / auth,firestore,storage
MCP 連線：已連線 / 失敗
firestore_* 工具：已載入 / 只有核心工具
唯讀驗證：成功 / 失敗
寫入測試：未執行 / 成功（測試文件已刪除）
安全規則：未變動 / 已依明確要求部署
初始化：未執行 / 已另行確認
```

---

## 常見問題

| 問題 | 解法 |
|------|------|
| `npx: command not found` | 確認 Node.js 已安裝，重啟終端機或 agent |
| PowerShell 報 `npx.ps1 cannot be loaded because running scripts is disabled` | 執行原則擋到 `.ps1`。改用 `npx.cmd`（`npm` 同理改 `npm.cmd`） |
| 只有核心工具，沒有 `firestore_*` | 沒指到專案目錄。修正 `cwd` / `--dir`，或呼叫 `firebase_update_environment(project_dir=...)` |
| 連接後查詢失敗 | 確認已成功 `firebase login` |
| 看不到 Firestore 資料 | 確認已在 Console 啟用 Cloud Firestore |
| 安全性規則過期 | 用了「測試模式」。到 Console → Firestore → 規則改成白名單或登入限制 |
| 寫入失敗：`Permission denied` | Firestore 規則沒允許這個集合。到 Console 幫該集合加規則 |
| `Collection id is invalid because it contains /` | `collection_path` 不能含尾巴 `/`，寫 `wordcloud_words` 不要 `wordcloud_words/` |
| `firestore_query_collection` 回 `read_time cannot be in the future` | MCP 查詢工具的時間參數問題。先用 `firestore_get_document`、`firestore_list_documents` 驗證可讀取，必要時重啟 MCP |
| `firestore_add_document` 說 document 格式 invalid | 不要把 document 包成 JSON 字串，要傳物件格式，例如 `fields.message.stringValue` |
| `firebase login` 在對話中卡住 | 互動式登入無法在 agent 對話內完成。請使用者開 cmd / PowerShell 手動跑一次 |
| **Codex** 重開前看不到 Firebase 工具 | 改完 `config.toml` 要完整重開 Codex，同一輪對話重新搜尋不會載入 |
| **Codex** `codex --version` 顯示 `Access is denied` | 不影響 Desktop。改走 GUI 或手動編輯 `config.toml` |
| Agent 讀 Google Drive 專案資料夾出現 sandbox 權限錯誤 | 需要使用者授權該路徑。同意授權後重跑，不要先判定檔案壞掉 |
| GitHub Pages 無法啟用 | 免費方案不支援私有 repo 的 Pages，需改成公開 |

---

## 免費方案說明（Spark 方案）

| 項目 | 免費額度 | 老師夠用嗎？ |
|------|---------|------------|
| Firestore 儲存 | 1 GB | ✅ 綽綽有餘 |
| Firestore 讀取 | 50,000 次/天 | ✅ 一個班級用不完 |
| Firestore 寫入 | 20,000 次/天 | ✅ 足夠 |
| 專案數量 | 無限 | ✅✅ |
| Authentication | 10,000 月活 | ✅ 用不完 |
| 閒置暫停 | 不會暫停 | ✅✅ 不用設防暫停排程 |

---

## 安全與隱私提醒

- **不要把 Firebase Admin SDK／service account 憑證放進公開的程式碼或 repo**
- 前端網頁使用的 Firebase Config（apiKey 等）是**設計給前端使用的，可以公開**
- `.firebaserc` 可能包含專案 ID，公開前先確認
- 示範時使用假資料，不要放真實學生個資
- **去識別化**：正式使用時只存**班級代號 + 座號**，不存學生真名

### 建議架構

| 頁面 | 功能 | 需要登入 |
|------|------|---------|
| 學生提交頁 | 答題、輸入文字 | 不需要 |
| 公開展示頁 | 文字雲、即時投票結果 | 不需要 |
| 老師管理 | Agent + MCP 直接查詢 | 不需要（本機操作） |

---

## 更新紀錄

| 日期 | 版本 | 更新內容 |
|------|------|---------|
| 2026-08-02 | v1.0 | 合併版：整併四份 Firebase 懶人包。預設採用「完全不碰線上規則」（Claude 版最新做法），Codex 版的規則部署流程改為明確同意才執行的進階章節；保留 OpenCode 的 `--only` 限縮與「初始化是另一個動作」、Antigravity 的合併流程與唯讀預設、Codex 的 `npx.cmd` 與 `cwd` 踩坑 |

---

## 相關連結

- [Firebase 官網](https://firebase.google.com)
- [Firebase MCP Server 官方文件](https://firebase.google.com/docs/ai-assistance/mcp-server)
- [Cloud Firestore 文件](https://firebase.google.com/docs/firestore)
- [#02：連接 GitHub](02-連接-GitHub.md)（教材上線用）
- [懶人包索引](../README.md)
