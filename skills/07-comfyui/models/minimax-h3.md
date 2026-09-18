# MiniMax H3（影片＋聲音）

本檔隨 `agent-comfyui` 安裝，由 `SKILL.md`〈模型筆記〉指向。社群版本比較、取捨原因與量測方式見 `guides/07-連接-ComfyUI.md` 步驟九。

一次生成畫面與立體聲音軌（對白、音效、配樂）。主模型分兩種：**FL2VA**（文字轉影片、首幀／首尾幀轉影片；範本
`video_minimax_h3_i2v`、`video_minimax_h3_t2v`）與 **Ref2VA**（參考圖／影片／聲音；`video_minimax_h3_r2v`，見〈Ref2VA〉）。
以下實測前半是 FL2VA 的 `video_minimax_h3_i2v`（不接首幀就是文字轉影片）；Ref2VA、〈多段影片〉、〈FL2VA 首尾幀〉各有一節。
`api_minimax_h3_*` 是付費雲端節點，不要用。

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
- ⚠️ 上表是 ComfyUI 0.35.1 的地址。**comfy-cli 1.20.0 讀不了 0.36.0 的 `video_minimax_h3_i2v`**（見〈FL2VA 首尾幀〉）。

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

## Ref2VA：把人放進全新場景（參考圖、參考聲音已實測；參考影片仍未實測）

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
  **參考圖成本很低**。`max`（2048 短邊）範本註明「最像但慢好幾倍」，**實測兩點都不成立**：864×480、5 秒、兩張參考圖，
  `match` 354.3 秒、`max` 374.1 秒（只慢 5.6%），但大特寫一樣走樣（見〈多段影片〉），**維持 `match`**。
  參考影片才是真正的加速殺手（每步重算）。
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
- **超過兩張參考圖或要加參考聲音**：UI 範本只有 `137`、`139` 兩顆 `LoadImage`、沒有 `LoadAudio`。`run --print-prompt`
  取得 API 格式後補節點，預檢通過再 `POST /prompt`（`SKILL.md` 步驟 8）：
  `"301": {"class_type": "LoadImage", "inputs": {"image": "<檔>"}}`，`136.inputs["ref_images.ref_image_2"] = ["301", 0]`（＝`<Picture 3>`）；
  `"302": {"class_type": "LoadAudio", "inputs": {"audio": "<檔.wav>"}}`，`136.inputs["ref_audios.ref_audio_0"] = ["302", 0]`（＝`<Audio 1>`）。
  `ref_image_N` 從 0 起算、`<Picture i>` 從 1 起算。
- **接著線的參考圖，裡面的人就會被放進畫面**：文字寫「她在鏡頭外」她照樣入鏡；參考圖帶到的人也可能被複製成第二個。
  某段只要一人出場就拔掉另一張的線；**場景參考圖一定要先去人**（`models/qwen-image-edit.md`）。
- **服裝一致靠定妝照，不靠文字**：生活照當 `<Picture 1>`、服裝用文字寫時，遠景是敞襟短打、特寫卻變立領盤扣。
  先用 `models/qwen-image-edit.md` 把生活照換裝成定妝照，裁頭到腰帶下緣，提示詞寫
  `Use <Picture 1> as the exact reference for the man's face, identity and costume` 加 `dressed exactly as in <Picture 1>`，
  各段服裝就一致。**不要用文字改參考圖本來的長相**（例如硬寫髮量），會跟參考圖打架而且無效。
- **場景一致靠場景版**：從已定稿那段抽一格最完整的廣角、去人，當 `<Picture 3>`，提示詞逐項點名物件與位置
  （`the same wooden double gate on the left, ... all in the same positions`），各段門、牆、樹才對得上。
- **參考聲音統一音色**：已定稿那段的音軌 `ffmpeg -i <段.mp4> -vn -acodec pcm_s16le <檔.wav>` 接成 `<Audio 1>`，寫
  `the man's voice must sound exactly like the man's voice in <Audio 1> ... the ambience must match <Audio 1> as well`。
  真人錄音（30 秒、16kHz 單聲道）當參考也可行。耗時 864×480／5 秒／兩張圖 354.3 → 431.7 秒（+22%），
  1056×608／5 秒／三張圖 752.7 → 749.4 秒（沒差），以實測為準。**無對白的段落不要接**，參考音軌裡的人聲會把台詞引回來。
  像不像 agent 聽不到，請使用者聽。

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
  只寫「波要一直前進」會被理解成原地波動。同一套寫法做「一團氣從甲的嘴飄到乙臉上」也一次成功，5 秒版同樣成立。
