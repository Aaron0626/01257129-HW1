# 長生採藥 Snake Game (SwiftUI)

![Baizhu 下午5 18 47](https://github.com/user-attachments/assets/16b410b6-7c57-40a9-babe-7cd101eece80)

一款以 SwiftUI 製作的經典貪食蛇變體遊戲。玩家扮演「長生」，穿梭於棋盤收集不同顏色的藥材，身體顏色會隨著收集比例逐步變化。提供兩種模式：
- 普通版「採集藥材」：越收集，身體越繽紛。
- 進階版「黑毒之解」：中毒狀態起始，收集藥材讓身體逐步恢復。

支援分數與最高分紀錄、暫停/倒數/結束覆蓋層、食物壽命與閃爍提示、難度切換與對應背景音樂。

## 功能特色

- 兩種難度模式
  - 普通版：收集藥材後，蛇身顏色朝著該藥材的主色增強。
  - 進階版：中毒狀態起始，收集藥材會「反向」調整色彩通道，逐步恢復。
- 動態蛇身顏色
  - 依玩家收集的紅/綠/藍藥材比例，蛇身 RGB 通道會逐步調整。
- 食物壽命與閃爍提示
  - 食物有 12 秒壽命；剩餘 3 秒內會以固定頻率閃爍，提示即將消失。
- 操作方式
  - 支援滑動手勢（上下左右）。
  - 亦提供畫面方向按鈕（DirectionPad）。
- 遊戲狀態管理
  - 開場倒數 5 秒、暫停覆蓋層、結束覆蓋層（顯示分數與最高分）。
- 最高分紀錄
  - 使用 @AppStorage 分別記錄普通/進階模式最高分。
- 背景音樂
  - 主選單與不同難度對應不同 BGM，支援淡入/淡出（BGMManager.swift）。

## 畫面一覽

- 主選單：選擇難度，右下角可開啟「遊戲簡介」與「歷史紀錄」。
<img width="352" height="702" alt="截圖 2025-09-24 下午6 37 59" src="https://github.com/user-attachments/assets/5751227b-3ce5-4e43-bb17-4ec529574045" />
<img width="365" height="706" alt="截圖 2025-09-24 下午6 38 16" src="https://github.com/user-attachments/assets/4af6d7e2-a6d2-4a12-80f5-883e9de374e4" />
<img width="342" height="698" alt="截圖 2025-09-24 下午6 38 24" src="https://github.com/user-attachments/assets/2b738384-2ba7-45d0-8140-61f75f2ff3bc" />

- 遊戲畫面：上方顯示分數與最高分，中段為棋盤，底部顯示收集統計與操作按鈕。
<img width="362" height="702" alt="截圖 2025-09-24 下午6 35 30" src="https://github.com/user-attachments/assets/b667353a-275a-4478-8fc3-51e40c724dcb" />

- 覆蓋層：倒數、暫停、結束畫面。
<img width="368" height="708" alt="截圖 2025-09-24 下午6 38 31" src="https://github.com/user-attachments/assets/84408049-6099-480e-8725-93ece93842d0" />
<img width="349" height="700" alt="截圖 2025-09-24 下午6 38 47" src="https://github.com/user-attachments/assets/3d76aedf-8eae-4286-accf-34f96898ba0f" />
<img width="354" height="705" alt="截圖 2025-09-24 下午6 38 56" src="https://github.com/user-attachments/assets/2c25bec1-3e34-4cf7-b3cd-cf5fa1639dcb" />

## 專案結構（節錄）

- ContentView.swift
  - SnakeRootView：主流程控制（主選單/遊戲切換、BGM 切換）。
  - StartScreen：難度選擇、遊戲簡介與歷史紀錄入口。
  - SnakeGameView：核心玩法（蛇移動、食物壽命與閃爍、分數與加速、碰撞判定）。
  - GameIntroView / HistoryView / GameOverOverlay / PauseOverlay / CountdownOverlay / DirectionPad / GridOverlay：相關 UI 元件與輔助視圖。
  - Color+RGB：顏色通道解析輔助。
- BGMManager.swift
  - 以 AVAudioPlayer 實作的 BGM 播放、淡入/淡出、暫停/恢復控制。

## 安裝與執行

1. 需求
   - Xcode 15 或以上
   - iOS 17（或對應的 SwiftUI 版本；如需更低版本請自行調整 API）
2. 取得專案
   - 將本專案 clone 或下載到本機後，使用 Xcode 開啟 .xcodeproj。
3. 資源配置
   - 字型：請確認已將「ChenYuluoyan-2.0-Thin」加入專案並在 Info.plist 的 Fonts provided by application 中註冊。
   - 圖片資源：請確認以下影像已加入 Asset Catalog，名稱需一致：
     - "Image 7", "Image 5", "Image 6", "Image 8", "Image 9",
       "Image 3", "Image 1", "Image 2", "Image 12", "Image 10", "Image 11", "Image", "Image 13", "Image 14"
   - 音樂資源：
     - 專案目前不隨倉庫附帶 mp3（避免超過 GitHub 100MB 限制）。請參考下方「音樂來源與加入方式」自行加入檔案。
4. 執行
   - 在 Xcode 中選擇目標裝置（模擬器或真機），按下 Run 即可。

## 音樂來源與加入方式
- 本專案預期的檔名：
  - 主選單：music1.mp3
  - 普通版：music2.mp3
  - 進階版：music3.mp3

- 音樂來源（YouTube）：
  - 主選單 BGM（music1.mp3）：https://youtu.be/-zGkld42Hdg?si=wPE7Qk2NdZHX-sPt
  - 普通版 BGM（music2.mp3）：https://youtu.be/QFMVNoRHVhI?si=C8FXS_VjcsqnE3an
  - 進階版 BGM（music3.mp3）：https://youtu.be/l2qHL3e7uuI?si=8r6PD7Y2iEeJ_89C

- 加入方式：
  1) 下載音源並轉成 mp3（建議 192kbps 或 256kbps，檔案保持在 100MB 以下）。
  2) 將檔案以上述檔名放入專案的根目錄資料夾（或直接拖曳進 Xcode 的專案樹）。
  3) 勾選「Copy items if needed」並加入目標 Target，確保檔案會被打包進 app bundle。

