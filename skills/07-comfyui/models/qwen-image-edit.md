# Qwen Image Edit 2511（照指令改圖）

本檔隨 `agent-comfyui` 安裝，由 `SKILL.md`〈模型筆記〉指向。原因與實例見 `guides/07-連接-ComfyUI.md` 步驟九〈多段影片〉。

給一張圖＋一句中文指令，改掉指定的部分、其餘保持原樣。在影片工作裡拿來做 **H3 Ref2VA 的參考圖**：
把真人生活照換裝成**定妝照**、把影片畫格裡的人移掉做成**場景版**（用法見 `models/minimax-h3.md`〈Ref2VA〉）。

## 範本與檔案

- 範本 `image_qwen_image_edit_2511_int8`，16GB 放得下，實測 `templates check` 為 `runnable`。
  其他 edit 範本（`image_qwen_image_edit_2509`、`image_flux2_klein_*_image_edit_*` 等）未實測。`api_*` 開頭的是付費雲端節點，不要用。
- 範本使用的檔：`diffusion_models/qwen_image_edit_2511_int8_convrot`、`text_encoders/qwen_2.5_vl_7b_fp8_scaled`、
  `vae/qwen_image_vae`；4 步加速 LoRA `Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16` 預設關閉，**未實測，保持關閉**。
- comfy-cli 1.20.0 讀得了這個範本，`comfy --json run --workflow <檔> --no-watch` 可直接送出。

## 欄位（改 UI 格式 JSON）

主要節點在子圖裡（`definitions.subgraphs[0]`，名稱 `Image Edit (Qwen-Image 2511 Int8)`）：

| 位置 | 節點 | 欄位（`widgets_values`） | 範本預設 |
|---|---|---|---|
| 頂層 `41` | `LoadImage` | `[檔名, "image"]`（檔要先在 input 資料夾） | 示範圖 |
| 子圖 `151` | `TextEncodeQwenImageEditPlus` | `[指令]` | `Convert this image to pop art poster style` |
| 子圖 `169` | `KSampler` | `[seed, "fixed", 步數, cfg, "euler", "simple", 1]` | 40 步、cfg 3 |
| 子圖 `168` | `PrimitiveBoolean` | `[false]`＝不開 4 步 LoRA | false |
| 頂層 `195` | `SaveImageAdvanced` | `[前綴, "png", "8-bit", "sRGB"]` | `Qwen_Edit_2511` |

- 子圖 `149` 是負面提示（空白），不用動。
- 輸出尺寸由 `FluxKontextImageScale` 自動縮放（實測 1024×1365 → 880×1184）。

## 參考速度（RTX 5060 Ti 16GB、40 步）

每張約 195–225 秒（含從 H3 換模型的載入）。跟 H3 交替使用時，**換模型前後都先清快取**：佇列清空後 `POST http://127.0.0.1:<埠>/free`，
body `{"unload_models": true, "free_memory": true}`（同 `models/minimax-h3.md`）。

## 指令寫法（實測）

- **指令寫中文**，先說要保留什麼、再說要改什麼，保留的東西逐項點名。
- **換裝（生活照 → 定妝照）**：`保持這個男人的長相、五官、臉型、髮型、髮際線和金屬圓框眼鏡完全不變，不要修改他的臉。`
  接著寫要換上的服裝（逐件）、體型、手上有沒有拿東西、新背景。4 個 seed **全部保住臉、髮際線與眼鏡**，服裝與背景都照改。
  要當 Ref2VA 參考圖時再裁「頭到腰帶下緣」：臉夠大，服裝重點也在畫面內。
- **畫格去人（做場景版）**：`把畫面中所有的人物完全移除，只留下空無一人的庭院。其他的東西全部保持原樣、位置完全不變：`
  加上逐項列出的物件，再寫 `人物原本站的位置補上原本的石板地面。畫面中沒有任何人，也沒有任何文字。`
  兩批各 2 個 seed，四張都把人移乾淨；但有一張把有花紋的窗花簡化成素面——**跟原圖並排比細節再挑**。
- 預設跑 2–4 個 seed 排隊，拼成對照圖給使用者挑。
