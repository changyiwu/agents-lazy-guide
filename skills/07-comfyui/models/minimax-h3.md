# MiniMax H3（影片＋聲音）

本檔隨 `agent-comfyui` 安裝，由 `SKILL.md`〈模型筆記〉指向。社群版本比較、取捨原因與量測方式見 `guides/07-連接-ComfyUI.md` 步驟九。

一次生成畫面與立體聲音軌（對白、音效、配樂）。主模型分兩種：**FL2VA**（文字轉影片、首幀／首尾幀轉影片；範本
`video_minimax_h3_i2v`、`video_minimax_h3_t2v`）與 **Ref2VA**（參考圖／影片／聲音；`video_minimax_h3_r2v`，見〈Ref2VA〉）。
以下實測都是 FL2VA 的 `video_minimax_h3_i2v`（不接首幀就是文字轉影片）。`api_minimax_h3_*` 是付費雲端節點，不要用。

## 選主模型與步數

| 顯卡 | 預設 | 使用者要快 |
|---|---|---|
| RTX 50 系列 16GB | 社群 NVFP4 主模型，20 步 | 官方 int8 主模型＋8 步 LoRA（送出前先清快取） |
| 24GB 以上，或不是 RTX 50 系列 | 官方 int8 主模型（範本預設），20 步 | int8＋8 步 LoRA |

- **避免 NVFP4＋8 步 LoRA**：兩組真人快速動作都出現殘影——揮手時手指紅綠色殘影、手形糊掉；招手的手臂半透明、轉身跑開時身體糊成半透明。
  同 seed 的 NVFP4 20 步、int8 兩種都沒有（兩組都只測 seed 42）。只在使用者明確要快速打草稿時用。
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
| `105.value_1` | `105:111` 的 `value` | 長度（秒），自動換算成 17k＋5 幀（24fps） | 5（= 124 幀，也是訓練範圍下限；3 秒 = 73 幀） |
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

## 角色要說台詞：官方撰寫指南的格式

MiniMax 官方撰寫指南（Hugging Face `MiniMaxAI/MiniMax-H3` 的 `docs/VIDEO_PROMPT_WRITING_GUIDE_base_en.md`）的首幀轉影片寫法。
結構寫英文，台詞保留原文；說話者用 `(S1)`、`(S2)`，台詞包成 `<d>[語言] 原文</d>`：

```
For the target video, at 0.00 seconds into the target video, <Picture 1> (from [Shot 1]) is fully referenced.
integrated_multimodal_description: [Shot 1] Live-action, cinematic, ... The young woman shown in <Picture 1> ...（場景、外觀、鏡頭、說話前的動作）, and the playful, sweet young woman (S1) says: <d>[Chinese] 哈、哈、哈，相公，你來追我啊。</d> Right after the line she ...（說完後的動作）
overall_soundscape: Soft waves washing against the rocks, a gentle sea breeze, and her light footsteps ...
non_diegetic_music: None.
```

- 三個欄位名稱照順序寫，後面接冒號與空格；不要配樂就寫 `None.`。
- 官方範例只示範 `[English]`；中文寫 `[Chinese]`、繁體字台詞，四種跑法都正常生成，嘴巴在說台詞的時段有說話的開合。**發音與嘴型是否對得上 agent 聽不到，請使用者自己聽。**
- 5 秒放一句短台詞（約 12 個中文字）加前後動作就滿了；語氣寫在 `(S1)` 前面（例如 `playful, sweet`）。

## Ref2VA：把人放進全新場景（參考圖已實測；參考影片仍未實測）

範本 `video_minimax_h3_r2v`，節點 `MiniMaxH3ReferenceToVideo`。**是「參考」不是「逐幀改寫」**：目標影片一樣從空 latent
重新生成，參考只進 conditioning。**只給一張人物照＋文字**，就能把那個人放進提示詞描述的全新場景與動作（已實測）；
給參考影片時動作、運鏡、場景會神似，但**不會逐幀對齊，背景是重畫的**。使用者要「原片原封不動只換人」就明講 H3 做不到，
要走逐幀控制的工作流（換臉、控制影片類），不要用本節硬湊。

