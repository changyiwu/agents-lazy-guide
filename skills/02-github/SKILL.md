---
name: agent-github
description: 連接 GitHub CLI，讓 agent 能管理 repo、commit、push。說「連接 GitHub」「設定 GitHub」時載入。
---

# 連接 GitHub

完整教學見 `guides/02-連接-GitHub.md`。以下是執行流程。

## 觀念

GitHub CLI（`gh`）與 GitHub App / Connector 是兩條不同連線：`gh` 負責本機 repo、commit、push；
App 讓 agent 在對話中讀取 repo、issue、PR。`gh auth status` 成功不代表 App 已連接，反之亦然。
本流程只處理 GitHub CLI；需要在對話中查 GitHub 時才引導連接 App。

## 步驟

1. **檢查工具**：`git --version`、`gh --version`。缺少時先詢問再安裝：
   - Windows：`winget install --id Git.Git` / `winget install --id GitHub.cli`（加 `--accept-source-agreements --accept-package-agreements`）
   - macOS：`brew install git gh`
   - Ubuntu/Debian：依官方套件庫說明，不使用未經確認的第三方腳本
   - 裝完找不到指令：請使用者完全關閉並重開 agent 或終端機
2. **登入**：`gh auth status`；未登入時詢問後執行 `gh auth login --web --git-protocol https`。
   授權須由使用者本人在瀏覽器完成；互動式登入需在互動式終端執行。
   出現 `Access is denied` 可能是權限範圍問題而非登入失敗。
3. **Git 身分**：顯示 `git config --global user.name`、`user.email` 現值。
   只有缺少或使用者要求變更時才設定，且需向使用者取得正確值，不可猜測。
4. **唯讀驗收**：`gh auth status` + `gh repo list --limit 5`。確認帳號正確、能讀 repo 清單。
   **只要求「連接 GitHub」時，做到這裡就結束。**
5. **（選用）push 驗證**：先詢問。優先用使用者指定的既有 repo；要建測試 repo 先確認名稱與可見性，
   預設 `--private`。`git status` → `git add <明確檔名>` → `git commit` → `gh repo create <名稱> --private --source=. --remote=origin --push`。
6. **（選用）GitHub Pages**：會公開到網路上，須另外取得明確同意，並確認內容不含個資。
7. **處理測試資源**：詢問保留或刪除。未經明確確認不得刪除遠端 repo 或本機資料夾；
   刪除本機資料夾前先確認解析後的完整路徑正確。

## 安全規則

- 不要求使用者把 token、密碼或驗證碼貼進 Markdown、repo 或對話紀錄。
- 連線流程本身不自動建立／刪除 repo、不自動 push、不啟用 Pages、不改預設 branch。
- commit 前檢查 `git status` 與 diff，不使用無差別 `git add .`。
- 安裝軟體、修改 Git 全域設定、建立或刪除遠端資源，都要逐項取得同意。

## 復原

`gh auth logout` 後重新登入。Git 身分需復原時，先顯示目前值，再由使用者指定改回什麼。

## 回報

Git 版本、GitHub CLI 版本、登入帳號、Git 使用者資訊、唯讀驗收結果、push 驗證結果、
GitHub App 狀態、Pages 狀態、測試資源處理結果。
