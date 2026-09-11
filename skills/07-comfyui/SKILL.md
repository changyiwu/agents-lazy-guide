---
name: agent-comfyui
description: 用官方 comfy-cli 操作本機 ComfyUI：套用範本或使用者自己的工作流程、改提示詞與參數、送出並取回生成的圖片（音樂、影片同一套流程）。使用者提到 ComfyUI，或說「連接 ComfyUI」「用 ComfyUI 生圖」「跑 ComfyUI 工作流程」時載入。
---

# 連接 ComfyUI

完整教學見 `guides/07-連接-ComfyUI.md`。以下是執行流程。

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

     **必須用 `Start-Process`**（`&` 會佔住指令到逾時、拿不到 PID）；含空白的路徑要用 `` `" `` 包住。輪詢 `system_stats` 有回應再繼續。
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
     `comfy --json templates fetch <名稱> -o <檔>`。
   - **依步驟 4 的 VRAM 選版本**：未滿 16GB 優先找量化版範本，例如 `image_z_image_turbo_int8`（下載約 11.3 GB，
     8GB 實測可跑）；完整版 `image_z_image_turbo`（約 19.3 GB）放不進 8GB，不要讓它靠系統記憶體硬跑。
   - 使用者自己的：🖐️ 請使用者在 ComfyUI 把工作流程存成 JSON（UI 或 API 格式都可以）。
     或直接取使用者在 ComfyUI 生過的 PNG：它的 `prompt` 文字區塊就是完整的 API 格式工作流程
     （`json.loads(Image.open(p).info["prompt"])`；ComfyUI 的 `.venv` 裡就有 Pillow）。

   工作流程檔放在專案的 `comfyui/` 資料夾。
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
   **不要重新送出**。參考速度（Z-Image Turbo，首張含載入模型／之後）：RTX 5060 Ti 16GB 完整版 32／11 秒；
   RTX 5060 Laptop 8GB Int8 版 34.5／11.1 秒。
10. **呈現結果**：圖片直接開給使用者看，並回報完整路徑。影片用 `comfy preview <檔>` 產縮圖；
    **agent 聽不到音樂**，請使用者自己聽。音樂與影片的注意事項見 guide（尚未實測）。

## Z-Image Turbo 提示詞要點

- **提示詞寫中文**，服裝與配件逐項描述。
- **負面提示無效**：「不要文字」改寫成「畫面中沒有任何文字」；小地方仍常長出亂碼字，**選定前放大檢查**。
- **數不準方陣、多角色常互換服裝或多長出動物**：要數的物件排單排；多角色逐張對照設定挑選。
- 預設只跑一張；**使用者要挑圖或說「多給幾張」時**，同一段提示跑 4 個 seed（`set-slot` 改 seed 後連續 `run --no-watch` 排隊）。

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