## 遊戲玩法

- 目標：操控長生收集盡可能多的藥材，並避免撞牆或撞到自己。
- 操作：
  - 滑動手勢：上下左右改變方向。
  - 底部方向按鈕：點按也可改變方向。
  - 禁止同一 tick 內直接反向（避免自撞）。
- 計分與加速：
  - 每吃到一顆食物 +1 分。
  - 每累積一定分數（accelerationEvery）會加速（tick 間隔縮短），不低於 minTick。
- 食物機制：
  - 棋盤上同時存在 1~3 顆食物（動態補充）。
  - 每顆食物壽命 12 秒；剩餘 3 秒內會以固定頻率閃爍。
- 結束條件：
  - 撞牆或撞到自己。
  - 結束後顯示分數、最高分與提示訊息，可選擇重新開始。

## 技術重點

- 純 SwiftUI 介面與互動。
- Timer 與 RunLoop（.common）驅動遊戲節奏。
- 狀態管理：
  - @State：遊戲狀態（蛇、食物、分數、暫停、倒數）。
  - @AppStorage：最高分持久化。
- 顏色系統：
  - Color 的 RGB 通道解析（支援 UIKit/AppKit）。
  - 依食物顏色調整蛇身色彩（普通/進階有不同策略）。
- 音效系統：
  - AVAudioPlayer + 定時器實作 BGM 淡入/淡出。
  - 依場景切換音樂（主選單/不同難度）。

## 已知事項

- 請確保所有圖片/字型/音樂資源名稱與專案程式一致。
- 若要支援更低的 iOS 版本，可能需調整部分 SwiftUI API 或可用性檢查。
- 若未加入 mp3，遊戲可正常運作但不會播放 BGM。

## 未來規劃

- 增加歷史記錄（例如顯示藥材比例對應的顏色）。
- 增加更多道具（加速/減速/護盾等）。
- 關卡或地形變化（障礙物/傳送門）。
- 排行榜（Game Center）。
- 觸覺回饋與音效效果（吃到食物、撞擊等）。
- 無障礙與在地化內容強化。
