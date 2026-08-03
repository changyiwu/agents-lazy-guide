---
title: 通用懶人包製作規範
date: '2026-08-02'
type: 規範文件
tags:
  - 懶人包
  - 模板
---

# 通用懶人包製作規範

> 每個主題都要有兩份：`guides/<編號>-<標題>.md`（人看）與 `skills/<編號>-<slug>/SKILL.md`（agent 執行）。
> 兩份都只有一版，不因 agent 分岔。

---

## 名詞說明

| 名詞 | 意思 |
|------|------|
| **slug** | 主題的英文短代號，只用**小寫英數與連字號**（`github`、`env-setup`、`gemini-notebook`）。定義在 `agents.json` 的 `topics[].slug`，是整個 repo 的名稱本體。 |
| **編號** | 兩位數的章節序號（`00`–`05`），只用來維持教學順序與 `guides/` ↔ `skills/` 的對應。**不是名稱的一部分**，不會出現在安裝結果裡。 |
| **prefix（前綴）** | 加在 slug 前面的字串，定義在 `agents.json` 每個 agent 的 `prefix`。目前四家統一為 `agent-`。`install.ps1` 只拿它**驗證**來源 name，不再改寫。 |
| **安裝名** | 技能裝到全域目錄後的資料夾名，也是來源 frontmatter 的 `name`。等於 `<prefix><slug>`。 |

同一個主題在不同位置的長相（以 GitHub 為例）：

```
agents.json     "slug": "github"        ← 本體
來源資料夾      skills/02-github/        ← 編號 + slug
來源 name       name: agent-github       ← prefix + slug，直接寫在來源
安裝後          agent-github             ← 與來源 name 相同（原樣複製）
```

> **為什麼 slug 只能用小寫英數與連字號**：這不是本專案的偏好，是工具的硬性要求。
> OpenCode 明文規定技能 `name` 為 1–64 字元的小寫英數與連字號，其他三家也相容此格式。
> 中文、空格、底線都不行。`sync-skills` 技能的步驟 1 會用
> `^[A-Za-z0-9._-]+$` 檢查並在不合格時停下來問人。

---

## 最高原則：不要為了某個 agent 開新檔

發現內容因 agent 而異時，依序考慮：

1. **能不能用 `agents.json` 表達？**（技能目錄、安裝指令、探索路徑）→ 寫進 `agents.json`
2. **是不是操作上的小差異？** → 寫進該篇的「依你的 Agent」表格
3. **真的完全不適用某個 agent？** → 在 `agents.json` 該 agent 的 `notes` 說明

**任何情況都不要建立 `guides/02-連接-GitHub-codex.md` 這種檔案。**

---

## guides/：人看的教學

### 必備區塊（順序不可更動）

```
frontmatter
標題 + 版本 + 更新日期 + 適用 agent
## 這份懶人包會幫你做什麼？      3–5 個 bullet，讓人 10 秒內決定要不要用
## 先備條件                      checkbox，一看就知道自己缺什麼
## 完成標準                      checkbox，做完怎麼算成功
## 執行原則（給 AI Agent）        安全規則
## 步驟零：環境檢查               ★ 每篇都要有
## 步驟一～N                     實際操作
## 依你的 Agent                  四 agent 差異表
## 完成回報格式                  固定格式的回報範本
## 如果失敗，如何重來             完整復原步驟
## 常見問題                      表格
## 更新紀錄                      表格
```

### frontmatter

```yaml
---
title: 'AI Agent 懶人包 #XX：[名稱]'
date: 'YYYY-MM-DD'
type: 懶人包
version: vX.X
status: 合併版（實作後更新） / 實測中 / 穩定版
tags:
  - 懶人包
  - [相關標籤]
---
```

### 步驟零模板（直接複製）

```markdown
## 步驟零：環境檢查

> 開始前先自動確認以下項目。任何一項不符合，先告知使用者問題所在並引導解決後再繼續。
> **不要跳過任何一項，不要假設環境正常。**

1. **確認作業系統**（Windows / macOS / Linux）—— 後續指令依實際系統選擇正確版本
2. **確認網路連線正常**
3. [依主題新增檢查項目]

> 全部通過後告知：「環境檢查完成，開始執行。」
> 安裝完工具後若指令仍找不到，提醒使用者完全關閉並重開 agent。
```

---

## skills/：Agent 執行的步驟

### frontmatter

```yaml
---
name: agent-<slug>    # ★ 直接寫含前綴的安裝名，四家同名
description: <觸發語句>。說「XXX」時載入。
---
```

