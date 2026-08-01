# 交接檔（handoff.md）

> 任何 Agent、任何電腦接手前**必讀**；收工時**必更新**。本檔只放交接必需的精簡資訊，詳細脈絡放 Obsidian（L3）。

## ⏯️ 目前做到哪

六個主題（#00 環境建置、#01 Gemini Notebook、#02 GitHub、#03 Obsidian、#04 Firebase、#05 生圖）
＋ install-all 全部搬移完成，四個 agent 的沙箱安裝實測通過（28 個 SKILL.md、frontmatter 前綴改寫零錯誤、
`draw.py` 四份都正確跟著複製）。專案初始化完成，已建立 L1／L2／L3。

## 🚦 目前狀態

- **可運行**：`scripts/install.ps1` 已驗證，四個 agent × 7 個技能全數安裝成功
- **尚未安裝到真實環境**：合併版技能名稱與舊 repo 已裝的**完全同名**（`claude-github` 等），
  安裝即原地覆蓋。依 2026-08-02 決定，**等六主題全搬完再一次切換** —— 現在條件已滿足，可以執行
- **內容為文件整併，尚未逐項重跑實測**：各主題的步驟取自四份來源的聯集，
  但合併後的流程本身還沒在真機上從頭跑過一次

## ➡️ 下一步

1. **一次切換**：`powershell -ExecutionPolicy Bypass -File "scripts/install.ps1" -Agent all -Force`
2. 切換後在四個 agent 各抽一個主題實跑，確認合併版步驟可用
3. 舊四個 repo 的 README 改成指向本 repo 的 stub（**不要刪 repo**）
4. 用 `sync-skills` 更新 `.skill-install/PC-YI-FY.json` 的安裝清單

## ⚠️ 注意事項

- **切換會覆蓋現有的 `claude-github` 等 7×4 個技能。** 舊 repo 原始檔完整保留，隨時可還原
- **根目錄絕對不能出現 `SKILL.md`**，否則 `npx skills` 會把整個 repo 當單一 Skill
- `skills/*/SKILL.md` 的 `name` 一律不帶前綴，改動時不要手動加 `claude-` 之類
- 舊 repo 留下的退役技能（`codex-notebooklm`、`opencode-browser`、`opencode-second-brain`、
  `antigravity-notebooklm`）尚未清理，**清理前要先取得使用者同意**
- #04 Firebase 的預設是「完全不碰線上安全規則」（採 Claude 版最新做法），
  Codex 舊版的規則部署流程已降級為需明確同意的進階章節 —— 改動這段前先確認這個取捨

## 🕐 最後更新

- 時間：2026-08-02 03:17
- 更新者：Claude Code @ PC-YI-FY
- Git push：✅ 已推
