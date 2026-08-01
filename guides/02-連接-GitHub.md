---
title: 'AI Agent 懶人包 #02：連接 GitHub'
date: '2026-08-02'
type: 懶人包
version: v1.0
status: 合併版（由四份懶人包整併，實作後更新）
tags:
  - 懶人包
  - GitHub
  - GitHub-Pages
---

# 懶人包 #02：連接 GitHub

> 版本：v1.0（合併版）
> 更新日期：2026-08-02
> 適用：Claude Code / Codex / OpenCode / Antigravity

> 📌 **本懶人包可獨立執行**：會自動檢查並安裝所需工具，不需要先看過 #00 環境建置。

---

## 這份懶人包會幫你做什麼？

- 安裝並檢查 Git 與 GitHub CLI（`gh`）
- 完成 GitHub 登入與 Git 身分設定
- 驗證你的 agent 真的能 commit、push
- （選用）開啟 GitHub Pages，讓學生掃 QR Code 就能打開教材
- 之後每次做好新教材，一句話就能上線

---

## 先備條件

- [ ] 你的 AI Agent 已安裝且能正常使用
- [ ] 有可用的 email 信箱（還沒 GitHub 帳號的話，下面有註冊引導）
- [ ] 電腦有網路連線

---

## 重要觀念：GitHub CLI 與 GitHub App 是兩件事

很多人卡在這裡，先講清楚：

| | 用途 | 怎麼連 |
|---|---|---|
| **GitHub CLI（`gh`）** | 本機的 repo、commit、push、建立 repo | `gh auth login` |
| **GitHub App / Connector** | 讓 agent 在**對話中**讀取 repo、issue、PR | 各 agent 的設定 → Apps / Connectors |

> ⚠️ `gh auth status` 成功**不代表** GitHub App 已連接；
> GitHub App 能讀 repo，也**不代表**本機 Git 有 push 權限。
>
> 本懶人包主要處理 GitHub CLI。GitHub App 是選用（步驟六）。

---

## 完成標準

- [ ] `git --version` 正常
- [ ] `gh --version` 正常
- [ ] `gh auth status` 顯示正確帳號，且 Git operations protocol 為 `https`
- [ ] Git 的 `user.name` 與 `user.email` 已確認
- [ ] 已用既有 repo 或測試 repo 驗證 push（選用）
- [ ] 若需要在對話中查 GitHub，GitHub App 已連接（選用）

---

## 執行原則（給 AI Agent）

> 以下內容是給 AI Agent 讀的操作指令。把這份 MD 丟給你的 agent，它會自動開始執行；
> 遇到需要你手動操作的地方，它會暫停並告訴你怎麼做。

一次只做一個步驟，完成後再繼續。並且：

- **安裝任何軟體前先詢問。**
- **修改 Git 全域姓名或 email 前，先顯示現值再詢問。**
- **建立 GitHub repo 前，先確認名稱與公開／私人設定。**
- **刪除遠端 repo 或本機測試資料夾前必須再次確認**，未經明確同意不得刪除。
- 不把 token、密碼或一次性驗證碼寫進 repo、Markdown 或對話紀錄。
- commit 前先看 `git status` 與 diff，**不使用無差別 `git add .`**。
- 連線流程本身不自動 push、不自動啟用 Pages、不修改預設 branch。

---

## 步驟零：環境檢查

> 開始前先自動確認以下項目。任何一項不符合，先告知使用者問題所在並引導解決後再繼續。
> **不要跳過任何一項，不要假設環境正常。**

1. **確認作業系統**（Windows / macOS / Linux）—— 後續所有指令依實際系統選擇正確版本
2. **確認網路連線正常**
3. **檢查 Git**：`git --version`
4. **檢查 GitHub CLI**：`gh --version`
5. **檢查 Git 身分**：`git config --global user.name`

> 全部通過後告知：「環境檢查完成，開始設定。」
> 有不通過的項目，列出清單並逐一引導解決。
> 安裝完工具後若指令仍找不到，提醒使用者**完全關閉並重開 agent**（PATH 需要重載）。

---

## 步驟零.五：還沒有 GitHub 帳號？

> 🖐️ **先問使用者**：「你有 GitHub 帳號了嗎？」
>
> - **已有** → 跳到步驟一
> - **還沒有** → 依下列流程引導註冊（約 3 分鐘）

**Step 1**：請使用者在瀏覽器開啟 https://github.com/signup

**Step 2**：依序引導填寫

| 欄位 | 說明 | 建議 |
|------|------|------|
| **Email** | 常用的 email | 學校 email 或個人常用 email |
| **Password** | 至少 15 字元，或 8 字元含數字+小寫 | 存到密碼管理器，**不要**寫在筆記、截圖或 repo |
| **Username** | 全站唯一，之後網址會用到 | **用英文+數字，不要中文**。例如 `mathteacher2026`、`wang-math` |
| **Email preferences** | 是否接收電子報 | 可取消勾選 |

> ⚠️ **Username 一旦決定就不好改**（GitHub Pages 網址會跟著變），請慎重。

