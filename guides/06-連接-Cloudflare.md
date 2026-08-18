---
title: 'AI Agent 懶人包 #06：連接 Cloudflare'
date: '2026-08-18'
type: 懶人包
version: v0.1
status: 初版（流程源自實際專案遷移，尚未以技能形式重跑）
tags:
  - 懶人包
  - Cloudflare
  - Workers
  - 部署
---

# 懶人包 #06：連接 Cloudflare

**版本** v0.1｜**更新日期** 2026-08-18｜**適用** Claude Code / Codex / OpenCode / Antigravity

---

## 這份懶人包會幫你做什麼？

- 在這台電腦裝好 **Wrangler**（Cloudflare 官方 CLI）並完成登入授權
- 設定你的 **workers.dev 帳號子網域**，之後所有網站都掛在它底下
- 把一個既有的靜態網站或前端專案（Vite、React、Astro…）設定成可部署到 Cloudflare
- 完成**首次上線**，拿到一個 `https://<專案>.<你的子網域>.workers.dev` 網址
- 接上 **Workers Builds**，之後 push 到 Git 就自動建置上線，不用再手動部署

做完之後，換任何一台電腦、任何一個 agent，都能用同一套流程再開一個新網站。

---

## Wrangler 與 Cloudflare MCP 的分工（重要）

很多人以為裝了 Cloudflare 的 MCP 就能叫 agent 部署網站，**這是錯的**。

| | Wrangler CLI | Cloudflare MCP |
|---|---|---|
| 是什麼 | 官方命令列工具 | 讓 agent 在對話中呼叫 Cloudflare 的服務 |
| 能不能部署 | ✅ 能 | ❌ **沒有部署工具** |
| 跨 agent | ✅ 四家行為完全一致 | 每個 agent 各自設定、各自授權 |
| 跨電腦 | 跟著專案的 `package.json` 走 | 每台電腦重設一次 |

**本懶人包只處理 Wrangler。** MCP 是選用的加值品：它適合拿來查官方文件、列出帳號資源、
查建置狀態，裝不裝都不影響你部署網站。

> Cloudflare 官方另有十幾個 MCP server（文件、Workers Bindings、Workers Builds、Observability、
> Radar…）。其中 `https://mcp.cloudflare.com/mcp`（Code Mode）涵蓋整個 Cloudflare API，
> 理論上能部署，但帶靜態資產的 Worker 要走多步驟上傳流程，手工拼很容易出錯——
> 這正是 Wrangler 存在的理由。想裝 MCP 請當成獨立的事，不要拿它取代本流程。

---

## 先備條件

