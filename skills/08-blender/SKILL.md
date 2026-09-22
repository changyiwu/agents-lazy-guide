---
name: agent-blender
description: 用本機 Blender 與 bpy 建立、修改、即時迭代、渲染及匯出 3D 場景。使用者提到 Blender、3D 建模、修改 blend 檔、程序化模型、參考圖造型比對或渲染預覽時載入。
---

# 用 Blender 做 3D 建模

完整教學見 `guides/08-連接-Blender.md`。本技能以 Blender Lab 官方 MCP 操作已開啟的 Blender；
可重現批次、CI 或 MCP 不可用時，改用背景 `bpy` runner。

## 附屬檔

| 檔案 | 何時使用 |
|---|---|
| `scripts/blender_runner.py` | 每次偵測環境；背景批次執行也使用 |
| `references/official-mcp.md` | 即時控制、首次設定、連線失敗或安全判斷時先讀 |
| `references/bpy-modeling.md` | 撰寫或審查任何建模程式碼前讀 |
| `templates/scene-template.py` | 從零建立批次場景時複製到工作目錄 |

## 步驟

1. **確認需求**：辨識新建或修改既有 `.blend`，取得尺寸、用途、輸出格式、造型基準與必要視角。
   資訊已足夠就直接做；會實質改變成果方向的缺口才詢問。
2. **偵測環境**：執行 `uv --version`，再從本技能實際載入路徑執行：

   ```text
   uv run <技能目錄>/scripts/blender_runner.py detect
   ```

   `ok` 不是 true 就停下。不要以 `pip install bpy` 取代本機 Blender。
3. **建立工作目錄**：使用 `blender/<工作-slug>/`，保存腳本、source、output、預覽與 log。修改既有檔時
   原檔只作輸入，結果另存。
4. **選擇模式**：需要查看或反覆修改目前 GUI 場景、參考圖對形、保留手動調整時用官方 MCP；一次生成、
   批次渲染、CI 或無法重啟 MCP client 時用背景 runner。MCP 設定先讀 `references/official-mcp.md`。
5. **MCP 即時模式**：先用唯讀工具取得物件摘要、目標細節與視窗／區域截圖。修改前確認正確場景及目標，
   並另存 checkpoint；再以小段、單一目的的 `execute_blender_code` 修改。每輪重新 inspect、渲染和實看，
   不以 tool 成功回應代替視覺驗收。若工具不在目前 session，重啟 MCP client 後再用，不自行發明替代協定。
6. **背景模式**：先讀 `references/bpy-modeling.md` 並撰寫工作腳本，再執行：

   ```text
   uv run <技能目錄>/scripts/blender_runner.py run --script <腳本> --timeout 900 --log <log> -- --output-dir <輸出目錄> --name <名稱>
   ```

   修改既有場景時在 `run` 後加 `--blend <輸入.blend>`。runner 預設 `--disable-autoexec`；只有使用者明確
   信任該檔且內嵌 Python／driver 是必要功能時，才可加 `--allow-autoexec`。
7. **參考圖建模**：建立 Front、Side、Back、Hero45 四個固定相機或 image empty，校正身高、肩、骨盆、膝
   與足底基準。依「輪廓比例 → 主要曲面 → 關節 → 面板分件 → 細節材質」分階段，每輪只修一層。
   商品頁圖片只能作視覺參考；不可下載、解包或仿冒其付費 mesh。來源與授權寫入作品報告。
8. **視覺驗收**：每輪渲染固定四視角並實際查看。優先檢查輪廓、頭身比、肩胯寬、關節位置與負空間，
   再看面板線和材質。每輪記錄最明顯的三個差異，通過後另存 checkpoint。
9. **交付**：確認 `.blend`、預覽、report 與指定交換格式存在。保留可重現的基礎腳本及階段修正腳本；
   Blender GUI 由使用者決定何時關閉，不替使用者強制結束。

## 安全規則

- MCP 會在 Blender 內執行 LLM 產生的 Python，權限等同 Blender；首次安裝／啟用與改連線方式前先明確說明並取得同意。
- 官方 bridge 只綁定 `localhost:9876`；不可改為區網或公開介面，不把埠轉發到外網。
- 連線期間不處理機密資料；只執行當前工作所需的小型程式碼，先 inspect、checkpoint，再 mutate。
- 不覆蓋輸入 `.blend` 或使用者既有成果；輸出一律在目前專案，改輸入或覆蓋前重新確認。
- 不清空整場、不大量刪除、不執行來源不明程式碼；破壞性修改需使用者明確確認。
- 不啟用來源不明 `.blend` 的 autoexec；不下載資產或啟動付費服務，除非先說明並取得同意。
- 高解析渲染、動畫、模擬或預估超過 5 分鐘的工作先告知成本與停止方式。

## 復原與回報

MCP 失敗先確認 Blender 外掛、Online Access、`localhost:9876` 與 client 重啟狀態；不能確認命令是否執行時，
先 inspect，不可盲目重送。背景失敗保留腳本與 log 後修正重跑。輸入檔與前一個通過的 checkpoint 永遠保留。

回報 Blender 路徑與版本、MCP／背景模式、連線狀態、輸入檔、腳本、物件與尺寸摘要、四視角驗收結果、
渲染引擎與耗時、輸出 `.blend`／預覽／交換格式、autoexec 狀態、參考素材授權及未完成項目。
