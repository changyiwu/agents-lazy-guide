---
name: agent-comfyui
description: 用官方 comfy-cli 操作本機 ComfyUI：套用範本或使用者自己的工作流程、改提示詞與參數、送出並取回生成的圖片（音樂、影片同一套流程）。使用者提到 ComfyUI，或說「連接 ComfyUI」「用 ComfyUI 生圖」「跑 ComfyUI 工作流程」時載入。
---

# 連接 ComfyUI

完整教學見 `guides/07-連接-ComfyUI.md`。以下是通用執行流程；**特定模型的版本選擇、欄位地址、提示詞要點與實測數據**
放在本技能資料夾的 `models/`，用到該模型時先讀（見〈模型筆記〉）。

## 觀念

- **走官方 `comfy-cli`，不走 MCP。** 四個 agent 都在 shell 跑同一套指令，不必各自設定 MCP；
  官方的本機 MCP（`comfy-mcp`）本身也依賴它。指令一律加 `--json`，看回傳的 `ok` 與 `error.hint`。
- 使用者**沒提到 ComfyUI** 的一般生圖需求，交給 `agent-draw`，不要搶用本技能。
- comfy-cli 自帶一套官方技能，**不安裝**。遇到本檔沒寫的情境，用 `comfy skills show comfy`
  （只印出、不寫入任何檔案）臨時查閱。

## 步驟

