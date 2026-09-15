---
title: 'AI Agent 懶人包 #07：連接 ComfyUI'
date: '2026-09-15'
type: 懶人包
version: v0.11
status: 初版（生圖、MiniMax H3 影片、Music 3 音樂已實測）
tags:
  - 懶人包
  - ComfyUI
  - 生圖
  - 影片
  - 音樂
  - 本機模型
---

# 懶人包 #07：連接 ComfyUI

**版本** v0.11｜**更新日期** 2026-09-15｜**適用** Claude Code / Codex / OpenCode / Antigravity

---

## 這份懶人包會幫你做什麼？

- 在這台電腦裝好 **comfy-cli**（ComfyUI 官方命令列工具），接上你已經在跑的 ComfyUI
- 讓 agent 能**套用官方範本或你自己的工作流程**，改提示詞、seed、尺寸後送出
- 送出前先**檢查缺哪些模型**，經你同意才下載，而且下載完會驗證檔案沒壞
- 生成結果**自動取回專案資料夾**，直接給你看
- 全程只用你自己的顯卡，**不花任何點數**；會花錢的雲端節點一律擋下來問你

做完之後，你只要跟 agent 說「用 ComfyUI 畫一張 XX」，它就會自己跑完整條流程。

---

## comfy-cli 與 MCP 的分工（重要）

Comfy 官方同時提供 CLI 與 MCP，**本懶人包只用 CLI**。

| | comfy-cli | 本機 MCP（`comfy-mcp`） | 雲端 MCP |
|---|---|---|---|
| 是什麼 | 官方命令列工具 | 包在 comfy-cli 外面的 MCP server | 在 Comfy Cloud 的 GPU 上跑 |
| 用誰的顯卡 | 你的 | 你的 | 雲端（**要訂閱、會扣點數**） |
| 跨 agent | ✅ 四家都在 shell 跑同一套指令 | 每家 agent 各自設定一次 | 每家 agent 各自授權 |
| 設定後 | 立刻能用 | 要重開 agent 才載入 | 要重開 agent 才載入 |
| 長時間工作 | 送出後拿編號，隨時接回 | 同樣可以，但受各家 MCP 逾時限制 | — |

選 CLI 的理由：本機 MCP **本身就要先裝 comfy-cli**，等於多包一層；它能做的
（改參數、送出前檢查）CLI 都有對應指令，而 MCP 的成本（四套設定、重開、逾時）每家都要付一次。

> **官方技能也不裝。** comfy-cli 內建 `comfy skills install`，會裝 6 個官方技能，主技能長達 1344 行。
> 它只裝到 Claude Code、Cursor 與家目錄的 `AGENTS.md`，不涵蓋 Codex、Antigravity，
> 內容還會教 agent 主動邀請你回饋、送出使用紀錄。需要深入資料時，用
> `comfy skills show comfy` 臨時讀一次就好（只印出來，不寫入任何檔案）。

---

## 先備條件