- ⚠️ **不要用 4 步 turbo LoRA**（`146.value` 保持 false）。實測同 seed、同提示詞：4 步版整片被紅色橫條紋吃掉，
  而且**直接照抄參考照片的房間背景與衣服**，提示詞寫的場景與動作完全沒出現；20 步原始模型一次就正確。
  每步時間兩者幾乎一樣（13.6 vs 13.1 秒），4 步省的只是步數，代價是整支報廢。與 fl2va 的「避免 NVFP4＋8 步 LoRA」同一個模式。
- **輸入上限**：參考圖 9 張（`<Picture i>`）、參考影片 3 段（`<Video k>`，24fps、2–15 秒，每段可各帶一條音軌）、
  獨立聲音 3 段（`<Audio j>`）。編號各型別各自從 1 起算，順序＝節點上連接的順序（影片的音軌標籤排在該影片前面）。
- **主模型是另一份權重** `minimax_h3_ref2va_pruned_int8_convrot.safetensors`（20,970,379,616 bytes，
  SHA256 `9255f52b…65779`），與 fl2va 不共用；16GB 放不下，實測 `19995MB Staged`。社群 NVFP4 的 ref2va 版未實測。
- `ref_image_size` 預設 `match`（縮到生成畫素量）。實測 864×480＋一張參考圖時每步 13.1 秒，與 i2v 的 480×864 相當，
  **參考圖成本很低**；`max`（2048 短邊）人物最像但範本註明慢好幾倍，未實測。參考影片才是真正的加速殺手（每步重算）。
- 取樣器 `res_multistep`；scheduler 改 `beta`（範本註明優於 `simple`，實測 20 步正常）。
- 參考影片會被截到目標長度並對齊 17k＋5，最少 5 幀；送進文字編碼器的只有 2fps 抽幀（每 12 幀一張）加時間戳，
  細碎快動作本來就看不全。
- 要保留原片某幾段原封不動，是另一個節點 `MiniMaxH3AddGuide`（把片段釘在指定幀，釘住的幀不進 denoise）——
  但保留下來的是原片的人，對換角沒用。
- **範本清單隨 ComfyUI 版本變動**（0.36.0 為 `video_minimax_h3_t2v`／`_i2v`／`_i2v_continuation`／`_r2v`），
  用 `comfy templates list` 核對再用。

### 欄位（`video_minimax_h3_r2v` 實測地址，ComfyUI 0.36.0）

這個範本**沒有子圖**，API 格式的節點 id 與 slots 地址同號。

| slots 地址 | 欄位 | 範本預設 |
|---|---|---|
| `137.image` | 參考圖 1 → `<Picture 1>`（檔要先在 input 資料夾） | 示範圖 `red_superboy_on_city_roof.png` |
| `139.image` | 參考圖 2 → `<Picture 2>` | 示範圖 `mecha_dragon_lightning.png` |
| `138.value` | 提示詞（長文改 API 格式的 `inputs.value`） | 範本示範 |
| `115.aspect_ratio`、`115.megapixels` | 比例、畫素量 | `16:9 (Widescreen)`、0.4（= 864×480） |
| `132.value` | 長度（秒），由 `131` 換算成 17k＋5 幀 | 5（= 124 幀） |
| `136.ref_image_size` | `match`／`max` | `match` |
| `146.value` | 4 步 turbo LoRA 開關（⚠️ 保持 false） | false |
| `143.value`／`144.value` | 原始步數／LoRA 步數 | 20／4 |
| `124.scheduler` | scheduler | `simple`（改 `beta`） |
| `129.noise_seed` | seed | 隨機 |
| `92.filename_prefix` | 輸出檔名，含 `video/` 子資料夾 | `video/MiniMax_H3` |

