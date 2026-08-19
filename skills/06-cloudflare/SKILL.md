---
name: agent-cloudflare
description: 連接 Cloudflare，讓 agent 能用 Wrangler 建置並部署靜態網站到 Workers。說「連接 Cloudflare」「部署到 Cloudflare」「把網站放上 Cloudflare」時載入。
---

# 連接 Cloudflare

完整教學見 `guides/06-連接-Cloudflare.md`。以下是執行流程。

## 觀念

Wrangler CLI 與 Cloudflare MCP 是兩條不同連線：**Wrangler 負責本機開發與部署**；MCP 讓 agent
在對話中查帳號與文件，但**沒有部署工具**。本流程只處理 Wrangler，因為它在每個 agent 上行為一致；
MCP 是選用的加值品，不裝也不影響部署。

網站放在 Workers 的「靜態資產」上：沒有 Worker 程式碼，只有一個發檔案的空殼。

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
7. **（選用）忽略暫存目錄**：`wrangler dev` 會產生 `.wrangler/`，內含會被 lint 掃到的暫存程式碼。
   把 `.wrangler/` 加進 `.gitignore`，並加進 lint 設定的忽略清單，否則 lint 會無故失敗。
8. **（選用）本機驗證**：`npx wrangler dev`，確認首頁、深層路徑（單頁應用應回 200）、
   快取標頭都正確後再上線。
9. **（選用）首次部署**：**會公開到網路上**，須另外取得明確同意。
   先 `npm run build`，再 🖐️ **由使用者執行** `npx wrangler deploy`。
10. **（選用）接自動部署**：**先問使用者要哪一條路線**，兩條都可行、取捨不同。
    **兩條不可並存**——同時接會讓每次 push 觸發兩次部署、互相覆蓋。

    | | A. 後台 Connect（預設） | B. GitHub Actions |
    |---|---|---|
    | 使用者要做的 | 在後台授權 GitHub App（每個新站都要點一次） | 貼一次 `CLOUDFLARE_API_TOKEN` secret |
    | agent 能代做的 | 幾乎沒有（授權是 OAuth，無 CLI 對應） | 除了貼 secret 以外全部 |
    | 設定放哪 | 後台，改動都要進去點 | repo 裡的 yml，進版控、可 review |
    | 能否部署前擋測試 | 否 | **能**（測試沒過就不上線） |
    | 長期憑證 | 無 | 有一顆 API Token 存在 |

    **沒有密碼管理器的人建議選 A**：B 的 token 只會完整顯示一次，沒存下來的話，
    下一個 repo 要再用就得重產一顆。（但已經設好的 B 不必為此拆掉——token 存在
    GitHub 的加密 secret store 裡，使用者不需要再看到它，只有「要用到第二個 repo」
    才會需要重產。）

    **路線 A：後台 Connect**
    🖐️ 使用者在後台 → 該 Worker → Settings → Build → Connect 連結 Git repo，
    build 指令填建置指令、deploy 指令用預設值、production branch 選主要分支。

    **路線 B：GitHub Actions**
    1. 🖐️ 使用者在後台 → 頭像 → Profile → API Tokens → Create Token →
       **"Edit Cloudflare Workers"** 模板 → 建立。Account Resources 選自己的帳號即可；
       模板附帶的 Zone Resources 是給自訂網域路由用的，走 `*.workers.dev` 用不到、
       留著也無妨。**若設了到期日，到期那天自動部署會無聲失效**，要先提醒。
    2. 🖐️ **使用者自己**執行 `gh secret set CLOUDFLARE_API_TOKEN --repo <owner>/<repo>`
       並在提示時貼上。**agent 不得代跑、不得要求把 token 貼進對話**。
    3. agent 建立 `.github/workflows/deploy-cloudflare.yml`：`on.push` 加 `paths`
       過濾（只有前端目錄、`wrangler.jsonc` 或該檔本身變動才跑），部署前先跑專案測試，
       `permissions` 只給 `contents: read`，最後用 `cloudflare/wrangler-action@v3`。
    4. **`wranglerVersion` 一定要指定 `"4"`**：action 預設裝 wrangler 3，而「沒有
       `main`、只有 `assets`」的純靜態 Worker 是 wrangler 4 才支援的寫法，用 3 會直接報
       `Missing entry-point`。本機通常已是 4.x，所以這個坑只在 CI 現形。
    5. 推上去後用 `gh run watch <id> --exit-status` 確認，失敗就 `gh run view --log-failed`。

    **從 B 換回 A**（順序反了會有一段空窗期，Cloudflare 站更新不了）：
    先接好 A → 確認自動部署成功一次 → 刪掉 workflow 檔 → 最後才刪 token 與 secret。

## 安全規則

- **部署是對外發布，每次都要取得明確同意**；agent 不得自行執行 `wrangler deploy`。
- 不自動建立自訂網域、不改 DNS、不建立或刪除任何 Worker、KV、R2、D1 資源。
- **不要求使用者把 API Token 貼進對話、Markdown 或 repo**；本機一律走 `wrangler login` 的 OAuth。
  唯一的例外是步驟 10 路線 B 的 CI 憑證：那顆 token 由**使用者自己**用 `gh secret set` 貼進
  GitHub 的加密 secret store，**不經過對話、不進任何檔案**，所以不違反本條。agent 全程看不到它，
  也不得代跑那道指令或要求使用者把值貼出來。
- 修改既有的 `wrangler.jsonc`、`.gitignore`、lint 設定前，先顯示現值再改。
- 「安裝 Skill」不等於「授權執行它」，步驟 6 之後每一項都要逐項確認。

## 復原

`npx wrangler logout` 解除本機授權。已部署的 Worker 要下線，須由使用者自己在 Cloudflare 後台
刪除（不可逆，agent 不得代為執行）。移除本流程新增的檔案即可回到未接 Cloudflare 的狀態。

## 回報

Node 與 Wrangler 版本、登入帳號、帳號子網域、Worker 名稱與網址、產生或修改的檔案清單、
本機驗證結果、部署狀態、自動部署走哪一條路線與其狀態、使用者仍需自己完成的互動步驟。
