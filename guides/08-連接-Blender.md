---
title: 'AI Agent 懶人包 #08：連接 Blender 做 3D 建模'
date: '2026-09-21'
type: 懶人包
version: v0.1
status: 實測中
tags:
  - 懶人包
  - Blender
  - 3D 建模
  - bpy
---

# AI Agent 懶人包 #08：連接 Blender 做 3D 建模

> 版本：v0.1｜更新日期：2026-09-21｜主要適用：Claude Code、Codex；OpenCode、Antigravity 尚未實測

## 這份懶人包會幫你做什麼？

- 找出電腦已安裝的 Blender 與版本，不要求額外安裝 MCP
- 讓 Agent 產生可重現的 `bpy` 建模腳本，在 Blender 背景模式執行
- 從零建立模型，或讀取既有 `.blend` 後另存修改版
- 自動輸出 `.blend`、預覽 PNG、建模報告，以及選用的 glTF／STL 等交換格式
- 保留腳本與 log，讓模型可以重跑、檢查與逐次修改

第一版刻意不控制目前開啟中的 Blender 視窗。Blender 背景模式處理的是磁碟上的檔案；
如果場景只有畫面裡有、尚未儲存，本版不會碰它。

## 先備條件

- [ ] 已安裝 Blender；本版以 Blender 4.2 以上為目標，首次在 Windows Blender 5.2.2 驗證
- [ ] `uv` 可用（只負責啟動 runner；建模仍由 Blender 內建 Python 執行）
- [ ] 專案資料夾可寫入，並有足夠空間存放 `.blend`、貼圖與渲染結果
- [ ] 使用者知道模型用途、主要尺寸與需要的輸出格式

官方依據：Blender 以 Python Extension／Add-on 擴充功能，核心場景資料可由 `bpy` 存取；
官方也支援背景執行 Python，但參數會依出現順序處理。