- **只用一張參考圖**：範本預接兩張，第二張的示範圖不在 input 會直接報錯。在 API 格式刪掉
  `136` 的 `inputs["ref_images.ref_image_1"]`，並把節點 `139` 整個刪掉（少一組參考 token 也比較快）。
- 提示詞寫法（實測可用）：風格、色調、場景一句 → `Use <Picture 1> as the exact reference for the man's face and identity:`
  加外觀描述與**要換上的服裝** → `CUT 1:` 描述動作與運鏡 → `Audio:` 描述聲音。
  20 步時這句 `exact reference` **不會**造成照抄背景（照抄是 4 步 LoRA 的症狀，不是用詞問題）。
- 照片要先 `ImageOps.exif_transpose` 轉正再裁：手機直式照常常是橫式存檔＋EXIF 轉向，直接裁會裁錯位置。
  裁成半身（臉佔比大）當參考圖，實測五官、髮色與眼鏡都保得住。

### 動作與特效的提示詞要點（ref2va 實測）

- **用詞決定方向，seed 決定程度與機位。** 同一份提示詞（逐字相同，只換 seed）：seed 1999 後仰到接近水平、屈膝下沉，
  機位自動變成從槍手肩後的過肩鏡頭；seed 42 只到 45–55 度、腿幾乎打直、側面中景。
  **要極端姿勢就固定提示詞掃 seed，不要反覆改字**——掃的時候用 5 秒小尺寸比 8 秒便宜三倍，挑中再放大重跑。
- **互相衝突的句子會抵消。** 「膝蓋彎成 90 度」與 `He is not crouching and not squatting` 同時寫，膝蓋那句不生效；
  拿掉後者才做得出屈膝。
- **借用的動作名詞會帶進它自己的姿勢。** 寫 `limbo` 會得到屈膝下蹲的 limbo 舞姿（彎得深但變成蟹式撐橋）；
  要「腳站著、腰為軸」就寫 `leans back from the waist like a hinge, feet planted flat, legs almost straight`。
- **深度要用可量的錨點**，不要只寫 extreme：`his head sinks to the same height as his belt`、`his back is flat like a tabletop`、
  `shins vertical and thighs level like a chair`。停留寫 `holds that pose for two full seconds`。
- **特效要寫起點、路徑、終點，否則會定在原地閃。** 子彈衝擊波實測有效的寫法：
  `born at the pistol muzzle in the foreground`（起點）→ `racing forward, sweeping over his chest without pausing,
  travels the full depth of the shot`（路徑）→ `shrinking as it flies off toward the city lights and out of frame`（終點），
  再加 `a new ring launches from the muzzle before the previous one leaves`，波列才會連續不斷。
  只寫「波要一直前進」會被理解成原地波動。
- 同 seed 換提示詞時，**姿勢不保證留著**（seed 決定的是雜訊不是動作），但實測只改特效段落時深蹲後仰有保住。

## 實測（RTX 5060 Ti 16GB、系統記憶體 62 GB、ComfyUI 0.35.1）

同一組內用同一張首幀、提示詞與 seed 42。主模型佔用（紀錄的 Staged）：NVFP4 11,944 MB、int8 19,995 MB（超過 VRAM）。

**640×640、3 秒**（動漫首幀，鏡頭推近、拉捲尺；範本格式提示詞）：

| | NVFP4＋8 步 | NVFP4 20 步 | int8 20 步 |
|---|---|---|---|
| 每步 | 5.52 秒 | 5.23 秒 | 6.15 秒 |
| 總耗時 | 74 秒 | 141 秒 | 137 秒（沿用快取的提示詞編碼） |
| 系統記憶體最少剩 | 10.3 GB | 9.6 GB | 4.4 GB |

**480×864（9:16）、5 秒，第一組**（寫實台灣女生首幀，撥頭髮、揮手、笑；範本格式提示詞）：

