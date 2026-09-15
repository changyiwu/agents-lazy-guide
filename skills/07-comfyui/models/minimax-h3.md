# MiniMax H3（影片＋聲音）

本檔隨 `agent-comfyui` 安裝，由 `SKILL.md`〈模型筆記〉指向。社群版本比較、取捨原因與量測方式見 `guides/07-連接-ComfyUI.md` 步驟九。

一次生成畫面與立體聲音軌（對白、音效、配樂）。主模型分兩種：**FL2VA**（文字轉影片、首幀／首尾幀轉影片；範本
`video_minimax_h3_i2v`、`video_minimax_h3_t2v`）與 **Ref2VA**（參考圖／影片／聲音；`video_minimax_h3_r2v`）。
以下實測都是 FL2VA 的 `video_minimax_h3_i2v`（不接首幀就是文字轉影片）。`api_minimax_h3_*` 是付費雲端節點，不要用。

## 選主模型與步數

| 顯卡 | 預設 | 使用者要快 |
|---|---|---|
| RTX 50 系列 16GB | 社群 NVFP4 主模型，20 步 | 官方 int8 主模型＋8 步 LoRA（送出前先清快取） |
| 24GB 以上，或不是 RTX 50 系列 | 官方 int8 主模型（範本預設），20 步 | int8＋8 步 LoRA |

- **避免 NVFP4＋8 步 LoRA**：5 秒真人揮手時手指出現紅綠色殘影、手形糊掉；同 seed 的 NVFP4 20 步、int8 兩種都沒有（各只測一個 seed）。
  只在使用者明確要快速打草稿時用。
- 主模型檔（`diffusion_models`）：
  - 社群 NVFP4 `minimax_h3_fl2va_pruned_nvfp4_all.safetensors`，12,528,637,032 bytes。照 `SKILL.md` 步驟 6 先問、驗證後才改名：來源
    `https://huggingface.co/MATLOWAI/minimax-h3-nvfp4/resolve/main/diffusion_models/minimax_h3_fl2va_pruned_nvfp4_all.safetensors`，
    SHA256 `d171fefc7ef9c61a5819cdc550b60a3e112bd871d3dd6a9e73ac19955b5228e8`。ComfyUI 原生支援，不需擴充節點。
  - 官方 int8 `minimax_h3_fl2va_pruned_int8_convrot.safetensors`，19.53 GB。16GB 放不下，部分權重留在系統記憶體。
- 不是 RTX 50 系列不要用 NVFP4：會退回比 int8 還慢的運算。GGUF 版要裝擴充節點，不採用。Ref2VA 的 NVFP4 版未實測。
- 其餘檔用範本列的官方檔：`text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq`（14.61 GB，不限 RTX 50 系列）、
  `vae/minimax_h3_video_vae_fp16`（4.85 GB）、`vae/minimax_h3_audio_vae_fp32`（0.56 GB）、
  `loras/minimax_h3_fl2v_turbo_8step_v1.0_comfyui_bf16`（1.82 GB）。範本另列的 4 步 768p LoRA 與 `minimaxh3_*` embedding 是選用的。
- 換用 NVFP4：把 `105.unet_name`（API 格式 `105:6`）改成它；紀錄出現 `Native ops: … nvfp4 …` 才是走原生運算。
- **清快取**：跑 int8 前，或剛跑過其他模型（生圖、音樂）時，佇列清空後先
  `POST http://127.0.0.1:<埠>/free`，body `{"unload_models": true, "free_memory": true}`。
  實測 ComfyUI 留著前面的模型佔 40.7 GB，可用記憶體只剩 9.4 GB，清完回到 47.8 GB。不要在工作執行中呼叫。

## 欄位（`video_minimax_h3_i2v` 實測地址）

