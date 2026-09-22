# Blender Lab 官方 MCP

即時操作 Blender、首次設定、連線失敗或需要判斷 MCP 安全界線時讀本檔。官方專案要求 Blender 5.1 以上。

## 架構與選用

```text
Codex / MCP client --stdio--> blender-mcp --TCP localhost:9876--> Blender MCP add-on --> bpy
```

- MCP 適合：目前 GUI 場景盤點、逐輪修改、截圖、參考圖對形、保留使用者手動調整。
- 背景 runner 適合：無人值守、批次、CI、可重現整場建立，或 client 尚未載入 MCP。
- 兩者都使用 Blender 的 `bpy`；MCP 是互動入口，不取代作品資料夾內的可重現腳本與 checkpoint。

## 一次性安裝

安裝前必須告知：官方 MCP 會讓 client 傳入 Python，並在 Blender 權限下執行。取得同意後：

1. Blender Preferences → Extensions → Repositories 加入 `https://lab.blender.org/`。
2. 從 Blender Lab 安裝並啟用 `MCP` extension。
3. 安裝官方 server：

   ```text
   uv tool install "git+https://projects.blender.org/lab/blender_mcp.git#subdirectory=mcp"
   ```

4. 註冊 Codex：

   ```text
   codex mcp add blender -- <blender-mcp 執行檔完整路徑>
   codex mcp list
   ```

5. 重啟 Codex／MCP client。新增 server 不會自動出現在已開始的舊 session。

Windows 若 Blender 全域 Online Access 維持關閉，可只在本次啟動暫時開啟：

```text
blender.exe --online-mode --disable-autoexec <場景.blend>
```

外掛預設 Auto Start、host `localhost`、port `9876`。不要改成 `0.0.0.0`、區網 IP 或公開介面。

## 操作順序

1. 先確認 client 已載入 `blender` MCP，且 Blender 的 MCP extension 顯示 Server is running。
2. 優先用 `get_objects_summary`、`get_object_detail_summary` 盤點，不先執行任意 Python。
3. 用 `get_screenshot_of_window_as_image`、`get_screenshot_of_area_as_image` 或
   `render_viewport_to_path` 查看實際畫面。
4. 修改前另存 checkpoint；以 `execute_blender_code` 執行小段、單一目的程式碼。程式碼必須自行
   `import bpy`，官方執行 namespace 不會預先注入 `bpy`。
5. 修改後再取摘要與固定視角預覽；不符合就回到上一個 checkpoint 或執行反向修正。
6. 要保留的修改另存新 `.blend`，並把可重現程式碼保存到作品資料夾，不只留在對話紀錄。

官方另有 `execute_blender_code_for_cli` 可對檔案執行背景工作；需要完整可重現命令、timeout 與 log 時，
仍優先使用本技能的 `blender_runner.py`。

## 連線檢查

```powershell
codex mcp list
Get-NetTCPConnection -LocalPort 9876 -State Listen
```

若沒有 listener：

1. 確認 Blender 5.1+、extension 已啟用，場景正在 GUI 中開啟。
2. 確認 Online Access；若不想永久開啟，以上述 `--online-mode` 啟動。
3. 在 extension 偏好中確認 Auto Start，或按 `Start MCP Bridge Server`。
4. 若 MCP 是剛註冊，重啟 client；若只有 Blender 重啟，不必重裝 server。
5. 仍失敗時保留 Blender console 錯誤，切換背景 runner；不可另開非官方公開網路 bridge。

## 安全界線

- `execute_blender_code` 不是沙箱。程式碼可讀寫 Blender 能存取的檔案與系統資源。
- 只接受本機 `localhost:9876`；不做 port forwarding，不在不受信任網路暴露。
- 不把密碼、token、個資或未公開資產放進程式碼、場景文字區塊或 log。
- 先讀後寫；不確定上次命令是否成功時先重新 inspect，避免重複 Boolean、複製或刪除。
- 刪除物件、清空集合、覆蓋檔案、安裝第三方 extension 前，必須得到針對該動作的明確同意。

## 官方資料

- Blender Lab MCP：https://www.blender.org/lab/mcp-server/
- 原始碼與 issue：https://projects.blender.org/lab/blender_mcp
- OpenAI MCP 設定：https://learn.chatgpt.com/docs/extend/mcp?surface=cli