- [ ] 有 Cloudflare 帳號（免費方案即可，[dash.cloudflare.com](https://dash.cloudflare.com) 註冊）
- [ ] 已安裝 Node.js 20 以上（沒有的話先做懶人包 #00 環境建置）
- [ ] 有一個能跑 `npm run build` 並產出靜態檔案的專案（純 HTML 網站也可以，見步驟三）
- [ ] 能開啟瀏覽器完成 OAuth 授權
- [ ] 要接自動部署的話：專案已推上 GitHub 或 GitLab（可參考懶人包 #02 連接 GitHub）

---

## 完成標準

- [ ] `npx wrangler whoami` 顯示你的 Cloudflare 帳號
- [ ] 帳號子網域已設定，你知道它叫什麼
- [ ] 專案根目錄有 `wrangler.jsonc`，`name` 與後台的 Worker 同名
- [ ] `npx wrangler dev` 能在本機跑起來，深層路徑與快取標頭都正確
- [ ] 網站已上線，用瀏覽器打得開
- [ ] （選用）push 到主要分支後會自動建置上線

---

## 執行原則（給 AI Agent）

- **部署是對外發布行為。** 每一次 `wrangler deploy` 都要取得使用者當下的明確同意，
  不可因為前面同意過就自行再部署。
- **互動式登入不可代跑。** `wrangler login` 需要瀏覽器 OAuth 與互動式終端，
  請使用者自己執行，不要改用「請把 API Token 貼給我」的做法。
- **不要主動建立或刪除遠端資源**：自訂網域、DNS 記錄、KV、R2、D1、其他 Worker，一律不碰。
- **修改既有檔案前先顯示現值**（`wrangler.jsonc`、`.gitignore`、lint 設定）。
- **不要把 API Token、帳號 ID 以外的機密寫進 repo 或對話紀錄。**
- 每個步驟失敗時給出具體排查方向，不要只說「請重試」。

---

## 步驟零：環境檢查

> 開始前先自動確認以下項目。任何一項不符合，先告知使用者問題所在並引導解決後再繼續。
> **不要跳過任何一項，不要假設環境正常。**

1. **確認作業系統**（Windows / macOS / Linux）—— 後續指令依實際系統選擇正確版本
2. **確認網路連線正常**
3. **確認 Node.js 版本**：`node -v`，需 20 以上
4. **確認在專案根目錄**：有 `package.json`，且 `scripts` 裡有可用的建置指令
5. **確認建置產物目錄**：跑一次建置指令，記住輸出到哪個資料夾（常見為 `dist`、`build`、`out`）

> 全部通過後告知：「環境檢查完成，開始執行。」
> 安裝完工具後若指令仍找不到，提醒使用者完全關閉並重開 agent。

---

## 步驟一：安裝 Wrangler

**裝進專案，不要全域安裝。** 全域安裝會讓不同電腦、不同專案的版本不一致，
CI 上跑的版本也對不起來。

```bash
npm install --save-dev --save-exact wrangler
```

確認：

```bash
npx wrangler --version
```

> `--save-exact` 會把版本鎖死（寫成 `4.124.0` 而不是 `^4.124.0`）。
> 部署工具的行為要可重現，不要讓它自己跳版。

安裝時可能出現 `esbuild`、`workerd` 的 install script 警告，屬正常現象；
`workerd` 是 Workers 的本機執行環境，`wrangler dev` 需要它。

---

## 步驟二：登入 Cloudflare

🖐️ **這一步要使用者自己做。** 它會開啟瀏覽器要你授權，agent 無法代為完成。

先確認目前狀態：

```bash
npx wrangler whoami
```

未登入時，請使用者在**互動式終端機**執行：

```bash
npx wrangler login
```

瀏覽器會跳出 Cloudflare 授權頁，按下同意後終端機會顯示成功訊息。

> **為什麼要手動**：這是 OAuth 授權，等於把你的 Cloudflare 帳號權限交出去，
> 必須由帳號本人在瀏覽器確認。任何要你把 API Token 貼進對話的做法都應該拒絕。

---

## 步驟三：設定帳號子網域

🖐️ **這一步要使用者自己做**，在 Cloudflare 後台完成。

1. 開啟 [dash.cloudflare.com](https://dash.cloudflare.com)
2. 左側選 **Workers & Pages**
3. 第一次進入會要求你選擇子網域，輸入想要的名字後送出
4. 之後要改：Workers & Pages 頁面「Your subdomain」旁的 **Change**

你的網站網址會長這樣：

```
你的專案名 . 你的帳號子網域 . workers.dev
```

> ⚠️ **一個帳號只有一個子網域，全球唯一，先搶先贏。**
> 而且**改掉之後所有舊網址會立刻失效**，第一次就挑一個願意長期使用的名字，
> 不要用 `test`、`temp` 這種暫時性的名稱。

如果你只是要「連接 Cloudflare」，做到這裡就結束了。以下是部署網站的部分。

---

## 步驟四：建立 `wrangler.jsonc`

在專案根目錄建立 `wrangler.jsonc`：

```jsonc
{
  "name": "my-site",
  "compatibility_date": "2026-08-18",
  "assets": {
    "directory": "./dist",
    "not_found_handling": "single-page-application"
  }
}
```

| 欄位 | 要改成什麼 |
|---|---|
| `name` | 你的專案名，**只能用小寫英數與連字號**。這會變成網址的第一段 |
| `compatibility_date` | 填今天的日期 |
| `assets.directory` | 步驟零記下的建置產物目錄 |
| `not_found_handling` | 單頁應用填 `single-page-application`；多頁靜態網站改填 `404-page` |

> ⚠️ **`name` 之後必須與 Cloudflare 後台的 Worker 名稱完全一致。**
> 接自動部署（步驟八）時兩者不符會讓建置**直接失敗**，而且錯誤訊息不會明說原因。

沒有 Worker 程式碼是正常的——純靜態網站不需要 `main` 欄位，這個 Worker 的唯一任務就是發檔案。

---

## 步驟五：設定快取標頭

帶內容雜湊的建置產物（檔名裡有一串亂碼的 JS、CSS、字型）可以永久快取。
在**建置來源目錄**建立 `_headers`（Vite 專案放 `public/_headers`，建置時會自動複製到輸出目錄）：

```
# 帶 hash 的建置產物可長期快取。
/assets/*
  Cache-Control: public, max-age=31536000, immutable
```

把 `/assets/*` 換成你的專案實際存放這些檔案的路徑。

> `_headers` 本身不會被當成網頁公開，Cloudflare 會讀取後丟棄它，不用擔心外洩。

---

## 步驟六：忽略 Wrangler 的暫存目錄

`wrangler dev` 會在專案裡產生 `.wrangler/`，裡面有自動生成的暫存 worker 程式碼。
**不處理的話，下次跑 lint 會憑空冒出一堆錯誤。**

`.gitignore` 加上：

```
.wrangler/
```

同時把它加進 lint 設定的忽略清單。以 ESLint flat config 為例：

```js
{ ignores: ["dist/**", ".wrangler/**"] }
```

> 這個坑很容易誤判成「我的程式碼壞了」，實際上錯誤全部來自 `.wrangler/tmp/` 底下
> 的自動生成檔案（`no-undef`、`no-unused-vars` 之類）。

---

## 步驟七：本機驗證

```bash
npm run build
npx wrangler dev
```

打開它顯示的網址（預設 `http://localhost:8787`），逐項確認：

| 檢查項目 | 預期結果 |
|---|---|
| 首頁 | 正常顯示，瀏覽器 console 無錯誤 |
| 隨便一個不存在的深層路徑 | 單頁應用要回 **200** 並顯示首頁；多頁網站回 404 頁 |
| 帶 hash 的資產 | 回應標頭有 `Cache-Control: ...immutable` |
| 啟動訊息 | 出現 `Parsed N valid header rule.` 代表 `_headers` 有生效 |

深層路徑回 404 就是 `not_found_handling` 沒設對；沒有 `Parsed ... header rule`
就是 `_headers` 沒被複製到建置輸出目錄。

---

## 步驟八：首次部署

> ⚠️ **這一步會把網站公開到網際網路上。** 上線前先確認內容不含個資、測試資料、未授權素材。
> agent 必須取得使用者當下的明確同意，且**由使用者自己執行部署指令**。

```bash
npm run build
```

```bash
npx wrangler deploy
```

成功後終端機會印出網址。用瀏覽器打開確認。

> Windows PowerShell 5.1 不支援 `&&`，兩行要分開跑。

**如果你的網站有社群預覽圖**：`og:url`、`og:image` 必須是絕對網址，
現在要改成新的 workers.dev 網址，否則預覽圖會抓不到（改完要重新部署才生效）。

---

## 步驟九：接上自動部署（Workers Builds）

🖐️ **這一步要使用者自己在後台做**，沒有 CLI 指令可以完成。

1. [dash.cloudflare.com](https://dash.cloudflare.com) → **Workers & Pages** → 點進你的 Worker
2. **Settings** → **Build** → **Connect**
3. 選 GitHub 或 GitLab，授權 Cloudflare 存取。權限範圍選 **Only select repositories**，
   只勾這個專案就好，不必給整個帳號
4. 填建置設定：

| 欄位 | 填什麼 |
|---|---|
| Production branch | 你的主要分支（通常是 `main`） |
| Root directory | `/` |
| Build command | `npm run build` |
| Deploy command | `npx wrangler deploy`（預設值，不用改） |

5. 儲存後 push 一個 commit，就會觸發第一次自動建置

**驗證方式**：GitHub 上該 commit 會出現名為 `Workers Builds: <你的 Worker 名>` 的檢查項目，
狀態變成 success 就代表成功。也可以用 `npx wrangler deployments list` 看有沒有新版本。

> **Node 版本不用另外設定**：Workers Builds 預設用 Node.js 24。
> 需要指定版本時，加一個 `.node-version` 檔或設 `NODE_VERSION` 建置環境變數。

接上之後，「部署」這件事就從你手上移交給 CI 了：push 就上線，不用再手動跑 `wrangler deploy`。
記得同步更新專案文件，不要留著「要手動部署」的過期說明。

---

## 依你的 Agent

流程四家完全相同，只有兩個地方要注意。

| Agent | 互動式登入 | 選用的 Cloudflare MCP |
|---|---|---|
| Claude Code | 桌面版的 Code 分頁不是互動式終端，`wrangler login` 請另開終端機執行 | 可在 Claude 的連接器設定加入，**跟著帳號走**，換電腦不用重設 |
| Codex | 同上，需在互動式終端執行 | 可用 `codex mcp add cloudflare --url https://mcp.cloudflare.com/mcp` 加入 |
| OpenCode | 同上 | 在 `~/.config/opencode/opencode.jsonc` 的 `mcp` 區塊加入遠端 server |
| Antigravity | 同上 | 在 `~/.gemini/config/mcp_config.json` 加入 |

> **不管哪一家，MCP 都不是必要的。** 部署能力來自 Wrangler，不是 MCP。
> 只有 Claude 的連接器是帳號層級（換電腦自動跟著走），其餘三家都要每台電腦各自設定——
> 這正是把流程做成 skill 而不是依賴 MCP 的原因。

---

## 完成回報格式

```
【Cloudflare 連接結果】
- Node.js 版本：
- Wrangler 版本：
- 登入帳號：
- 帳號子網域：
- Worker 名稱：
- 網站網址：

【檔案異動】
- 新增：
- 修改：

【驗證結果】
- 本機 wrangler dev：
- 深層路徑（單頁應用）：
- 快取標頭：
- 線上網址可開啟：

【自動部署】
- Workers Builds 連結狀態：
- 首次自動建置結果：

【使用者仍需自己完成】
-
```

---

## 如果失敗，如何重來

| 想回到哪裡 | 怎麼做 |
|---|---|
| 解除本機授權 | `npx wrangler logout`，之後重跑步驟二 |
| 重設專案設定 | 刪掉 `wrangler.jsonc`、`_headers`、`.wrangler/`，從步驟四重來 |
| 取消自動部署 | 後台該 Worker → Settings → Build → 中斷 Git 連結 |
| 網站下線 | 🖐️ 使用者自己在後台刪除該 Worker（**不可逆**，agent 不得代為執行） |

刪除 Worker 後，該網址會立刻回 404。如果網址已經分享出去，考慮先保留並改成轉址，
不要直接刪。

---

## 常見問題

| 問題 | 原因與解法 |
|---|---|
| `wrangler deploy` 說找不到設定 | 不在專案根目錄，或 `wrangler.jsonc` 檔名打錯 |
| 深層路徑回 404 | `not_found_handling` 沒設成 `single-page-application` |
| 快取標頭沒生效 | `_headers` 沒被複製到建置輸出目錄；Vite 要放在 `public/` 底下 |
| lint 突然冒出一堆錯 | `.wrangler/` 沒加進忽略清單，見步驟六 |
| 自動建置失敗且訊息看不懂 | 先比對後台 Worker 名稱與 `wrangler.jsonc` 的 `name` 是否完全一致 |
| 社群分享沒有預覽圖 | `og:image`／`og:url` 還指著舊網址，或不是絕對網址 |
| 校內網路打不開網站 | `*.workers.dev` 可能被過濾器擋掉，解法是接自訂網域，不是換平台 |
| PowerShell 說 `&&` 不是有效分隔符號 | Windows PowerShell 5.1 不支援，指令分兩行跑 |

---

## 免費方案說明

靜態網站放在 Cloudflare 上實質是零成本：

- **靜態資產請求免費且不限次數**。免費方案「每天 10 萬次請求」的上限只計算會**執行 Worker
  程式碼**的請求，純靜態網站沒有程式碼，碰不到那個上限
- 每個版本可放 20,000 個檔案、單檔上限 25 MiB
- `workers.dev` 子網域免費，不需要購買網域

只有想用自訂網址時才需要付費，而且付的是**網域本身的年費**，Cloudflare 的服務仍然免費。

---

## 更新紀錄

| 版本 | 日期 | 變更 |
|------|------|------|
| v0.1 | 2026-08-18 | 初版。流程與所有踩坑紀錄來自一次實際的網站遷移（Netlify → Cloudflare Workers，含首次部署與接上 Workers Builds），尚未以技能形式重跑驗證 |

---

## 相關連結

- [Cloudflare 後台](https://dash.cloudflare.com)
- [Workers 靜態資產文件](https://developers.cloudflare.com/workers/static-assets/)
- [Workers Builds 文件](https://developers.cloudflare.com/workers/ci-cd/builds/)
- [Wrangler 設定參考](https://developers.cloudflare.com/workers/wrangler/configuration/)
- [Cloudflare 官方 MCP server 目錄](https://developers.cloudflare.com/agents/model-context-protocol/cloudflare/servers-for-cloudflare/)
