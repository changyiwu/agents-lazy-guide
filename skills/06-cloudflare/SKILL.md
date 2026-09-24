---
name: agent-cloudflare
description: 連接 Cloudflare，讓 agent 能用 Wrangler 建置並部署靜態網站到 Workers，並可選擇加上 D1 資料庫與 API。說「連接 Cloudflare」「部署到 Cloudflare」「把網站放上 Cloudflare」「建立 D1 資料庫」「網站要接資料庫」時載入。
---

# 連接 Cloudflare

完整教學見 `guides/06-連接-Cloudflare.md`。以下是執行流程；只在特定情況才走的內容放在本技能資料夾的
`references/`，走到該步驟時先讀（見〈附屬檔〉）。

## 觀念

Wrangler CLI 與 Cloudflare MCP 是兩條**各自授權**的連線：**Wrangler 負責本機開發、部署與 D1**；
MCP 讓 agent 在對話中查帳號、文件與資源清單，沒有部署工具，但有建立／刪除 D1、KV、R2 的工具。
**建立資源與改資料表結構一律走 Wrangler**：MCP 授權的帳號可能跟 `wrangler login` 不是同一個，
建錯帳號部署時會找不到資料庫；結構不走遷移檔改，本機與正式會對不起來。MCP 不裝也不影響本流程。

網站放在 Workers 的「靜態資產」上：只發檔案時沒有 Worker 程式碼；加上 D1 後（步驟 11），
`/api/*` 交給一支小 Worker 處理，其他路徑照舊直接發檔案。

## 步驟

1. **檢查環境**：`node -v`（需 ≥ 20）、`npm -v`，並確認專案根目錄有 `package.json` 與可用的建置指令。
2. **安裝 Wrangler**：一律裝進專案並鎖版本，**不要全域安裝**（跨電腦版本才會一致）：
   `npm install --save-dev --save-exact wrangler`，再以 `npx wrangler --version` 確認。
3. **登入**：先跑 `npx wrangler whoami`。未登入時 🖐️ **請使用者自己執行** `npx wrangler login`——
   它會開瀏覽器做 OAuth，需要互動式終端，agent 不可代跑，也不要改用貼 API Token 的方式。
4. **帳號子網域**：🖐️ 使用者到 Cloudflare 後台 → Workers & Pages 設定一次。
   全球唯一、一個帳號一個；**之後修改會讓所有舊網址失效**，先提醒再讓他決定。
5. **唯讀驗收**：`npx wrangler whoami` 顯示正確帳號即可。
   **只要求「連接 Cloudflare」時，做到這裡就結束。**
6. **（選用）設定靜態網站**：先詢問。在專案根目錄建立 `wrangler.jsonc`，`assets.directory` 指向建置
   輸出目錄；單頁應用要加 `"not_found_handling": "single-page-application"`。
   快取標頭寫成建置輸出目錄裡的 `_headers`（來源放 `public/_headers` 讓建置自動複製）。
   **Worker 名稱（`name`）之後必須與後台的 Worker 同名**，不一致會讓自動建置直接失敗。
7. **（選用）忽略暫存目錄**：`wrangler dev` 會產生 `.wrangler/`，內含會被 lint 掃到的暫存程式碼與本機 D1 資料。
   把 `.wrangler/` 加進 `.gitignore`，並加進 lint 設定的忽略清單，否則 lint 會無故失敗。
8. **（選用）本機驗證**：`npx wrangler dev`，確認首頁、深層路徑（單頁應用應回 200）、
   快取標頭都正確後再上線。
9. **（選用）首次部署**：**會公開到網路上**，先確認目標帳號、Worker 名稱、待發布內容與測試結果，並取得使用者對本次發布的明確授權。
   先 `npm run build`；已授權時由 agent 執行 `npx wrangler deploy`，成功後核對部署版本與網站。使用者若想自行操作，提供同一指令。