**Step 3**：完成拼圖驗證 → 點「Create account」

**Step 4**：到 email 收 8 位數驗證碼，回頁面貼上

**Step 5**：問卷可捲到最下方 Skip；方案選 **Free**

**Step 6**：看到 Dashboard 即完成，告知使用者：「✅ GitHub 帳號註冊完成！」

> 🖐️ **常見註冊問題**
>
> | 問題 | 解法 |
> |------|------|
> | Username 被搶走 | 後面加數字或連字號，例如 `wang-math-2026` |
> | 沒收到驗證信 | 檢查垃圾郵件匣，或點「Resend code」 |
> | 拼圖驗證一直失敗 | 重新整理頁面再試 |
> | 想改 username | Settings → Account → Change username（會影響既有連結） |

---

## 步驟一：檢查並安裝 Git 與 GitHub CLI

```bash
git --version
gh --version
```

缺少時**先取得使用者確認**，再依作業系統安裝：

**Windows（PowerShell）**

```powershell
winget install --id Git.Git --accept-source-agreements --accept-package-agreements
winget install --id GitHub.cli --accept-source-agreements --accept-package-agreements
```

**macOS**

```bash
brew install git gh
```

**Ubuntu / Debian**

依 Git 與 GitHub CLI **官方套件庫**說明安裝。不使用未經確認的第三方安裝腳本。

> 安裝後若仍找不到指令，請完全關閉並重開你的 agent 或終端機。

---

## 步驟二：登入 GitHub CLI

先檢查：

```bash
gh auth status
```

若尚未登入，詢問後執行：

```bash
gh auth login --web --git-protocol https
```

> 🖐️ **需要手動操作**：
> 1. 終端機會顯示一組驗證碼（例如 `ABCD-1234`），請告知使用者
> 2. 瀏覽器會自動開啟 GitHub 授權頁；沒開的話請手動開 https://github.com/login/device
> 3. 使用者輸入驗證碼並點「Authorize」
> 4. 成功後終端機顯示「Logged in as [帳號]」
>
> 瀏覽器授權必須由使用者本人完成。**不要**要求使用者把 token 貼進對話或 Markdown。

完成後再次確認帳號與協定：

```bash
gh auth status
```

> 📌 若讀取 GitHub CLI 設定時出現 `Access is denied`，可能是目前權限範圍無法讀取設定檔，
> **不一定是登入失敗**。取得使用者允許後重新檢查。

---

## 步驟三：設定 Git 使用者資訊

先讀現況：

```bash
git config --global user.name
git config --global user.email
```

只有**缺少或使用者要求變更**時才設定。設定前先向使用者取得正確姓名與 email，**不可自行猜測**：

```bash
git config --global user.name "你的姓名"
git config --global user.email "你的email@example.com"
```

> 不想公開私人信箱時，可使用 GitHub 提供的 no-reply email。

---

## 步驟四：唯讀驗收

到這裡連線已完成。先做不寫入任何東西的驗收：

```bash
gh auth status
gh repo list --limit 5
```

確認登入帳號正確、能讀取 repo 清單即可。

> **如果使用者只是要「連上 GitHub」，做到這裡就結束了。**
> 步驟五之後都是選用，且都會在遠端建立東西，需要另外取得同意。

---

## 步驟五：驗證 commit 與 push（選用）

> 🖐️ 先詢問使用者。優先使用**使用者指定的既有專案**；沒有合適專案時，才詢問是否建立臨時測試 repo。

建立測試 repo 前先確認**名稱與可見性**。以私人 repo `github-test` 為例：

**Windows（PowerShell）**

```powershell
$testRoot = Join-Path $env:USERPROFILE "Documents\github-test"
New-Item -ItemType Directory -Path $testRoot -Force
Set-Location $testRoot
git init -b main
```

**macOS / Linux**

```bash
mkdir -p ~/Documents/github-test && cd ~/Documents/github-test
git init -b main
```

建立 `README.md`：

```markdown
# GitHub 連線測試

如果這份文件出現在 GitHub，代表 commit 與 push 已成功。
```

接著（注意：明確指定檔名，不要 `git add .`）：

```bash
git status
git add README.md
git commit -m "建立 GitHub 連線測試"
gh repo create github-test --private --source=. --remote=origin --push
gh repo view github-test
```

**成功標準**：commit 建立成功 → remote 指向正確 repo → push 成功 → `gh repo view` 讀得到資訊。

---

## 步驟六：教材上線 GitHub Pages（選用）

> 這一步會**把內容公開到網路上**，務必先取得使用者明確同意，並確認內容不含個資或未授權素材。

要讓學生掃 QR Code 就能開啟教材，repo 需為 **public**：

```bash
gh repo create my-lesson --public --source=. --push
gh api repos/{owner}/my-lesson/pages -X POST -f build_type=workflow -f source.branch=main -f source.path=/
```

也可以在 repo 的 **Settings → Pages** 手動選擇從 `main` 分支部署。

