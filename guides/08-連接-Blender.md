---
title: 'AI Agent 懶人包 #08：連接 Blender 做 3D 建模'
date: '2026-09-22'
type: 懶人包
version: v0.3
status: 實測中
tags:
  - 懶人包
  - Blender
  - 3D 建模
  - MCP
  - bpy
---

# AI Agent 懶人包 #08：連接 Blender 做 3D 建模

> 版本：v0.3｜更新日期：2026-09-22｜主要適用：Codex；Claude Code、OpenCode、Antigravity 待實測

## 這份懶人包會幫你做什麼？

- 用 Blender Lab 官方 MCP 即時查看和修改目前 Blender GUI 場景
- 用背景 `bpy` runner 建立可重現、可批次執行的 `.blend`、預覽與交換格式
- 從零建模或讀取既有 `.blend` 後另存修改版
- 用固定 Front／Side／Back／Hero45 視角反覆比對輪廓與比例
- 保留腳本、checkpoint、預覽、報告與安全紀錄

## 為什麼是 MCP＋CLI 雙軌？

| 需求 | 建議方式 |
|---|---|
| 操作目前開啟的 GUI 場景 | 官方 MCP |
| 參考圖對形、多輪細修、保留手動修改 | 官方 MCP |
| 一次生成、批次渲染、CI、可重跑整場 | 背景 runner |
| client 尚未重啟、MCP 暫時不可用 | 背景 runner |

MCP 負責互動入口，`bpy` 才是實際建模 API。背景 runner 不是次等方案，而是可重現工作的可靠備援。

## 先備條件與風險

- Blender 5.1 以上；本版在 Windows Blender 5.2.2 LTS 驗證
- `uv` 與可執行本機程序的 agent
- 工作目錄可寫入，且有足夠空間保存 `.blend`、貼圖與渲染
- 使用者已知道：官方 MCP 會在 Blender 權限下執行 LLM 產生的 Python

Blender 官方因此建議只在受信任、無敏感資料的環境使用。外掛只綁 `localhost:9876`，不可改成區網或
公開介面。安裝／啟用前要先說明並取得同意。

官方資料：