- **倒下、跪下要留在畫面內**：寫 `the flagstones at their feet stay inside the bottom of the frame the whole time, so that
  when she drops her whole body is still in frame`；沒寫時她倒下去大半掉出下緣。
- 同 seed 換提示詞時，**姿勢不保證留著**（seed 決定的是雜訊不是動作），但實測只改特效段落時深蹲後仰有保住。

## 多段影片：一致性、鏡頭與剪接（ref2va 實測）

實測一支四段的古裝庭院雙人短片（1056×608、每段 4–8 秒、成品約 23 秒）。每段都要注意：

**一致性**
- 外觀、場景、聲音的段落寫成腳本裡的共用字串，**每段逐字相同**、只換 `CUT` 段落；改外觀就改字串、所有段一起重生。
- **以使用者點頭的那一段為基準**：它的一格做場景版、它的音軌做參考聲音，其他段對齊它。各段 `115.megapixels` 相同才能直接拼。

**景別與像度**
- **越近越不像，而且會禿**：中景、全身時頭髮與五官都對；推到頭頂佔滿畫面的大特寫，髮際線後退、臉偏離參考圖，
  而且隨秒數惡化。寫髮量的句子壓不住。**要像的角色維持中景**：`never frames anyone above the chest`。
- **雙人對話有很強的推近先驗**：`locked-off on a tripod`、`does not move at all`、`never comes closer` 都擋不住；
  單人中近景寫 `locked-off` 則一次就對。鎖得住雙人景別的是**場景版＋`never frames anyone above the chest`＋起點寫全身廣角**。
- **鏡頭句裡提到場景物件，畫面會被拉寬**（`standing just inside the gate` 變成廣角）。要中近景就別在那句提場景。

**剪與切**
- `HARD CUT to the reverse angle.` **獨立成一行**，正反打、換機位都做得出來；但切點不準（寫 4.6 秒、實際 2.6 秒就切）。
- **段落接點最怕「幾乎一樣但差一點」**，看起來像跳一下。要嘛用首尾幀讓它一樣（〈FL2VA 首尾幀〉），要嘛讓前一段
  收在**尺寸、主體、角度都不同**的鏡頭（例如收在她的單人特寫，下一段開在雙人廣角）。只挪切點救不了。
- **多生一點再剪**：視線、身分都隨時間衰減，後段常不能用。精確剪要重新編碼，`-c copy` 會對齊到關鍵影格：
  `ffmpeg -i <in> -t <秒> -c:v libx264 -crf 16 -preset slow -pix_fmt yuv420p -c:a aac -b:a 192k <out>`。

**表演**
- **視線寫成持續狀態**：`His eyes are locked on her from the first frame to the last ... He never looks away from her, never
  looks down, never glances off to the side, and never turns his head toward the camera.` 動作句再綁一次
  （`without taking his eyes off her`）。只寫一次性的 `turns and looks at her` 會飄。實測撐約 4 秒，之後照樣飄——剪在 4 秒前。
- **不說話要給嘴巴別的事做**：只寫 `Neither of them speaks` 他照樣開口。三處一起寫才壓住：開頭
  `Nobody speaks in this shot. There is no dialogue at all`；動作句 `his lips stay pressed together and completely still`
  ＋收尾動作 `he draws one slow breath in through his nose ... the shot ends before any sound comes out`；
  `Audio:` 寫 `No voices and no speech of any kind`。
- **進場寫因果順序**：`the gate doors are clearly seen swinging open first, and only after they are open does he appear in
  the gateway and walk in on foot ... He never appears out of nowhere, he never steps through a closed door`。
  5 秒太短時照樣「門沒開人就在院子裡」，給 7–8 秒。
- **開頭多一個一模一樣的人**：寫 `she is the only person in the courtyard, alone, no one else anywhere in the frame`，
  下一個進場的人標 `he is the second and last person to appear`。
- **左右站位**寫 `stands on the LEFT side of the frame, in front of the gate`，並讓它跟場景版的物件位置互相呼應。

**拼接與發布**
- 各段有剪過的、有原始輸出，直接 `-c copy` 容易出錯。用 concat filter 重新編碼一次並順手清 metadata：
  `ffmpeg -i 1.mp4 -i 2.mp4 -i 3.mp4 -i 4.mp4 -filter_complex "[0:v][0:a][1:v][1:a][2:v][2:a][3:v][3:a]concat=n=4:v=1:a=1[v][a]"
  -map "[v]" -map "[a]" -map_metadata -1 -c:v libx264 -crf 16 -preset slow -pix_fmt yuv420p -r 24 -c:a aac -b:a 192k
  -ar 48000 -movflags +faststart <成品>.mp4`
