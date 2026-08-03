---
name: agent-draw
description: 生圖技能。當使用者要求「畫一張」、「生一張圖」、「做一張圖」、「產生圖片」、「畫個封面」、「畫插圖」、「畫示意圖」、「畫分鏡」，或要「改這張圖」、「把背景換成 XX」等任何需要 AI 生成或修改圖像的情境時，請一定要使用此技能。優先使用 agent 內建生圖工具；沒有內建能力時，執行本 Skill 同目錄的 draw.py 以 gpt-image-2 生圖，預設 quality low，存到當前專案的 slides/generated/（無則 generated/）。
---

# 生圖

完整教學見 `guides/05-生圖.md`（含 OpenAI 儲值、Individual 驗證、API Key 取得）。

## 先選路線

1. **路線 A：agent 內建生圖** —— 先確認目前介面**確實存在**可呼叫的內建生圖工具
   （Codex 有 `imagegen`；Antigravity 視 IDE 版本）。存在就走這條，不需要 API Key。
   **找不到就不要假裝有這個能力** —— 回報現況並詢問是否改走路線 B。
   也不要因為目錄裡有腳本就自動改走 API。
2. **路線 B：OpenAI API + 同目錄的 `draw.py`** —— Claude Code 與 OpenCode 沒有內建生圖，
   一律走這條；其他 agent 在使用者明確指定「用 OpenAI 生圖」時才走。

> ⚠️ 訂閱額度與 OpenAI API Platform 是**分開的兩套帳**。能用內建工具不代表 API 已開通。

## 路線 A 流程

1. 先確認：用途、尺寸比例、主題、畫面內容、風格、色彩、文字、限制、輸出位置。
2. 用自然語言請內建工具產圖。
3. **回報完整絕對路徑**。圖片預設存在 agent 的暫存目錄
   （Codex：`~/.codex/generated_images/<工作識別碼>/`）。
4. 專案要引用的圖片，複製到專案 `assets/` 或使用者指定位置，並回報新路徑
   —— **不要只留在暫存目錄**。

## 路線 B 流程

### 前置檢查

1. 確認**本 Skill 同目錄**的 `draw.py` 存在。
2. 確認 `uv --version` 可用（或 `python --version` ≥ 3.10）。
3. 確認 `OPENAI_API_KEY` 環境變數存在，或使用者家目錄的 `.openai.env` 含該變數。
   **只回報「已設定／未設定」**，不可輸出金鑰內容。

### 執行

先確認本 Skill 的實際目錄，再執行同目錄的 `draw.py`：

```powershell
uv run --with openai python "<本 Skill 目錄>/draw.py" "<完整提示詞>" --name <簡短名稱> --quality low
```

沒有 uv 時先 `pip install openai`（macOS/Linux 加 `--break-system-packages`），改用 `python` 直接執行。

各 agent 的安裝位置（名稱都是 `agent-draw`）：`~/.claude/skills/agent-draw/`、
`~/.agents/skills/agent-draw/`、`~/.config/opencode/skills/agent-draw/`、
`~/.gemini/config/skills/agent-draw/`。

### 參數

`prompt`（必填）、`--size`（`1024x1024` 預設 / `1536x1024` 橫 / `1024x1536` 直）、
`--quality`（`low` 預設 / `medium` / `high` / `auto`）、`--n`（1–8）、`--name`（檔名前綴）、
`--outdir`（輸出目錄）、`--edit <圖片路徑>`（改圖）、`--mask <遮罩路徑>`（搭配 `--edit`）。

輸出：`<name>_<YYYYMMDD_HHMMSS>.png`。
預設位置：有 `slides/` → `slides/generated/`；否則 `generated/`；使用者指定則用 `--outdir`。
Key 讀取順序：shell 環境變數 → 當前目錄 `.env` → `~/.openai.env`。

## 品質等級

**預設永遠 `low`**：

- **low** — 99% 情境。簡報、教學插圖、封面、demo 都夠。
- **medium** — low 細節明顯不足時才用。
- **high** — 實體印刷、跨語言文字要零錯才用。
- **auto** — 不要用，費用不可預測。

不確定就 `low`，**不要自作主張升級**。

## 代理工具隔離規則

- 本 Skill **只能執行自己目錄下的 `draw.py`**。
- **不得**搜尋、載入、複製、修改或改用其他 agent 的生圖 Skill
  （不要因為在別的目錄找到同名的 `draw/` 就改用那一份，尤其是舊 repo 留下的
  `claude-draw`／`codex-draw`／`opencode-draw`／`antigravity-draw`）。
- 同目錄缺少 `draw.py` 時，**立即停止生圖並回報安裝不完整**，
  用 `scripts/install.ps1` 從本 repo 重新安裝。**不得刪除或簡化本 Skill。**

## 安全規則

- **不印出、不回報 API Key**；不可用 `type`／`cat`／`Get-Content` 顯示 `.openai.env` 全文。
- 不把 Key 寫進腳本、Skill、Markdown、`AGENTS.md`／`CLAUDE.md`、對外筆記或 Git。
- 專案 `.gitignore` 必須忽略 `.openai.env`。
- **不在終端輸出完整 prompt。**
- API 失敗時只回報狀態碼、原因與 request ID，**不傾印完整回應**。
- 不把暫存圖片全部 commit；刪除暫存檔前先詢問使用者。

## 錯誤處理

- `403 Organization must be verified` → 到 platform.openai.com/settings/organization/general 做 Individual 驗證
- `401 Invalid API key` → 檢查環境變數與 `~/.openai.env`
- `429 Rate limit` → 額度用完，到 Billing 儲值

## 驗收與回報

確認圖片存在、可開啟、尺寸與格式符合需求。**中文文字需人工檢查**，重要文字建議後製。

回報：使用路線（A／B）、API Key 已設定／未設定（不顯示內容）、`draw.py` 是否存在、
模型、品質、尺寸、測試結果、**完整輸出檔案路徑**。
