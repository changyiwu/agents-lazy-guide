# 懶人包安裝入口

> 這是給 AI Agent 讀的安裝流程。使用者只要說「安裝懶人包」，agent 就從這裡開始。

> ⚠️ **本檔不可改名為 `SKILL.md`。** 根目錄若存在 `SKILL.md`，`npx skills` 會把整個 repo
> 視為單一 Skill，導致 `skills/` 底下的項目無法被列出。

---

## 步驟一：辨識目前的 Agent

讀取 `agents.json`，依你自己是哪一個 agent 取得對應設定：

| Agent | 全域技能目錄 | 前綴 |
|---|---|---|
| Claude Code | `~/.claude/skills/` | `claude-` |
| Codex | `~/.agents/skills/` | `codex-` |
| OpenCode | `~/.config/opencode/skills/` | `opencode-` |
| Antigravity | `~/.gemini/config/skills/` | `antigravity-` |

**目錄不存在＝這台電腦沒裝那個工具**，略過即可，不要建目錄、不要當成錯誤。

無法自我辨識時，直接問使用者。

---

## 步驟二：列出可安裝項目

| 編號 | 來源資料夾 | 安裝後名稱 | 說明 | 前置需求 |
|------|-----------|-----------|------|---------|
| 00 | `skills/00-env-setup` | `<前綴>env-setup` | Node.js LTS、uv、agent 本體與登入 | 無 |
| 01 | `skills/01-gemini-notebook` | `<前綴>gemini-notebook` | Gemini Notebook（原 NotebookLM）MCP | uv |
| 02 | `skills/02-github` | `<前綴>github` | Git、GitHub CLI 與登入 | 無 |
| 03 | `skills/03-obsidian` | `<前綴>obsidian` | Obsidian vault 連接 | Node.js、vault |
| 04 | `skills/04-firebase` | `<前綴>firebase` | Firebase / Firestore MCP | Node.js、Google 帳號 |
| 05 | `skills/05-draw` | `<前綴>draw` | 生圖（內建或 gpt-image-2），含 `draw.py` | uv |
| — | `skills/install-all` | `<前綴>install-all` | 一次安裝全部 | 無 |

以 Claude Code 為例，02 安裝後就是 `~/.claude/skills/claude-github/SKILL.md`。

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

### 為什麼用這個腳本，而不是各 agent 的原生安裝器

`skills/` 底下的 `SKILL.md` frontmatter 一律寫**不帶前綴的 slug**（例如 `name: github`）。
腳本會在安裝時把 `name` 改寫成 `<前綴><slug>`，再複製到該 agent 的全域目錄。

**這是「維護一份、裝到四個 agent」的關鍵** —— 前綴由安裝時產生，原始檔不分岔。
若直接用各 agent 的原生安裝器，會把 `github` 原名裝進去，四個 agent 的技能就會撞名。

各 agent 的原生安裝指令記錄在 `agents.json` 的 `nativeInstall`，僅作為腳本無法執行時的參考；
若改用原生安裝器，**必須自行把 frontmatter 的 `name` 改成帶前綴的名稱**。

---

## 步驟五：驗收並回報

逐項確認 `<全域技能目錄>/<前綴><slug>/SKILL.md` 存在，且 frontmatter `name` 與資料夾名稱一致。

若只看到 `02-github` 這種帶編號的資料夾，視為命名錯誤，不得回報成功。

**舊版技能處理**：若偵測到舊 repo 留下的同主題技能（例如 `claude-github` 之外還有
`codex-notebooklm`、`opencode-browser`、`opencode-second-brain`、`antigravity-notebooklm` 等），
**先回報清單並取得使用者同意**，才處理。不得自行覆蓋或刪除。

每項回報 ✅／⚠️／❌，列出實際全域路徑，最後給總表，並註明：
安裝狀態、驗證結果、使用者仍需完成的互動步驟、建立的檔案或遠端資源、未執行或跳過的項目。
