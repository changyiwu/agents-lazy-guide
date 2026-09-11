---
title: 'AI Agent 懶人包 #07：連接 ComfyUI'
date: '2026-09-11'
type: 懶人包
version: v0.6
status: 初版（生圖已實測，音樂與影片未實測）
tags:
  - 懶人包
  - ComfyUI
  - 生圖
  - 本機模型
---

# 懶人包 #07：連接 ComfyUI

**版本** v0.6｜**更新日期** 2026-09-11｜**適用** Claude Code / Codex / OpenCode / Antigravity

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
- [ ] 磁碟有足夠空間放模型（生圖模型一組約 11–20 GB，依顯卡選的版本而定，見步驟四；影片模型更大）

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
   - 載入需要一點時間，輪詢 `system_stats` 到有回應再繼續（16GB 桌機實測 5.6–8.1 秒）。
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
> 你自己的工作流程或範本都要用 `workflow set-slot`。

中文提示詞實測可用（Z-Image Turbo 官方標明支援中英文）。

### Z-Image Turbo 提示詞實測心得

以下來自實際生成教材插圖與四格漫畫的經驗（Int8 版，筆電 8GB）：

| 現象 | 做法 |
|---|---|
| 英文提示常把服裝、配件畫錯（「連身工作服」變吊帶褲、推在額頭上的護目鏡戴到眼睛上） | **提示詞寫中文**，服裝與配件逐項描述 |
| 寫「不要文字」「no text」沒有用 | 範本是 cfg 1＋`ConditioningZeroOut`（從生出的圖讀回 KSampler 確認 `cfg: 1.0`），**負面提示根本不起作用**。改寫成正面描述：「畫面中沒有任何文字」 |
| 就算這樣寫，碼錶、尺、牆面刻痕這類小地方仍會長出亂碼數字 | **選定前放大檢查**；面積很小的話，可以用左右相鄰的顏色內插蓋掉 |
| 「2 排、每排 4 塊」這種二維方陣、分節的軌道，數量幾乎都錯（實測 5 張全錯） | 要數的東西只排**單排**，或乾脆改構圖避開計數 |
| 兩個角色時常把服裝互換，或多長出一隻動物 | 挑候選時**逐張對照角色設定** |
| 本機生成免費，一張只要十幾秒 | 要挑圖時，**同一段提示一次跑 4 個 seed** 再從中挑一張；只要一張時照常跑一張 |

需要挑圖時，跑 4 個 seed 的做法：`workflow set-slot` 改 seed → `run --no-watch` 拿到 prompt_id，重複 4 次
（工作會在 ComfyUI 排隊），再逐一 `jobs watch`、`download`。

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

---

## 步驟九：音樂與影片（尚未實測）

流程和生圖**完全相同**：選範本 → `templates check` → 補模型 → 改參數 → 預檢 → 送出取回。
本機可跑的範本例如：

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
- **看結果**：影片可用 `comfy preview <檔>` 產生縮圖給 agent 看；**agent 聽不到音樂**，要請使用者自己聽

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
| 8GB 顯卡生圖很慢或爆顯存 | 用到完整版範本了。改用量化版範本（例如 `image_z_image_turbo_int8`），見步驟四 |
| 下載中 `.part` 一直是 0 bytes | Windows 在檔案關閉前不一定更新大小，看下載輸出判斷，不要重下 |
| 不開 Desktop 視窗能用嗎？ | 可以，由 agent 背景啟動，見步驟零方式二（Windows 實測） |
| 背景啟動時 `ModuleNotFoundError: No module named 'torch'` | 用到 `standalone-env\python.exe` 了，換成 `<installPath>\ComfyUI\.venv\Scripts\python.exe` |
| 負面提示寫了沒效果 | Z-Image Turbo 範本是 cfg 1，負面提示不起作用；改寫成正面描述，見步驟六 |
| 可以不裝 comfy-cli、直接打 ComfyUI 的 HTTP API 嗎？ | 可以：`POST /prompt` 送 API 格式工作流程、輪詢 `GET /history/<prompt_id>`、`GET /view` 取圖（實測可用）。但少了送出前預檢與付費節點攔截，本篇不採用 |
| 背景啟動後 agent 的指令一直卡住到逾時 | 用了 `& python.exe main.py` 前景執行。改用 `Start-Process -PassThru`，見步驟零方式二 |
| 行程清單裡跑的是 `standalone-env\python.exe`，不是 `.venv` 的 | 正常。`.venv` 的 python.exe 是啟動器，會帶起它並帶入 `.venv` 的套件，見步驟零方式二第 5 點 |

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

---

## 相關連結

- [comfy-cli（官方命令列工具）](https://github.com/Comfy-Org/comfy-cli)
- [Comfy MCP 官方文件](https://docs.comfy.org/agent-tools/mcp)
- [comfy-mcp（官方本機 MCP）](https://github.com/Comfy-Org/comfy-mcp)
- [ComfyUI Desktop 下載](https://www.comfy.org/download)
