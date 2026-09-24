---
title: 'AI Agent 懶人包 #06：連接 Cloudflare'
date: '2026-09-14'
type: 懶人包
version: v0.4
status: 初版（部署流程源自實際專案遷移；D1 段落依官方文件撰寫；皆尚未以技能形式重跑）
tags:
  - 懶人包
  - Cloudflare
  - Workers
  - 部署
---

# 懶人包 #06：連接 Cloudflare

**版本** v0.3｜**更新日期** 2026-09-15｜**適用** Claude Code / Codex / OpenCode / Antigravity

---

## 這份懶人包會幫你做什麼？

- 在這台電腦裝好 **Wrangler**（Cloudflare 官方 CLI）並完成登入授權
- 設定你的 **workers.dev 帳號子網域**，之後所有網站都掛在它底下
- 把一個既有的靜態網站或前端專案（Vite、React、Astro…）設定成可部署到 Cloudflare
- 完成**首次上線**，拿到一個 `https://<專案>.<你的子網域>.workers.dev` 網址
- 接上 **Workers Builds**，之後 push 到 Git 就自動建置上線，不用再手動部署
- （選用）加上 **D1 資料庫**與一支小小的 API，讓網站能存取資料（留言、報名、計分…）

做完之後，換任何一台電腦、任何一個 agent，都能用同一套流程再開一個新網站。

---

## Wrangler 與 Cloudflare MCP 的分工（重要）

很多人以為裝了 Cloudflare 的 MCP 就能叫 agent 部署網站，**這是錯的**。

| | Wrangler CLI | Cloudflare MCP |
|---|---|---|
| 是什麼 | 官方命令列工具 | 讓 agent 在對話中呼叫 Cloudflare 的服務 |
| 能不能部署 | ✅ 能 | ❌ **沒有部署工具** |
| 能不能建立／刪除 D1、KV、R2 | ✅ 能 | ✅ 能（本懶人包只用它查看，建立走 Wrangler） |
| 跨 agent | ✅ 四家行為完全一致 | 每個 agent 各自設定、各自授權 |
| 跨電腦 | 跟著專案的 `package.json` 走 | 每台電腦重設一次 |

**本懶人包只處理 Wrangler。** MCP 是選用的加值品：它適合拿來查官方文件、列出帳號資源、
查建置狀態，裝不裝都不影響你部署網站。

> **為什麼 MCP 能建立資源，本懶人包還是走 Wrangler**：
>
> 1. **可能建到別的帳號。** MCP 用你在 agent 連接器授權的帳號，Wrangler 用這台電腦 `wrangler login`
>    的帳號，兩邊各自授權、不一定相同。用 MCP 建的資料庫若不在 Wrangler 的帳號裡，部署時會找不到。
> 2. **資料表結構要走遷移檔。** 用 MCP 直接對正式資料庫下 `CREATE TABLE`，Wrangler 的遷移紀錄
>    （`d1_migrations` 表）不會知道，本機與正式的結構就對不起來。
> 3. **四家做法一致。** 只有部分 agent 接了 MCP；而且 `wrangler d1 create --update-config`
>    會順手把 binding 寫進設定檔，MCP 建完還得手動抄 `database_id`。
>
> 列出資料庫、查看資源資訊這類唯讀用途，用 MCP 沒問題。刪除與還原不管用哪個工具，都由你自己執行。

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
- [ ] 要接自動部署的話：專案已推上 GitHub 或 GitLab（可參考懶人包 #02 連接 GitHub）。
      走 GitHub Actions 那條路線（步驟九路線 B）還需要 `gh` 已登入
- [ ] 要加 D1 的話：Wrangler 4.20 以上（步驟一裝的最新版即可）

---

## 完成標準

- [ ] `npx wrangler whoami` 顯示你的 Cloudflare 帳號
- [ ] 帳號子網域已設定，你知道它叫什麼
- [ ] 專案根目錄有 `wrangler.jsonc`，`name` 與後台的 Worker 同名
- [ ] `npx wrangler dev` 能在本機跑起來，深層路徑與快取標頭都正確
- [ ] 網站已上線，用瀏覽器打得開
- [ ] （選用）push 到主要分支後會自動建置上線
- [ ] （選用）D1 資料庫已建立，本機與正式資料庫都套用了遷移，線上的 `/api/...` 讀寫正常