- [ ] 已安裝 **ComfyUI**（建議用 [ComfyUI Desktop](https://www.comfy.org/download)，一鍵安裝；要不要開啟 Desktop 見步驟零）
- [ ] 有 NVIDIA 顯卡，**VRAM 8GB 以上**（實測 RTX 5060 Laptop 8GB、RTX 5060 Ti 16GB；VRAM 越大能跑的模型越多）
- [ ] 已安裝 **uv**（沒有的話先做懶人包 #00 環境建置）
- [ ] 磁碟有足夠空間放模型（生圖模型一組約 11–20 GB，依顯卡選的版本而定，見步驟四；影片模型更大，MiniMax H3 一組約 34–41 GB，見步驟九）

---

## 完成標準

- [ ] `comfy --json system-stats` 顯示你的 ComfyUI 版本與顯卡
- [ ] 至少一個範本 `templates check` 結果為可執行（沒有缺模型）
- [ ] 送出前 `workflow validate` 通過
- [ ] 實際生成一張圖，檔案取回專案的 `generated/` 資料夾，打得開
- [ ] 過程中沒有花費任何 Comfy 點數

---

## 執行原則（給 AI Agent）

- **預設只跑本機的免費模型。** `--allow-spend`、`--where cloud`、`comfy generate`、`comfy cloud login`
  都會花點數或連雲端，每次都要取得使用者當下的明確同意。遇到 `spend_consent_required` 錯誤時，
  **不可**為了讓錯誤消失而自行加上 `--allow-spend`。
- **下載模型前先問。** 列出檔名、放哪個資料夾、大小、來源；模型動輒數 GB。
- **不要動 Desktop 的安裝。** 不執行 `comfy install`／`launch`／`update`／`stop`，Desktop 自己管理。
  步驟零「方式二」只是用 Desktop 裝好的環境跑一個 ComfyUI 行程，不改安裝；用完只停自己啟動的那個行程。
- **不安裝官方技能**（`comfy skills install`），也不主動送出 `comfy feedback`／`comfy agent-review`。
- **不安裝擴充節點**，除非使用者明確同意——`comfy node install` 會在本機執行第三方程式碼。
- **不可盲目套用工具給的建議值**，尤其是 `workflow validate` 的 `suggestions`（見步驟七）。
- 不把 `COMFY_API_KEY` 寫進檔案、指令列或對話。
- **哪些要逐項確認**：安裝 comfy-cli、背景啟動 ComfyUI、下載模型、付費節點、安裝擴充節點、刪除任何東西。
  改參數、送出前預檢、送出本機免費的工作**不必再問**——使用者說「用 ComfyUI 畫一張」就是要 agent 跑完。
- 每個步驟失敗時給出具體排查方向，不要只說「請重試」。

---

## 步驟零：環境檢查

> 開始前先自動確認以下項目。任何一項不符合，先告知使用者問題所在並引導解決後再繼續。
> **不要跳過任何一項，不要假設環境正常。**

1. **確認作業系統**（Windows / macOS / Linux）—— 後續指令依實際系統選擇正確版本
2. **確認網路連線正常**
3. **確認 uv**：`uv --version`
4. **確認 ComfyUI 在線**：打開 `http://127.0.0.1:8188/system_stats` 應回傳 JSON
   - Windows：`Invoke-RestMethod http://127.0.0.1:8188/system_stats`
   - macOS / Linux：`curl -s http://127.0.0.1:8188/system_stats`
5. **記下 VRAM**：同一份回傳的 `devices[0].vram_total`（位元組），步驟四要依它選模型版本

> 全部通過後告知：「環境檢查完成，開始執行。」
> 安裝完工具後若指令仍找不到，提醒使用者完全關閉並重開 agent。

**連不上 ComfyUI 時**，先問使用者要用哪一種方式。

**方式一：開啟 Desktop（預設）**——🖐️ 請使用者開啟 ComfyUI Desktop，等它載入完成再試。
新版 Desktop 實測使用 **8188** 埠；如果你的 ComfyUI 用別的埠，設定環境變數
`COMFY_LOCAL_URL=http://127.0.0.1:<埠>`，之後所有 `comfy` 指令都會連到那裡。

**方式二：不開 Desktop 視窗，由 agent 在背景以 API 模式啟動**（Windows 的 Desktop 安裝實測可用）。
適合只要 agent 生圖、不需要看 ComfyUI 畫面的時候。後面的步驟完全相同，因為 comfy-cli 都走 HTTP 連線。

1. **讀路徑，不要照抄**——每台電腦的實例 id 都不同：

   | 要什麼 | 從哪裡讀 |
   |---|---|
   | 安裝位置、實例 id | `%APPDATA%\Comfy Desktop\installations.json` 的 `installPath`、`id`（取 `sourceId` 不是 `cloud` 的那一筆；`Comfy Cloud` 那筆沒有 `installPath`） |
   | 模型路徑設定檔 | `%APPDATA%\Comfy Desktop\instance-model-paths\<實例 id>.yaml` |
   | 輸入、輸出資料夾 | `%APPDATA%\Comfy Desktop\settings.json` 的 `inputDir`、`outputDir` |

2. **Python 一定要用 `<installPath>\ComfyUI\.venv\Scripts\python.exe`**。
   同層的 `<installPath>\standalone-env\python.exe` 看起來也像，但**沒有 torch**，一跑就 `ModuleNotFoundError`。
3. **確認 Desktop 沒有開著**，否則兩個行程會搶同一個埠。
4. **用 `Start-Process` 放背景啟動**，工作目錄設在 `<installPath>\ComfyUI`：

   ```powershell
   $p = Start-Process -FilePath "<installPath>\ComfyUI\.venv\Scripts\python.exe" `
     -WorkingDirectory "<installPath>\ComfyUI" -WindowStyle Hidden -PassThru `
     -ArgumentList "main.py --listen 127.0.0.1 --port 8188 --disable-auto-launch --extra-model-paths-config `"<模型路徑設定檔>`" --output-directory `"<outputDir>`" --input-directory `"<inputDir>`""
   $p.Id   # 記下來，停止時用
   ```

   - **不要用 `& python.exe main.py …`**：那是前景執行，會一直佔住 agent 的指令直到逾時，也拿不到 PID。
   - **含空白的路徑要用 `` `" `` 包起來**：模型路徑設定檔在 `Comfy Desktop` 資料夾裡，路徑有空白；
     `-ArgumentList` 不會自動加引號，不包的話會在空白處被拆成兩個參數（實測包起來後完整傳入）。
   - **只帶模型、輸入、輸出三組路徑**，模型與產出才會和 Desktop 共用。`installations.json` 裡 Desktop 自己的
     `launchArgs`（例如 `--enable-manager`）**刻意不帶**：API 模式只給 agent 送工作，用不到擴充管理器。
   - `--listen` 只綁 `127.0.0.1`，不要改成 `0.0.0.0`（會讓同網段的人都能送工作）。
   - 載入需要一點時間，輪詢 `system_stats` 到有回應再繼續（16GB 桌機實測 5.6–8.1 秒；另一台 16GB 桌機某次要 71 秒，要給足時間）。
5. **用完停掉自己啟動的那個行程**。不要停 Desktop 開的 ComfyUI，也不要用 `comfy stop`：

   ```powershell
   Stop-Process -Id <記下的 PID>
   Get-NetTCPConnection -LocalPort 8188 -State Listen -ErrorAction SilentlyContinue   # 應該沒有結果
   ```

   `.venv\Scripts\python.exe` 其實是 uv 建立的**啟動器**（約 240 KB），它會帶起 `standalone-env\python.exe` 當子行程，
   並帶入 `.venv` 的套件（所以有 torch；步驟 2 說的「沒有 torch」是指直接執行它）。**真正監聽 8188 的是子行程**，
   實測停掉啟動器，子行程會跟著結束、埠隨即釋放（先以測試腳本驗證，之後實際啟動 ComfyUI 再測兩次，約 1 秒釋放 8188）。
   萬一 8188 還在監聽，查它的 `OwningProcess`，用 `Get-CimInstance Win32_Process -Filter "ProcessId=<OwningProcess>"`
   確認 `ParentProcessId` 是你記下的 PID 才停；不是的話那是別人（例如 Desktop）開的，不要動。

---

## 步驟一：安裝 comfy-cli

```bash
uv tool install comfy-cli
comfy --version
```

> **不想安裝也可以。** 把本篇所有 `comfy` 換成 `uvx --from comfy-cli comfy`，
> uv 會暫時下載來執行，不會加進 PATH。兩種方式都實測過（comfy-cli 1.20.0）。

`comfy` 找不到時，執行 `uv tool update-shell` 後重開 agent。

---

## 步驟二：關閉使用統計

```bash
comfy tracking disable
```

comfy-cli 內建匿名使用統計。先關掉是隱私優先的預設值；你想幫官方改善工具，隨時可以 `comfy tracking enable`。

---

## 步驟三：連線驗收

```bash
comfy --json system-stats
```

確認回傳裡有 `comfyui_version` 與你的顯卡名稱、VRAM。

> ⚠️ **`comfy which` 顯示的路徑不存在是正常的。** comfy-cli 預設假設 ComfyUI 是它自己裝的，
> 會指到 `Documents\comfy\ComfyUI`。Desktop 版裝在別處，但**送出工作、查範本、檢查工作流程**
> 都走 HTTP 連線，不受影響。只有「安裝、啟動、下載模型、裝擴充節點」這類指令會依賴那個路徑——
> 這些本篇一律不用。

如果你只是要「連接 ComfyUI」，做到這裡就結束了。以下是實際生成的部分。

---

## 步驟四：選工作流程

有兩種來源。

### 來源 A：官方範本（推薦新手）

官方範本庫有數百個工作流程（實測：圖片 299、音訊 35、影片 237）。

```bash
comfy --json templates ls --type image
comfy --json templates check image_z_image_turbo
comfy --json templates fetch image_z_image_turbo -o comfyui/z-image.json
```

**先依 VRAM 選版本**。同一個模型，官方範本庫常有完整版與量化版兩種範本，
缺的模型檔完全不同。以 Z-Image Turbo 為例：

| 你的 VRAM | 範本 | 要下載的模型 | 合計 |
|---|---|---|---|
| 16GB 以上 | `image_z_image_turbo` | `z_image_turbo_bf16` 11.46 GB＋`qwen_3_4b` 7.49 GB＋`ae` 0.31 GB | 約 19.3 GB |
| 8GB–未滿 16GB | `image_z_image_turbo_int8` | `z_image_turbo_int8_convrot` 5.78 GB＋`qwen_3_4b_fp8_mixed` 5.25 GB＋`ae` 0.31 GB | 約 11.3 GB |

- 完整版在 16GB 桌機生圖時佔用約 12.6 GB VRAM，**8GB 放不下**。ComfyUI 會自動把放不下的部分搬到系統記憶體，
  所以仍跑得動，但會慢很多，而且需要 32GB 以上記憶體——**不要讓它硬跑，直接換 Int8 範本**
- Int8 範本實測（RTX 5060 Laptop 8GB）生圖時 VRAM 約 4.5 GB，不需要擴充節點；兩個範本改參數的地址相同（步驟六）
- 量化版用同一個 seed **不會**得到和完整版一樣的圖；兩者畫質尚未並排對比
- VRAM 未滿 8GB 尚未實測

`templates check` 會告訴你三件事：

| 欄位 | 意思 |
|---|---|
| `verdict` | 能不能直接跑；`missing-models` 代表缺模型 |
| `models.missing` | 缺的檔名、該放哪個資料夾、官方下載網址 |
| `api.dependent` | 是否依賴**付費**的雲端節點，true 就要先問使用者 |

> 範本名稱以 `api_` 開頭的，幾乎都是付費雲端節點。

### 來源 B：你自己的工作流程

🖐️ 在 ComfyUI 裡把做好的工作流程存成 JSON，放進專案的 `comfyui/` 資料夾。
UI 格式或 API 格式都可以，comfy-cli 會自動轉換。

> **不想另存也可以：直接用生過的圖。** ComfyUI 存的 PNG 內嵌一個 `prompt` 文字區塊，
> 內容就是那張圖的**完整 API 格式工作流程**。用 Pillow 讀出來存成 JSON 即可
> （ComfyUI 的 `.venv` 裡就有 Pillow，不必另外裝）：
>
> ```python
> import json
> from PIL import Image
> wf = json.loads(Image.open("那張圖.png").info["prompt"])
> with open("comfyui/my-workflow.json", "w", encoding="utf-8") as f:
>     json.dump(wf, f, ensure_ascii=False, indent=2)
> ```
>
> 實測 Desktop 用 Z-Image Turbo 範本生的圖讀得出完整工作流程（10 個節點，含提示詞、seed、尺寸）。
> 取出後一樣先跑步驟六的 `slots` 看地址，不要自己猜節點 id。

---

## 步驟五：補模型

`templates check` 回報缺模型時，agent 要**先列出清單、取得同意才下載**。

**1. 查大小**：對官方網址發 HEAD 請求，讀 `X-Linked-Size` 標頭（位元組數）。
順便記下 `X-Linked-ETag`——**Hugging Face 的這個值就是檔案的 SHA256**，下載完拿來比對。

**2. 找放置位置**：`comfy --json system-stats` 回傳的 `argv` 裡有 `--extra-model-paths-config`，
指向一個 yaml 檔，裡面的 `base_path` 加上資料夾名就是目標位置。Desktop 通常是：

```
%LOCALAPPDATA%\Comfy-Desktop\ComfyUI-Shared\models\<資料夾>\
```

**3. 下載**：先存成 `<檔名>.part`，確認**大小與 SHA256 都相符**後才改名。
ComfyUI 會掃資料夾，直接用正式檔名下載的話，它可能讀到只下載一半的檔。

**4. 確認**：

```bash
comfy --json model list-folder vae
```

> **不要用 `comfy model download`**：它依賴 comfy-cli 自己的工作區（就是那個不存在的路徑），
> 在 Desktop 下未驗證會寫到哪裡。

> **大檔一律放背景跑。** 模型動輒 5 GB 以上，會超過 agent 單一指令的時限。
> 下載途中 Windows 可能一直顯示 `.part` 是 0 bytes——那是檔案還沒關閉、大小沒更新，**不是卡住**；
> 看下載腳本的輸出或 curl 行程是否還在來判斷，不要因此重下。
>
> PowerShell 7 用 `Invoke-WebRequest -Method Head -MaximumRedirection 0` 查大小時，會印出「已超過重新導向次數上限」，
> 但標頭照樣讀得到、數值正確，可以忽略。一次查好幾個檔時紅字會蓋過結果，可以改用
> `curl.exe -sI <url>`，從輸出取 `x-linked-size`、`x-linked-etag` 兩行，就不會出現這個訊息。

**實測紀錄**：

| 電腦 | 補下載的檔 | 耗時 | 驗證 |
|---|---|---|---|
| 桌機 16GB（完整版） | `vae/ae.safetensors`（335,304,388 bytes） | 8 秒 | SHA256 相符 |
| 另一台桌機 16GB（完整版，全新安裝） | `vae/ae.safetensors` 0.31 GB＋`text_encoders/qwen_3_4b.safetensors` 7.49 GB＋`diffusion_models/z_image_turbo_bf16.safetensors` 11.46 GB | 共約 7 分鐘（約 45 MB/s） | 三個都 SHA256 相符 |
| 筆電 8GB（Int8 版） | `vae/ae.safetensors` 320 MB＋`text_encoders/qwen_3_4b_fp8_mixed.safetensors` 5.25 GB＋`diffusion_models/z_image_turbo_int8_convrot.safetensors` 5.78 GB | 共約 27 分鐘（約 6–8 MB/s） | 三個都 SHA256 相符 |

三個檔都來自 Hugging Face `Comfy-Org/z_image_turbo`。下載速度依網路而定，差很多是正常的。

---

## 步驟六：改參數

```bash
comfy --json workflow slots comfyui/z-image.json
```

會列出每個可調欄位與目前的值，例如 Z-Image Turbo 範本（完整版與 Int8 版地址相同）：

| 地址 | 欄位 | 預設值 |
|---|---|---|
| `57.text` | 提示詞 | 一段英文描述 |
| `57.width`／`57.height` | 尺寸 | 1024 |
| `57.seed` | 亂數種子 | 0 |
| `57.steps` | 步數 | 8 |

改值：

```bash
comfy --json workflow set-slot comfyui/z-image.json "57.text=一隻戴墨鏡的貓，水彩風格" "57.seed=42"
```

> ⚠️ **地址是節點 id，不是標題**，而且每個工作流程都不一樣。一律先跑 `slots`，**照抄**它給的地址。
>
> ⚠️ **`comfy run --set` 不能搭配 `--workflow`**。它只能改 comfy-cli 內建的預設流程，
> 你自己的工作流程或範本要用 `workflow set-slot`，或是用腳本直接改 API 格式 JSON（見下一段）。
>
> 💡 **提示詞很長（尤其中文），或一次要產生很多個工作檔時，改用腳本直接改 JSON**：長中文放在指令列裡，
> 容易被 shell 的引號與編碼弄壞（Windows 主控台是 cp950）。讀入 API 格式 JSON → 改文字節點的 `inputs.text`、
> 取樣節點的 `inputs.seed`、`EmptySD3LatentImage` 的 `width`／`height`、`SaveImage` 的 `filename_prefix` →
> 以 UTF-8 一個工作存一個檔。節點 id 照 `slots` 查到的那組；`filename_prefix` 帶上名稱與 seed，
> 之後才能從輸出資料夾對回每一張。批次時抽一個檔跑預檢即可。

中文提示詞實測可用（Z-Image Turbo 官方標明支援中英文）。

### Z-Image Turbo 提示詞實測心得

以下來自實際生成教材插圖與四格漫畫的經驗（Int8 版筆電 8GB、完整版桌機 16GB）：

| 現象 | 做法 |
|---|---|
| 英文提示常把服裝、配件畫錯（「連身工作服」變吊帶褲、推在額頭上的護目鏡戴到眼睛上） | **提示詞寫中文**，服裝與配件逐項描述 |
| 寫「不要文字」「no text」沒有用 | 範本是 cfg 1＋`ConditioningZeroOut`（從生出的圖讀回 KSampler 確認 `cfg: 1.0`），**負面提示根本不起作用**。改寫成正面描述：「畫面中沒有任何文字」 |
| 就算這樣寫，碼錶、尺、牆面刻痕這類小地方仍會長出亂碼數字 | **選定前放大檢查**；面積很小的話，可以用左右相鄰的顏色內插蓋掉 |
| 「2 排、每排 4 塊」這種二維方陣、分節的軌道，數量幾乎都錯（實測 5 張全錯） | 要數的東西只排**單排**，或乾脆改構圖避開計數 |
| 兩個角色時常把服裝互換，或多長出一隻動物 | 挑候選時**逐張對照角色設定** |
| 本機生成免費，一張只要十幾秒 | 要挑圖時，**同一段提示一次跑 4 個 seed** 再從中挑一張；只要一張時照常跑一張 |
| 想壓掉偶爾出現的白色紙邊，加一句「四周沒有白色紙邊或邊框」，結果 12 張全部長出白紙邊（沒寫這句時約三成） | 否定語意進不了模型，「紙邊」這個詞本身就是正向訊號。**原本少見的東西不要提**，把那句拿掉、靠多跑 seed 挑 |
| 兩個角色的動作被對調（要少女倒漆、少年拿刷子，連兩輪 8 張都是少年倒漆），把服裝寫進動作句也沒用 | 改用**畫面位置綁定**：「畫面左半邊：穿藏青色工作服的少女倒漆……畫面右半邊：穿卡其色圍裙的少年只拿著刷子」，並把角色設定改成先描述做主要動作的那個人，8 張全對 |

#### 畫面中的中文字（招牌實測）

2026-09-15 在桌機（完整版、1536×864、8 步）生台灣騎樓街景，每組同一段提示跑 4 個 seed（101／202／303／404），逐字放大核對。

**第一輪**：六間店同框，招牌依序 1、2、3、4、5、7 字，刻意放入簡繁字形不同的字：

| 指定 | 4 張實際寫成 |
|---|---|
| 麵 | 4 張都是日文字形「麺」（左邊是「麦」） |
| 藥局 | 4 張全對 |
| 豆漿店 | 4 張都是「豆浆店」 |
| 臺灣雞排 | 4 張都是「台湾雞排」 |
| 阿嬤滷肉飯 | 「阿」「肉飯」都對；「嬤」「滷」4 張全錯 |
| 永豐鐘錶眼鏡行 | 沒有一張全對：豐變成豊／壹／宣、錶變成銀，一張只剩 6 字 |

第一輪看起來像是「字越多越糟」，但長招牌剛好也放了比較難的字。**第二輪對照**把字全部換成簡體、繁體、日文字形都相同的常用字，
分成六塊同框（版面同第一輪）與單塊招牌（1–10 字各一組）兩種，表中是 4 張裡「字與字數完全正確」的張數：

| 字數 | 指定 | 六塊同框 | 單塊招牌 |
|---|---|---|---|
| 1 | 茶 | 4/4 | 0/4（字對但重複補滿：兩張「茶茶茶」、兩張第一個字變成「自」「相」） |
| 2 | 牙科 | 4/4 | 4/4 |
| 3 | 豆花店 | 4/4 | 4/4 |
| 4 | 日本料理 | 4/4 | 4/4 |
| 5 | 天天早午餐 | 0/4（兩張「早早餐」、兩張少了「午」） | 2/4（另兩張「早早餐」） |
| 6 | 平安水果商行 | — | 4/4 |
| 7 | 大同平安五金行 | 1/4（兩張「金金行」、一張只剩 4 字） | 4/4 |
| 8 | 老王手工早午餐店 | — | 1/4（另三張「早早餐」） |
| 9 | 中山北路日本料理店 | — | 4/4 |
| 10 | 小林家手工豆花甜品店 | — | 4/4 |

| 現象 | 做法 |
|---|---|
| 簡繁字形不同的字被寫成簡體或日文字形，少見字直接變錯字；換成簡繁同形的字後，同樣字數幾乎全對 | 限制在**字形**不在字數。要正確繁體就生無字招牌再後製疊字，或挑簡繁同形的字 |
| 「早午」「五金」這種相鄰、字形相近的字，後一個常被寫成前一個 | 避開這種組合，或多跑 seed 逐字挑 |
| 橫跨整個店面的寬招牌只寫一個字，模型把空間補滿成三個字 | 一字招牌要縮小招牌寬度（六塊同框時的窄招牌 4/4 正確） |
| 同樣 7 字，單塊招牌 4/4，六塊同框只剩 1/4 | 重要的字**一張圖只放一塊招牌** |
| 寫了「除了這塊招牌之外，畫面中沒有任何文字」，店門口的小匾額、公告仍長出亂字 | 選定前放大檢查，必要時裁掉或蓋掉 |

各組只跑 4 個 seed、只測紅底白字的立體招牌字，數字是方向而不是精確比例。

**海報實測**（同日，1088×1536、4 個 seed）：做一張中秋活動海報，同一個版面分成兩種做法：

| 做法 | 結果 |
|---|---|
| 直接生字：金色大標題「中秋賞月晚會」、白色副標題「月圓人團圓」、底部兩行活動資訊 | 4 張都寫成「中秋赏月晚會」「月圆人圆圆」（賞、圓變簡體，團被複製成圓）；「9月25日 星期五 晚上7點」「地點：學校操場」4 張全對，放大確認點、學、場是繁體。另有一張多長出一行標題、一張把活動資訊壓在月亮上 |
| 無字底圖（上下各四分之一描述成乾淨的夜空與漸層，結尾「畫面中沒有任何文字」）＋ Pillow 以微軟正黑體疊字 | 4 張底圖都沒有冒出亂字，疊上的字全對。一張畫成貼在牆上的海報樣張（提示詞寫了「海報背景」），一張月亮頂到副標題的位置，能直接用的是 2/4 |

| 現象 | 做法 |
|---|---|
| 同一張圖裡點、學、場寫對，賞、圓固定變簡體，事先猜不到哪些字會錯 | 不要靠挑字保證正確；有正確性要求的字一律疊字，資訊圖表更是如此 |
| 直接生字的字體與插畫融合得比較好，疊字版用系統字型顯得陽春 | 疊字時挑有份量的字型、加描邊或光暈（這次沒有調整） |
| 提示詞寫「海報背景」，4 張中 1 張畫成牆上海報的樣張 | 底圖提示詞避開「海報」一詞（替代寫法未實測） |

需要挑圖時，跑 4 個 seed 的做法：`workflow set-slot` 改 seed → `run --no-watch` 拿到 prompt_id，重複 4 次
（工作會在 ComfyUI 排隊），再逐一 `jobs watch`、`download`。

一次排很多張（例如十張圖各跑 4 個 seed）時，逐一 `jobs watch` 太慢：全部送完後，在背景輪詢本機 ComfyUI 的
`http://127.0.0.1:8188/queue`，`queue_running` 與 `queue_pending` 都空了就是整批跑完，再直接讀 ComfyUI 的輸出資料夾，
用 `filename_prefix` 找檔。這只適用 ComfyUI 跑在本機；佇列清空不代表每張都成功，要數輸出檔數是否等於送出數。

---

## 步驟七：送出前預檢

`workflow validate` 會對照 ComfyUI **當下實際有的節點與模型**逐項檢查，比送出後才失敗省時間。
但它**只吃 API 格式**，所以要先轉換：

```bash
comfy --json run --workflow comfyui/z-image.json --print-prompt
```

`--print-prompt` 只印出轉換後的內容、**不會送出**。把回傳 JSON 的 `data.prompt` 存成
`comfyui/z-image.api.json`，再檢查：

```bash
comfy --json workflow validate --workflow comfyui/z-image.api.json
```

`valid` 為 true 才繼續。

> ⚠️ **不可盲目套用 `suggestions`。** 實測缺 VAE 時，validate 回報 `'ae.safetensors' not in 1 known options`
> 並建議改成 `pixel_space`——那是資料夾空空時唯一剩下的選項，**不是修正**。正確做法是回步驟五補模型。
>
> `validate` 的參數**一定要寫 `--workflow`**，直接接檔名會報用法錯誤。

---

## 步驟八：送出、等待、取回

```bash
comfy --json run --workflow comfyui/z-image.json --no-watch
```

一秒內回傳 `data.prompt_id`。接著等它完成：

```bash
comfy --json jobs watch <prompt_id>
```

完成才會 exit 0；失敗 exit 1 並附錯誤原因。最後取回：

```bash
comfy --json download <prompt_id> -o generated
```

專案有 `slides/` 資料夾的話改用 `-o slides/generated`（與 #05 生圖一致）。
下載的檔名是 `prompt_id 前 8 碼_序號`，例如 `d7cc3dae_000.png`，需要時自行改名。

**為什麼要分兩段，而不是 `run --wait` 一次等完**：agent 的指令多半有時間上限。
分段送出後，就算 `jobs watch` 被時限切斷，**工作仍然在 ComfyUI 上繼續跑**，
重新執行 `jobs watch <prompt_id>` 就能接回，**不要重新送出**（會多跑一次）。

**實測速度**（Z-Image Turbo、8 步）：

| 情況 | 桌機 RTX 5060 Ti 16GB（完整版） | 筆電 RTX 5060 Laptop 8GB（Int8 版） |
|---|---|---|
| 第一張（含載入模型） | 32 秒（另一台同規格 31.5 秒，1024×1024） | 34.5 秒 |
| 第二張（模型已在記憶體） | 11 秒（1280×720） | 11.1 秒（1024×1024） |

8GB 筆電換成 Int8 版後，速度和 16GB 桌機跑完整版差不多。

另一次在桌機用完整版生 864×1536 直式人像（2026-09-15）：ComfyUI 剛由 agent 背景啟動後的第一張 19.5 秒，每步 1.70 秒。

同日招牌實測（完整版、1536×864 橫式，見步驟六〈畫面中的中文字〉）：首張含載入模型 36.8 秒，之後 47 張每張 14.4–16.1 秒（平均約 14.9 秒，
取自 `/history` 的 `execution_start` 到 `execution_success`）。一次排 44 張，從送出到佇列清空約 11 分鐘。

---

## 步驟九：影片與音樂

流程和生圖**完全相同**：選範本 → `templates check` → 補模型 → 改參數 → 預檢 → 送出取回。
差別在模型大很多、一次跑好幾分鐘，以及 **agent 聽不到聲音**（影片音軌與音樂都要請使用者自己聽）。

> 範本名稱以 `api_` 開頭的（例如 `api_minimax_h3_max_i2v`）是付費雲端節點，不是用你的顯卡。
>
> **agent 執行時讀的是技能資料夾的 `models/minimax-h3.md`、`models/minimax-music3.md`**（隨技能安裝）；
> 本節是給人看的完整版，多了取捨原因與量測方式。

### 影片：MiniMax H3（已實測）

MiniMax H3 一次生成畫面和立體聲音軌（對白、音效、配樂），官方原生畫布短邊 768、最長約 15 秒、24fps。主模型分兩種：

| 主模型 | 用途 | 範本 |
|---|---|---|
| FL2VA | 文字轉影片（不接圖）、首幀／首尾幀轉影片 | `video_minimax_h3_i2v`、`video_minimax_h3_t2v` |
| Ref2VA | 多張參考圖、參考影片、參考聲音 | `video_minimax_h3_r2v`、`video_minimax_h3_multiframe_reference` |

以下實測都是 FL2VA 的 `video_minimax_h3_i2v`。

#### 1. 依顯卡選主模型

官方只提供 int8（和同大小的 fp8）版，**19.5 GB，16GB 顯卡放不下**。社群有更小的量化版：

| 版本 | 主模型大小 | 要擴充節點 | 適用 |
|---|---|---|---|
| 官方 `minimax_h3_fl2va_pruned_int8_convrot` | 19.53 GB | 不用 | 24GB 以上，或不是 RTX 50 系列的顯卡 |
| 社群 NVFP4 `minimax_h3_fl2va_pruned_nvfp4_all`（[MATLOWAI/minimax-h3-nvfp4](https://huggingface.co/MATLOWAI/minimax-h3-nvfp4)） | 11.67 GB | 不用 | **RTX 50 系列 16GB（✅ 實測）** |
| 社群 int4／int8 混合（[Abiray](https://huggingface.co/Abiray/Minimax-H3-nvfp4-INT4-INT8-Convrot)） | 14.81 GB | 不用 | 作者標需約 15.5 GB，16GB 幾乎沒有餘裕；未實測 |
| 社群 GGUF Q4_K_M（Abiray、unsloth 等） | 約 10.7 GB | **要**（ComfyUI-GGUF） | 本篇不採用：要執行第三方程式碼，ComfyUI 啟動訊息也建議改用原生格式 |

- **NVFP4 只有 RTX 50 系列（Blackwell）能原生運算**。其他顯卡會退回較慢的做法，比 int8 還慢（MATLOWAI 說明），請用官方 int8
- 畫質代價：MATLOWAI 實測權重誤差約 9.4%（官方 int8 約 1.0%），同一個 seed 跑出來是「同場景、表現略不同」
- Abiray 另有 Ref2VA 的 NVFP4 版，未實測
- 其餘檔案用範本列的官方檔：文字編碼器 `qwen3vl_32b_minimax_h3_nvfp4_awq` 14.61 GB（官方註明不限 RTX 50 系列）、
  影像 VAE 4.85 GB、聲音 VAE 0.56 GB、8 步加速 LoRA `minimax_h3_fl2v_turbo_8step_v1.0_comfyui_bf16` 1.82 GB。
  NVFP4 路線整套約 33.5 GB，int8 路線約 41.4 GB
- 範本另外列的 4 步 768p LoRA 與 `minimaxh3_*` 風格 embedding 是選用的，不下載也能跑

**實測下載**：NVFP4 主模型 12,528,637,032 bytes，3.6 分鐘（約 55 MB/s），SHA256 `d171fefc…28e8` 與 Hugging Face 相符。

#### 2. 範本設定

`workflow slots` 實測的地址（`video_minimax_h3_i2v`）：

| 地址 | 欄位 | 範本預設 | 實測設定 |
|---|---|---|---|
| `114.image` | 首幀圖檔名（要先放進 input 資料夾） | `transparent_rgb_gaming_mouse.png` | 使用者既有的 1:1 圖（複製過去） |
| `115.aspect_ratio`／`115.megapixels` | 比例／畫素量 | `1:1 (Square)`／0.4 | 同左（= 640×640） |
| `105.value_1` | 長度（秒） | 5 | 3 |
| `105.noise_seed` | seed | 隨機大數 | 42 |
| `105.unet_name` | 主模型 | int8 | NVFP4 或 int8 |
| `92.filename_prefix` | 輸出檔名（含 `video/` 子資料夾） | `video/MiniMax_H3` | `video/h3test_<版本>_s42` |

- 幀數由秒數自動換算成 17k＋5 的格子（24fps）：3 秒 = 73 幀、5 秒 = 124 幀
- 畫素量對照（範本附註，16:9）：0.4 = 864×480、0.98 = 1344×768（官方 768p）。直式選 `9:16 (Portrait Widescreen)`，0.4 = 480×864（實測）
- API 格式的節點 id（子圖展開後）：長度 `105:111` 的 `value`、seed `105:15`、主模型 `105:6`、提示詞 `105:104`；範本改版可能會變，改之前用 `class_type` 核對
- 範本的示範首幀要從 GitHub 下載。**用使用者自己的圖就不必下載**；要用示範圖，先問
- 提示詞很長，直接改 API 格式裡 `MiniMaxH3ImageToVideo` 節點的 `inputs.prompt`（步驟六的腳本做法）。範本示範的寫法是：
  先寫整體風格與場景，再分 `SHOT 1:`、`SHOT 2:` 描述鏡頭與動作，最後 `Audio:` 描述聲音
- ⚠️ **8 步加速 LoRA 預設是關的**：範本的 `Boolean (Enable Lightning LoRA)` 為 false，實際跑的是原始模型 20 步。
  要 8 步就在 API 格式裡找 `_meta.title` 為 `Boolean (Enable Lightning LoRA)` 的節點，把 `inputs.value` 改成 true。
  依標題找：節點在子圖裡，id 是 `105:126` 這種形式，範本改版可能會變
- 預檢會出現節點 119、120 的 `node_not_reachable_from_output` 警告：範本留下沒接上輸出的節點，執行時會被略過，可忽略
- 產出在 ComfyUI output 資料夾的 `video\`。`comfy download` 用在影片上未實測，本次直接讀輸出資料夾

#### 角色要說台詞：官方撰寫指南的格式

範本示範的「風格場景 → `SHOT 1:` → `Audio:`」寫法沒有示範對白。要角色開口說話時，改用 MiniMax 官方撰寫指南的格式
（[VIDEO_PROMPT_WRITING_GUIDE_base_en.md](https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/docs/VIDEO_PROMPT_WRITING_GUIDE_base_en.md)；
官方另有 [h3-prompt-writing 技能](https://github.com/MiniMax-AI/MiniMax-H3/blob/main/skills/h3-prompt-writing/SKILL.md)）：

```
For the target video, at 0.00 seconds into the target video, <Picture 1> (from [Shot 1]) is fully referenced.
integrated_multimodal_description: [Shot 1] Live-action, cinematic, natural photorealistic look. The young Japanese woman shown in <Picture 1> stands on a seaside promenade at dusk, ...（外觀、場景、鏡頭）. She tilts her head and laughs brightly and playfully, then looks straight at the camera with a teasing smile and beckons toward the camera with one hand, and the playful, sweet young woman (S1) says: <d>[Chinese] 哈、哈、哈，相公，你來追我啊。</d> Right after the line she turns around and runs away along the promenade, glancing back over her shoulder with a laugh, while the camera gently follows her.
overall_soundscape: Soft waves washing against the rocks, a gentle sea breeze, and her light footsteps on the stone promenade as she runs away.
non_diegetic_music: None.
```

- **第一行是首幀對齊句**，表示 `<Picture 1>` 在 0.00 秒完整出現
- **三個欄位照順序寫**：`integrated_multimodal_description`（依時間寫畫面、動作、說話者與台詞）、`overall_soundscape`（環境音、腳步聲等）、
  `non_diegetic_music`（配樂，不要就寫 `None.`）。欄位名稱後接冒號與空格
- **結構寫英文，台詞保留原文**。說話者用 `(S1)`、`(S2)` 標記，台詞包成 `<d>[語言] 原文</d>`；語氣寫在 `(S1)` 前面
- 官方範例只示範 `[English]`。C 組中文寫 `[Chinese]`、台詞用繁體字，四種跑法都正常生成，說台詞的時段嘴巴有開合；
  **發音對不對、嘴型對不對得上，agent 聽不到，要使用者自己聽**
- 5 秒放一句短台詞（約 12 個中文字）加上前後動作就滿了。節點說明寫訓練範圍是 124–362 幀（約 5–15 秒），台詞多就拉長
- 網路上有些第三方整理只用引號包台詞（例如 Runware 的文件），沒有 `(S1)`、`<d>`；本篇以官方指南為準

#### 3. 實測數據

環境：Windows 11、ComfyUI 0.35.1（agent 背景啟動）、RTX 5060 Ti 16GB、Ryzen 5 9600X、系統記憶體 62 GB、comfy-cli 1.20.0。
同一組內各版本都用同一張首幀、同一段英文提示詞、seed 42。產出 mp4 含 AAC 32 kHz 立體聲音軌。

**A 組：640×640、3 秒（73 幀）**。1:1 動漫首幀，動作是鏡頭推近、拉捲尺，mp4 約 0.5–0.6 MB（2026-09-15 上午）：

| | NVFP4 20 步 | int8 20 步 | NVFP4＋8 步 LoRA |
|---|---|---|---|
| 主模型佔用（紀錄的 Staged） | 11,944 MB | 19,995 MB（超過 VRAM） | 11,944 MB |
| 每步 | 5.23 秒 | 6.15 秒 | 5.52 秒 |
| 生成階段 | 104 秒 | 123 秒 | 44 秒 |
| 總耗時 | 141 秒（含首次文字編碼） | 137 秒（沿用快取的提示詞編碼） | 74 秒 |
| 系統記憶體最少剩 | 9.6 GB | 4.4 GB | 10.3 GB |

**B 組：480×864（9:16）、5 秒（124 幀）**。寫實真人首幀（Z-Image 生成），動作是撥頭髮、揮手、笑，鏡頭推近（同日下午）：

| | NVFP4＋8 步 LoRA | NVFP4 20 步 | int8＋8 步 LoRA | int8 20 步 |
|---|---|---|---|---|
| 主模型佔用（紀錄的 Staged） | 11,944 MB | 11,944 MB | 19,995 MB | 19,995 MB |
| 每步 | 13.3 秒 | 12.8 秒 | 14.5 秒 | 13.9 秒 |
| 生成階段 | 106 秒 | 256 秒 | 115 秒 | 277 秒 |
| 總耗時 | 159 秒 | 296 秒 | 156 秒 | 317 秒 |
| 系統記憶體最少剩 | 未量 | **10.9 GB** | **3.9 GB** | 4.7 GB |
| 手部（抽 5 幀並排） | **❌ 揮手時手指出現紅綠色殘影、手形糊掉** | ✅ 乾淨 | ✅ 乾淨 | ✅ 乾淨 |

NVFP4＋8 步是接在生圖與音樂之後直接跑；其餘三支送出前都先清快取（見下方）。

**C 組：同 B 組規格，換人物、動作與提示詞格式**。寫實日本女生首幀（Z-Image 生成），動作是大笑、看鏡頭說一句中文台詞、招手、轉身沿步道跑開，
提示詞改用官方撰寫指南的格式（見上方〈角色要說台詞〉），四支都在送出前清快取（同日傍晚）：

| | NVFP4＋8 步 LoRA | NVFP4 20 步 | int8＋8 步 LoRA | int8 20 步 |
|---|---|---|---|---|
| 主模型佔用（紀錄的 Staged） | 11,944 MB | 11,944 MB | 19,995 MB | 19,995 MB |
| 每步 | 13.7 秒 | 12.9 秒 | 14.5 秒 | 13.9 秒 |
| 總耗時 | 160 秒 | 296 秒 | 156 秒 | 318 秒 |
| 系統記憶體最少剩 | 11.8 GB | 12.1 GB | 6.3 GB | 6.5 GB |
| 畫面（5 幀並排＋1–4 秒每 0.5 秒一格） | **❌ 招手的手臂半透明、跑開時身體與白上衣糊成半透明** | ✅ 乾淨，勾手指招手清楚 | ✅ 乾淨，招手變成往前指 | ✅ 乾淨，勾手指招手清楚 |

四支都照提示詞演完：歪頭大笑 → 看鏡頭、2.0–3.5 秒嘴巴有說話的開合 → 招手 → 轉身跑開。台詞發音與嘴型由使用者試聽。

**結論（16GB 的 RTX 50 系列）**：

- **預設用 NVFP4 20 步**：B、C 兩組都畫面乾淨、系統記憶體最寬裕，每步也最快
- **要快用 int8＋8 步 LoRA**：總時間約一半、畫面乾淨；但部分權重留在系統記憶體，最少只剩 4–6.5 GB，**送出前一定要先清快取**
- **NVFP4＋8 步 LoRA 只拿來打草稿**：A 組縮圖看不出問題，B、C 兩組換了人物、動作與提示詞格式，**快速動作都出現殘影**。同樣 NVFP4 改 20 步沒有，
  同樣 8 步 LoRA 換 int8 也沒有，問題出在這個組合。兩組都只跑 seed 42，換 seed 是否每次都出現尚未驗證
- B、C 兩組耗時差不到 3%：換提示詞格式、加台詞不影響速度
- v0.8 建議「預設 NVFP4＋8 步 LoRA」，是只看 A 組縮圖得出的，B 組推翻了這個建議

**其他觀察**：

- 幀數從 73 增加到 124（1.7 倍）、畫素量差不多，每步卻慢了 2.3–2.5 倍；估長影片的時間不能照幀數線性推
- int8 比 NVFP4 每步慢的幅度，A 組約 17%，B 組只剩約 8–9%
- 8 步 LoRA 每步比 20 步稍慢（紀錄顯示多了 208 個 patch），但步數少，總時間約是 20 步的一半
- 手部破綻出現在 1/5、1/3 幀，首尾幀看不出來；抽幀時要取到中段
- GPU 最高用量都約 15.5 GB：ComfyUI 的動態 VRAM 會盡量用滿，**這個數字不能用來判斷放不放得下**，要看紀錄的 Staged
- 文字編碼器 14,956 MB、影像 VAE 4,965 MB，和主模型依序載入，不同時佔用
- A 組背景啟動 ComfyUI 花了 71 秒才連上，B 組同一台只花 7 秒，輪詢要給足時間
- 首幀是生成的圖時，生圖提示詞寫「及肩髮、小耳環」，圖上卻是長過肩的頭髮、圓圈耳環；影片提示詞照圖上實際的樣子寫，人物才不會變
- 動作流暢度與聲音由使用者自行確認

**清快取**：ComfyUI 跑完工作後會把模型留在系統記憶體，換跑別的模型時不一定先釋放。
B 組前面跑過生圖和音樂，ComfyUI 佔了 40.7 GB、可用只剩 9.4 GB；送出 int8 前呼叫
`POST http://127.0.0.1:8188/free`（body `{"unload_models": true, "free_memory": true}`），3 秒內回到 47.8 GB。
佇列清空後再呼叫，不要在工作執行中呼叫。

**怎麼量**：

- 每步秒數與模型載入：`GET http://127.0.0.1:8188/internal/logs/raw` 的 `entries[].m`（tqdm 進度列、`Staged`、`Native ops`）。
  紀錄緩衝有筆數上限，長工作要邊跑邊存
- 確認 NVFP4 走原生運算：紀錄出現 `Native ops: … nvfp4 …`
- 確認 8 步 LoRA 有沒有套上：紀錄的 `Model MiniMaxH3 prepared … 208 patches attached` 是有套上，`0 patches attached` 是原始 20 步
- 單一工作耗時：`GET /history/<prompt_id>` 的 `status.messages` 裡，`execution_start` 與 `execution_success` 的 timestamp 相減
- **比速度看「每步秒數」與生成階段**；總耗時會因提示詞編碼被快取而偏短
- 顯卡與記憶體：背景每 2 秒記一次 `nvidia-smi --query-gpu=memory.used,utilization.gpu` 與系統可用記憶體
  （B 組用 `Get-CimInstance Win32_OperatingSystem` 的 `FreePhysicalMemory`）
- 畫面：用 PyAV 抽首、1/5、1/3、2/3、末幀，多個版本上下並排比對（見下方〈讓 agent 看影片〉）

### 音樂：MiniMax Music 3（已實測）

範本 `audio_minimax_music_3`，由風格描述與歌詞生成含人聲的完整歌曲，最長約 5 分鐘。三個檔都放得進 16GB：

| 檔案 | 參數量／格式 | 大小 |
|---|---|---|
| `diffusion_models/minimax_music3_dit_fp16` | 2.5B／fp16 | 4.58 GB |
| `text_encoders/minimax_music3_text_encoder_pruned_int8_convrot` | 8.4B／int8 | 8.57 GB |
| `vae/minimax_music3_dav` | fp32 | 0.20 GB |

範本另列 `minimax_music3_dit_int8_convrot`，是給小顯卡的替代版，16GB 不需要；未滿 16GB 未實測。

| 地址 | 欄位 | 範本預設 |
|---|---|---|
| `37.caption` | 風格描述，依序寫 Global Metadata → Vocal Details → Arrangement | lo-fi hip-hop 範例 |
| `37.lyrics` | 歌詞；`[Intro]` `[Verse]` `[Chorus]` `[Bridge]` `[Outro]` `[Instrumental]` 標籤才會決定段落結構 | 英文範例 |
| `37.max_duration` | 長度（秒），最長約 300 | 60 |
| `37.seed` | seed | 固定值 |
| `35.filename_prefix` | 輸出檔名（含 `audio/` 子資料夾），mp3 V0 | `audio/audio_minimax_music3` |

- 流程分三段：文字編碼器先逐 token 生成（紀錄的 `AR sampling`）→ DiT 30 步（cfg 1.7）→ 解碼
- 範本有分塊解碼（Tiled decode）選項：長歌 VRAM 不夠時用，稍慢、分塊接縫可能有痕跡
- **agent 聽不到音樂**，好不好聽要請使用者自己聽

**實測**（同上環境）：

| | 60 秒（範本預設，只改檔名） | 120 秒（英文風格描述＋繁體中文歌詞，三版） |
|---|---|---|
| AR sampling | 1501 token，52 秒（約 28.6 token/秒） | 3001 token，105 秒（約 28.5 token/秒） |
| DiT 30 步 | 2.53 秒/步，75 秒 | 5.2–5.4 秒/步，155–161 秒 |
| 總耗時 | **140 秒** | **286–288 秒** |
| 產出 mp3（44.1 kHz 立體聲） | 60.0 秒、1.96 MB | 120.0 秒、3.8–4.0 MB |
| 系統記憶體最少剩 | 29 GB | 未量 |

- 兩段耗時都和長度成正比：token 數加倍，DiT 每步秒數也加倍。估時間抓「每秒歌約 2.4 秒」
- 三版只改風格描述、歌詞與 seed，速度幾乎一樣

**風格描述怎麼寫**（120 秒實測的做法，三版效果由使用者試聽，本篇未記錄主觀評價）：

- 中文歌可以用英文風格描述：Vocal Details 寫明 `singing in Mandarin Chinese`，歌詞直接寫繁體中文。長中文照步驟六的原則用腳本寫進 JSON
- **沒有調音高、力度的數值欄位**，使用者說「更高」「更有力」只能改描述：
  - 第一版：E 小調，主歌輕柔帶氣音、副歌才用胸聲高亢
  - 使用者要「更有力、更高」→ 第二版：調性移到 A 小調（最後升 B 小調），主歌寫明 `never soft or breathy`，副歌寫明唱在男聲音域最頂端；歌詞、seed 不變，方便對照
  - 使用者要「力度再加強、音高再高，旋律歌詞也換」→ 第三版：升 C 小調（最後再升到升 D 小調）、84 BPM 搖滾編曲，副歌 `belted with maximum power`、峰值帶沙啞，歌詞重寫、seed 從 42 換成 2026
- **描述裡不寫真實歌手的名字**。使用者說「參考某位歌手」時，先查報導整理出聲音特點再寫進描述：模型不一定認得人名，
  也避免指定模仿特定真人的聲音。這次參考的 AI 歌手「大頭針」，報導形容兼具高亢音色、憂鬱感與爆發力，就寫成高音男高音、主歌帶憂鬱、副歌爆發

### 讓 agent 看影片

`comfy preview` 未實測。實測可行的做法是用 ComfyUI `.venv` 的 Python（內建 PyAV 與 Pillow）抽幀拼圖：

```python
import av
from PIL import Image
c = av.open("影片.mp4")
frames = [f.to_image() for f in c.decode(video=0)]
picks = [frames[i] for i in (0, len(frames)//3, 2*len(frames)//3, len(frames)-1)]
w, h = picks[0].size
sheet = Image.new("RGB", (w * 4, h))
for i, im in enumerate(picks):
    sheet.paste(im, (i * w, 0))
sheet.save("影片_抽幀.png")
```

同一個容器也讀得到解析度、幀數、長度與音軌格式（`c.streams.video[0]`、`c.streams.audio`）。

### 其他音樂與影片範本（尚未實測）

| 類型 | 範本名稱 | 模型 |
|---|---|---|
| 音樂 | `audio_ace_step1_5_xl_turbo` | ACE-Step 1.5 |
| 影片 | `video_ltx2_3_t2v` | LTX-2.3 |
| 影片 | `video_wan2_2_5B_ti2v` | Wan 2.2 5B |

影片模型通常數十 GB，**VRAM 不足會跑不動**，下載前先確認大小並取得同意。

官方技能整理的注意事項（未經本懶人包實測）：

- **音樂**：ACE-Step 的拍號填 `"4"` 而不是 `"4/4"`；文字編碼與空白音訊的長度必須一致；
  輸出格式是 FLAC；純音樂要把歌詞設為空字串
- **影片**：一定要有 SaveVideo 節點才會存檔；不要寫死 fps

---

## 依你的 Agent

流程四家完全相同，都是在 shell 執行 `comfy` 指令。差別只在指令時限與能不能直接看圖。

| Agent | 指令時限 | 看結果 |
|---|---|---|
| Claude Code | 單一指令預設 2 分鐘、最長 10 分鐘，長工作用步驟八的分段做法或放背景執行 | 可直接讀取圖片給使用者看 |
| Codex | 依設定而異，一律用分段做法 | 視介面而定，至少回報完整路徑 |
| OpenCode | 同上 | 同上 |
| Antigravity | 同上 | 同上 |

> **選用的本機 MCP**：官方文件只示範 Claude Code（`claude mcp add comfy-mcp -- comfy-mcp`）、
> Claude Desktop 與 Cursor。Codex、OpenCode、Antigravity 要自己查證 stdio MCP 的設定方式。
> **不裝 MCP 完全不影響本流程。**

---

## 完成回報格式

```
【ComfyUI 連接結果】
- ComfyUI 版本與埠：
- 顯卡與 VRAM：
- comfy-cli 版本（安裝或 uvx）：
- 使用統計：已關閉 / 使用者選擇開啟

【本次生成】
- 範本或工作流程：
- 修改的欄位：
- 補下載的模型（檔名／大小／SHA256 是否相符）：
- prompt_id：
- 耗時：
- 輸出檔完整路徑：
- 是否花費點數：否

【使用者仍需自己完成】
-
```

---

## 如果失敗，如何重來

| 想回到哪裡 | 怎麼做 |
|---|---|
| `comfy` 指令找不到 | `uv tool update-shell` 後重開 agent；或改用 `uvx --from comfy-cli comfy` |
| 連不上 ComfyUI（`server_not_running`） | 確認 Desktop 已開啟、埠號正確，必要時設 `COMFY_LOCAL_URL`；或改用步驟零方式二 |
| 停掉 agent 背景啟動的 ComfyUI | 停啟動時記下的 PID，再確認 8188 已無人監聽；仍在監聽時，先確認監聽者的父行程是自己記下的 PID 才停（見步驟零方式二第 5 點） |
| 工作卡住 | `comfy --json jobs ls` 看佇列；確定要放棄才 `comfy --json jobs cancel <prompt_id>` |
| 工作流程改壞了 | 重新 `templates fetch` 一份，或從使用者的原始檔重來 |
| 模型下載一半中斷 | 刪掉 `.part` 檔重新下載（先確認刪的是 `.part`） |
| 移除 comfy-cli | `uv tool uninstall comfy-cli`；設定檔在 `%LOCALAPPDATA%\comfy-cli\`，確認後再刪 |
| 刪除模型或產出 | 🖐️ 使用者確認後再刪；ComfyUI 自己的產出在它的 output 資料夾 |

---

## 常見問題

| 問題 | 原因與解法 |
|---|---|
| 和 #05 生圖差在哪？ | #05 用 agent 內建工具或 OpenAI 付費 API，不需要顯卡；#07 用你自己的顯卡跑本機模型，免費但要先下載模型 |
| 為什麼不用 MCP？ | 見開頭「分工」一節：本機 MCP 本身就依賴 comfy-cli，CLI 四家通用 |
| `comfy which` 路徑不存在 | Desktop 版正常現象，見步驟三 |
| `--set` 改提示詞報錯 | `--set` 不能搭配 `--workflow`，改用 `workflow set-slot` |
| validate 建議改成 `pixel_space` | 缺模型，回步驟五補，不要套用建議 |
| validate 報用法錯誤 | 參數要寫 `--workflow <檔>`，而且要先轉成 API 格式 |
| 出現 `spend_consent_required` | 工作流程含付費節點。先問使用者要不要花點數，不要自己加 `--allow-spend` |
| 下載的檔名是一串亂碼 | 那是 prompt_id 前 8 碼，屬正常，需要時自行改名 |
| 中文提示詞能用嗎？ | Z-Image Turbo 完整版與 Int8 版都實測可以；其他模型依模型而定 |
| Z-Image 能在圖裡寫出正確的繁體中文嗎？ | 簡繁同形的常用字單塊招牌寫到 10 字都穩；簡繁不同的字會變簡體或日文字形、少見字會錯。要正確繁體就後製疊字，見步驟六〈畫面中的中文字〉 |
| 8GB 顯卡生圖很慢或爆顯存 | 用到完整版範本了。改用量化版範本（例如 `image_z_image_turbo_int8`），見步驟四 |
| 下載中 `.part` 一直是 0 bytes | Windows 在檔案關閉前不一定更新大小，看下載輸出判斷，不要重下 |
| 不開 Desktop 視窗能用嗎？ | 可以，由 agent 背景啟動，見步驟零方式二（Windows 實測） |
| 背景啟動時 `ModuleNotFoundError: No module named 'torch'` | 用到 `standalone-env\python.exe` 了，換成 `<installPath>\ComfyUI\.venv\Scripts\python.exe` |
| 負面提示寫了沒效果 | Z-Image Turbo 範本是 cfg 1，負面提示不起作用；改寫成正面描述，見步驟六 |
| 可以不裝 comfy-cli、直接打 ComfyUI 的 HTTP API 嗎？ | 可以：`POST /prompt` 送 API 格式工作流程、輪詢 `GET /history/<prompt_id>`、`GET /view` 取圖（實測可用）。但少了送出前預檢與付費節點攔截，本篇不採用 |
| 背景啟動後 agent 的指令一直卡住到逾時 | 用了 `& python.exe main.py` 前景執行。改用 `Start-Process -PassThru`，見步驟零方式二 |
| 行程清單裡跑的是 `standalone-env\python.exe`，不是 `.venv` 的 | 正常。`.venv` 的 python.exe 是啟動器，會帶起它並帶入 `.venv` 的套件，見步驟零方式二第 5 點 |
| MiniMax H3 放得進 16GB 顯卡嗎？ | 官方 int8 主模型 19.5 GB 放不下。RTX 50 系列改用社群 NVFP4 版（11.67 GB，實測整個放進顯卡）；其他顯卡用 int8，會慢且很吃系統記憶體，見步驟九 |
| H3 範本跑了 20 步，比預期慢 | 範本的 8 步加速 LoRA 預設關閉，把 `Boolean (Enable Lightning LoRA)` 改成 true，見步驟九 |
| 怎麼確認 NVFP4 真的用上 4-bit 運算？ | ComfyUI 紀錄出現 `Native ops: … nvfp4 …`；不是 RTX 50 系列會退回較慢的運算 |
| 顯卡用量一直接近滿載，是不是放不下？ | 不一定。動態 VRAM 會盡量用滿，要看紀錄的 `… MB Staged` 是否小於 VRAM |
| `templates check` 報 `server_not_running`，`templates fetch` 卻可以 | `check` 要對照 ComfyUI 已安裝的模型，ComfyUI 必須在線；`fetch` 只下載範本 |
| 預檢警告節點 119／120 `node_not_reachable_from_output` | H3 範本留下沒接上輸出的節點，執行時會被略過，可忽略 |
| 模型相關的設定寫在技能哪裡？ | 技能資料夾的 `models/<模型>.md`，隨技能安裝，agent 用到該模型時才讀；`SKILL.md` 只放通用流程 |
| H3 影片的手指出現紅綠色殘影、手臂或身體變半透明 | 實測兩組真人快速動作都只出現在「NVFP4＋8 步 LoRA」組合。16GB 的 RTX 50 系列改用 NVFP4 20 步，或 int8＋8 步 LoRA，見步驟九 |
| H3 影片要角色說台詞怎麼寫？ | 用官方撰寫指南的格式：首幀對齊句＋`integrated_multimodal_description`／`overall_soundscape`／`non_diegetic_music` 三欄，說話者 `(S1)`、台詞 `<d>[Chinese] 原文</d>`，見步驟九〈角色要說台詞〉 |
| 跑完生圖或音樂再跑影片，系統記憶體只剩幾 GB | ComfyUI 把前面的模型留在記憶體裡。佇列清空後 `POST /free`（body `{"unload_models": true, "free_memory": true}`），見步驟九 |
| Music 3 能直接調音高或力度嗎？ | 沒有數值欄位，只能改風格描述（調性、唱法、編曲）與換 seed，見步驟九 |

---

## 更新紀錄

| 版本 | 日期 | 變更 |
|------|------|------|
| v0.1 | 2026-09-10 | 初版。於 Windows 11、Comfy Desktop 1.0.47（ComfyUI 0.35.0）、RTX 5060 Ti 16GB 實測：comfy-cli 1.20.0（以 `uvx` 執行）的送出、等待、取回、改參數、預檢，以及 Z-Image Turbo 補 VAE 後實際生圖全部通過。`uv tool install`、音樂、影片、macOS／Linux 尚未實測 |
| v0.2 | 2026-09-11 | 環境檢查加入 VRAM，步驟四新增「依 VRAM 選版本」：未滿 16GB 改用 `image_z_image_turbo_int8`。於 RTX 5060 Laptop 8GB（ComfyUI 0.35.1）實測：`uv tool install comfy-cli` 可用、Int8 三個模型下載並通過 SHA256 驗證、中文提示詞生圖首張 34.5 秒、之後 11.1 秒。步驟五補上大檔放背景下載、`.part` 顯示 0 bytes 的說明。完整版與 Int8 畫質未並排對比；音樂、影片、macOS／Linux 仍未實測 |
| v0.3 | 2026-09-11 | 移入另一個專案（國中數學教材站）用本機 ComfyUI 生教材圖的實戰經驗：步驟零新增「方式二：不開 Desktop 視窗、由 agent 以 API 模式背景啟動」（路徑從 Desktop 設定檔讀、Python 必須用 `ComfyUI\.venv`）；來源 B 新增從生過的 PNG 讀出 API 格式工作流程；步驟六新增 Z-Image Turbo 提示詞實測心得；常見問題補 4 條。於桌機核對 Desktop 設定檔欄位、`.venv` 有 torch 而 `standalone-env` 沒有、PNG 內嵌工作流程為 cfg 1.0＋`ConditioningZeroOut` |
| v0.4 | 2026-09-11 | 修正步驟零方式二：啟動指令改用 `Start-Process -PassThru`（原本 `&` 前景執行會佔住 agent 的指令、拿不到 PID），含空白的路徑加 `` `" ``；明寫不帶 Desktop 的 `launchArgs`；`installations.json` 註明排除 `Comfy Cloud` 那筆；補停止與確認方式（`.venv` 的 python.exe 是 uv 啟動器，監聽埠的是 `standalone-env\python.exe` 子行程）。技能改為把啟動指令直接寫進 `SKILL.md`，因為安裝後的技能讀不到 `guides/`。於桌機用 `.venv` 的 python 跑測試腳本（綁 18188 埠）代替 ComfyUI 驗證：含空白路徑完整傳入、監聽者為子行程、停啟動器後子行程隨之結束；本版未實際以 API 模式重新啟動 ComfyUI |
| v0.5 | 2026-09-11 | 生圖預設只跑一張，使用者要挑圖時才一次跑 4 個 seed；執行原則明列哪些要逐項確認（改參數、預檢、送出本機免費工作不必再問）；先備條件改為「已安裝 ComfyUI」，不必事先開啟（`INSTALL.md` 與 `install-all` 同步）。技能的提示詞要點精簡為做法，原因與實例留在步驟六 |
| v0.6 | 2026-09-11 | 在另一台 RTX 5060 Ti 16GB 桌機（Comfy Desktop 全新安裝、ComfyUI 0.35.1）從零實測完整版：`uv tool install comfy-cli`、下載 bf16 三個檔共 19.26 GB（約 7 分鐘，大小與 SHA256 全數相符）。**步驟零方式二第一次實際啟動 ComfyUI 驗證**：`Start-Process` 啟動後 5.6／8.1 秒可連線，監聽者是 `standalone-env\python.exe` 子行程，停掉啟動器約 1 秒後釋放 8188。範本預設提示詞生圖，首張 31.5 秒。步驟五補上 `curl.exe -sI` 查大小的替代寫法。`SKILL.md` 未修改 |
| v0.7 | 2026-09-13 | 移入教材站在桌機 RTX 5060 Ti 16GB 用完整版一次批次生 76 張候選的經驗：步驟六的改值說明補上「長中文提示或批次產生工作檔時，用腳本直接改 API 格式 JSON」（指令列傳長中文容易被引號與 cp950 弄壞）；挑圖段落補上「一次排很多張時輪詢本機 `/queue`、直接讀輸出資料夾」，並註明要數輸出檔數確認每張都成功；提示詞實測心得補兩條（原本少見的東西不要提、角色動作對調時用畫面左右半邊綁定）。`SKILL.md` 步驟 7、步驟 9 與提示詞要點同步補上 |
| v0.8 | 2026-09-15 | 步驟九改為「影片與音樂」，於 RTX 5060 Ti 16GB＋62 GB 記憶體桌機（ComfyUI 0.35.1、agent 背景啟動、comfy-cli 1.20.0）實測 **MiniMax H3** 與 **MiniMax Music 3**：H3 官方 int8 主模型 19.5 GB 放不進 16GB，改下載社群 NVFP4 版（MATLOWAI，12,528,637,032 bytes，3.6 分鐘，SHA256 相符），ComfyUI 原生支援；640×640、3 秒同 seed 比較 NVFP4 20 步 141 秒（5.23 秒/步）、int8 20 步 6.15 秒/步且系統記憶體只剩 4.4 GB、NVFP4＋8 步 LoRA 74 秒；發現範本的加速 LoRA 預設關閉。Music 3 範本預設 60 秒歌 140 秒。補上量速度的方法（`/internal/logs/raw`、`/history` timestamp）與用 PyAV 抽幀讓 agent 看影片。**技能結構調整**：模型專屬內容從 `SKILL.md` 移到技能資料夾的 `models/`（`z-image-turbo.md`、`minimax-h3.md`、`minimax-music3.md`，隨技能安裝），`SKILL.md` 只留通用流程與索引表（`agents.md` 同步加入這條規則） |
| v0.9 | 2026-09-15 | 同一台桌機（ComfyUI 0.35.1、agent 背景啟動）做一次完整的「照片 → 影片 → 歌曲」實測。**H3 B 組**：Z-Image 生的寫實人像當首幀，480×864（9:16）、5 秒（124 幀）、seed 42，NVFP4／int8 × 8 步 LoRA／20 步四種組合：NVFP4＋8 步 159 秒但揮手時手指出現紅綠色殘影，NVFP4 20 步 296 秒（12.8 秒/步、系統記憶體最少剩 10.9 GB）、int8＋8 步 156 秒（最少剩 3.9 GB）、int8 20 步 317 秒，後三者畫面乾淨。**16GB 的 RTX 50 系列預設由 NVFP4＋8 步 LoRA 改為 NVFP4 20 步**，要快用 int8＋8 步 LoRA（各只測一個 seed）。補上 `POST /free` 清快取（可用記憶體 9.4 → 47.8 GB）、9:16 的畫素量、API 格式節點 id、看紀錄的 `patches attached` 確認 LoRA、首幀是生成圖時照圖描述人物、抽幀要取到中段。**Music 3**：120 秒中文歌三版（英文風格描述＋繁體中文歌詞），各 286–288 秒，AR 3001 token 105 秒、DiT 5.2–5.4 秒/步，耗時與長度成正比；補上沒有音高數值欄位時怎麼用風格描述讓聲音更高、更有力，以及描述裡不寫真實歌手名字。Z-Image 補 864×1536 首張 19.5 秒。**H3 C 組**（同日傍晚補測，當第二筆佐證）：換成 Z-Image 生的日本女生首幀，動作改為大笑、說一句中文台詞、招手、轉身跑開，提示詞改用官方撰寫指南的格式（首幀對齊句＋三欄、`(S1)`、`<d>[Chinese] …</d>`），四種組合耗時與 B 組差不到 3%，NVFP4＋8 步 LoRA 再次出現殘影（招手手臂半透明、跑開時身體糊成半透明），其他三種乾淨；步驟九新增〈角色要說台詞〉，常見問題補一條。`models/minimax-h3.md`、`models/minimax-music3.md`、`models/z-image-turbo.md` 與 `SKILL.md` 的索引表同步更新 |
| v0.10 | 2026-09-15 | 同一台桌機（ComfyUI 0.35.2、agent 背景啟動、comfy-cli 1.20.0）實測 **Z-Image Turbo 在圖中寫繁體中文**：台灣騎樓街景、1536×864、每組 4 個 seed，共 48 張、逐字放大核對。第一輪六塊招牌放入簡繁字形不同的字（麵、漿、灣、嬤、滷、豐、錶），全數被寫成簡體、日文字形或錯字，只有「藥局」4/4；第二輪對照全改用簡繁同形的常用字，單塊招牌 2、3、4、6、7、9、10 字都 4/4，確認**限制在字形而不在字數**。另找出三種失敗型態：相鄰相近字被複製（早午→早早、五金→金金）、寬招牌只寫一字被補成三字、多塊同框時長招牌掉字（7 字單塊 4/4、同框 1/4）。步驟六新增〈畫面中的中文字〉、步驟八補 1536×864 速度（首張 36.8 秒、之後平均 14.9 秒）、常見問題補一條；`models/z-image-turbo.md` 新增〈畫面中的中文字〉一節與速度數據。`SKILL.md` 未修改 |
| v0.11 | 2026-09-15 | 同一台桌機（ComfyUI 0.35.2、agent 背景啟動）實測 **Z-Image 做繁中海報**：中秋活動海報 1088×1536、4 個 seed，同一版面比較「直接生字」與「無字底圖＋Pillow 疊字」。直接生字 4 張都把「賞」「圓」寫成簡體、「團」複製成「圓」，但「點」「學」「場」4/4 正確，確認**猜不到哪些繁體字會錯**；無字底圖 4 張都沒有亂字、疊上的字全對，但一張因提示詞寫「海報背景」畫成牆上海報樣張、一張主體頂到留白區，可直接用 2/4；直接生字的字體與插畫融合度較好，疊字版字型未調整。步驟六〈畫面中的中文字〉補海報實測兩張表；`models/z-image-turbo.md` 補「海報、資訊圖表一律無字底圖＋疊字」、底圖提示詞不要寫「海報」、本機繁中字型路徑。`SKILL.md` 未修改 |

---

## 相關連結

- [comfy-cli（官方命令列工具）](https://github.com/Comfy-Org/comfy-cli)
- [Comfy MCP 官方文件](https://docs.comfy.org/agent-tools/mcp)
- [comfy-mcp（官方本機 MCP）](https://github.com/Comfy-Org/comfy-mcp)
- [ComfyUI Desktop 下載](https://www.comfy.org/download)
