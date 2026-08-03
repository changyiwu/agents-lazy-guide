# AI Agent 通用懶人包

> 一份懶人包，四個 agent 通用：**Claude Code / Codex / OpenCode / Antigravity**。
>
> 取代原本各自維護的 `claude-code-lazy-packs`、`codex-lazy-packs`、
> `opencode-lazy-packs`、`antigravity-lazy-pack`。

---

## 為什麼合併

原本四份懶人包講的是同樣 6 個主題，共 23 份教學 MD、26 份 SKILL.md，改一次要改四遍。

實際上 agent 之間的差異只有兩件事：**全域技能目錄、安裝方式**。
這是一張表就能表達的，不需要四份文件。所以本 repo 的做法是：

- 內容只留**一份**，放在 `guides/`（人看的教學）與 `skills/`（agent 執行的步驟）
- 差異全部集中在 **`agents.json`**
- 技能名稱四個 agent **完全相同**，統一用 `agent-` 前綴

---

## 使用方式

### 給使用者

1. 把整個 repo 交給你的 agent
2. 說「安裝懶人包」
3. Agent 會讀 `INSTALL.md`，列出項目讓你選，然後裝到正確的全域目錄

### 給 AI Agent

讀 [`INSTALL.md`](INSTALL.md)。

### 手動安裝

```powershell
powershell -ExecutionPolicy Bypass -File "scripts/install.ps1" -Agent claude -Topic github
```

`-Agent` 可填 `claude` / `codex` / `opencode` / `antigravity` / `all`；
`-Topic` 省略即全部；加 `-ListOnly` 只看不寫；加 `-Force` 覆蓋既有安裝。

---

## 懶人包清單

| 編號 | 主題 | 教學 | 技能 |
|------|------|------|------|
| 00 | 環境建置 | [教學](guides/00-環境建置.md) | `skills/00-env-setup` |
| 01 | 連接 Gemini Notebook | [教學](guides/01-連接-Gemini-Notebook.md) | `skills/01-gemini-notebook` |
| 02 | 連接 GitHub | [教學](guides/02-連接-GitHub.md) | `skills/02-github` |
| 03 | 連接 Obsidian 第二大腦 | [教學](guides/03-連接-Obsidian.md) | `skills/03-obsidian` |
| 04 | 連接 Firebase 資料庫 | [教學](guides/04-連接-Firebase.md) | `skills/04-firebase` |
| 05 | 生圖 | [教學](guides/05-生圖.md) | `skills/05-draw`（含 `draw.py`） |
| — | 一次安裝全部 | — | `skills/install-all` |

> 六個主題全部搬移完成。原本四份懶人包共 23 份教學 MD、26 份 SKILL.md，
> 現在是 6 份教學 + 7 份技能。

---

## Repo 結構

```
agents-lazy-guide/
├── README.md            # 你正在看的，人看的索引
├── INSTALL.md           # AI Agent 讀的安裝入口（不可改名為 SKILL.md）
├── agents.json          # ★ 四個 agent 的差異表，唯一的差異來源
├── TEMPLATE.md          # 懶人包寫作規範
├── guides/              # 人看的完整教學，一主題一份
├── skills/              # Agent 執行的精簡步驟，一主題一份
└── scripts/
    └── install.ps1      # 讀 agents.json，裝到各 agent 的正確目錄
```

**兩層設計**：`guides/` 給人看（含背景、註冊引導、常見問題），`skills/` 給 agent 執行
（精簡步驟、安全規則、復原）。兩層都只有一份，不因 agent 而分岔。

---

## Agent 差異對照

| | 全域技能目錄 |
|---|---|
| Claude Code | `~/.claude/skills/` |
| Codex | `~/.agents/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| Antigravity | `~/.gemini/config/skills/` |

> 這裡的 **Antigravity 指 Antigravity 2.0 桌面 App**（獨立的 agent 應用），不是程式編輯器／IDE。

技能名稱四個 agent 相同，統一用 `agent-` 前綴：`agent-github`、`agent-obsidian`、
`agent-firebase`、`agent-draw`、`agent-env-setup`、`agent-gemini-notebook`、`agent-install-all`。

> **重點是「四家同名」，不是「有沒有前綴」。** OpenCode 會同時掃描 `~/.claude/skills`
> 與 `~/.agents/skills`，所以用**各自**的前綴（`claude-github`／`codex-github`／
> `opencode-github`）會讓同一主題在 OpenCode 裡出現三份；四家同名則會被自動去重成一份。
> 實測（opencode 1.17.11）：切換前載入 35 個技能、六主題佔 18 份；切換後 23 個、六主題各 1 份。
>
> 前綴選 `agent-` 而非完全不帶，是為了讓本專案的七個技能在全域目錄裡集中成一區
> ——純 slug 按字母排序會散落各處，也比較容易誤觸發。

完整差異（安裝指令、探索路徑、各 agent 注意事項）見 [`agents.json`](agents.json)。

---

## 目前狀態：已安裝（2026-08-02）

六個主題全部搬移完成，並已切換到四個 agent 的全域目錄。
舊 repo 留下的 24 個各自前綴技能（`claude-*`／`codex-*`／`opencode-*`／`antigravity-*`）已清除。

重新安裝或更新：

```powershell
powershell -ExecutionPolicy Bypass -File "scripts/install.ps1" -Agent all -Force
```

> 改前綴要同時改 `agents.json` 的 `prefix` 與各 `SKILL.md` 的 `name`（兩者不符會被腳本擋下），
> 改完重裝，並記得清掉舊名稱的資料夾
> ——名稱不同的技能**不會互相覆蓋**，舊的會變成孤兒留在原地。

---

## 舊 repo 怎麼辦

四個舊 repo **不刪除**，README 改為指向本 repo 的 stub。
`claude-code-lazy-packs` 是公開 repo，直接刪除會斷掉他人既有連結。

---

## 致謝與來源

本專案改編自 **三師爸（宋睿偉）** 的
[claude-code-lazy-packs](https://github.com/mathruffian-dot/claude-code-lazy-packs)，
依自身使用需求整併為四 agent 通用版本。原始著作權歸原作者所有。

## 授權

MIT License，歡迎自由使用與分享。
