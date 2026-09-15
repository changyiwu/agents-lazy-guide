# 自動部署路線 B：GitHub Actions

本檔隨 `agent-cloudflare` 安裝，由 `SKILL.md` 步驟 10 指向。**使用者選了路線 B，或要從 B 換回 A 時才讀。**
兩條路線的取捨表在 `SKILL.md`；踩坑背景見 `guides/06-連接-Cloudflare.md` 步驟九。

**與路線 A 不可並存**——同時接會讓每次 push 觸發兩次部署、互相覆蓋。

## 步驟

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

之後加上 D1 時，這顆 token 的模板**不含 D1 權限**：CI 報 D1 權限錯誤時，請使用者在 token 加 Account → D1 → Edit。

## 從 B 換回 A

順序反了會有一段空窗期，Cloudflare 站更新不了：
先接好 A（`SKILL.md` 步驟 10 路線 A）→ 確認自動部署成功一次 → 刪掉 workflow 檔 → 最後才刪 token 與 secret。
token 與 secret 由使用者自己在後台與 GitHub 刪除。
