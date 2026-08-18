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
10. **（選用）接自動部署**：🖐️ 使用者在後台 → 該 Worker → Settings → Build → Connect 連結
    Git repo，build 指令填建置指令、deploy 指令用預設值、production branch 選主要分支。
    之後 push 就會自動上線。

## 安全規則

- **部署是對外發布，每次都要取得明確同意**；agent 不得自行執行 `wrangler deploy`。
- 不自動建立自訂網域、不改 DNS、不建立或刪除任何 Worker、KV、R2、D1 資源。
- 不要求使用者把 API Token 貼進對話、Markdown 或 repo；一律走 `wrangler login` 的 OAuth。
- 修改既有的 `wrangler.jsonc`、`.gitignore`、lint 設定前，先顯示現值再改。
- 「安裝 Skill」不等於「授權執行它」，步驟 6 之後每一項都要逐項確認。

## 復原

`npx wrangler logout` 解除本機授權。已部署的 Worker 要下線，須由使用者自己在 Cloudflare 後台
刪除（不可逆，agent 不得代為執行）。移除本流程新增的檔案即可回到未接 Cloudflare 的狀態。

## 回報

Node 與 Wrangler 版本、登入帳號、帳號子網域、Worker 名稱與網址、產生或修改的檔案清單、
本機驗證結果、部署狀態、自動部署連結狀態、使用者仍需自己完成的互動步驟。