- [Blender Lab MCP](https://www.blender.org/lab/mcp-server/)
- [Blender MCP 原始碼](https://projects.blender.org/lab/blender_mcp)
- [Blender Python API](https://docs.blender.org/api/current/)
- [OpenAI MCP 設定](https://learn.chatgpt.com/docs/extend/mcp?surface=cli)

## 步驟零：環境檢查

1. 執行 `uv --version`。
2. 從技能目錄執行：

   ```text
   uv run <技能目錄>/scripts/blender_runner.py detect
   ```

3. `ok` 必須為 true，並回報 Blender 路徑與版本。
4. 找不到 Blender 就設定 `BLENDER_PATH` 或請使用者安裝；不要用 `pip install bpy` 代替桌面 Blender。

## 步驟一：安裝 Blender Lab 官方外掛

1. Blender Preferences → Extensions → Repositories。
2. 加入 `https://lab.blender.org/`，同步後安裝 `MCP`。
3. 啟用 extension，保持 host `localhost`、port `9876`、Auto Start 開啟。
4. 若全域 Online Access 維持關閉，啟動本次 Blender 時加：

   ```text
   blender.exe --online-mode --disable-autoexec <場景.blend>
   ```

`--online-mode` 只處理這次啟動，不必永久開啟全域 Online Access。

## 步驟二：安裝 MCP server 並註冊 Codex

```text
uv tool install "git+https://projects.blender.org/lab/blender_mcp.git#subdirectory=mcp"
codex mcp add blender -- <blender-mcp.exe 完整路徑>
codex mcp list
```

新增 server 後要重啟 Codex。桌面 App、CLI 和 IDE 共用 MCP 設定，但已開始的 session 不會動態增加工具。

## 步驟三：建立作品目錄

```text
blender/<工作-slug>/
├── scene.blend
├── build_scene.py
├── checkpoints/
├── previews/
├── blender.log
└── report.md
```

不得在技能安裝目錄產生作品。修改既有 `.blend` 時原檔只作輸入，輸出另存。

## 步驟四：MCP 即時操作

1. 先確認 Blender extension 顯示 Server is running，並檢查 `localhost:9876`。
2. 用 `get_objects_summary` 盤點場景，再用 `get_object_detail_summary` 查目標。
3. 用視窗／區域 screenshot 或 `render_viewport_to_path` 看實際畫面。
4. 修改前另存 checkpoint。
5. 用 `execute_blender_code` 執行小段、單一目的程式碼；每段自行 `import bpy`，不要一段完成整場重建。
6. 修改後重新取得摘要與預覽，實際看過才算通過。
7. 把可重現的程式碼保存為作品內 `.py`，不可只留在對話紀錄。

不能確定前一個命令是否執行時，先 inspect，不可盲目重送可能重複複製、Boolean 或刪除的命令。

## 步驟五：背景 runner

新場景：

```text
uv run <技能目錄>/scripts/blender_runner.py run --script <工作>/build_scene.py --timeout 900 --log <工作>/blender.log -- --output-dir <工作>/output --name <名稱>
```

修改既有場景：

```text
uv run <技能目錄>/scripts/blender_runner.py run --blend <輸入.blend> --script <工作>/build_scene.py --timeout 900 --log <工作>/blender.log -- --output-dir <工作>/output --name <名稱>
```

runner 預設 `--disable-autoexec`。只有使用者明確信任輸入檔，而且 driver／內嵌 Python 是必要功能時，
才加 `--allow-autoexec`。

## 步驟六：參考圖精細建模

1. 校正 Front／Side／Back／Hero45 四個固定相機或 image empty。
2. 標記身高、頭頂、下巴、肩、骨盆、膝、踝與足底基準。
3. 依「輪廓比例 → 主要曲面 → 關節 → 面板分件 → 細節材質」逐層修改。
4. 每輪只修一層，固定四視角渲染，記錄最明顯三個差異。
5. 一層通過就另存 checkpoint，再進下一層。

商品頁圖片只作視覺參考；不得下載、解包或重用付費 mesh。來源與授權寫入 `report.md`。

## 完成標準

- Blender 路徑、版本與使用模式已回報
- MCP 模式能讀取場景摘要與畫面；或背景 runner 回傳成功
- 原始 `.blend` 未覆蓋，成果 `.blend` 與 checkpoint 存在
- Front／Side／Back／Hero45 已實際查看並記錄差異
- 可重現腳本、預覽、report 與要求的交換格式齊全
- autoexec、資產來源、授權與未完成項目有記錄

## 常見失敗

| 現象 | 處理 |
|---|---|
| MCP 工具未出現在 client | `codex mcp list` 後重啟 Codex |
| 9876 沒有 listener | 檢查 extension、Online Access、Auto Start，必要時在偏好中按 Start |
| MCP 命令逾時 | 先 inspect 判斷是否已執行，不盲目重送 |
| runner 非零退出 | 看 `stderr_tail` 與 `blender.log`，修腳本後重跑 |
| 預覽全黑或空白 | 檢查 active camera、燈光、曝光、visibility 與 clipping |
| 外觀不像參考 | 先修輪廓與比例，不用更多微小零件掩蓋大形錯誤 |

## 依你的 Agent

| Agent | 狀態 | 注意事項 |
|---|---|---|
| Codex | 官方 MCP 註冊與背景 runner 已在 Windows Blender 5.2.2 驗證 | 新增 MCP 後需重啟 task/client |
| Claude Code | 待實測 | 使用該 client 的 stdio MCP 設定；不可直接照抄 Codex 指令宣稱完成 |
| OpenCode | 待實測 | 先確認本機 MCP 設定格式與權限 |
| Antigravity | 待實測 | 先確認桌面 App 是否支援本機 stdio MCP |

## 更新紀錄

| 版本 | 日期 | 內容 |
|---|---|---|
| v0.1 | 2026-09-21 | Blender 偵測、背景 runner、場景範本與安全規則 |
| v0.2 | 2026-09-21 | 實驗性專案檔案佇列 GUI bridge；未安裝到正式副本 |
| v0.3 | 2026-09-22 | 改採 Blender Lab 官方 MCP 作即時主線，背景 runner 作可重現備援 |
