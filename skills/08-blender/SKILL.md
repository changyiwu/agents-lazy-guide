---
name: agent-blender
description: 用本機 Blender 與 bpy 建立、修改、渲染及匯出 3D 場景。使用者提到 Blender、3D 建模、修改 blend 檔、程序化模型或渲染預覽時載入。
---

# 用 Blender 做 3D 建模

完整教學見 `guides/08-連接-Blender.md`。本技能第一版以 **Blender 背景模式＋`bpy` 腳本**工作，
不依賴 MCP，也不控制目前開啟中的 Blender 視窗或未儲存場景。

## 附屬檔

| 檔案 | 何時使用 |
|---|---|
| `scripts/blender_runner.py` | 每次偵測或執行 Blender 都使用；輸出固定為 JSON |
| `templates/scene-template.py` | 從零建立場景時複製到專案工作目錄再修改，不可直接改技能副本 |
| `references/bpy-modeling.md` | 撰寫或審查建模腳本前讀，尤其是修改既有 `.blend` 時 |

## 步驟

1. **確認需求**：辨識是新建或修改既有 `.blend`，取得尺寸與單位、風格、用途、輸出格式及必要視角。
   資訊已足夠就直接做；會實質改變模型方向的缺口才詢問。
2. **偵測環境**：執行 `uv --version`，再從本技能實際載入路徑執行：

   ```text
   uv run <技能目錄>/scripts/blender_runner.py detect
   ```

   找不到 `uv` 時，取得同意後交給 `agent-env-setup` 安裝；不要自行換一套環境管理方式。
   `ok` 不是 true 就停下。Blender 未安裝時請使用者自行安裝；已安裝但找不到時，請使用者設定
   `BLENDER_PATH` 為執行檔完整路徑。不要改用 `pip install bpy` 取代本機 Blender。
3. **建立工作目錄**：在目前專案建立 `blender/<工作-slug>/`，至少放 `build_scene.py`、輸出、預覽與 log。
   不可把工作檔寫進全域技能目錄。修改既有檔時保留原檔，只把它當輸入，結果另存新檔。
4. **撰寫腳本**：先讀 `references/bpy-modeling.md`。新場景複製 `templates/scene-template.py` 後修改；
   既有場景則寫專用腳本，使用穩定物件名稱或自訂屬性定位目標，不靠目前選取狀態。
   腳本必須輸出 `.blend`、至少一張預覽 PNG 與 `report.json`；報告包含 Blender 版本、物件清單、尺寸與輸出路徑。
5. **執行前預檢**：列出輸入 `.blend`、腳本、輸出目錄與可能覆蓋的生成檔。
   使用者已明確要求用 Blender 完成目前工作，視為同意首次執行；否則先問。
   高解析渲染、長動畫或預估超過 5 分鐘的工作要先說明成本。
6. **背景執行**：新場景使用：

   ```text
   uv run <技能目錄>/scripts/blender_runner.py run --script <build_scene.py> --timeout 900 --log <blender.log> -- --output-dir <輸出目錄> --name <名稱>
   ```

   修改既有場景時在 `run` 後加 `--blend <輸入.blend>`。路徑一律傳完整路徑；不要自行拼接 shell 字串。
   runner 預設加入 `--disable-autoexec`，只有使用者明確信任該 `.blend` 且確實需要其內嵌 Python／driver 時，
   才可加 `--allow-autoexec`。
7. **驗收**：`ok` 必須為 true；確認 `.blend`、PNG、`report.json` 都存在，再查看預覽圖。
   檢查比例、穿插、懸浮、鏡頭裁切、材質與光照。失敗時先讀 JSON 的 `stderr_tail` 與完整 log，修腳本後重跑；
   不可只因程序 exit 0 就宣告模型正確。
8. **迭代與交付**：同一工作目錄內可覆蓋 agent 自己產生的中間輸出；換輸入檔或會覆蓋使用者既有成果時重新確認。
   最後交付 `.blend`、預覽與使用者指定的交換格式，並保留建模腳本以便重現。

## 目前不支援的情境

- 要即時操作已開啟、含未儲存修改的 Blender：說明本版只處理磁碟上的檔案，建議另做 Blender Extension 橋接；
  不要自動改用 Computer Use 點擊介面。
- 要使用第三方外掛：先列出名稱、來源與必要性，取得同意後才安裝；外掛不是本技能的預設依賴。

## 安全規則

- 不覆蓋輸入 `.blend`；預設另存到專案的 `blender/<工作>/`。
- `.blend` 可含自動執行內容；runner 預設停用。不得為了消除錯誤擅自加 `--allow-autoexec`。
- `bpy` 腳本可讀寫本機檔案。只允許腳本存取使用者指定輸入與目前專案的工作目錄，不碰其他資料夾。
- 下載模型、材質、HDRI，安裝 Blender 或外掛前先說明來源、大小與授權並取得同意。
- 刪除檔案、清除既有場景內容、覆蓋使用者成果前再次確認。
- 不啟動本機網路服務、不開放監聽埠；若未來改走 HTTP／WebSocket，另行設計與授權。

## 復原

背景工作失敗時保留 `build_scene.py` 與 log，修正後重跑；不要刪除原始 `.blend`。
要取消長工作時只停止這次 runner 啟動的 Blender 行程。生成內容都在專案 `blender/<工作>/`；
使用者確認後才可刪除整個工作目錄。技能本身不修改 Blender 偏好設定，也不需要解除全域設定。

## 回報

回報 Blender 執行檔與版本、工作類型（新建／修改）、輸入檔、建模腳本、物件與尺寸摘要、
渲染引擎與耗時、輸出 `.blend`／預覽／交換格式的完整路徑、是否允許 autoexec、未完成項目與原因。
