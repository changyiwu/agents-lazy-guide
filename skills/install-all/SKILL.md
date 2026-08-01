---
name: install-all
description: 一次安裝並執行全部六個懶人包技能（環境建置、Gemini Notebook、GitHub、Obsidian、Firebase、生圖）。說「全部安裝」「裝完所有懶人包」「一次安裝全部」時載入。
---

# 一次安裝全部

> ⚠️ **「安裝 Skill」不等於「授權執行它」。**
> 安裝只是把技能檔案放到全域目錄；每一項要不要實際執行（登入、建立遠端資源、寫入檔案），
> 都要**逐項再確認**。不可把一次「全部安裝」擴張成登入或建立資源的授權。

> 💡 只要完成基礎環境、暫時不處理 GitHub 帳號的話，**不要用「全部安裝」** ——
> 只安裝並執行 `env-setup` 即可。

## 六個項目

| 編號 | 技能 | 內容 | 前置需求 |
|------|------|------|---------|
| 00 | `env-setup` | Node.js LTS、uv、agent 本體與登入 | 無 |
| 01 | `gemini-notebook` | Gemini Notebook（原 NotebookLM）MCP | uv |
| 02 | `github` | Git、GitHub CLI 與登入 | 無 |
| 03 | `obsidian` | Obsidian vault 連接（MCPVault 或資料夾授權） | Node.js、vault |
| 04 | `firebase` | Firebase / Firestore MCP | Node.js、Google 帳號 |
| 05 | `draw` | 生圖（agent 內建或 OpenAI gpt-image-2） | uv、（路線 B）OpenAI API Key |

安裝後的實際名稱會加上該 agent 的前綴，例如 Claude Code 是 `claude-github`。

## 步驟

1. **辨識目前的 agent**（讀 `agents.json`），無法自我辨識時直接問使用者。
2. **列出上表與目前安裝狀態**，讓使用者選擇「全部」或編號組合。
3. **安裝**（四個 agent 都用同一個腳本，會自動改寫 frontmatter 前綴）：

   ```powershell
   powershell -ExecutionPolicy Bypass -File "scripts/install.ps1" -Agent <agent>
   ```

   先看會做什麼而不寫入：加 `-ListOnly`。更新既有安裝：加 `-Force`（預設不覆蓋）。

4. **逐項確認是否要執行 00–05**。已安裝且驗證正常的外部工具可以跳過執行，
   但對應的 Skill 本身仍須保留在全域目錄。
5. **驗收**：確認 `<全域技能目錄>/<前綴><slug>/SKILL.md` 存在，
   且 frontmatter `name` 與資料夾名稱一致。
   只看到 `02-github` 這種帶編號的資料夾視為命名錯誤，不得回報成功。

## 舊版技能處理

偵測到舊 repo 留下的同主題技能（例如 `codex-notebooklm`、`opencode-browser`、
`opencode-second-brain`、`antigravity-notebooklm`）時，**先回報清單並取得使用者同意**才處理。
**不得自行覆蓋或刪除。**

## 回報

每完成一項報告進度。最終給總表，逐項列出：

- 安裝狀態（✅ 已安裝 / ⚠️ 已存在 / ❌ 失敗 / 跳過）
- 實際全域路徑
- 驗證結果
- 使用者仍需完成的互動步驟（例如瀏覽器登入）
- 建立的檔案或遠端資源
- 未執行或跳過的項目與原因