- [Blender Python API](https://docs.blender.org/api/current/)
- [Blender 命令列參數](https://docs.blender.org/manual/en/latest/advanced/command_line/arguments.html)
- [Blender Extensions](https://docs.blender.org/manual/en/latest/advanced/extensions/index.html)

## 完成標準

- [ ] Agent 能回報 Blender 執行檔與版本
- [ ] 建模腳本與 log 存在專案 `blender/<工作>/`
- [ ] Blender 背景工作回傳成功
- [ ] `.blend`、預覽 PNG 與 `report.json` 都已產生
- [ ] Agent 實際查看預覽並檢查尺寸、穿插、鏡頭與材質
- [ ] 原始 `.blend` 未被覆蓋

## 執行原則（給 AI Agent）

- 預設路線是本機 Blender＋`bpy`，不安裝 MCP、不安裝第三方外掛、不用 Computer Use 點介面。
- 只處理使用者指定輸入與目前專案的 `blender/` 工作目錄。
- 修改既有檔一律另存；執行任意下載腳本、允許 `.blend` autoexec、下載資產或安裝外掛前先問。
- 輸出必須同時包含可重現腳本、`.blend`、預覽與結構化報告；exit code 0 不等於視覺驗收通過。
- 預估超過 5 分鐘的高解析渲染、動畫或模擬，先說明成本與停止方式。

## 步驟零：環境檢查

> 開始前先自動確認以下項目。任何一項不符合，先告知使用者問題所在並引導解決後再繼續。
> **不要跳過任何一項，不要假設環境正常。**

1. 確認作業系統（Windows / macOS / Linux）。
2. 執行 `uv --version`；找不到 `uv` 時，取得同意後交給 `agent-env-setup`，不擅自安裝。
3. 從已載入的 `agent-blender` 技能目錄執行：

   ```text
   uv run <技能目錄>/scripts/blender_runner.py detect
   ```

4. `ok` 必須為 true，並回報 `path` 與 `version`。
5. 找不到 Blender：請使用者自己安裝，或把 `BLENDER_PATH` 設為執行檔完整路徑後重試。
6. 檢查專案磁碟空間與 `blender/` 是否可寫。

> 全部通過後告知：「環境檢查完成，開始執行。」

## 步驟一：定義建模工作

先整理以下資訊，缺少但會改變成果方向時才詢問：

| 項目 | 例子 |
|---|---|
| 工作類型 | 新建模型／修改既有 `.blend` |
| 用途 | 示意圖、動畫、遊戲資產、3D 列印 |
| 尺寸與單位 | 120 × 60 × 75 cm、毫米 |
| 造型 | 寫實、低多邊形、工業、卡通 |
| 必要細節 | 倒角、孔洞、活動零件、材質 |
| 輸出 | `.blend`、PNG、glTF、STL |

## 步驟二：建立工作目錄

每個工作用自己的資料夾：

```text
blender/<工作-slug>/
├── build_scene.py
├── blender.log
├── output/
│   ├── <名稱>.blend
│   ├── <名稱>-preview.png
│   └── report.json
└── source/                 # 使用者提供的模型、貼圖或參考檔；沒有就不建
```

不得在技能安裝目錄裡產生工作成果，否則更新技能時可能被覆蓋。

## 步驟三：撰寫 bpy 腳本

新場景把技能內 `templates/scene-template.py` 複製為 `build_scene.py` 再修改；不要直接改全域技能副本。
修改既有場景先盤點物件與集合，透過穩定名稱或自訂屬性定位，不依賴目前 selection。

腳本至少要做到：

1. 明確設定單位、尺寸與座標。
2. 以穩定名稱建立或定位物件、材質、相機與燈光。
3. 結果另存到 `output/`，不覆蓋輸入檔。
4. 渲染至少一張可檢查比例與接觸面的 PNG。
5. 寫出 `report.json`，包含版本、物件、dimensions、引擎與輸出路徑。

## 步驟四：背景執行

新場景：

```text
uv run <技能目錄>/scripts/blender_runner.py run --script <工作目錄>/build_scene.py --timeout 900 --log <工作目錄>/blender.log -- --output-dir <工作目錄>/output --name <名稱>
```

修改既有場景：

```text
uv run <技能目錄>/scripts/blender_runner.py run --blend <輸入.blend> --script <工作目錄>/build_scene.py --timeout 900 --log <工作目錄>/blender.log -- --output-dir <工作目錄>/output --name <名稱>
```

runner 不用 shell 字串啟動程序，並在 Windows 隱藏背景視窗；預設加入 `--disable-autoexec`。
只有使用者明確信任輸入檔，而且內嵌 driver／Python 是任務必要條件時，才加 `--allow-autoexec`。

## 步驟五：驗收與迭代

1. 檢查 runner JSON：`ok: true`、`returncode: 0`、`timed_out: false`。
2. 確認 `.blend`、預覽與 `report.json` 存在且大小合理。
3. Agent 開啟預覽圖，檢查比例、穿插、懸浮、鏡頭裁切、材質、陰影與曝光。
4. 比對 `report.json` 的 dimensions 與需求。
5. 有問題就修改同一份 `build_scene.py` 並重跑；不可用口頭推測取代重新渲染。

## 步驟六：既有檔案與交換格式

- 原始 `.blend` 只讀取，結果永遠另存新檔。
- `.blend` 是主要交付檔；使用者需要跨工具交換時再額外輸出 glTF／STL／OBJ／USD。
- 3D 列印用途要額外檢查封閉性、非流形邊、最小厚度與實際單位。
- 遊戲資產要回報面數、材質數、貼圖路徑與座標軸；不要假設所有引擎的軸向與尺度相同。

## 依你的 Agent

| Agent | 第一版狀態 | 注意事項 |
|---|---|---|
| Claude Code | 目標支援 | 用 shell 執行同一支 runner；不要另建 Claude 專屬檔案 |
| Codex | 已在 Windows Blender 5.2.2 煙霧測試 | 使用實際技能路徑；本機 GUI 程序權限不足時先取得允許 |
| OpenCode | 尚未實測 | 理論上可走相同 Python／shell 流程，未驗證前不可宣稱支援完成 |
| Antigravity | 尚未實測 | 桌面 App 是否能執行本機程序要當場確認，不套用舊 IDE 行為 |

## 完成回報格式

```text
✅ Blender：<版本>（<執行檔>）
📦 工作：<新建／修改>，輸入 <路徑或無>
🧱 場景：<物件、尺寸與單位摘要>
🖼️ 預覽：<完整路徑>
💾 Blender：<完整路徑>
📤 交換格式：<完整路徑或未要求>
🧾 腳本／報告／log：<完整路徑>
🔐 autoexec：停用／經同意啟用
⚠️ 尚未完成：<無或原因>
```

## 如果失敗，如何重來

1. `detect` 失敗：確認 Blender 安裝位置，設定 `BLENDER_PATH` 後重跑。
2. runner 非零退出：先看 JSON 的 `stderr_tail`，再看完整 `blender.log`，不要重複盲跑。
3. Blender 開檔失敗：保留原檔，複製到短且純英文的專案路徑測試；仍失敗就回報版本與錯誤。
4. 腳本錯誤：依 traceback 修 `build_scene.py`；不要用 `--allow-autoexec` 當通用修復。
5. 渲染全黑或空畫面：檢查 active camera、燈光、曝光、物件 visibility 與相機 clipping。
6. 逾時：確認 Blender 行程已停止，降低解析度／採樣或拆小工作；不要同時啟動多份重試。

## 常見問題

| 問題 | 回答 |
|---|---|
| 為什麼不用 MCP？ | 兩個主要目標 Agent 都能直接產生檔案並執行本機程序，第一版少一層協定更容易驗證與復原。 |
| 為什麼不用 `pip install bpy`？ | 它是另一份 Blender runtime，版本與使用者安裝可能不同，也不會控制桌面上現有的 session。 |
| 可以修改目前畫面裡未存檔的場景嗎？ | 不行；先由使用者存檔，或後續另做 Blender Extension 即時橋接。 |
| 可以直接執行網路下載的 `.blend` 嗎？ | 可讀取，但維持 autoexec 停用；需要內嵌程式時先確認來源與風險。 |
| 為什麼一定要預覽？ | 建模腳本成功不代表比例、材質、接觸與鏡頭正確，必須查看實際渲染。 |

## 更新紀錄

| 版本 | 日期 | 內容 |
|---|---|---|
| v0.1 | 2026-09-21 | 初版：Blender 偵測、背景執行器、場景範本、安全規則與 Windows 5.2.2 煙霧測試 |