---

## 執行原則（給 AI Agent）

- **正式部署或推送到會自動部署的分支都是對外發布。** 先確認帳號、Worker、分支、變更範圍與測試結果；
  取得使用者涵蓋本次發布的明確授權後，agent 可執行 `wrangler deploy` 或 push，不把先前一次授權用於無關變更。
- **互動式登入不可代跑。** `wrangler login` 需要瀏覽器 OAuth 與互動式終端，
  請使用者自己執行，不要改用「請把 API Token 貼給我」的做法。
- **不要主動建立或刪除遠端資源**：自訂網域、DNS 記錄、KV、R2、其他 Worker，一律不碰。
- **D1 只做步驟十列出的動作，而且要當下同意**：建立資料庫、套用遷移到正式資料庫、
  任何 `d1 execute --remote`（含 MCP 的 `d1_database_query`），每一次都先問。
  **刪除資料庫與時間點還原由使用者自己執行**，agent 不得代跑，也不得改用 MCP 的刪除工具。
- **D1 不主動提議。** 預設是純靜態站，使用者要求存資料時才做步驟十。
- **建立資源與改資料表結構走 Wrangler**；Cloudflare MCP 只用來列出、查看資源（原因見上方分工說明）。
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
要接資料庫時才需要程式碼，見步驟十。

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

`wrangler dev` 會在專案裡產生 `.wrangler/`，裡面有自動生成的暫存 worker 程式碼，
加了 D1 之後本機資料庫檔也放在這裡（`.wrangler/state/`）。
**不處理的話，下次跑 lint 會憑空冒出一堆錯誤，本機測試資料也會被推上 Git。**

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
> agent 必須取得使用者對本次發布的明確授權；授權後可由 agent 執行部署指令。

```bash
npm run build
```

```bash
npx wrangler deploy
```

成功後終端機會印出網址。agent 核對部署版本並打開網站確認；使用者想自行操作時也可直接執行上述指令。

> Windows PowerShell 5.1 不支援 `&&`，兩行要分開跑。

**如果你的網站有社群預覽圖**：`og:url`、`og:image` 必須是絕對網址，
現在要改成新的 workers.dev 網址，否則預覽圖會抓不到（改完要重新部署才生效）。

---

## 步驟九：接上自動部署

有兩條路線，**擇一，不要兩條都接**——同時接會讓每次 push 觸發兩次部署、互相覆蓋。

| | A. Workers Builds（預設） | B. GitHub Actions |
|---|---|---|
| 你要做的 | 在後台授權 Cloudflare 的 GitHub App，**每個新專案都要點一次** | 產一顆 API Token、貼一次 secret |
| Agent 能代做的 | GitHub 連結授權仍由使用者操作；連上後可依授權 push 並查核部署 | 除了貼 secret 以外全部 |
| 設定放哪 | Cloudflare 後台，之後要改都得進去點 | repo 裡的 `.yml`，進版控、可 review |
| 部署前能不能擋測試 | 可以，建置指令先跑測試 | **可以**，測試沒過就不上線 |
| 有沒有長期憑證 | 沒有 | 有一顆 API Token |

**沒在用密碼管理器的話建議選 A。** B 的 token 只會完整顯示一次，沒存下來的話，
下一個專案要再用就得重產一顆——而 A 每次雖然要點，但不必保管任何東西。

反過來說，**已經接好 B 的專案不必為了這個理由拆掉**：token 存在 GitHub 的加密
secret store 裡，你不需要再看到它，只有「要用到第二個 repo」時才會需要重產。

### 路線 A：Workers Builds

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

5. 儲存後 push 一個 commit，就會觸發第一次自動建置；這次 push 若由 agent 執行，先取得涵蓋發布的授權

**驗證方式**：GitHub 上該 commit 會出現名為 `Workers Builds: <你的 Worker 名>` 的檢查項目，
狀態變成 success 就代表成功。也可以用 `npx wrangler deployments list` 看有沒有新版本。

> **Node 版本不用另外設定**：Workers Builds 預設用 Node.js 24。
> 需要指定版本時，加一個 `.node-version` 檔或設 `NODE_VERSION` 建置環境變數。

