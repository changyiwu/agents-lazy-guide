# 懶人包安裝入口

> 這是給 AI Agent 讀的安裝流程。使用者只要說「安裝懶人包」，agent 就從這裡開始。

> ⚠️ **本檔不可改名為 `SKILL.md`。** 根目錄若存在 `SKILL.md`，`npx skills` 會把整個 repo
> 視為單一 Skill，導致 `skills/` 底下的項目無法被列出。

---

## 步驟一：辨識目前的 Agent

讀取 `agents.json`，依你自己是哪一個 agent 取得對應設定：

| Agent | 全域技能目錄 |
|---|---|
| Claude Code | `~/.claude/skills/` |
| Codex | `~/.agents/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| Antigravity | `~/.gemini/config/skills/` |

技能名稱**四個 agent 完全相同**，不帶 agent 前綴（`github`、`obsidian`…）。

**目錄不存在＝這台電腦沒裝那個工具**，略過即可，不要建目錄、不要當成錯誤。

無法自我辨識時，直接問使用者。

---

## 步驟二：列出可安裝項目

| 編號 | 來源資料夾 | 安裝後名稱 | 說明 | 前置需求 |
|------|-----------|-----------|------|---------|
| 00 | `skills/00-env-setup` | `env-setup` | Node.js LTS、uv、agent 本體與登入 | 無 |
| 01 | `skills/01-gemini-notebook` | `gemini-notebook` | Gemini Notebook（原 NotebookLM）MCP | uv |
| 02 | `skills/02-github` | `github` | Git、GitHub CLI 與登入 | 無 |
| 03 | `skills/03-obsidian` | `obsidian` | Obsidian vault 連接 | Node.js、vault |
| 04 | `skills/04-firebase` | `firebase` | Firebase / Firestore MCP | Node.js、Google 帳號 |
| 05 | `skills/05-draw` | `draw` | 生圖（內建或 gpt-image-2），含 `draw.py` | uv |
| — | `skills/install-all` | `install-all` | 一次安裝全部 | 無 |

以 Claude Code 為例，02 安裝後就是 `~/.claude/skills/github/SKILL.md`。

---

## 步驟三：讓使用者選擇

問：「你要安裝哪些？輸入全部，或編號組合（例如 00, 02, 03）。」

> 安裝 Skill **不等於**授權執行它。裝完後每一項要不要實際執行（登入、建立遠端資源、寫入檔案），
> 都要逐項再確認。不可把一次「全部安裝」擴張成登入或建立資源的授權。

---

## 步驟四：安裝

在 repo 根目錄執行（四個 agent 都用同一個腳本）：

```powershell
powershell -ExecutionPolicy Bypass -File "scripts/install.ps1" -Agent <agent> -Topic <slug>
```

例：

```powershell
powershell -ExecutionPolicy Bypass -File "scripts/install.ps1" -Agent claude -Topic github
```

全部安裝：

```powershell
powershell -ExecutionPolicy Bypass -File "scripts/install.ps1" -Agent claude
```

先看會做什麼而不寫入：

```powershell
powershell -ExecutionPolicy Bypass -File "scripts/install.ps1" -Agent all -ListOnly
```

更新已存在的項目要加 `-Force`（預設不覆蓋，只回報「已存在」）。

### 為什麼技能不帶 agent 前綴

四個 agent 的全域目錄各自獨立，本來就不會撞名，所以**不需要**前綴。
更重要的是：**OpenCode 會同時掃描 `~/.claude/skills` 與 `~/.agents/skills`**，
所以裝給 Claude Code 與 Codex 的副本它也看得到。

若使用前綴，`claude-github`／`codex-github`／`opencode-github` 是三個不同名字，
會在 OpenCode 裡同時出現三份、全部命中「連接 GitHub」。
**改用同名之後，OpenCode 會自動去重成一份**（first-match-wins）。

> 實測（2026-08-02，opencode 1.17.11）：四個技能目錄共 64 個資料夾，
> OpenCode 只載入 35 個技能且名稱全不重複。詳見 `agents.json` 的 `skillDiscovery.dedup`。

腳本會在安裝時確保 frontmatter 的 `name` 與目標資料夾名一致
（`agents.json` 的 `prefix` 目前皆為空字串，等於原名安裝）。
各 agent 的原生安裝指令記錄在 `nativeInstall`，僅作為腳本無法執行時的參考。

---

## 步驟五：驗收並回報

逐項確認 `<全域技能目錄>/<slug>/SKILL.md` 存在，且 frontmatter `name` 與資料夾名稱一致。

若只看到 `02-github` 這種帶編號的資料夾，視為命名錯誤，不得回報成功。

**舊版技能處理**：舊 repo 裝的是帶前綴的名稱（`claude-github`、`codex-github`、
`opencode-github`、`antigravity-github`…），與本 repo 的同名技能**不會互相覆蓋**，
會變成孤兒留在原地。另外還可能有已退役的 `codex-notebooklm`、`opencode-browser`、
`opencode-second-brain`、`antigravity-notebooklm`。
一律**先回報完整清單並取得使用者同意**，才處理。**不得自行覆蓋或刪除。**

每項回報 ✅／⚠️／❌，列出實際全域路徑，最後給總表，並註明：
安裝狀態、驗證結果、使用者仍需完成的互動步驟、建立的檔案或遠端資源、未執行或跳過的項目。