10. **（選用）接自動部署**：**先問使用者要哪一條路線**，兩條都可行、取捨不同。
    **兩條不可並存**——同時接會讓每次 push 觸發兩次部署、互相覆蓋。

    | | A. 後台 Connect（預設） | B. GitHub Actions |
    |---|---|---|
    | 使用者要做的 | 在後台授權 GitHub App（每個新站都要點一次） | 貼一次 `CLOUDFLARE_API_TOKEN` secret |
    | agent 能代做的 | 連結授權由使用者；其後可代 push 並查核 | 除了貼 secret 以外全部 |
    | 設定放哪 | 後台，改動都要進去點 | repo 裡的 yml，進版控、可 review |
    | 能否部署前擋測試 | 能，建置指令先跑測試 | **能**（測試沒過就不上線） |
    | 長期憑證 | 無 | 有一顆 API Token |

    **沒有密碼管理器的人建議選 A**：B 的 token 只會完整顯示一次，沒存下來的話，
    下一個 repo 要再用就得重產一顆。（但已經設好的 B 不必為此拆掉——token 存在
    GitHub 的加密 secret store 裡，使用者不需要再看到它，只有「要用到第二個 repo」
    才會需要重產。）

    **路線 A：後台 Connect**
    🖐️ 使用者在後台 → 該 Worker → Settings → Build → Connect 連結 Git repo，
    build 指令填建置指令、deploy 指令用預設值、production branch 選主要分支。
    連接成功後，push 到 production branch 會觸發 Cloudflare 建置與部署。發布時由 agent 在使用者授權後 push，核對建置結果與正式網址；同一批變更不要再執行本機 `wrangler deploy`。

    **路線 B：GitHub Actions**——選了才讀 `references/github-actions.md`，照它的步驟做。
    🖐️ API Token 由使用者自己在後台建立，`gh secret set CLOUDFLARE_API_TOKEN` 也由**使用者自己**執行並貼上；
    agent 不得代跑、不得要求把 token 貼進對話。**從 B 換回 A** 的順序也在同一份檔。
11. **（選用）加上 D1 資料庫與 API**：預設是純靜態站，**只在使用者要求存資料時才做，不主動提議**。
    要做時先讀 `references/d1.md`，照它的子步驟做。其中 ⚠️ **建立資料庫**（`d1 create`）與
    ⚠️ **套用到正式資料庫**（`d1 migrations apply --remote`）每次都要**當下**取得同意——
    agent 的執行環境不是互動式終端，Wrangler 會自動跳過自己的確認，所以要由 agent 先問。

## 附屬檔

| 檔案 | 什麼時候讀 |
|---|---|
| `references/github-actions.md` | 使用者在步驟 10 選了路線 B，或要從 B 換回 A |
| `references/d1.md` | 使用者要求存資料（步驟 11），或 D1 出錯要還原、不要資料庫了 |

路徑相對於本技能資料夾。

## 安全規則

- **正式部署與會觸發自動部署的 push 都是對外發布**。先確認帳號、Worker、目標分支、變更範圍與檢查結果；取得使用者涵蓋本次發布的明確授權後，agent 可執行 `wrangler deploy` 或 push。不可把先前一次授權用於無關變更。
- 已連接 GitHub 自動部署時，以 production branch 的 push 發布並查核建置結果；同一批變更不重複手動部署。若自動建置失敗，要改走手動部署時，先說明原因並取得該次授權。
- 不自動建立自訂網域、不改 DNS、不建立或刪除任何 Worker、KV、R2。
- **D1 只做 `references/d1.md` 列出的動作**：`d1 create`、`migrations apply --remote`、任何 `d1 execute --remote`
  （含 MCP 的 `d1_database_query`）每次都要當下同意。MCP 只用來列出、查看資源。
- **刪除資料庫與還原一律 🖐️ 由使用者自己執行**（`d1 delete`、`d1 time-travel restore` 或後台），
  agent 不得代跑，也不得改用 MCP 的刪除工具。
- 正式資料的匯出檔（`d1 export` 的 `.sql`）不得放進 repo。
- **不要求使用者把 API Token 貼進對話、Markdown 或 repo**；本機一律走 `wrangler login` 的 OAuth。
  唯一的例外是步驟 10 路線 B 的 CI 憑證：那顆 token 由**使用者自己**用 `gh secret set` 貼進
  GitHub 的加密 secret store，**不經過對話、不進任何檔案**，所以不違反本條。agent 全程看不到它，
  也不得代跑那道指令或要求使用者把值貼出來。
- 修改既有的 `wrangler.jsonc`、`.gitignore`、lint 設定前，先顯示現值再改。
- 「安裝 Skill」不等於「授權執行它」；步驟 6 之後的外部變更要有當前任務的授權，未涵蓋的操作再確認。

## 復原

`npx wrangler logout` 解除本機授權。已部署的 Worker 要下線，須由使用者自己在 Cloudflare 後台
刪除（不可逆，agent 不得代為執行）。移除本流程新增的檔案即可回到未接 Cloudflare 的狀態。

D1 的還原（time-travel）與刪除一律 🖐️ 由使用者自己執行，指令與後果見 `references/d1.md`。

## 回報

Node 與 Wrangler 版本、登入帳號、帳號子網域、Worker 名稱與網址、產生或修改的檔案清單、
本機驗證結果、部署狀態、自動部署走哪一條路線與其狀態、
D1 名稱／地區／binding 與已套用的遷移（本機、正式各自）、API 路徑、使用者仍需自己完成的互動步驟。