- 驗證：`ffprobe -v error -show_entries format_tags -of json <成品>` 只剩 `major_brand` 之類；再掃檔案位元組，
  `prompt` 與模型檔名出現 0 次。**ComfyUI 原始輸出的段落仍帶工作流程**，單獨給人前另外清（`SKILL.md` 步驟 11）。
- 硬切處的環境音若突兀，可只對音軌做短交叉淡化、畫面維持硬切（未實測）。接點聲音 agent 聽不到，請使用者聽。

## FL2VA 首尾幀：讓一段的結尾接上另一段的開頭（實測）

`MiniMaxH3ImageToVideo` 有 `first_frame`、`last_frame` 兩個選用輸入。尾幀設成下一段的第一格，這段就會停在
幾乎同一個畫面（實測站位、服裝、光線、道具全對上，景別只差約 5%）。

- ⚠️ **comfy-cli 1.20.0 讀不了 ComfyUI 0.36.0 的 `video_minimax_h3_i2v`**：原始範本也一樣，`run --print-prompt`、
  `workflow slots` 都輸出空字串、exit code 卻是 0。改拿 ref2va 的 API 圖改裝（兩個節點的輸出都是 `positive`＋`LATENT`）：
  `136` 換成 `MiniMaxH3ImageToVideo`，inputs 只留 `clip`、`vae`、`prompt`、`width`、`height`、`length`（沿用原連線），
  加 `first_frame: ["137", 0]`、`last_frame: ["139", 0]`；`127.unet_name` 改 `minimax_h3_fl2va_pruned_int8_convrot.safetensors`；
  `124.scheduler` 改 `simple`、`124.steps` 直接填 20、`126.model` 改接 `["127", 0]`（繞過 turbo LoRA 的 switch）；
  刪掉 `141`–`146` 與其他參考圖節點。`workflow validate` 通過再 `POST /prompt`。
- 首尾兩格要已經是目標解析度（實測兩格都是 1056×608，直接用）。提示詞改 FL2VA 的 `SHOT 1:` 寫法，不寫 `<Picture>`。
- **取捨**：FL2VA **不吃 `<Picture>` 參考圖**，長相只靠首尾兩格外推——接縫幾乎無痕，**但中段像度比 ref2va 差**，
  使用者看過後選回 ref2va。要像就用 ref2va，接點改用換機位處理（〈多段影片〉）；同機位、同站位的接點才值得用首尾幀。
- 1056×608、8 秒、20 步：1295.4 秒，與 ref2va 同長度相當。

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

**Ref2VA 1056×608（`16:9`＋`megapixels` 0.6）**（ComfyUI 0.36.0、20 步、`beta`）：

| 長度 | 參考 | 總耗時 |
|---|---|---|
| 5 秒／124 幀 | 兩張圖 | 687.4 秒 |
| 5 秒／124 幀 | 三張圖 | 752.7 秒 |
| 5 秒／124 幀 | 三張圖＋參考聲音 | 749.4 秒 |
| 7 秒／175 幀 | 三張圖 | 1206.8 秒 |
| 8 秒／192 幀 | 兩張圖 | 1250–1337 秒（7 支） |
| 8 秒／192 幀 | 三張圖 | 1356.3、1400.0 秒 |

- `megapixels` 0.6 實際輸出 **1056×608**（不是 1024×576，節點向上進位），比 864×480 多 55% 畫素。
- 同一模型連續排隊時第二支省掉載入，約少 40 秒，中間不必清快取；換成 Qwen Image Edit 或 FL2VA 前才清。
- 長度換算補：5 → 124（5.17 秒）、7 → 175（7.29 秒）。

- 兩組 5 秒的耗時差不到 3%：換提示詞格式、加台詞不影響速度。
- 估時間：幀數 1.7 倍、畫素量相近時，每步慢 2.3–2.5 倍，不能照幀數線性推。8 步 LoRA 總時間約是 20 步的一半。
- int8 的系統記憶體最少只剩 4–6.5 GB；影片更長或更大時先提醒使用者有記憶體不足的風險。
- GPU 用量都約 15.5 GB（動態 VRAM 會盡量用滿），不能拿來判斷放不放得下，要看 Staged。
- 看畫面時抽 5 幀並排（首、1/5、1/3、2/3、末）；手部與快速動作的破綻出現在中段與跑開的末段，只看首幀看不出來。
  有台詞時另抽 1–4 秒每 0.5 秒一格，看嘴型與手勢。
- 產出 mp4 含 AAC 32 kHz 立體聲，聲音請使用者自己聽。