> `name` 直接寫**含 `agent-` 前綴**的安裝名（`agent-github`），**不要**寫成 `claude-github`
> 這種各自前綴。`install.ps1` 只驗證它等於 `agents.json` 的 `<prefix><slug>`，
> 不一致就報錯並要求改來源；安裝時是**原樣複製**，不改寫任何內容。
>
> **為什麼不靠安裝時改寫**：`sync-skills` 以來源 frontmatter 的 `name` 決定安裝名，
> 並逐檔比對 hash 證明副本一致。若前綴由安裝時加上，來源叫 `github`、副本叫 `agent-github`，
> 兩邊 name 與內容都對不起來，`sync-skills` 會報錯。
>
> description 也不要提到特定 agent 名稱。
>
> **前綴四家必須相同**：OpenCode 會同時掃描 `~/.claude/skills` 與 `~/.agents/skills`，
> 用**各自**的前綴會讓同一主題出現三份不同名的技能；四家同名才會被自動去重。
> 選 `agent-` 而非完全不帶，是為了讓本專案技能在全域目錄集中成一區。
> 詳見 `agents.json` 的 `skillDiscovery` 與 `repoRules.whySharedPrefix`。

### 必備區塊

```
# 標題
一行指向 guides/ 的完整教學
## 步驟          編號流程，精簡可執行
## 安全規則      不做什麼、什麼要先取得同意
## 復原          怎麼回到乾淨狀態
## 回報          要回報哪些欄位
```

長度控制在 40–60 行。背景說明、註冊引導、常見問題留給 `guides/`。

---

## 寫作規則

### 給 Agent 的指令要明確

- ✅ 「執行 `git --version`，如果未安裝，先詢問再引導安裝」
- ❌ 「確認 Git 有裝好」（太模糊，會被跳過）

### 手動操作要標記

用 🖐️ 標記所有需要使用者親自操作的地方，並說明：要做什麼、為什麼要手動、做完怎麼確認。

### 跨平台指令要分開寫

Windows / macOS / Linux 用明確標題區分，或在步驟零要求 agent 判斷後選擇。

### 安全規則每篇都要有

至少涵蓋：

- 安裝軟體前先詢問
- 修改全域設定前先顯示現值
- 建立遠端資源前確認名稱與可見性
- 刪除任何東西前必須再次確認
- 不把 token、密碼、驗證碼寫進 repo 或對話
- 「安裝 Skill」不等於「授權執行它」

### 錯誤處理要具體

每個步驟都要寫「失敗怎麼辦」，給具體排查方向，不要只說「請重試」。

---

## 合併既有內容時：取聯集，不要挑一份當基底

從舊的四份懶人包搬內容時，四份各有別人沒有的價值。以 #02 GitHub 為例：

| 來源 | 獨有的內容 |
|---|---|
| Claude Code 版 | GitHub 帳號註冊逐步引導、Pages 教材上線、常見問題表 |
| Codex 版 | GitHub CLI 與 GitHub App 的區別、`Access is denied` 說明、完成回報格式 |
| OpenCode 版 | 跨平台安裝指令、私人測試 repo 預設 |
| Antigravity 版 | 安全規則區塊、唯讀驗收、復原步驟 |

**四份都要讀完再動筆**，把獨有的部分全部吃進來。

---

## 版本管理

| 版本 | 含義 |
|------|------|
| v0.1 | 初版，尚未實測 |
| v0.2 | 加入環境檢查、復原機制等防禦性設計 |
| v1.0 | 合併版首發，或經實測後的穩定版本 |
| v1.x | 實作過程中遇到的問題與解法 |

更新流程：改內容 → 更新 frontmatter 的 `version` 與 `date` → 更新紀錄表格加一行 →
若主題狀態有變，同步更新 `agents.json` 的 `topics[].status`、`README.md` 與 `INSTALL.md` 的清單。

---

## 新增一個主題的檢查清單

- [ ] `guides/<編號>-<標題>.md` 已建立，區塊齊全
- [ ] `skills/<編號>-<slug>/SKILL.md` 已建立，`name` 為 `agent-<slug>`
- [ ] `agents.json` 的 `topics` 已加入該主題，`status` 正確
- [ ] `README.md` 與 `INSTALL.md` 的清單已更新
- [ ] `scripts/install.ps1 -Agent all -ListOnly` 看得到該主題
- [ ] 至少在一個 agent 實際安裝過並驗證 frontmatter `name` 與資料夾名一致