| | NVFP4＋8 步 | NVFP4 20 步 | int8＋8 步 | int8 20 步 |
|---|---|---|---|---|
| 每步 | 13.3 秒 | 12.8 秒 | 14.5 秒 | 13.9 秒 |
| 總耗時 | 159 秒 | 296 秒 | 156 秒 | 317 秒 |
| 系統記憶體最少剩 | 未量 | 10.9 GB | 3.9 GB | 4.7 GB |
| 畫面 | ❌ 手指紅綠色殘影 | ✅ | ✅ | ✅ |

**480×864（9:16）、5 秒，第二組**（寫實日本女生首幀，大笑、說一句中文台詞、招手、轉身跑開；官方格式提示詞；每支送出前都清快取）：

| | NVFP4＋8 步 | NVFP4 20 步 | int8＋8 步 | int8 20 步 |
|---|---|---|---|---|
| 每步 | 13.7 秒 | 12.9 秒 | 14.5 秒 | 13.9 秒 |
| 總耗時 | 160 秒 | 296 秒 | 156 秒 | 318 秒 |
| 系統記憶體最少剩 | 11.8 GB | 12.1 GB | 6.3 GB | 6.5 GB |
| 畫面 | ❌ 招手手臂半透明、跑開時身體糊成半透明 | ✅ | ✅ | ✅ |


**Ref2VA 864×480、5 秒、一張半身人物參考圖、無參考影片**（同一張圖、同提示詞、seed 42；ComfyUI 0.36.0）：

| | 4 步＋turbo LoRA | 20 步原始模型 |
|---|---|---|
| 每步 | 13.63 秒 | 13.08 秒 |
| 取樣 | 54 秒 | 4 分 23 秒 |
| 總耗時 | 110 秒 | 299 秒 |
| 畫面 | ❌ 紅色橫條紋、照抄參考圖的房間背景與衣服 | ✅ 場景、動作、運鏡都照提示詞做出來 |

- 主模型 `19995MB Staged`（int8 超過 16GB VRAM）。每步時間與 fl2va 的 480×864 相當，**一張 `match` 參考圖幾乎沒有額外成本**。
- 相似度：半身照一張就保住五官、灰白髮與金屬圓框眼鏡；服裝可由提示詞換掉（實測換成黑色長大衣）。

**Ref2VA 8 秒（192 幀）對照**（864×480、20 步、同一張參考圖）：

| | 5 秒／124 幀 | 8 秒／192 幀 |
|---|---|---|
| 每步 | 13.1 秒 | 27.4 秒 |
| 取樣 | 4 分 23 秒 | 9 分 20 秒 |
| 總耗時 | 299 秒 | 607–619 秒 |

- 幀數 1.55 倍 → 每步 2.1 倍，與 fl2va 的非線性規律一致；`19995MB Staged` 不變，8 秒沒出現記憶體警告。
- 長度換算（`132.value` 秒 → 幀）：8 → 192（正好 8.00 秒）、6 → 158（6.58 秒）、10 → 243（10.125 秒）。
  **只有秒數換算後剛好落在 17k＋5 才會是整數秒**，要標準長度就挑 8 秒。

- 兩組 5 秒的耗時差不到 3%：換提示詞格式、加台詞不影響速度。
- 估時間：幀數 1.7 倍、畫素量相近時，每步慢 2.3–2.5 倍，不能照幀數線性推。8 步 LoRA 總時間約是 20 步的一半。
- int8 的系統記憶體最少只剩 4–6.5 GB；影片更長或更大時先提醒使用者有記憶體不足的風險。
- GPU 用量都約 15.5 GB（動態 VRAM 會盡量用滿），不能拿來判斷放不放得下，要看 Staged。
- 看畫面時抽 5 幀並排（首、1/5、1/3、2/3、末）；手部與快速動作的破綻出現在中段與跑開的末段，只看首幀看不出來。
  有台詞時另抽 1–4 秒每 0.5 秒一格，看嘴型與手勢。
- 產出 mp4 含 AAC 32 kHz 立體聲，聲音請使用者自己聽。
