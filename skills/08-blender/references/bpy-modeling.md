# bpy 建模實作準則

只在撰寫、修改或審查 Blender Python 建模腳本時讀本檔。API 細節以實際安裝版本的
[Blender Python API](https://docs.blender.org/api/current/) 為準。

## 可重現性

- 每個工作使用獨立資料夾，保存腳本、輸出、預覽與 log。輸出檔名要穩定且能看出工作名稱。
- 明確設定單位、尺寸、座標、相機、燈光、渲染引擎與解析度，不依賴使用者的啟動場景。
- 物件、材質、集合、Geometry Nodes 與相機都用有意義且穩定的名稱；需要跨次定位時加自訂屬性。
- 新場景可從 factory startup 清空；修改既有檔時只處理目標集合或帶標記的物件，不可整場刪除。
- 腳本重跑時應得到相同結果。隨機程序要固定 seed，時間或機器名稱不可進入幾何計算。

## API 選擇

- 能用 `bpy.data` 或 `bmesh` 完成時優先使用；`bpy.ops` 依賴 mode、active object、selection 與 area context，
  使用前要明確設定上下文，不能假設使用者目前選了什麼。
- 建立 modifier 前先確認物件 scale 是否該套用；Bevel、Array、Boolean 等對未套用 scale 的結果可能不同。
- Boolean 後檢查法線、非流形邊與退化面。要交付列印模型時，額外檢查封閉性、厚度與實際單位。
- 不直接解析或修改 `.blend` 二進位格式；一律由相符版本的 Blender／`bpy` 讀寫。

## 材質與資產

- 材質用 nodes 並直接取得命名節點，不靠節點順序。顏色傳入 Blender 時使用 RGBA 四值。
- 貼圖、HDRI、字型與外部模型保留授權與來源；下載前先取得同意。交付前檢查外部路徑是否失效。
- 需要可攜檔案時，依使用者要求決定 pack resources 或連同資產資料夾交付；不要擅自膨脹 `.blend`。

## 修改既有場景

- runner 預設 `--disable-autoexec`。只有使用者明確信任檔案且 driver／內嵌腳本是工作必要條件，才允許 autoexec。
- 原始 `.blend` 永遠只當輸入；腳本用 `bpy.ops.wm.save_as_mainfile()` 寫到專案的新路徑。
- 先輸出場景盤點：物件、集合、材質、連結資產、單位、渲染引擎與相機，再決定修改方式。
- 若依名稱找不到唯一目標就停下，不可猜一個最像的物件直接修改。

## MCP 即時修改程式碼

- 每支修正腳本只負責一個可描述的變更，並能在執行前檢查必要物件；不要把整個模型重建塞進每一輪。
- 程式碼由官方 MCP 在已開啟的 Blender session 直接執行，不可清空整個場景，也不要依賴命令列 `sys.argv`。
- 每個獨立 MCP 程式碼片段都要明確 `import bpy`；執行 namespace 不保證預先注入 Blender 模組。
- 使用穩定名稱或 `agent_id` 自訂屬性定位物件；找不到唯一目標時拋出錯誤，讓 MCP result 保留 traceback。
- 需要大量拓樸運算時，先存 checkpoint；修改後更新 view layer，讓下一次 inspect 與 render 看到最新結果。

## 驗收

- `report.json` 至少包含 Blender 版本、輸出路徑、render engine、物件類型、位置與 dimensions。
- 至少渲染一張能看出比例與接觸面的預覽；容易遮蔽或具有內部結構的模型要增加視角或剖面圖。
- 檢查：比例、穿插、懸浮、法線、鏡頭裁切、材質遺失、過曝／全黑、物件數量與輸出格式。
- 程序成功只代表腳本沒拋例外；視覺與幾何驗收仍不可省略。
