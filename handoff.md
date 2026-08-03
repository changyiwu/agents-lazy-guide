# 交接檔（handoff.md）

> 任何 Agent、任何電腦接手前**必讀**；收工時**必更新**。本檔只放交接必需的精簡資訊，詳細脈絡放 Obsidian（L3）。

## ⏯️ 目前做到哪

六個主題 ＋ install-all 全部搬移完成，**三台電腦的四個 agent 全域目錄都已切換完畢**，
舊 repo 留下的各自前綴技能全數清除。技能名稱四家統一為 `agent-<slug>`。
本次（NB-YI）只做這台的清舊裝新，repo 內容未動。

## 🚦 目前狀態

- **已上線的電腦**：PC-YI-FY（2026-08-02）、PC-YI-SL（2026-08-02 補做）、
  NB-YI（2026-08-03 補做）。三台的四個技能目錄現在都是 7 個 `agent-*`，舊前綴殘留為 0
- **NB-YI 切換明細**（2026-08-03）：刪 26 個舊前綴技能
  （claude-* 6／codex-* 7／opencode-* 8／antigravity-* 5，含已退役的
  `codex-essentials`、`opencode-browser`、`opencode-install-all`），
  再跑 `install.ps1 -Agent all -Force` 裝回 7 × 4。
  之後同一天由 `sync-skills` 另外補裝他專案技能，四個目錄現各 22 個資料夾
  （7 個 `agent-*` ＋ 15 個他專案）。**各台的他專案技能數不一致，屬正常**，
  本 repo 只保證 `agent-*` 那 7 個
- **OpenCode 去重驗證通過**：切換前載入 35 個技能、六主題佔 18 份；切換後 23 個、六主題各 1 份
- **內容為文件整併，尚未逐項重跑實測**：各主題的步驟取自四份來源的聯集，
  但合併後的流程本身還沒在真機上從頭跑過一次

## ➡️ 下一步

1. 在四個 agent 各抽一個主題實跑，確認合併版步驟可用（`agents.md` 階段八）
2. 舊四個 repo 的 README 改成指向本 repo 的 stub（**不要刪 repo**）
3. 之後每次改動 `skills/` 或 `agents.json`，重跑
   `scripts/install.ps1 -Agent all -Force`，再跑 `sync-skills` 更新安裝清單

## 🔗 本次一起異動的其他 repo（都已 push）

- `antigravity-lazy-pack`：編號三循環對齊其他三份（03 Obsidian／04 Firebase／05 生圖）。
  安裝名 `antigravity-*` 未變，已安裝者不必重裝。`validate-lazy-pack.ps1` 通過
- `skill-sync`：`sync-skills` 鐵則 4 補上四家官方依據與實測數據
  （57 個 `SKILL.md` 有 36 個資料夾名 ≠ `name`），四份副本已同步並 hash 驗證

## ⚠️ 注意事項

- **前綴必須四家相同。** 目前是 `agent-`。改成各自的 `claude-`／`codex-` 會讓
  OpenCode 同時看到三份同主題技能（它會掃 `~/.claude/skills` 與 `~/.agents/skills`）
- **改 `prefix` 後舊名稱不會被覆蓋**，會變孤兒留在原地，要另外清掉
- **來源 `skills/*/SKILL.md` 的 `name` 寫不帶前綴的 slug**（`github`），
  `agent-` 由 `install.ps1` 安裝時加上。不要手動寫進源檔
- **根目錄絕對不能出現 `SKILL.md`**，否則 `npx skills` 會把整個 repo 當單一 Skill
- **技能目錄不在雲端硬碟，每台電腦都要各自清舊裝新。** 換電腦接手先實際列一次
  四個目錄，不要相信本檔的記錄（PC-YI-SL 與 NB-YI 都是這樣才發現舊技能整組還在）
- **技能目錄會被其他 session／`sync-skills` 同時改動。** NB-YI 這次裝完 9 分鐘後，
  目錄就從 10 個資料夾長到 22 個。要回報目錄狀態就當場重列一次，不要沿用幾分鐘前的結果
- 已退役技能在三台都已刪除（`codex-essentials`、`opencode-browser`、
  `opencode-install-all`、`opencode-second-brain`、四家的 `*-notebooklm`）。
  新 repo 有對應主題的是 notebooklm → `agent-gemini-notebook`、
  install-all → `agent-install-all`；`browser`／`second-brain`／`essentials` 沒有對應主題，已捨棄
- #04 Firebase 的預設是「完全不碰線上安全規則」（採 Claude 版最新做法），
  Codex 舊版的規則部署流程已降級為需明確同意的進階章節 —— 改動這段前先確認這個取捨

## 🕐 最後更新

- 時間：2026-08-03（NB-YI 清舊裝新）
- 更新者：Claude Code @ NB-YI
- Git push：待推