1. **檢查環境**：`uv --version`；確認 `http://127.0.0.1:8188/system_stats` 有回應。連不上 → 問使用者選哪一種：
   - 🖐️ 使用者自己開啟 ComfyUI Desktop。新版 Desktop 實測用 8188 埠；
     用其他埠時設 `COMFY_LOCAL_URL=http://127.0.0.1:<埠>`。
   - **不開 Desktop 視窗，由 agent 在背景以 API 模式啟動**（Windows 的 Desktop 安裝）。路徑依這台讀，不要照抄：
     `%APPDATA%\Comfy Desktop\installations.json` 取 `sourceId` 不是 `cloud` 那筆的 `installPath`、`id`；
     同資料夾 `settings.json` 的 `inputDir`、`outputDir`；模型路徑設定檔是 `instance-model-paths\<id>.yaml`。
     Python **一定要用 `ComfyUI\.venv\Scripts\python.exe`**（直接跑 `standalone-env\python.exe` 沒有 torch）。Desktop 開著時不要啟動。

     ```powershell
     $p = Start-Process "<installPath>\ComfyUI\.venv\Scripts\python.exe" -WorkingDirectory "<installPath>\ComfyUI" -WindowStyle Hidden -PassThru -ArgumentList "main.py --listen 127.0.0.1 --port 8188 --disable-auto-launch --extra-model-paths-config `"<yaml>`" --output-directory `"<outputDir>`" --input-directory `"<inputDir>`""
     ```

     **必須用 `Start-Process`**（`&` 會佔住指令到逾時、拿不到 PID）；含空白的路徑要用 `` `" `` 包住。
     輪詢 `system_stats` 有回應再繼續（實測 6 秒到 71 秒不等，要給足時間）。
     只綁 `127.0.0.1`；**刻意不帶** Desktop 的 `launchArgs`（`--enable-manager`）。記下 `$p.Id`，停止方式見「復原」。
2. **安裝 comfy-cli**（先詢問）：`uv tool install comfy-cli`，再 `comfy --version`。
   不想安裝時，把後面的 `comfy` 一律換成 `uvx --from comfy-cli comfy`（兩種方式都實測過，1.20.0）。
   **不要**執行 `comfy install`／`launch`／`update`／`stop`——Desktop 自己管理安裝與更新。
3. **關閉使用統計**：`comfy tracking disable`（隱私優先，使用者想開再開）。
4. **連線驗收**：`comfy --json system-stats`，回報 ComfyUI 版本、GPU 與 VRAM（`devices[0].vram_total`，步驟 5 選版本用）。
   `comfy which` 對 Desktop 會指到不存在的 `Documents\comfy\ComfyUI`，**這是正常的，忽略它**。
   **只要求「連接 ComfyUI」時，做到這裡就結束。**
5. **選工作流程**（先問使用者要做什麼）：
   - 官方範本：`comfy --json templates ls --type image`（或 `audio`／`video`）→
     `comfy --json templates check <名稱>` 看 `verdict`、缺哪些模型、`api.dependent` 是否為 true（付費節點）→
     `comfy --json templates fetch <名稱> -o <檔>`。`templates check` 要 ComfyUI 在線（否則回 `server_not_running`），`fetch` 不用。
     名稱以 `api_` 開頭的範本是付費雲端節點。
   - **依步驟 4 的 VRAM 選版本**：該模型有〈模型筆記〉就先讀再選。沒有筆記時，模型檔總大小超過 VRAM 就先找量化版範本或量化檔，
     不要讓它靠系統記憶體硬跑。
   - 使用者自己的：🖐️ 請使用者在 ComfyUI 把工作流程存成 JSON（UI 或 API 格式都可以）。
     或直接取使用者在 ComfyUI 生過的 PNG：它的 `prompt` 文字區塊就是完整的 API 格式工作流程
     （`json.loads(Image.open(p).info["prompt"])`；ComfyUI 的 `.venv` 裡就有 Pillow）。工作流程檔放專案的 `comfyui/`。
6. **補模型**（`verdict` 為 `missing-models` 時）：列出檔名、資料夾、大小、來源，**取得同意才下載**。
   - 大小：對 `templates check` 給的 `url` 發 HEAD 請求讀 `X-Linked-Size`；Hugging Face 的
     `X-Linked-ETag` 就是 SHA256，下載後拿來比對。
   - 位置：`system-stats` 的 `argv` 裡 `--extra-model-paths-config` 指向一個 yaml，取其中
     `base_path` 加上資料夾名（Desktop 通常是 `%LOCALAPPDATA%\Comfy-Desktop\ComfyUI-Shared\models`）。
   - 先存成 `<檔名>.part`，大小與 SHA256 都相符才改名，避免 ComfyUI 讀到下載一半的檔。
     大檔放背景下載；Windows 上 `.part` 途中顯示 0 bytes 不代表卡住，看下載輸出判斷。
   - 不要用 `comfy model download`：它依賴 comfy-cli 自己的工作區，未驗證在 Desktop 下會寫到哪裡。
   - 完成後 `comfy --json model list-folder <資料夾>` 確認 ComfyUI 看得到。
7. **改參數**：`comfy --json workflow slots <檔>` 列出可調欄位，**地址照抄**（例如 `57.text`、
   `57.seed`，是節點 id 不是標題）→ `comfy --json workflow set-slot <檔> "57.text=..." "57.seed=42"`。
   `comfy run --set` **不能搭配 `--workflow`**，只適用 comfy-cli 內建的預設流程。
   **長提示詞（尤其中文）、要改 `slots` 沒列出的欄位，或批次產生多個工作檔時，改用腳本直接改 API 格式 JSON**
   （長中文放指令列會被引號與 cp950 弄壞）：改 `inputs.text`、`inputs.seed`、`EmptySD3LatentImage` 的 `width`／`height`、
   `SaveImage` 的 `filename_prefix`（帶名稱與 seed，步驟 9 才對得回每一張），UTF-8 一個工作存一個檔、中文直接寫字面；
   子圖裡的節點 id 形如 `105:126`，依 `_meta.title` 找比猜 id 可靠；批次時抽一個檔跑步驟 8。
8. **送出前預檢**：`comfy --json run --workflow <檔> --print-prompt`（不會送出），把回傳的
   `data.prompt` 存成 `<檔>.api.json`，再 `comfy --json workflow validate --workflow <檔>.api.json`
   （只吃 API 格式，而且一定要帶 `--workflow`）。`valid` 不是 true 就停下回報。
   **不可盲目套用 `suggestions`**：缺 VAE 時它會建議換成 `pixel_space`，那不是修正，是換成別的東西。
9. **送出與取回**：

   ```
   comfy --json run --workflow <檔> --no-watch     # 立刻回傳 data.prompt_id
   comfy --json jobs watch <prompt_id>              # 完成才 exit 0，失敗 exit 1
   comfy --json download <prompt_id> -o generated   # 專案有 slides/ 就用 slides/generated
   ```

   `jobs watch` 逾時或 agent 的指令時限到了，**工作仍在 ComfyUI 上跑**：重跑 `jobs watch` 接回，
   **不要重新送出**。影片與音樂單次常超過 2 分鐘，送出後放背景輪詢。各模型參考速度見〈模型筆記〉。
   **一次排很多張時不必逐個 `jobs watch`／`download`**（只限本機 ComfyUI）：送完後在背景輪詢 `http://127.0.0.1:<埠>/queue`，
   `queue_running`、`queue_pending` 都空了，就直接讀輸出資料夾（`system-stats` 的 `--output-directory`）依 `filename_prefix` 找檔。
   佇列清空不代表都成功：每個 `run` 要回 `ok: true`，輸出檔數要等於送出數，少的用 `jobs watch <prompt_id>` 查錯。
   **使用者要比較速度時**：每步秒數、模型佔用（`… MB Staged`）、原生運算格式（`Native ops`）看 `GET /internal/logs/raw` 的
   `entries[].m`（緩衝有筆數上限，長工作邊跑邊存）；單一工作耗時用 `GET /history/<prompt_id>` 裡 `execution_start` 與
   `execution_success` 的 timestamp 相減。提示詞編碼被快取時總耗時會偏短，比較版本看每步秒數。