> 首次部署需要 1–2 分鐘。取得網址後請使用者在瀏覽器確認。
> Pages 不是 GitHub 連線的必要驗證，只是教材上線的常見用途。

---

## 步驟七：處理測試資源

驗證後**必須詢問**：

> 「GitHub 測試成功。遠端 repo 與本機測試資料夾要保留，還是刪除？」

只有使用者明確要求時才能刪除。

```bash
gh repo delete <owner>/github-test --yes
```

刪除本機資料夾前，**先確認解析後的完整路徑就是預期的測試資料夾**，再刪除
（PowerShell 請用 `Remove-Item -LiteralPath`）。

---

## 依你的 Agent

以下是四個 agent 實際會遇到的差異，其餘步驟完全相同：

| Agent | 需要注意的地方 |
|---|---|
| **Claude Code** | 所有安裝與設定都可在桌面版的 Code 分頁內完成，不需另開 PowerShell。只有桌面版確實無法執行時才引導到終端機。 |
| **Codex** | GitHub App / Connector 在 Codex 或 ChatGPT 的設定 → Apps / Connectors 中連接（見下方）。讀取 `gh` 設定出現 `Access is denied` 時，先確認是權限範圍問題而非登入失敗。 |
| **OpenCode** | `gh auth login` 這類互動式登入需由使用者**在互動式終端**執行，agent 代跑會卡在等待輸入。 |
| **Antigravity** | 預設只做到步驟四的唯讀驗收。步驟五之後（建立 repo、push、Pages）都必須另外取得授權。 |

### GitHub App / Connector（Codex 等支援的 agent）

只需要本機 commit 與 push 的話可以略過。要在對話中查 repo、issue、PR：

1. 打開 agent 的設定
2. 在 Apps / Connectors / Integrations 中找到 GitHub
3. 登入 GitHub，選擇帳號與允許存取的 repo
4. 回到對話，請 agent 列出可存取的 repo

---

## 完成回報格式

```text
Git：已安裝 <版本> / 未安裝
GitHub CLI：已安裝 <版本> / 未安裝
GitHub 帳號：<帳號>
Git 使用者資訊：已確認 / 待設定
唯讀驗收：成功 / 失敗
push 驗證：成功 / 未執行 / 失敗
GitHub Pages：已啟用 <網址> / 未執行
GitHub App：已連接 / 未連接 / 不需要
測試資源：保留 / 已刪除 / 未建立
```

---

## 完成！接下來你可以這樣用

| 你說的話 | Agent + GitHub 會做的事 |
|----------|------------------------|
| 「幫我做一個互動遊戲並推到 GitHub 上線」 | 產生 HTML → 建 repo → 推送 → 開 Pages → 給你網址 |
| 「幫我更新這個網頁的內容」 | 修改檔案 → 推送 → 自動更新 |
| 「幫我把這個網頁的 QR Code 產生出來」 | 產生 QR Code 圖片 |
| 「幫我把這個 repo 刪除」 | 確認後刪除 GitHub 上的 repo |

---

## 如果失敗，如何重來

對你的 agent 說：

> 「GitHub 懶人包執行失敗了，幫我檢查哪裡出問題，重新處理。」

Agent 會重跑環境檢查 → 確認 Git / gh 狀態 → 確認登入狀態 → 找出問題並修復。

完全重置 GitHub CLI 登入：

```bash
gh auth logout
gh auth login --web --git-protocol https
```

Git 身分若要復原，**先顯示目前值**，再由使用者指定要移除或改回什麼。

---

## 常見問題

| 問題 | 解法 |
|------|------|
| `gh: command not found` | 完全關閉並重開 agent；確認安裝路徑已加入 PATH |
| `git: command not found` | 重開 agent；Windows 確認 Git for Windows 已安裝 |
| `gh auth login` 瀏覽器沒開 | 手動開 https://github.com/login/device 並輸入驗證碼 |
| `gh auth status` 顯示未登入 | 執行網頁登入後再檢查 |
| 登入帳號不正確 | 先 `gh auth logout` 登出錯誤帳號，再重新登入 |
| 讀取 gh 設定出現 `Access is denied` | 可能是權限範圍問題而非登入失敗，取得允許後重查 |
| commit 顯示作者資料缺失 | 檢查 `user.name` 與 `user.email` |
| push 被拒絕 | 檢查帳號、repo 權限與 remote；確認 `gh auth status` 有 `repo` 權限 |
| GitHub Pages 顯示 404 | 等 1–2 分鐘再重新整理，部署需要時間 |
| GitHub App 找不到 repo | 檢查 App 是否獲准存取該 repo |
| GitHub App 能讀但不能 push | 回頭檢查本機 Git 與 `gh` 權限 |

---

## 更新紀錄

| 日期 | 版本 | 更新內容 |
|------|------|---------|
| 2026-08-02 | v1.0 | 合併版：整併 Claude Code / Codex / OpenCode / Antigravity 四份 #02，取聯集 |

---

## 相關連結

- [懶人包索引](../README.md)
- [安裝入口](../INSTALL.md)
