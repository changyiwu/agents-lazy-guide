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

| 地址 | 欄位 | 範本預設 |
|---|---|---|
| `37.caption` | 風格描述，依序寫 Global Metadata → Vocal Details → Arrangement | lo-fi hip-hop 範例 |
| `37.lyrics` | 歌詞；`[Intro]` `[Verse]` `[Chorus]` `[Bridge]` `[Outro]` `[Instrumental]` 標籤決定段落結構 | 英文範例 |
| `37.max_duration` | 長度（秒），最長約 300 | 60 |
| `37.seed` | seed | 固定值 |
| `35.filename_prefix` | 輸出檔名，含 `audio/` 子資料夾（mp3 V0） | `audio/audio_minimax_music3` |

- 風格描述與歌詞很長，照 `SKILL.md` 步驟 7 的原則改 API 格式 JSON，不要塞進指令列。
- 範本有分塊解碼（Tiled decode）選項：長歌 VRAM 不夠時用，稍慢、分塊接縫可能有痕跡。

## 實測（RTX 5060 Ti 16GB、系統記憶體 62 GB、ComfyUI 0.35.1）

範本預設（只改檔名），60 秒歌總耗時 **140 秒**：文字編碼器逐 token 生成（紀錄的 `AR sampling`）1501 token 52 秒 →
DiT 30 步 75 秒（2.53 秒/步）→ 解碼約 5 秒。系統記憶體最少剩 29 GB。
產出 mp3 60.0 秒、44.1 kHz 立體聲、1.96 MB。**agent 聽不到**，請使用者自己聽。
