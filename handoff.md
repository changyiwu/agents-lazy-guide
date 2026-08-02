# 交接檔（handoff.md）

> 任何 Agent、任何電腦接手前**必讀**；收工時**必更新**。本檔只放交接必需的精簡資訊，詳細脈絡放 Obsidian（L3）。

## ⏯️ 目前做到哪

六個主題 ＋ install-all 全部搬移完成，**已安裝到四個 agent 的全域目錄**，
舊 repo 留下的 24 個各自前綴技能也已清除。技能名稱四家統一為 `agent-<slug>`。

## 🚦 目前狀態

- **已上線**：四個目錄各 22 個技能，其中 7 個是本專案的 `agent-*`
- **OpenCode 去重驗證通過**：切換前載入 35 個技能、六主題佔 18 份；切換後 23 個、六主題各 1 份
- **內容為文件整併，尚未逐項重跑實測**：各主題的步驟取自四份來源的聯集，
  但合併後的流程本身還沒在真機上從頭跑過一次

## ➡️ 下一步

1. 在四個 agent 各抽一個主題實跑，確認合併版步驟可用（`agents.md` 階段六）
2. 舊四個 repo 的 README 改成指向本 repo 的 stub（**不要刪 repo**）
3. 之後每次改動 `skills/` 或 `agents.json`，重跑
   `scripts/install.ps1 -Agent all -Force`，再跑 `sync-skills` 更新安裝清單

## ⚠️ 注意事項

- **前綴必須四家相同。** 目前是 `agent-`。改成各自的 `claude-`／`codex-` 會讓
  OpenCode 同時看到三份同主題技能（它會掃 `~/.claude/skills` 與 `~/.agents/skills`）
- **改 `prefix` 後舊名稱不會被覆蓋**，會變孤兒留在原地，要另外清掉
- **來源 `skills/*/SKILL.md` 的 `name` 寫不帶前綴的 slug**（`github`），
  `agent-` 由 `install.ps1` 安裝時加上。不要手動寫進源檔
- **根目錄絕對不能出現 `SKILL.md`**，否則 `npx skills` 會把整個 repo 當單一 Skill
- 舊 repo 可能還有已退役的技能（`codex-notebooklm`、`opencode-browser`、
  `opencode-second-brain`、`antigravity-notebooklm`），清理前先取得使用者同意
- #04 Firebase 的預設是「完全不碰線上安全規則」（採 Claude 版最新做法），
  Codex 舊版的規則部署流程已降級為需明確同意的進階章節 —— 改動這段前先確認這個取捨

## 🕐 最後更新

- 時間：2026-08-02 04:10
- 更新者：Claude Code @ PC-YI-FY
- Git push：✅ 已推
