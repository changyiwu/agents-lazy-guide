# agents-lazy-guide（專案藍圖）

> 本檔為跨 Agent 通用的專案藍圖（AGENTS.md 開放標準）。任何 Agent 的每個 session 都應先讀本檔＋`handoff.md`。
> Claude Code 不讀 `agents.md`，改由 `CLAUDE.md` 的 `@agents.md` import 本檔；Claude 專屬規範寫在 `CLAUDE.md`。

## 專案簡介

把原本四份各自維護的 AI Agent 懶人包（`claude-code-lazy-packs`、`codex-lazy-packs`、
`opencode-lazy-packs`、`antigravity-lazy-pack`）合併成**一份通用版本**，同時適用
Claude Code / Codex / OpenCode / Antigravity 四個 agent，不用再維護四份。

**核心設計**：內容只留一份，agent 差異全部集中在 `agents.json`，
技能名稱**四個 agent 完全相同**，統一用 `agent-` 前綴（`agent-github`、`agent-obsidian`…）——
關鍵是四家同名，OpenCode 多路掃描時才會自動去重；共用前綴則讓本專案技能在全域目錄集中成一區。
`scripts/install.ps1` 依 `agents.json` 把同一份原始檔原樣裝到各 agent 的正確目錄，
並驗證 frontmatter `name` 與資料夾名一致。

## 關鍵時程

- 2026-08-02：六個主題全部搬移完成、專案初始化、切換上線，技能命名定案為 `agent-<slug>`
- 2026-08-03：前綴改由來源 `SKILL.md` 直接帶（不再安裝時改寫），`install.ps1` 改為驗證＋原樣複製

## 目標與路線圖

- [x] 階段一：建立差異表（`agents.json`）、寫作規範（`TEMPLATE.md`）、安裝腳本（`scripts/install.ps1`）
- [x] 階段二：#02 GitHub 試作並驗證四個 agent 都能正確安裝
- [x] 階段三：搬移其餘五個主題（#00 環境建置、#01 Gemini Notebook、#03 Obsidian、#04 Firebase、#05 生圖）＋ install-all
- [x] 階段四：**一次切換上線** —— 四個 agent 各裝 7 個技能，並清除舊 repo 留下的 24 個各自前綴技能
- [x] 階段五：查證四家官方文件，確立命名規則（見「技能命名規則」）並回寫 `agents.json` 的 `skillDiscovery`
- [x] 階段六：`antigravity-lazy-pack` 編號對齊其他三份（03 Obsidian／04 Firebase／05 生圖）
- [x] 階段七：來源 `SKILL.md` 的 `name` 直接帶 `agent-` 前綴，`install.ps1` 停止改寫（相容 `sync-skills`）
- [ ] 階段八：舊四個 repo 的 README 改成指向本 repo 的 stub（不刪除）
- [ ] 階段九：實機驗證各主題流程（目前內容為文件整併，尚未逐項重跑實測）

## 技能命名規則（定案）

安裝後的名稱是 **`agent-<slug>`，四個 agent 完全相同**。兩條規則不可違反：

1. **前綴必須四家相同。** OpenCode 會同時掃描 `~/.claude/skills` 與 `~/.agents/skills`，
   改成各自的 `claude-`／`codex-` 會讓同一主題在 OpenCode 出現三份；四家同名才會自動去重。
   實測：切換前載入 35 個技能、六主題佔 18 份；切換後 23 個、六主題各 1 份。
2. **來源 `SKILL.md` 的 `name` 直接寫含前綴的安裝名**（`agent-github`）。
   2026-08-03 從「安裝時加前綴」改為「來源就帶前綴」：`sync-skills` 以來源 frontmatter 的
   `name` 決定安裝名並逐檔比對 hash，安裝時改寫會讓來源（`github`）與副本（`agent-github`）
   對不起來而報錯。`install.ps1` 現在只**驗證** `name == <prefix><slug>`，不改寫、原樣複製。

選 `agent-` 而非完全不帶前綴，是為了讓本專案的七個技能在全域目錄按字母排序時集中成一區。

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
- **`skills/*/SKILL.md` 的 frontmatter `name` 一律寫 `agent-<slug>`**（例如 `agent-github`），
  與安裝後的資料夾名一致（OpenCode 硬性要求）。`install.ps1` 只驗證不改寫。
  description 也不要提到特定 agent 名稱。
  **前綴必須四家相同** —— 改成各自的 `claude-`／`codex-` 會讓 OpenCode 同時看到三份同主題技能。
- **根目錄不可出現 `SKILL.md`** —— `npx skills` 會把整個 repo 當成單一 Skill，
  導致 `skills/` 底下的項目列不出來。入口固定用 `INSTALL.md`。
- **新增或修改主題後**，同步更新 `agents.json` 的 `topics`、`README.md`、`INSTALL.md` 三處清單。
- 合併既有內容時**取聯集**，四份來源都要讀完再動筆，不要挑一份當基底。
- 舊四個 repo 保留不刪（`claude-code-lazy-packs` 是公開 repo，刪除會斷他人連結）。
- 本專案改編自三師爸（宋睿偉）的 `claude-code-lazy-packs`（MIT），**致謝須保留於 README.md**。

## 三個檔案的職責（依「時效性」分家，不是依「詳細程度」）

| 檔案 | 時效 | 寫入方式 | 放什麼 |
|------|------|---------|--------|
| `handoff.md` | **只對下一個 session 有效**，過期即丟 | 每次收工整份重寫 | 做到哪、下一步、**這次**的暫時 workaround |
| `agents.md`（本檔） | **長期有效**，每個 session 都適用 | 只有規則本身變了才改 | 目標、路線圖、常設規則、結構 |
| Obsidian／`git log` | **歷史**：發生過什麼、為什麼 | 只增不刪 | 決策紀錄、踩坑完整版、逐次進度 |

驗收標準：**`handoff.md` 整份刪掉，不應損失任何長期資訊**——會的話代表該升級進本檔卻沒升級。

**本檔不要出現的東西**：❌ `## 最近進度`／逐次工作紀錄、❌ 決策理由與踩坑完整版。歷史寫 L3 筆記的〈🗓️ 最近更動紀錄〉〈🧠 決策紀錄〉〈🕳️ 踩坑筆記〉；踩過的坑只把**結論**收斂成一條祈使句寫進〈工作約定〉，原因留 L3。

## 工作約定

- 任何 Agent、任何電腦：**開工先讀 `handoff.md`，收工必更新 `handoff.md`**
- 修改共用檔案前先讀最新內容，避免覆蓋其他 Agent 的變更
- 所有回應與文件使用繁體中文
- 修改前先確認計畫，優先保留原有資料結構
- 改動安裝腳本後，**先用沙箱實測**（複製 `scripts/` + `skills/` 到暫存區、
  改寫 `agents.json` 的 `detectDir`/`skillsDir` 指向假目錄再跑），不要直接動真實技能目錄
- **`scripts/install.ps1` 必須保留 UTF-8 BOM。** 它宣告 `#Requires -Version 5.1`，
  好讓沒裝 PowerShell 7 的電腦也能直接跑；但 Windows PowerShell 5.1 讀「無 BOM 的 UTF-8」
  會當成 ANSI，檔內中文全部亂碼、解析階段就失敗。用編輯器另存時要確認 BOM 沒被拿掉
- **全域技能目錄不在雲端硬碟，每台電腦都要各自跑一次安裝。** 換電腦接手時先確認
  `~/.claude/skills` 等四個目錄裝的是 `agent-*` 還是舊前綴，不要以 `handoff.md` 的記錄為準