接上之後，push 到 production branch 就會由 Cloudflare 自動建置與部署，不必對同一批變更再手動跑 `wrangler deploy`。
agent 可在取得本次發布授權後 push，並確認建置成功、正式網站已更新；自動建置失敗時不逕自改走手動部署。
記得同步更新專案文件，不要留著「要手動部署」的過期說明。

### 路線 B：GitHub Actions

> agent 執行時讀的是技能資料夾的 `references/github-actions.md`（隨技能安裝，含下方「從 B 換回 A」）；本節是給人看的完整版。

只有第 1、2 步要你動手，其餘可以交給 agent。

**1. 產一顆 API Token**（🖐️ 你自己做）

[dash.cloudflare.com](https://dash.cloudflare.com) → 右上頭像 → **Profile** → **API Tokens**
→ **Create Token** → 選 **"Edit Cloudflare Workers"** 模板 → 建立。

- **Account Resources**：Include 你自己的帳號
- **Zone Resources**：模板會自動帶上，那是給**自訂網域**路由用的。走 `*.workers.dev`
  用不到，留著也不會多給出什麼
- **有效期限**：如果設了到期日，**到期那天自動部署會無聲失效**，先想清楚

> 按下 Create 之後 **token 只會完整顯示這一次**，關掉就看不到了。

**2. 把 token 貼進 GitHub**（🖐️ 你自己做）

```bash
gh secret set CLOUDFLARE_API_TOKEN --repo <你的帳號>/<專案>
```

提示出現時貼上、Enter。值直接進 GitHub 的加密 secret store，**不經過對話、不進任何檔案**。
不要把 token 貼給 agent 看——這一步刻意由你自己做。

**3. 讓 agent 建立 workflow**

請 agent 在 `.github/workflows/deploy-cloudflare.yml` 寫入部署流程，要點有四個：

| 要點 | 為什麼 |
|---|---|
| `on.push` 加 `paths` 過濾 | 只有前端目錄或 `wrangler.jsonc` 變動才跑，不浪費 Actions 分鐘數 |
| 部署前先跑專案測試 | 測試沒過就不上線，這是路線 A 做不到的 |
| `permissions: contents: read` | 這支只需要讀原始碼，不給任何寫入權限 |
| **`wranglerVersion: "4"`** | 見下方警告，**漏了一定失敗** |

> ⚠️ **`wranglerVersion` 一定要指定 `"4"`**。`cloudflare/wrangler-action@v3` 預設安裝的是
> wrangler **3**，而「沒有 `main`、只有 `assets`」的純靜態 Worker 是 wrangler 4 才支援的寫法，
> 用 3 會直接報 `Missing entry-point`。你本機裝的通常已經是 4.x，所以**這個坑只在 CI 現形**，
> 症狀是「本機部署得好好的，CI 卻說找不到進入點」。

**驗證方式**：push 之後看 GitHub 的 Actions 頁面，或用指令：

```bash
gh run watch <run-id> --exit-status
```

失敗就用 `gh run view <run-id> --log-failed` 看實際錯誤。也可以用
`npx wrangler deployments list --name <worker 名>` 確認 Cloudflare 上真的多了一個版本，
比對時間戳就知道是不是 CI 推的。

### 從 B 換回 A

順序反了會有一段空窗期，Cloudflare 站更新不了：

1. 先在後台接好 Workers Builds
2. 確認它成功自動部署一次
3. **刪掉 repo 裡的 workflow 檔**——留著會每次 push 都紅叉，兩套並存還會互相覆蓋
4. 最後才刪 Cloudflare 的 API Token 與 GitHub secret

> 刪掉 token **不會影響已經上線的網站**，它照常運作。token 只用在「部署」這個動作。
> 壞掉的是自動部署，而且失敗得很安靜：CI 紅叉，網站停在舊版本，你不去看不會發現。

---

## 步驟十：加上 D1 資料庫與 API（選用）

> **預設是純靜態站，這一步只在你需要存資料時才做**，agent 不會主動提議。
>
> agent 執行時讀的是技能資料夾的 `references/d1.md`（隨技能安裝）；本節是給人看的完整版。

靜態網站只能「發檔案」，沒辦法存資料。要讓網頁能留言、報名、記分，就需要資料庫。
**D1** 是 Cloudflare 的 SQL 資料庫（底層是 SQLite），免費方案就能用。

### 先搞懂一件事：瀏覽器不能直接連 D1

D1 只能從 **Worker 程式碼**裡存取。所以加資料庫其實是兩件事：

```
瀏覽器 ──/api/notes──▶ Worker 程式碼 ──env.DB──▶ D1
瀏覽器 ──其他路徑────▶ 靜態檔案（跟以前一樣，不經過程式碼）
```

用 `run_worker_first: ["/api/*"]` 把兩者分開：只有 `/api/` 開頭的請求會執行程式碼，
其他請求照舊直接發檔案，免費額度與速度都不受影響。

### 1. 建立資料庫（⚠️ 要你同意）

agent 會先跟你確認三件事，你說好才執行：

| 要確認的 | 說明 |
|---|---|
| 資料庫名稱 | 小寫英數與連字號，例如 `my-site-db` |
| 地區 | 台灣選 `apac`（亞太）。**建立後不能改**，而且只是偏好，Cloudflare 不保證一定放在那裡 |
| binding 名稱 | 程式碼裡用來叫資料庫的名字，預設 `DB`（程式碼寫 `env.DB`） |

```bash
npx wrangler d1 create my-site-db --location apac --binding DB --update-config
```

`--update-config` 會自動把設定寫進 `wrangler.jsonc`。完成後檢查是否多了這段：

```jsonc
"d1_databases": [
  {
    "binding": "DB",
    "database_name": "my-site-db",
    "database_id": "（d1 create 印出的 ID）"
  }
]
```

沒寫進去的話，把指令輸出的那段手動貼上即可。

> **為什麼建立交給 agent，刪除卻要你自己來**：D1 不會公開任何東西，建錯了也能刪，
> 所以不必像部署一樣由你親手按。刪除則不可逆，資料一去不回，一律由你自己執行。

### 2. 寫遷移檔（資料表結構）

不要直接對資料庫下 `CREATE TABLE`，改用**遷移檔**記錄每一次結構變更，才能在本機與正式環境重現：

```bash
npx wrangler d1 migrations create my-site-db create-notes
```

它會在 `migrations/` 產生一個帶編號的 `.sql` 檔，寫入：

```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  body TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
```

> ⚠️ **已經套用過的遷移檔不要改。** Wrangler 用資料庫裡的 `d1_migrations` 表記住哪些檔案套用過，
> 改了舊檔不會重跑。要改結構就再 `migrations create` 一份新的。

### 3. 套用到本機

```bash
npx wrangler d1 migrations apply my-site-db --local
```

本機資料庫是 `.wrangler/state/` 裡的一個 SQLite 檔，跟正式資料完全分開，怎麼玩都不影響線上。

### 4. 寫 API Worker

`wrangler.jsonc` 加上 `main` 與 `run_worker_first`：

```jsonc
{
  "name": "my-site",
  "compatibility_date": "2026-09-14",
  "main": "./worker/index.js",
  "assets": {
    "directory": "./dist",
    "not_found_handling": "single-page-application",
    "run_worker_first": ["/api/*"]
  },
  "d1_databases": [
    { "binding": "DB", "database_name": "my-site-db", "database_id": "（ID）" }
  ]
}
```

建立 `worker/index.js`（放在 `worker/` 而不是 `src/`，避免跟前端程式碼混在一起）：

```js
export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === "/api/notes" && request.method === "GET") {
      const { results } = await env.DB.prepare(
        "SELECT id, body, created_at FROM notes ORDER BY id DESC LIMIT 50"
      ).all();
      return Response.json(results);
    }

    if (url.pathname === "/api/notes" && request.method === "POST") {
      const data = await request.json().catch(() => null);
      const body = data?.body;
      if (typeof body !== "string" || body.length === 0 || body.length > 500) {
        return Response.json({ error: "body 需為 1–500 字的文字" }, { status: 400 });
      }
      await env.DB.prepare("INSERT INTO notes (body) VALUES (?)").bind(body).run();
      return Response.json({ ok: true }, { status: 201 });
    }

    return Response.json({ error: "Not found" }, { status: 404 });
  },
};
```

> ⚠️ **SQL 一律用 `prepare(...).bind(...)`**，不要用字串相加把使用者輸入拼進 SQL，
> 否則任何人都能透過輸入框對你的資料庫下指令（SQL injection）。

`run_worker_first` 寫成陣列需要 **Wrangler 4.20 以上**；舊版會把它當成錯誤設定。

### 5. 本機驗證

```bash
npm run build
npx wrangler dev
```

| 檢查項目 | 預期結果 |
|---|---|
| `GET /api/notes` | 回 `[]`（還沒有資料） |
| `POST /api/notes`，body 為 `{"body":"測試"}` | 回 201，再 GET 就看得到 |
| 首頁與深層路徑 | 跟加 D1 之前一樣正常 |
| `/api/不存在` | 回 404 JSON |

### 6. 套用到正式資料庫（⚠️ 要你同意）

```bash
npx wrangler d1 migrations apply my-site-db --remote
```

> ⚠️ **這一步 Wrangler 本來會問「確定要套用嗎？」，但在 agent 的執行環境裡會自動跳過。**
> agent 執行指令的環境不是互動式終端，Wrangler 偵測到後會直接套用。所以 agent 必須**自己先**
> 列出要套用的遷移檔、取得你的同意，才能跑這道指令。

**順序很重要**：先套用遷移、再部署程式碼。反過來的話，新程式碼上線那一刻資料表還不存在，API 會直接報錯。

### 7. 部署

照步驟八（手動）或步驟九（自動部署）上線，D1 設定跟著 `wrangler.jsonc` 一起走，不用另外處理。

> ⚠️ **API 上線後任何人都能呼叫。** 範例的 `POST /api/notes` 沒有任何驗證，
> 知道網址的人都能寫入。正式使用前要想好：需不需要登入？要不要限制頻率？
> 至少先確認寫入的內容不會被當成 HTML 直接顯示在網頁上。

**走 GitHub Actions（路線 B）的話**：「Edit Cloudflare Workers」模板**不含 D1 權限**。
CI 部署若出現 D1 相關的權限錯誤，到後台編輯那顆 token，加上 **Account → D1 → Edit**。
遷移建議在本機經同意後手動套用，不要放進 CI 自動跑。

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

【D1 資料庫】（有做步驟十才填）
- 資料庫名稱／地區：
- binding 名稱：
- 已套用的遷移（本機）：
- 已套用的遷移（正式）：
- API 路徑與驗證結果：

【使用者仍需自己完成】
-
```

---

## 如果失敗，如何重來

| 想回到哪裡 | 怎麼做 |
|---|---|
| 解除本機授權 | `npx wrangler logout`，之後重跑步驟二 |
| 重設專案設定 | 刪掉 `wrangler.jsonc`、`_headers`、`.wrangler/`，從步驟四重來 |
| 取消自動部署（路線 A） | 後台該 Worker → Settings → Build → 中斷 Git 連結 |
| 取消自動部署（路線 B） | 刪掉 workflow 檔，再刪 GitHub secret 與 Cloudflare 的 API Token |
| 網站下線 | 🖐️ 使用者自己在後台刪除該 Worker（**不可逆**，agent 不得代為執行） |
| 正式資料庫改壞了 | 🖐️ `npx wrangler d1 time-travel restore <名稱> --timestamp=<Unix 時間>`，可回到 7 天內（付費方案 30 天）任一時間點。會覆蓋現有資料，但指令會給一個 bookmark，還原錯了能再還原回來 |
| 本機資料庫想重來 | 刪掉 `.wrangler/state/`，重跑 `migrations apply --local` |
| 不要資料庫了 | 🖐️ 先 `npx wrangler d1 export <名稱> --remote --output backup.sql` 備份，再 `npx wrangler d1 delete <名稱>`（**不可逆**），最後從 `wrangler.jsonc` 移除 binding、刪掉 `main` 與 `run_worker_first` |

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
| `database_id` 可以推上公開 repo 嗎？ | 可以。它只是識別碼，沒有 Cloudflare 帳號授權的人拿到也動不了資料庫 |
| 本機 API 有資料，線上卻是空的 | 本機與正式是兩個資料庫。線上要另外 `migrations apply --remote`，資料也不會自動同步 |
| 線上 API 報 `no such table` | 程式碼先部署了、遷移還沒套用到正式資料庫，補跑 `migrations apply --remote` |
| `d1 create` 失敗 | 名稱已被自己帳號用過，或免費方案已滿 10 個資料庫。用 `npx wrangler d1 list` 查，舊的要不要刪由你決定 |
| `/api/...` 回的是首頁 HTML | `run_worker_first` 沒設、寫錯，或 Wrangler 低於 4.20 |
| 讀取次數用得很快 | D1 以「掃過的列數」計費，沒有索引的查詢會整張表掃。常用的 `WHERE` 欄位要建索引（寫成新的遷移檔） |

---

## 免費方案說明

靜態網站放在 Cloudflare 上實質是零成本：

- **靜態資產請求免費且不限次數**。免費方案「每天 10 萬次請求」的上限只計算會**執行 Worker
  程式碼**的請求，純靜態網站沒有程式碼，碰不到那個上限
- 每個版本可放 20,000 個檔案、單檔上限 25 MiB
- `workers.dev` 子網域免費，不需要購買網域

只有想用自訂網址時才需要付費，而且付的是**網域本身的年費**，Cloudflare 的服務仍然免費。

**加了 D1 之後**，只有 `/api/*` 請求會執行程式碼、計入每天 10 萬次的上限，靜態檔案照舊免費。
D1 免費方案的額度：

| 項目 | 免費方案 |
|---|---|
| 資料庫數量 | 10 個 |
| 單一資料庫大小 | 500 MB |
| 帳號總儲存量 | 5 GB |
| 讀取 | 每天 500 萬列 |
| 寫入 | 每天 10 萬列 |
| 每次請求可下的查詢數 | 50 次 |
| 時間點還原（Time Travel） | 7 天 |

課堂、活動規模的網站通常遠遠用不完。超過額度時請求會失敗，不會自動扣款。

---

## 更新紀錄

| 版本 | 日期 | 變更 |
|------|------|------|
| v0.1 | 2026-08-18 | 初版。流程與所有踩坑紀錄來自一次實際的網站遷移（Netlify → Cloudflare Workers，含首次部署與接上 Workers Builds），尚未以技能形式重跑驗證 |
| v0.2 | 2026-09-14 | 新增步驟十「加上 D1 資料庫與 API」：建立資料庫、遷移檔、`run_worker_first` 分流的 API Worker、本機與正式環境的套用順序。確立同意點：建立與正式遷移由 agent 在當下同意後執行（Wrangler 在非互動環境會自動跳過自己的確認），刪除與還原由使用者執行；建立資源與改結構走 Wrangler、MCP 只用來查看（兩者授權帳號可能不同）；D1 不主動提議。補免費額度、復原與常見問題。依官方文件撰寫，尚未實測 |
| v0.3 | 2026-09-15 | 教學內容不變，**技能結構調整**：只在特定情況才走的內容從 `SKILL.md` 移到技能資料夾的附屬檔——D1（步驟十）→ `references/d1.md`，自動部署路線 B 與「從 B 換回 A」→ `references/github-actions.md`，隨技能安裝。`SKILL.md` 由 129 行降為 106 行，保留路線取捨表、路線 A、D1 兩個同意點與全部安全規則，並加上附屬檔索引表。依據是同日在 PC-YI-SL 實測 Codex、OpenCode、Antigravity 都讀得到技能資料夾裡的附屬檔（通則寫入 `TEMPLATE.md`〈附屬檔〉） |
| v0.4 | 2026-09-24 | Cloudflare 正式部署改為使用者授權本次發布後可由 agent 執行；Workers Builds 連接 GitHub 後，推送到 production branch 可自動部署，agent 的 push 同樣要有發布授權並查核結果。同一批變更不重複手動部署。 |

---

## 相關連結

- [Cloudflare 後台](https://dash.cloudflare.com)
- [Workers 靜態資產文件](https://developers.cloudflare.com/workers/static-assets/)
- [Workers Builds 文件](https://developers.cloudflare.com/workers/ci-cd/builds/)
- [Wrangler 設定參考](https://developers.cloudflare.com/workers/wrangler/configuration/)
- [D1 Wrangler 指令](https://developers.cloudflare.com/d1/wrangler-commands/)
- [D1 遷移](https://developers.cloudflare.com/d1/reference/migrations/)
- [D1 額度限制](https://developers.cloudflare.com/d1/platform/limits/)
- [D1 時間點還原](https://developers.cloudflare.com/d1/reference/time-travel/)
- [Cloudflare 官方 MCP server 目錄](https://developers.cloudflare.com/agents/model-context-protocol/cloudflare/servers-for-cloudflare/)