| slots 地址 | API 格式節點 | 欄位 | 範本預設 |
|---|---|---|---|
| `114.image` | `114` | 首幀檔名（檔要先在 input 資料夾） | 示範圖 `transparent_rgb_gaming_mouse.png` |
| `115.aspect_ratio`、`115.megapixels` | `115` | 比例、畫素量 | `1:1 (Square)`、0.4（= 640×640；16:9 為 864×480；`9:16 (Portrait Widescreen)` 為 480×864） |
| `105.value_1` | `105:111` 的 `value` | 長度（秒），自動換算成 17k＋5 幀（24fps） | 5（= 124 幀；3 秒 = 73 幀） |
| `105.noise_seed` | `105:15` | seed | 隨機 |
| `105.unet_name` | `105:6` | 主模型 | int8 |
| — | `105:104` 的 `prompt` | 提示詞 | 範本示範 |
| `92.filename_prefix` | `92` | 輸出檔名，含 `video/` 子資料夾 | `video/MiniMax_H3` |

API 格式的子圖 id 可能隨範本改版變動，改之前用 `class_type`／`_meta.title` 核對。

- 首幀用使用者自己的圖就**複製**進 input 資料夾；範本的示範圖要從 GitHub 下載，須先問。
- 提示詞很長，改 API 格式裡 `MiniMaxH3ImageToVideo` 節點的 `inputs.prompt`。範本寫法：整體風格與場景 →
  `SHOT 1:`、`SHOT 2:` 描述鏡頭與動作 → `Audio:` 描述聲音。
- 首幀是生成的圖時，**先看圖，照圖上實際的樣子描述人物外觀**（生圖提示詞寫的不一定照做），前後才一致。
- ⚠️ **8 步加速 LoRA 預設關閉，實際跑原始模型 20 步。** 要 8 步：在 API 格式找 `_meta.title` 為
  `Boolean (Enable Lightning LoRA)` 的節點，把 `inputs.value` 改 true（依標題找；id 在子圖內，例如 `105:126`）。
  紀錄出現 `Model MiniMaxH3 prepared … 208 patches attached` 是有套上 LoRA，`0 patches attached` 是原始 20 步。
- 預檢出現節點 119、120 的 `node_not_reachable_from_output` 警告：範本留下的未接線節點，可忽略。
- 官方畫布短邊 768（上限 768×1344）、最長約 15 秒；比實測更長、更大的設定未實測，會更慢、更吃記憶體。

## 實測（RTX 5060 Ti 16GB、系統記憶體 62 GB、ComfyUI 0.35.1）

同一組內用同一張首幀、提示詞與 seed 42。主模型佔用（紀錄的 Staged）：NVFP4 11,944 MB、int8 19,995 MB（超過 VRAM）。

**640×640、3 秒**（動漫首幀，鏡頭推近、拉捲尺）：

| | NVFP4＋8 步 | NVFP4 20 步 | int8 20 步 |
|---|---|---|---|
| 每步 | 5.52 秒 | 5.23 秒 | 6.15 秒 |
| 總耗時 | 74 秒 | 141 秒 | 137 秒（沿用快取的提示詞編碼） |
| 系統記憶體最少剩 | 10.3 GB | 9.6 GB | 4.4 GB |

**480×864（9:16）、5 秒**（寫實真人首幀，撥頭髮、揮手、笑）：

| | NVFP4＋8 步 | NVFP4 20 步 | int8＋8 步 | int8 20 步 |
|---|---|---|---|---|
| 每步 | 13.3 秒 | 12.8 秒 | 14.5 秒 | 13.9 秒 |
| 總耗時 | 159 秒 | 296 秒 | 156 秒 | 317 秒 |
| 系統記憶體最少剩 | 未量 | 10.9 GB | 3.9 GB | 4.7 GB |
| 手部 | ❌ 紅綠色殘影 | ✅ | ✅ | ✅ |

- 估時間：幀數 1.7 倍、畫素量相近時，每步慢 2.3–2.5 倍，不能照幀數線性推。8 步 LoRA 總時間約是 20 步的一半。
- int8 的系統記憶體最少只剩約 4 GB；影片更長或更大時先提醒使用者有記憶體不足的風險。
- GPU 用量都約 15.5 GB（動態 VRAM 會盡量用滿），不能拿來判斷放不放得下，要看 Staged。
- 看畫面時抽 5 幀並排（首、1/5、1/3、2/3、末）；手部與快速動作的破綻出現在中段，只看首尾幀看不出來。
- 產出 mp4 含 AAC 32 kHz 立體聲，聲音請使用者自己聽。
