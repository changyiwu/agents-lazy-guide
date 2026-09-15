# MiniMax Music 3（音樂）

本檔隨 `agent-comfyui` 安裝，由 `SKILL.md`〈模型筆記〉指向。完整說明見 `guides/07-連接-ComfyUI.md` 步驟九。

範本 `audio_minimax_music_3`：由風格描述與歌詞生成含人聲的完整歌曲，最長約 5 分鐘。

## 檔案（都放得進 16GB）

| 資料夾 | 檔案 | 大小 |
|---|---|---|
| `diffusion_models` | `minimax_music3_dit_fp16.safetensors`（2.5B） | 4.58 GB |
| `text_encoders` | `minimax_music3_text_encoder_pruned_int8_convrot.safetensors`（8.4B） | 8.57 GB |
| `vae` | `minimax_music3_dav.safetensors` | 0.20 GB |

範本另列的 `minimax_music3_dit_int8_convrot` 是小顯卡的替代版，16GB 不需要；未滿 16GB 未實測。

## 欄位（實測地址）

| slots 地址 | API 格式節點 | 欄位 | 範本預設 |
|---|---|---|---|
| `37.caption` | `37:13` | 風格描述，依序寫 Global Metadata → Vocal Details → Arrangement | lo-fi hip-hop 範例 |
| `37.lyrics` | `37:13` | 歌詞；`[Intro]` `[Verse]` `[Chorus]` `[Bridge]` `[Outro]` `[Instrumental]` 標籤決定段落結構 | 英文範例 |
| `37.max_duration` | `37:13` | 長度（秒），最長約 300 | 60 |
| `37.seed` | `37:38` | seed | 固定值 |
| `35.filename_prefix` | `35` | 輸出檔名，含 `audio/` 子資料夾（mp3 V0） | `audio/audio_minimax_music3` |

- 風格描述與歌詞很長，照 `SKILL.md` 步驟 7 的原則改 API 格式 JSON，不要塞進指令列。
- 範本有分塊解碼（Tiled decode）選項：長歌 VRAM 不夠時用，稍慢、分塊接縫可能有痕跡。

## 風格描述要點

- 描述用英文、歌詞用中文可以直接產出：Vocal Details 寫明 `singing in Mandarin Chinese`，歌詞直接寫繁體中文。
- **沒有音高、力度的數值欄位**，只能改描述與 seed：
  - 更高：Global Metadata 的調性往上移（實測 E minor → A minor → C sharp minor），並寫最後一段再升一個全音；
    Vocal Details 寫明唱在男聲音域最頂端、結尾拉長高音。
  - 更有力：Vocal Details 寫明主歌就用胸聲、`never soft or breathy`，副歌 `belted with maximum power`、峰值帶沙啞；
    Arrangement 同步加重鼓、失真吉他與弦樂。
  - 換旋律：換 seed，可一併改速度（BPM）與編曲。
- 使用者說「參考某位歌手」時，查該歌手的聲音特點寫成描述，**不在描述裡寫真實人名**。
- **agent 聽不到**，每一版都請使用者聽過再決定怎麼改。

## 實測（RTX 5060 Ti 16GB、系統記憶體 62 GB、ComfyUI 0.35.1）

| | 60 秒（範本預設，只改檔名） | 120 秒（中文歌詞，三版） |
|---|---|---|
| 文字編碼器逐 token 生成（紀錄的 `AR sampling`） | 1501 token，52 秒 | 3001 token，105 秒 |
| DiT 30 步 | 2.53 秒/步，75 秒 | 5.2–5.4 秒/步，155–161 秒 |
| 總耗時 | 140 秒 | 286–288 秒 |
| 產出 mp3（44.1 kHz 立體聲） | 60.0 秒、1.96 MB | 120.0 秒、3.8–4.0 MB |

- 兩段耗時都跟長度成正比，估時間抓「每秒歌約 2.4 秒」。改風格描述不影響速度。
- 60 秒時系統記憶體最少剩 29 GB；120 秒未量。
