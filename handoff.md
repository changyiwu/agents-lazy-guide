# 交接檔（handoff.md）

> 任何 Agent、任何電腦接手前**必讀**；收工時**必更新**。本檔只放交接必需的精簡資訊，詳細脈絡放 Obsidian（L3）。

## ⏯️ 目前做到哪

六個主題（#00 環境建置、#01 Gemini Notebook、#02 GitHub、#03 Obsidian、#04 Firebase、#05 生圖）
＋ install-all 全部搬移完成，四個 agent 的沙箱安裝實測通過（28 個 SKILL.md、frontmatter 前綴改寫零錯誤、
`draw.py` 四份都正確跟著複製）。專案初始化完成，已建立 L1／L2／L3。

## 🚦 目前狀態

- **可運行**：`scripts/install.ps1` 已驗證，四個 agent × 7 個技能全數安裝成功
- **尚未安裝到真實環境**：條件已滿足，可以執行一次切換
- **技能已改用中性名稱**（2026-08-02）：`github` 而非 `claude-github`。原因是 OpenCode 會同時
  掃描 `~/.claude/skills` 與 `~/.agents/skills`，帶前綴會讓同一主題出現三份；同名則自動去重
  （實測 opencode 1.17.11：64 個資料夾 → 載入 35 個、名稱全不重複）
- **內容為文件整併，尚未逐項重跑實測**：各主題的步驟取自四份來源的聯集，
  但合併後的流程本身還沒在真機上從頭跑過一次

## ➡️ 下一步

1. **一次切換**：`powershell -ExecutionPolicy Bypass -File "scripts/install.ps1" -Agent all`
2. **清理 24 個舊的帶前綴技能**（4 目錄 × 6 主題）—— 中性名稱不會覆蓋它們，會變孤兒。
   **先列清單給使用者確認再刪**
3. 切換後在四個 agent 各抽一個主題實跑，確認合併版步驟可用
4. 舊四個 repo 的 README 改成指向本 repo 的 stub（**不要刪 repo**）
5. 用 `sync-skills` 更新 `.skill-install/PC-YI-FY.json`（技能改名後清單會過時）

## ⚠️ 注意事項

- **切換不會覆蓋舊的帶前綴技能**（名字不同），會並存 —— 一定要接著做清理，否則每個主題有兩份
- **根目錄絕對不能出現 `SKILL.md`**，否則 `npx skills` 會把整個 repo 當單一 Skill
- `skills/*/SKILL.md` 的 `name` 一律不帶 agent 前綴，且必須與資料夾名一致。
  **不要為了「區分 agent」把前綴加回去** —— 那正是造成 OpenCode 重複的原因
- 舊 repo 留下的退役技能（`codex-notebooklm`、`opencode-browser`、`opencode-second-brain`、
  `antigravity-notebooklm`）尚未清理，**清理前要先取得使用者同意**
- #04 Firebase 的預設是「完全不碰線上安全規則」（採 Claude 版最新做法），
  Codex 舊版的規則部署流程已降級為需明確同意的進階章節 —— 改動這段前先確認這個取捨

## 🕐 最後更新

- 時間：2026-08-02 03:17
- 更新者：Claude Code @ PC-YI-FY
- Git push：✅ 已推
