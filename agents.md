# agents-lazy-guide（專案藍圖）

> 本檔為跨 Agent 通用的專案藍圖（AGENTS.md 開放標準）。任何 Agent 的每個 session 都應先讀本檔＋`handoff.md`。
> Claude Code 不讀 `agents.md`，改由 `CLAUDE.md` 的 `@agents.md` import 本檔；Claude 專屬規範寫在 `CLAUDE.md`。

## 專案簡介

把原本四份各自維護的 AI Agent 懶人包（`claude-code-lazy-packs`、`codex-lazy-packs`、
`opencode-lazy-packs`、`antigravity-lazy-pack`）合併成**一份通用版本**，同時適用
Claude Code / Codex / OpenCode / Antigravity 四個 agent，不用再維護四份。

**核心設計**：內容只留一份，agent 差異全部集中在 `agents.json`，
技能名稱**四個 agent 完全相同**（`github`、`obsidian`…），不帶 agent 前綴 ——
四個全域目錄各自獨立不會撞名，而 OpenCode 多路掃描時同名會自動去重。
`scripts/install.ps1` 依 `agents.json` 把同一份原始檔裝到各 agent 的正確目錄，
並保證 frontmatter `name` 與資料夾名一致。

## 關鍵時程

- 2026-08-02：六個主題全部搬移完成，專案初始化

## 目標與路線圖

- [x] 階段一：建立差異表（`agents.json`）、寫作規範（`TEMPLATE.md`）、安裝腳本（`scripts/install.ps1`）
- [x] 階段二：#02 GitHub 試作並驗證四個 agent 都能正確安裝
- [x] 階段三：搬移其餘五個主題（#00 環境建置、#01 Gemini Notebook、#03 Obsidian、#04 Firebase、#05 生圖）＋ install-all
- [ ] 階段四：**一次切換** —— `scripts/install.ps1 -Agent all -Force` 覆蓋舊 repo 裝的同名技能
- [ ] 階段五：舊四個 repo 的 README 改成指向本 repo 的 stub（不刪除）
- [ ] 階段六：實機驗證各主題流程（目前內容為文件整併，尚未逐項重跑實測）

## 資料夾結構

```
agents-lazy-guide/
├── README.md            人看的索引
├── INSTALL.md           AI Agent 讀的安裝入口（★ 不可改名為 SKILL.md）
├── agents.json          ★ 四個 agent 的差異表，唯一的差異來源
├── TEMPLATE.md          懶人包寫作規範
├── agents.md            本檔（專案藍圖）
├── handoff.md           交接檔
├── CLAUDE.md            橋接檔（@agents.md）
├── guides/              人看的完整教學，一主題一份
│   ├── 00-環境建置.md
│   ├── 01-連接-Gemini-Notebook.md
│   ├── 02-連接-GitHub.md
│   ├── 03-連接-Obsidian.md
│   ├── 04-連接-Firebase.md
│   └── 05-生圖.md
├── skills/              agent 執行的精簡步驟，一主題一份
│   ├── 00-env-setup/SKILL.md
│   ├── 01-gemini-notebook/SKILL.md
│   ├── 02-github/SKILL.md
│   ├── 03-obsidian/SKILL.md
│   ├── 04-firebase/SKILL.md
│   ├── 05-draw/SKILL.md ＋ draw.py
│   └── install-all/SKILL.md
└── scripts/
    └── install.ps1      讀 agents.json，裝到各 agent 的正確目錄
```

## 同步層級（本專案初始化至第三層級）

| 層級 | 平台 | 位置 | 讀取時機 |
|------|------|------|---------|
| L1 | 本地（GDrive） | `agents.md`＋`handoff.md`＋`CLAUDE.md`（橋接） | 每個 session |
| L2 | GitHub | [changyiwu/agents-lazy-guide](https://github.com/changyiwu/agents-lazy-guide)（**公開**） | 指定時 |
| L3 | Obsidian | `agents-lazy-guide/專案工作流程.md` | 有需要時 |

## 四個 Agent 差異對照

| | 全域技能目錄 | 是否多路掃描 |
|---|---|---|
| Claude Code | `~/.claude/skills/` | 否 |
| Codex | `~/.agents/skills/` | 否 |
| OpenCode | `~/.config/opencode/skills/` | **是**，另讀 `~/.claude/skills`、`~/.agents/skills` |
| Antigravity | `~/.gemini/config/skills/` | 否 |

完整差異（安裝指令、各 agent 注意事項）以 `agents.json` 為準，**不要在別處另存一份**。

## 專案專屬規則

- **不要為了某個 agent 開新檔案。** 差異依序考慮：能不能寫進 `agents.json` →
  能不能寫進該篇的「依你的 Agent」表格 → 才考慮在 `agents.json` 的 `notes` 說明。
  任何情況都不要建 `guides/02-連接-GitHub-codex.md` 這種檔案。
- **`skills/*/SKILL.md` 的 frontmatter `name` 一律寫不帶 agent 前綴的 slug**（例如 `github`），
  且必須與資料夾名一致（OpenCode 硬性要求）。description 也不要提到特定 agent 名稱。
  **不要為了「區分」而加回前綴** —— 那會讓 OpenCode 同時看到三份同主題技能。
- **根目錄不可出現 `SKILL.md`** —— `npx skills` 會把整個 repo 當成單一 Skill，
  導致 `skills/` 底下的項目列不出來。入口固定用 `INSTALL.md`。
- **新增或修改主題後**，同步更新 `agents.json` 的 `topics`、`README.md`、`INSTALL.md` 三處清單。
- 合併既有內容時**取聯集**，四份來源都要讀完再動筆，不要挑一份當基底。
- 舊四個 repo 保留不刪（`claude-code-lazy-packs` 是公開 repo，刪除會斷他人連結）。
- 本專案改編自三師爸（宋睿偉）的 `claude-code-lazy-packs`（MIT），**致謝須保留於 README.md**。

## 工作約定

- 任何 Agent、任何電腦：**開工先讀 `handoff.md`，收工必更新 `handoff.md`**
- 修改共用檔案前先讀最新內容，避免覆蓋其他 Agent 的變更
- 所有回應與文件使用繁體中文
- 修改前先確認計畫，優先保留原有資料結構
- 改動安裝腳本後，**先用沙箱實測**（複製 `scripts/` + `skills/` 到暫存區、
  改寫 `agents.json` 的 `detectDir`/`skillsDir` 指向假目錄再跑），不要直接動真實技能目錄