10. **呈現結果**：圖片直接開給使用者看，並回報完整路徑。影片、音樂在輸出資料夾的子資料夾（依 `filename_prefix`，例如 `video\`、`audio\`）。
    影片用 ComfyUI `.venv` 的 python 以 PyAV 抽幀：`c = av.open(p)`、`[f.to_image() for f in c.decode(video=0)]`，
    取首、1/3、2/3、末幀用 Pillow 拼成一張再看。**agent 聽不到聲音**（影片音軌與音樂），請使用者自己聽。

## 模型筆記

| 檔案 | 範本 | 內容 |
|---|---|---|
| `models/z-image-turbo.md` | `image_z_image_turbo`、`image_z_image_turbo_int8` | 依 VRAM 選範本、欄位地址、參考速度、提示詞要點 |
| `models/minimax-h3.md` | `video_minimax_h3_i2v` 等 | 依顯卡選主模型與步數（含 NVFP4 下載資訊）、清快取、欄位地址、加速 LoRA 開關、台詞提示詞格式、實測數據 |
| `models/minimax-music3.md` | `audio_minimax_music_3` | 檔案、欄位地址、風格描述要點（更高、更有力）、實測數據 |

實測出新模型的設定或數據時，新增一份 `models/<模型>.md` 並補進這張表，不要寫進本檔。

## 安全規則

- **預設只跑本機的免費模型。** `--allow-spend`、`--where cloud`、`comfy generate`、`comfy cloud login`
  都會花 Comfy 點數或連到雲端，須取得當次明確同意。遇到 `spend_consent_required` 錯誤，
  **不可**自行加 `--allow-spend` 讓錯誤消失。
- 下載模型、安裝擴充節點（`comfy node install` 會執行第三方程式碼）前都要先問，並列出名稱、大小、來源。
- **不執行 `comfy skills install`**：它會寫入 `~/.claude/`、`~/.cursor/` 與家目錄的 `AGENTS.md`，
  繞過本 repo 的安裝規則。
- 不主動送出 `comfy feedback`／`comfy agent-review`（官方技能會教 agent 這麼做），除非使用者自己要求。
- 不把 `COMFY_API_KEY` 寫進檔案、指令列或對話。
- 刪除模型、輸出檔、工作流程前再次確認。
- 「安裝 Skill」不等於「授權執行它」：步驟 1、2 與上面各條要逐項確認；改參數、預檢、送出本機免費工作不必再問。

## 復原

`uv tool uninstall comfy-cli` 移除工具；Windows 上的設定與工作狀態檔在 `%LOCALAPPDATA%\comfy-cli\`，
使用者同意後才刪。下載的模型、ComfyUI output 資料夾裡的產出，都由使用者確認後再刪。
agent 在背景啟動的 ComfyUI：`Stop-Process -Id $p.Id`，再確認 `Get-NetTCPConnection -LocalPort 8188 -State Listen` 已無結果。
`$p.Id` 是 `.venv` 的啟動器，監聽的是它帶起的子行程，實測停啟動器會一起結束；仍在監聽時，
先確認 `OwningProcess` 的 `ParentProcessId` 是 `$p.Id` 才停，不是就不要動（可能是 Desktop 的）。

## 回報

ComfyUI 版本與埠、由誰啟動（Desktop／agent 背景啟動，是否已停止）、GPU 與 VRAM、comfy-cli 版本、
使用的範本或工作流程、改了哪些欄位、補下載的模型（檔名、大小、SHA256 是否相符）、prompt_id、耗時、
**輸出檔完整路徑**、是否花費點數（應為否）、使用者仍需自己完成的步驟。
