import SwiftUI

// App 的主要入口視圖，顯示遊戲根視圖
struct ContentView: View {
    var body: some View {
        // 直接呈現遊戲的根視圖（包含起始畫面與遊戲畫面之切換邏輯）
        SnakeRootView()
    }
}

// 方向枚舉：控制蛇的移動方向
private enum Direction {
    case up, down, left, right
}
private let introFontName = "ChenYuluoyan-2.0-Thin" // 自訂字型名稱（需在專案中註冊）

// 難易度：普通版與進階版
// - 提供不同的初始速度、加速度頻率與最小速度等參數
private enum Difficulty: String, CaseIterable, Identifiable {
    case normal = "普通版 - [採集藥材]"
    case advanced = "進階版 - [黑毒之解]"

    var id: String { rawValue }

    // 棋盤行數
    var rows: Int {
        switch self {
        case .normal: return 20
        case .advanced: return 20
        }
    }
    // 棋盤列數
    var cols: Int {
        switch self {
        case .normal: return 20
        case .advanced: return 20
        }
    }
    // 初始一格移動的時間間隔（秒）
    var initialTick: Double {
        switch self {
        case .normal: return 0.30
        case .advanced: return 0.25
        }
    }
    // 每累積多少分就加速一次
    var accelerationEvery: Int {
        switch self {
        case .normal: return 5
        case .advanced: return 5
        }
    }
    // 每次加速減少的 tick 間隔
    var accelerationDelta: Double {
        switch self {
        case .normal: return 0.005
        case .advanced: return 0.005
        }
    }
    // 允許的最小 tick（不會比這更快）
    var minTick: Double {
        switch self {
        case .normal: return 0.06
        case .advanced: return 0.05
        }
    }
    // 遊戲結束提示訊息
    var endMessage: String {
        switch self {
        case .normal: return "今天收穫滿滿！嘶～"
        case .advanced: return "嘶～身體好了一點"
        }
    }
}

// 網格座標（x, y）
// - 用於蛇身各節、食物位置
private struct Point: Hashable, Equatable {
    var x: Int
    var y: Int
}

// App Root：負責顯示起始畫面(Start)或遊戲畫面(Playing)
// - 並處理背景音樂的切換（進入/離開遊戲）
private struct SnakeRootView: View {
    // App 階段：起始畫面或正在遊戲（帶有難度）
    enum AppPhase: Equatable { case start, playing(difficulty: Difficulty) }
    @State private var phase: AppPhase = .start

    var body: some View {
        ZStack {
            switch phase {
            case .start:
                // 起始畫面：選難度、看介紹、看歷史
                StartScreen { selected in
                    // 切換至遊戲前，先把主選單 BGM 淡出
                    BGMManager.shared.fadeOutAndStop(duration: 5)
                    phase = .playing(difficulty: selected)
                }
            case .playing(let difficulty):
                // 進入遊戲畫面
                SnakeGameView(difficulty: difficulty) {
                    // 從遊戲返回主選單，先淡出遊戲 BGM
                    BGMManager.shared.fadeOutAndStop(duration: 5)
                    phase = .start
                }
            }
        }
        .animation(.easeInOut, value: phase) // 切換畫面時的過場動畫
        .onAppear {
            // App 啟動時若在起始畫面，播放主選單 BGM（淡入）
            if case .start = phase {
                BGMManager.shared.playFileWithFadeIn(named: "music1", ext: "mp3", loops: -1, duration: 5, targetVolume: 1.0)
            }
        }
        .onChange(of: phase) { newValue in
            // 每次回到主選單時，重新播放主選單 BGM（淡入）
            if case .start = newValue {
                BGMManager.shared.playFileWithFadeIn(named: "music1", ext: "mp3", loops: -1, duration: 5, targetVolume: 1.0)
            }
        }
    }
}

// 起始頁（主選單）
// - 提供兩個難度按鈕
// - 右下角兩顆按鈕可呼叫遊戲簡介與歷史紀錄（用 sheet 呈現）
// - 上方標題使用自訂字型
private struct StartScreen: View {
    @State private var selected: Difficulty? = nil
    var isLocked: Bool = false // 可用來禁用按鈕（預留）
    var onSelect: (Difficulty) -> Void
    
    @State private var showingIntroSheet = false
    @State private var showingHistorySheet = false

    init(isLocked: Bool = false, onSelect: @escaping (Difficulty) -> Void) {
        self.isLocked = isLocked
        self.onSelect = onSelect
    }

    var body: some View {
        ZStack {
            // 背景圖（鋪滿）
            Image("Image 7")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer().frame(height: 8)

                // 小標題
                Text("選擇遊戲難易度")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.secondary)

                // 兩個難度按鈕
                VStack(spacing: 16) {
                    DifficultyButton(
                        difficulty: .normal,
                        subtitle: "隨著長生不斷收集草藥\n草藥的藥效逐漸被身體吸收。",
                        assetName: "Image 5",
                        systemImage: nil,
                        color: .green,
                        isSelected: selected == .normal,
                        disabled: isLocked
                    ) {
                        selected = .normal
                        onSelect(.normal)
                    }
                    DifficultyButton(
                        difficulty: .advanced,
                        subtitle: "長生誤中奇毒\n服用解毒草，觀察身體的變化",
                        assetName: "Image 6",
                        systemImage: "speedometer",
                        color: .blue,
                        isSelected: selected == .advanced,
                        disabled: isLocked
                    ) {
                        selected = .advanced
                        onSelect(.advanced)
                    }
                }
                .padding(.horizontal)

                // 鎖定狀態提示（若 isLocked 為真）
                if isLocked {
                    Text("準備中…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.top, 80)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 右下角兩顆功能按鈕：遊戲簡介、歷史紀錄
            VStack {
                Spacer()
                HStack {
                    Button {
                        showingIntroSheet = true
                    } label: {
                        Image("Image 13")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 45, height: 45)
                            .padding()
                            .background(
                                Color(red: 55/255, green: 76/255, blue: 100/255).opacity(0.5),
                                in: Circle()
                            )
                    }
                    
                    Spacer()
                    
                    Button {
                        showingHistorySheet = true
                    } label: {
                        Image("Image 14")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 45, height: 45)
                            .padding()
                            .background(
                                Color(red: 55/255, green: 76/255, blue: 100/255).opacity(0.5),
                                in: Circle()
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .zIndex(10)

            // 上方大標題（自訂字型）
            VStack {
                HStack {
                    Text("🐍長生採藥🌿")
                        .font(.custom(introFontName, size: 60))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .padding(.top, 12)
                Spacer()
            }
            .allowsHitTesting(false)
        }
        // 兩個 sheet：遊戲簡介與歷史紀錄
        .sheet(isPresented: $showingIntroSheet) {
            GameIntroView()
        }
        .sheet(isPresented: $showingHistorySheet) {
            HistoryView()
        }
    }
}

// 遊戲簡介視圖
// - 簡述世界觀、玩法與注意事項
// - 以半透明毛玻璃卡片呈現
private struct GameIntroView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 20) {
                // 主標與簡短導語
                VStack(spacing: 8) {
                    Text("꧁ 遊戲簡介 ꧂")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("長生是醫師白朮的眷屬\n幫助長生收集更多的藥材！\n")
                        .font(.custom(introFontName, size: 25))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                // 遊戲特色
                VStack(alignment: .leading, spacing: 12) {
                    Text("༺ 遊戲特色 ༻")
                        .font(.system(size: 22, weight: .bold))
                    Text("每收集一枚藥材，身上的色素會增加一點，可以探索不同的藥材比例造成的變化！")
                        .font(.custom(introFontName, size: 20))
                }
                
                // 遊戲玩法（兩種模式）
                VStack(alignment: .leading, spacing: 12) {
                    Text("༺ 遊戲玩法 ༻")
                        .font(.system(size: 22, weight: .bold))
                    Text("࿔普通版[採集藥材]：\n引導長生收集越多藥材，收集越多身體顏色會變得越豐富。\n\n ࿔進階版[黑毒之解]：\n因為長生中毒，導致身體通體為黑色，收集藥材會讓身體逐漸恢復正常。")
                        .font(.custom(introFontName, size: 20))
                }
                
                // 注意事項（撞牆或自撞會結束）
                VStack(alignment: .leading, spacing: 12) {
                    Text("༺ 注意事項 ༻")
                        .font(.system(size: 22, weight: .bold))
                    Text("當你的頭部撞到牆壁或自己的身體時，遊戲就會結束。")
                        .font(.custom(introFontName, size: 20))
                }
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .shadow(radius: 12)
            .padding(.horizontal)
            
            // 關閉按鈕（xmark）
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 34, weight: .regular)) // 放大
            }
            .foregroundColor(.secondary)
            .padding(.bottom, 24)
            
            Spacer()
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// 歷史紀錄視圖
// - 以 @AppStorage 保存兩個難度的最高分
// - 提供一鍵重設功能
private struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("normalBestScore") private var normalBestScore: Int = 0
    @AppStorage("advancedBestScore") private var advancedBestScore: Int = 0
    
    private func resetAllScores() {
        normalBestScore = 0
        advancedBestScore = 0
    }
    var body: some View {
        VStack {
            Spacer()
            // 卡片內容：兩種模式的最高分
            VStack(spacing: 20) {
                Text("꧁ 成就 ꧂")
                    .font(.system(size: 38, weight: .bold))
                
                VStack(spacing: 16) {
                    ScoreRecordView(
                        title: "採集藥材 (普通版)",
                        score: normalBestScore
                    )
                    ScoreRecordView(
                        title: "黑毒之解 (進階版)",
                        score: advancedBestScore
                    )
                }
                .padding()
                
                Divider()
                
                Button("重設所有歷史最高分") {
                    resetAllScores()
                }
                .tint(.red)
                .buttonStyle(.bordered)
                .font(.body)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .shadow(radius: 12)
            .padding(.horizontal)
            
            // 關閉按鈕（xmark）
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 34, weight: .regular)) // 放大
            }
            .foregroundColor(.secondary)
            .padding(.bottom, 24)
            
            Spacer()
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// 單一筆分數紀錄卡片
private struct ScoreRecordView: View {
    let title: String
    let score: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.custom(introFontName, size: 28))
            
            if score == 0 {
                Text("尚未有紀錄")
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                Text("\(score)")
                    .font(.system(size: 40, weight: .bold))
                    .monospacedDigit()
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

// 難度按鈕
// - 支援資產圖或系統圖示
// - isSelected 時外框高亮
private struct DifficultyButton: View {
    let difficulty: Difficulty
    let subtitle: String
    let assetName: String?
    let systemImage: String?
    let color: Color
    let isSelected: Bool
    let disabled: Bool
    let action: () -> Void

    init(
        difficulty: Difficulty,
        subtitle: String,
        assetName: String? = nil,
        systemImage: String? = nil,
        color: Color,
        isSelected: Bool = false,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.difficulty = difficulty
        self.subtitle = subtitle
        self.assetName = assetName
        self.systemImage = systemImage
        self.color = color
        self.isSelected = isSelected
        self.disabled = disabled
        self.action = action
    }

    // 左側圖示：優先使用資產圖，其次系統圖，否則顯示占位
    @ViewBuilder
    private var leadingIcon: some View {
        if let assetName, !assetName.isEmpty {
            Image(assetName)
                .resizable()
                .scaledToFill()
                .frame(width: 84, height: 84)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else if let systemImage, !systemImage.isEmpty {
            Image(systemName: systemImage)
                .font(.system(size: 60, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 84, height: 84)
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 84, height: 84)
        }
    }

    // 背景樣式：依難度變化
    @ViewBuilder
    private var backgroundStyle: some View {
        switch difficulty {
        case .normal:
            RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.18))
        case .advanced:
            RoundedRectangle(cornerRadius: 12).fill(
                LinearGradient(colors: [
                    Color.green.opacity(0.20),
                    Color.blue.opacity(0.20),
                    Color.purple.opacity(0.20),
                    Color.red.opacity(0.20)
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                leadingIcon
                VStack(alignment: .leading, spacing: 6) {
                    Text(difficulty.rawValue)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(Color(red: 0.35, green: 0.4, blue: 0.35))
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                ZStack {
                    // 毛玻璃底 + 額外色塊混合
                    RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial)
                    backgroundStyle
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color.opacity(0.6) : Color.secondary.opacity(0.15), lineWidth: 1)
            )
        }
        .disabled(disabled)
    }
}

// 倒數覆蓋層：顯示選定難度、倒數秒數與提示
private struct CountdownOverlay: View {
    let secondsLeft: Int
    let difficulty: Difficulty

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(difficulty.rawValue)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("\(secondsLeft)")
                    .font(.system(size: 72, weight: .bold))
                    .monospacedDigit()
                Text("即將開始…")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 10)
        }
        .transition(.opacity)
    }
}

// 暫停覆蓋層：顯示一張圖片與「繼續遊戲」按鈕
private struct PauseOverlay: View {
    let imageName: String
    let onResume: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 380, maxHeight: 380)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 8)
                Button("繼續遊戲", action: onResume)
                    .font(.system(size: 17, weight: .semibold))
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
            }
            .padding(20)
            .frame(maxWidth: 360)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 16)
        }
        .transition(.opacity)
    }
}

// 遊戲視圖（核心邏輯）
// - 計時器驅動的回合制移動（tick）
// - 透過 foods 陣列管理食物與其壽命、閃爍效果
// - 分數與加速管理、暫停/倒數/結束覆蓋層控制
private struct SnakeGameView: View {
    // 棋盤尺吋
    private let rows: Int
    private let cols: Int
    private let minCellSize: CGFloat = 16 // 單格最小像素

    // 遊戲狀態
    @State private var tickInterval: Double
    @State private var snake: [Point] = [] // 蛇身（第 0 節為頭）
    @State private var direction: Direction = .right
    @State private var nextDirection: Direction = .right // 下一步方向（避免同一 tick 內連續反向）
    @State private var score: Int = 0
    @State private var isGameOver: Bool = false
    @State private var isPaused: Bool = false
    
    // 收集到的三色草藥統計
    @State private var redHerbsCollected: Int = 0
    @State private var greenHerbsCollected: Int = 0
    @State private var blueHerbsCollected: Int = 0

    // 食物資料結構：位置、顏色、剩餘壽命、閃爍狀態與累積器
    private struct Food: Identifiable, Equatable {
        let id = UUID()
        var position: Point
        var color: Color
        var lifetimeRemaining: Double
        var flashVisible: Bool
        var flashAccumulator: Double
    }
    @State private var foods: [Food] = []

    // 主要遊戲計時器（控制蛇移動）
    @State private var timer: Timer?
    // 開場倒數計時器
    @State private var countdown: Int = 5
    @State private var countdownTimer: Timer?

    // 以蛇身顏色（由三色通道組合）產生外觀
    private var startColor: Color { snakeBodyColor() }

    // 最高分儲存（不同難度各自一組）
    @AppStorage("normalBestScore") private var normalBestScore: Int = 0
    @AppStorage("advancedBestScore") private var advancedBestScore: Int = 0

    // 食物顏色枚舉（對應三原色）
    private enum FruitColor: CaseIterable {
        case red, green, blue
        var color: Color {
            switch self {
            case .blue: return .blue
            case .green: return .green
            case .red: return .red
            }
        }
    }

    // 蛇身顏色的通道值（允許超出 0...1，實際使用時再 clamp）
    @State private var snakeRUnbounded: Double = 0.9
    @State private var snakeGUnbounded: Double = 1.0
    @State private var snakeBUnbounded: Double = 0.9

    // 每吃到一顆食物時，調整顏色通道的增減幅度
    private let colorIncrement: Double = 0.05

    // 食物壽命與閃爍設定（秒）
    private let foodLifetimeTotal: Double = 12.0
    private let foodFlashWindow: Double = 3.0
    private let foodFlashFrequency: Double = 3.0

    // 棋盤定位模式：控制棋盤放在畫面的位置
    private enum BoardOriginMode {
        case fixedTopLeft(padding: CGSize)
        case topCentered(topPadding: CGFloat)
        case fixedBottomRight(padding: CGSize)
    }
    private let boardOriginMode: BoardOriginMode = .topCentered(topPadding: 20)

    // 難度參數（tick、加速頻率、加速幅度、最小 tick）
    private let difficulty: Difficulty
    private let accelEvery: Int
    private let accelDelta: Double
    private let minTick: Double

    // 從遊戲返回主選單的回呼
    var onExitToMenu: () -> Void

    // 指定難度 + 外部回呼
    init(difficulty: Difficulty, onExitToMenu: @escaping () -> Void) {
        self.difficulty = difficulty
        self.rows = difficulty.rows
        self.cols = difficulty.cols
        self._tickInterval = State(initialValue: difficulty.initialTick)
        self.accelEvery = difficulty.accelerationEvery
        self.accelDelta = difficulty.accelerationDelta
        self.minTick = difficulty.minTick
        self.onExitToMenu = onExitToMenu
    }

    // 不同難度的背景圖
    private var gameBackgroundImageName: String {
        switch difficulty {
        case .normal: return "Image 8"
        case .advanced: return "Image 9"
        }
    }

    // 讀取對應難度的最高分
    private var bestScore: Int {
        switch difficulty {
        case .normal: return normalBestScore
        case .advanced: return advancedBestScore
        }
    }

    var body: some View {
        GeometryReader { proxy in
            // 根據容器大小計算棋盤與單格大小（盡量取整數、偶數，視覺更利落）
            let containerSize = proxy.size
            let rawCell = min(containerSize.width, containerSize.height) / CGFloat(max(rows, cols))
            let snappedCell = floor(rawCell / 2) * 2
            let cellSize = max(minCellSize, snappedCell)

            let boardSize = CGSize(width: cellSize * CGFloat(cols), height: cellSize * CGFloat(rows))
            let boardCorner: CGFloat = 6

            let rawOrigin = boardOrigin(in: containerSize, boardSize: boardSize)
            let origin = CGPoint(x: round(rawOrigin.x), y: round(rawOrigin.y))

            ZStack {
                // 遊戲背景圖
                Image(gameBackgroundImageName)
                    .resizable()
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    // 最高分顯示
                    HStack(alignment: .firstTextBaseline) {
                        HStack(spacing: 8) {
                            Spacer()
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill").foregroundStyle(.yellow)
                                Text("最高分：\(bestScore)")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.gray.gradient)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // 目前分數
                    HStack(alignment: .firstTextBaseline) {
                        HStack(spacing: 12) {
                            Image(systemName: "trophy.fill").foregroundStyle(.orange)
                            Text("分數：\(score)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color(red: 0.96, green: 0.96, blue: 0.86))
                                .bold()
                        }
                    }
                    .padding(.horizontal)

                    // 棋盤 + 蛇 + 食物
                    ZStack(alignment: .topLeading) {
                        let boardShape = RoundedRectangle(cornerRadius: 6)

                        // 棋盤底與格線
                        boardShape
                            .fill(Color(red: 0.87, green: 0.87, blue: 0.9))
                            .frame(width: boardSize.width, height: boardSize.height)
                            .overlay(
                                GridOverlay(rows: rows, cols: cols, cellSize: cellSize)
                                    .clipShape(boardShape)
                            )
                            .position(x: origin.x + boardSize.width / 2,
                                      y: origin.y + boardSize.height / 2)

                        // 棋盤內容（蛇與食物）
                        ZStack {
                            let bodyColor = snakeBodyColor()
                            // 畫蛇：每節使用圓角方塊，頭部加眼睛
                            ForEach(Array(snake.enumerated()), id: \.offset) { idx, segment in
                                let isHead = idx == 0
                                let inset: CGFloat = 2
                                RoundedRectangle(cornerRadius: max(2, cellSize * 0.12))
                                    .fill(isHead ? bodyColor : bodyColor.opacity(0.85))
                                    .frame(width: cellSize - inset, height: cellSize - inset)
                                    .position(positionForPoint(segment, cellSize: cellSize, boardOrigin: origin))
                                    .overlay {
                                        if isHead {
                                            Circle()
                                                .fill(.black.opacity(0.7))
                                                .frame(width: cellSize * 0.18, height: cellSize * 0.18)
                                                .offset(x: eyeOffset().x * cellSize * 0.15,
                                                        y: eyeOffset().y * cellSize * 0.15)
                                        }
                                    }
                            }

                            // 畫食物（在壽命末段會閃爍）
                            let foodInset: CGFloat = 2
                            ForEach(foods) { food in
                                if food.flashVisible {
                                    Circle()
                                        .fill(food.color)
                                        .frame(width: cellSize - foodInset, height: cellSize - foodInset)
                                        .position(positionForPoint(food.position, cellSize: cellSize, boardOrigin: origin))
                                }
                            }
                        }
                        .frame(width: boardSize.width, height: boardSize.height)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .position(x: origin.x + boardSize.width / 2, y: origin.y + boardSize.height / 2)
                    }
                    .gesture(dragGesture()) // 支援滑動改變方向
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(countdown == 0) // 倒數時禁止互動
                    
                    // 下方三色草藥數量顯示（依難度使用不同圖示）
                    switch difficulty {
                    case .normal:
                        HStack {
                            HStack(spacing: 4) {
                                Image("Image 3")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 45, height: 45)
                                Text("\(redHerbsCollected)")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(Color(red: 0.96, green: 0.96, blue: 0.86))
                            }
                            Spacer()
                            HStack(spacing: 4) {
                                Image("Image 1")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 45, height: 45)
                                Text("\(greenHerbsCollected)")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(Color(red: 0.96, green: 0.96, blue: 0.86))
                            }
                            Spacer()
                            HStack(spacing: 4) {
                                Image("Image 2")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 45, height: 45)
                                Text("\(blueHerbsCollected)")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(Color(red: 0.96, green: 0.96, blue: 0.86))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 30)
                    case .advanced:
                        HStack {
                            Image("Image 12")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 45, height: 45)
                                .foregroundColor(.yellow)
                            Text("\(redHerbsCollected)")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Color(red: 0.96, green: 0.96, blue: 0.86))
                            Spacer()
                            Image("Image 10")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 45, height: 45)
                                .foregroundColor(.yellow)
                            Text("\(greenHerbsCollected)")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Color(red: 0.96, green: 0.96, blue: 0.86))
                            Spacer()
                            Image("Image 11")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 45, height: 45)
                                .foregroundColor(.yellow)
                            Text("\(blueHerbsCollected)")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Color(red: 0.96, green: 0.96, blue: 0.86))
                            Spacer()
                        }
                        .padding(.horizontal, 30)
                    }

                    // 重新開始 / 暫停 或 繼續 + 方向鍵
                    VStack(spacing: 8) {
                        HStack(spacing: 200) {
                            Button("重新開始") { restart() }
                                .buttonStyle(.borderedProminent)
                                .disabled(countdown > 0) // 倒數時不可按
                                .font(.system(size: 17, weight: .semibold))

                            Button(isPaused ? "繼續" : "暫停") { togglePause() }
                                .buttonStyle(.bordered)
                                .disabled(countdown > 0)
                                .font(.system(size: 17, weight: .semibold))
                        }

                        // 方向按鈕（上左下右）
                        DirectionPad {
                            changeDirection(to: .up)
                        } left: {
                            changeDirection(to: .left)
                        } down: {
                            changeDirection(to: .down)
                        } right: {
                            changeDirection(to: .right)
                        }
                        .opacity(countdown > 0 ? 0.5 : 1)
                        .allowsHitTesting(countdown == 0)
                    }
                    .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())

                // 倒數覆蓋層
                if countdown > 0 {
                    CountdownOverlay(secondsLeft: countdown, difficulty: difficulty)
                        .zIndex(20)
                        .transition(.opacity)
                }

                // 暫停覆蓋層（遊戲中、非結束且非倒數時）
                if isPaused && countdown == 0 && !isGameOver {
                    PauseOverlay(imageName: "Image", onResume: { togglePause() })
                        .zIndex(30)
                        .transition(.opacity)
                }

                // 結束覆蓋層（顯示分數與最高分，並提供重新開始）
                if isGameOver {
                    GameOverOverlay(
                        title: "下山囉～",
                        notice: difficulty.endMessage,
                        scoreText: "分數：\(score)",
                        bestText: "最高分：\(bestScore)",
                        noticeColor: snakeBodyColor(),
                        onRestart: { restart() }
                    )
                    .zIndex(40)
                    .transition(.opacity .combined(with: .scale))
                }
            }
            // 左上角返回主選單
            .overlay(alignment: .topLeading) {
                Button {
                    onExitToMenu()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("主選單")
                    }
                }
                .buttonStyle(.bordered)
                .tint(.primary)
                .padding(.horizontal)
                .padding(.top, 8)
                .zIndex(1000)
                .font(.body)
            }
            .onAppear {
                // 進入遊戲：設定棋盤與倒數，並播放難度對應 BGM
                setupGameAndCountdown()
                switch difficulty {
                case .normal:
                    BGMManager.shared.playFileWithFadeIn(named: "music2", ext: "mp3", loops: -1, duration: 5, targetVolume: 1.0)
                case .advanced:
                    BGMManager.shared.playFileWithFadeIn(named: "music3", ext: "mp3", loops: -1, duration: 5, targetVolume: 1.0)
                }
            }
            .onDisappear {
                // 離開遊戲：停止所有計時器、淡出 BGM
                stopAllTimers()
                BGMManager.shared.fadeOutAndStop(duration: 0.5)
            }
        }
    }

    // 依定位模式計算棋盤起點（左上角）
    private func boardOrigin(in container: CGSize, boardSize: CGSize) -> CGPoint {
        switch boardOriginMode {
        case .fixedTopLeft(let padding):
            return CGPoint(x: padding.width, y: padding.height)
        case .topCentered(let topPadding):
            let x = (container.width - boardSize.width) / 2
            return CGPoint(x: max(0, x), y: topPadding)
        case .fixedBottomRight(let padding):
            let x = container.width - boardSize.width - padding.width
            let y = container.height - boardSize.height - padding.height
            return CGPoint(x: max(0, x), y: max(0, y))
        }
    }

    // 以 clamp 後的 RGB 通道生成蛇身顏色
    private func snakeBodyColor() -> Color {
        let r = min(max(snakeRUnbounded, 0), 1)
        let g = min(max(snakeGUnbounded, 0), 1)
        let b = min(max(snakeBUnbounded, 0), 1)
        return Color(red: r, green: g, blue: b)
    }

    // 將格點轉換為實際畫面座標（中心點）
    private func positionForPoint(_ p: Point, cellSize: CGFloat, boardOrigin: CGPoint) -> CGPoint {
        let localX = (CGFloat(p.x) + 0.5) * cellSize
        let localY = (CGFloat(p.y) + 0.5) * cellSize
        return CGPoint(x: boardOrigin.x + localX, y: boardOrigin.y + localY)
    }

    // 頭部眼睛的偏移（依移動方向）
    private func eyeOffset() -> (x: CGFloat, y: CGFloat) {
        switch direction {
        case .up: return (0, -1)
        case .down: return (0, 1)
        case .left: return (-1, 0)
        case .right: return (1, 0)
        }
    }

    // 進入遊戲：初始化並啟動倒數
    private func setupGameAndCountdown() {
        setupGame()
        startCountdown()
    }

    // 初始化棋盤與狀態
    private func setupGame() {
        // 初始蛇身位置（靠左中線）
        let startX = cols / 4
        let midY = rows / 2
        snake = [
            Point(x: startX + 2, y: midY),
            Point(x: startX + 1, y: midY),
            Point(x: startX, y: midY)
        ]
        direction = .right
        nextDirection = .right
        score = 0
        isGameOver = false
        isPaused = true // 先暫停，待倒數結束再開始

        // 依難度設定蛇身初始顏色（進階版偏黑；普通版較亮）
        if difficulty == .advanced {
            snakeRUnbounded = 0.15
            snakeGUnbounded = 0.2
            snakeBUnbounded = 0.18
        } else {
            snakeRUnbounded = 0.5
            snakeGUnbounded = 0.8
            snakeBUnbounded = 0.7
        }
        redHerbsCollected = 0
        greenHerbsCollected = 0
        blueHerbsCollected = 0
        
        foods = []
        spawnFoodsInitial() // 產生初始食物
        stopTimer() // 停止主遊戲計時器，等待倒數
    }

    // 啟動開場倒數（5 → 0），倒數結束後開始計時器
    private func startCountdown() {
        countdown = 5
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown <= 1 {
                countdownTimer?.invalidate()
                countdownTimer = nil
                countdown = 0
                isPaused = false
                startTimer()
            } else {
                countdown -= 1
            }
        }
        if let countdownTimer {
            RunLoop.main.add(countdownTimer, forMode: .common)
        }
    }

    // 重新開始：重置 tick、狀態與倒數
    private func restart() {
        stopAllTimers()
        tickInterval = difficulty.initialTick
        setupGameAndCountdown()
    }

    // 啟動主遊戲計時器（依 tickInterval 重複觸發 gameTick）
    private func startTimer() {
        guard !isPaused else { return }
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { _ in
            gameTick()
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    // 在更新 tick 後重啟計時器（維持節奏）
    private func restartTimer() {
        guard !isGameOver, !isPaused else { return }
        startTimer()
    }

    // 停止主遊戲計時器
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // 停止所有計時器（主計時器 + 倒數）
    private func stopAllTimers() {
        stopTimer()
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    // 暫停/繼續切換
    private func togglePause() {
        isPaused.toggle()
        if isPaused {
            stopTimer()
        } else {
            startTimer()
        }
    }

    // 依分數加速（每累積 accelEvery 分，縮短 tickInterval）
    private func maybeAccelerateIfNeeded() {
        guard accelEvery > 0 else { return }
        if score > 0 && score % accelEvery == 0 {
            let newTick = max(0.1, tickInterval - accelDelta)
            if newTick < tickInterval - 1e-9 {
                tickInterval = newTick
                restartTimer()
            }
        }
    }

    // 單一 tick 的遊戲步進：
    // - 應用方向、計算新頭部
    // - 撞牆/自撞檢查
    // - 吃到食物則加分、調整顏色、補食物與加速
    // - 未吃到則移除尾巴
    private func gameTick() {
        guard !isGameOver else { return }
        applyNextDirection()
        updateFoodsLifetime()

        // 計算新頭部位置
        var newHead = snake.first!
        switch direction {
        case .up: newHead.y -= 1
        case .down: newHead.y += 1
        case .left: newHead.x -= 1
        case .right: newHead.x += 1
        }

        // 撞牆（注意此邊界：y 的範圍與生成食物時一致）
        if newHead.x < 0 || newHead.x >= cols || newHead.y < -1 || newHead.y >= rows-1 {
            gameOver(hitWall: true)
            return
        }

        // 自撞
        if snake.contains(newHead) {
            gameOver(hitWall: false)
            return
        }

        // 把新頭插到陣列最前
        snake.insert(newHead, at: 0)

        // 檢查是否吃到食物
        if let hitIndex = foods.firstIndex(where: { $0.position == newHead }) {
            score += 1

            // 依食物顏色調整蛇身顏色通道（普通與進階版相反趨勢）
            let eatenColor = foods[hitIndex].color
            let rgb = eatenColor.componentsRGB()
            if let maxChannel = rgb.maxChannel {
                switch difficulty {
                case .normal:
                    switch maxChannel {
                    case .r:
                        snakeRUnbounded += colorIncrement
                        snakeGUnbounded -= colorIncrement
                        snakeBUnbounded -= colorIncrement
                        redHerbsCollected += 1
                    case .g:
                        snakeRUnbounded -= colorIncrement
                        snakeGUnbounded += colorIncrement
                        snakeBUnbounded -= colorIncrement
                        greenHerbsCollected += 1
                    case .b:
                        snakeRUnbounded -= colorIncrement
                        snakeGUnbounded -= colorIncrement
                        snakeBUnbounded += colorIncrement
                        blueHerbsCollected += 1
                    }
                case .advanced:
                    switch maxChannel {
                    case .r:
                        snakeRUnbounded -= colorIncrement
                        snakeGUnbounded += colorIncrement
                        snakeBUnbounded += colorIncrement
                        redHerbsCollected += 1
                    case .g:
                        snakeRUnbounded += colorIncrement
                        snakeGUnbounded -= colorIncrement
                        snakeBUnbounded += colorIncrement
                        greenHerbsCollected += 1
                    case .b:
                        snakeRUnbounded += colorIncrement
                        snakeGUnbounded += colorIncrement
                        snakeBUnbounded -= colorIncrement
                        blueHerbsCollected += 1
                    }
                }
            }

            // 移除被吃掉的食物，補充新的
            foods.remove(at: hitIndex)
            refillFoods()
            maybeAccelerateIfNeeded()
            restartTimer()
        } else {
            // 未吃到：移除尾巴，維持長度
            _ = snake.popLast()
        }
    }

    // 遊戲結束：更新最高分、停止計時
    private func gameOver(hitWall: Bool) {
        isGameOver = true
        stopAllTimers()
        switch difficulty {
            case .normal:
                if score > normalBestScore {
                    normalBestScore = score
                }
            case .advanced:
                if score > advancedBestScore {
                    advancedBestScore = score
                }
            }
    }

    // 初始產生 1~3 顆食物
    private func spawnFoodsInitial() {
        foods.removeAll()
        let count = Int.random(in: 1...3)
        for _ in 0..<count {
            if let f = makeRandomFood(excluding: foods.map { $0.position }) {
                foods.append(f)
            }
        }
    }

    // 維持食物數量在 1~3 之間（隨機目標）
    private func refillFoods() {
        let target = Int.random(in: 1...3)
        while foods.count < target {
            if let f = makeRandomFood(excluding: foods.map { $0.position }) {
                foods.append(f)
            } else {
                break
            }
        }
    }

    // 生成一顆隨機食物（避開蛇身與已占用位置）
    // - 注意 y 範圍使用 -1..<rows-1 對應到碰撞邏輯
    private func makeRandomFood(excluding occupied: [Point]) -> Food? {
        var emptyCells: [Point] = []
        emptyCells.reserveCapacity(rows * cols - snake.count - occupied.count)
        for y in -1..<rows-1 {
            for x in 0..<cols {
                let p = Point(x: x, y: y)
                if !snake.contains(p) && !occupied.contains(p) {
                    emptyCells.append(p)
                }
            }
        }
        guard let pos = emptyCells.randomElement() else { return nil }

        let fc = FruitColor.allCases.randomElement() ?? .red
        let color = fc.color

        return Food(position: pos,
                    color: color,
                    lifetimeRemaining: 12.0,
                    flashVisible: true,
                    flashAccumulator: 0.0)
    }

    // 更新所有食物的壽命與閃爍狀態
    // - 壽命歸零則替換成一顆新食物
    // - 剩餘 <= 3 秒時，依頻率切換可見狀態（達成閃爍效果）
    private func updateFoodsLifetime() {
        guard !isPaused, countdown == 0, !isGameOver else { return }

        var updated: [Food] = []
        updated.reserveCapacity(foods.count)

        for var f in foods {
            f.lifetimeRemaining -= tickInterval
            if f.lifetimeRemaining <= 0 {
                if let newFood = makeRandomFood(excluding: foods.map { $0.position }) {
                    updated.append(newFood)
                }
            } else {
                if f.lifetimeRemaining <= 3.0 {
                    let period = 1.0 / 3.0
                    f.flashAccumulator += tickInterval
                    while f.flashAccumulator >= period {
                        f.flashAccumulator -= period
                        f.flashVisible.toggle()
                    }
                } else {
                    f.flashVisible = true
                    f.flashAccumulator = 0
                }
                updated.append(f)
            }
        }

        foods = updated
    }

    // 嘗試變更方向（禁止直接反向）
    private func changeDirection(to new: Direction) {
        switch (direction, new) {
        case (.up, .down), (.down, .up), (.left, .right), (.right, .left):
            return
        default:
            nextDirection = new
        }
    }

    // 應用下一步方向（在 tick 時機更新）
    private func applyNextDirection() {
        direction = nextDirection
    }

    // 拖曳手勢：依水平/垂直拖曳量決定方向
    private func dragGesture() -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                if abs(dx) > abs(dy) {
                    changeDirection(to: dx > 0 ? .right : .left)
                } else {
                    changeDirection(to: dy > 0 ? .down : .up)
                }
            }
    }
}

// 遊戲結束覆蓋層
// - 顯示標題、提示文字、分數與最高分
// - 提供重新開始按鈕
private struct GameOverOverlay: View {
    let title: String
    let notice: String?
    let scoreText: String
    let bestText: String
    let noticeColor: Color
    let onRestart: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 34, weight: .bold))
                if let notice {
                    Text(notice)
                        .font(.system(size: 18))
                        .foregroundStyle(noticeColor)
                        .multilineTextAlignment(.center)
                }
                VStack(spacing: 4) {
                    Text(scoreText)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(bestText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                Button {
                    onRestart()
                } label: {
                    Text("重新開始")
                        .font(.system(size: 17, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 12)
        }
        .transition(.opacity)
    }
}

// 網格疊加（Canvas 畫格線）
// - 僅視覺用途，無互動
private struct GridOverlay: View {
    let rows: Int
    let cols: Int
    let cellSize: CGFloat

    var body: some View {
        Canvas { context, _ in
            let path = Path { p in
                for r in 0...rows {
                    let y = round(CGFloat(r) * cellSize)
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: round(CGFloat(cols) * cellSize), y: y))
                }
                for c in 0...cols {
                    let x = round(CGFloat(c) * cellSize)
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: round(CGFloat(rows) * cellSize)))
                }
            }
            context.stroke(path, with: .color(.gray.opacity(0.15)), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}

// 方向按鈕（上左下右）
// - 行動裝置或無滑動操作時可用
private struct DirectionPad: View {
    var up: () -> Void
    var left: () -> Void
    var down: () -> Void
    var right: () -> Void

    var body: some View {
        HStack(spacing: 28) {
            Button(action: left) { Image(systemName: "arrow.left.circle.fill").font(.system(size: 36)) }
            VStack(spacing: 18) {
                Button(action: up) { Image(systemName: "arrow.up.circle.fill").font(.system(size: 36)) }
                Button(action: down) { Image(systemName: "arrow.down.circle.fill").font(.system(size: 36)) }
            }
            Button(action: right) { Image(systemName: "arrow.right.circle.fill").font(.system(size: 36)) }
        }
        .foregroundStyle(.blue)
        .opacity(0.9)
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// Color 解析輔助：將 SwiftUI.Color 取出 RGB 通道
// - 方便判斷哪個通道（R/G/B）最大，以決定吃到的食物顏色
private extension Color {
    struct RGBComponents {
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
        enum Channel { case r, g, b }
        var maxChannel: Channel? {
            let maxV = max(r, g, b)
            if maxV == r { return .r }
            if maxV == g { return .g }
            if maxV == b { return .b }
            return nil
        }
    }

    func componentsRGB() -> RGBComponents {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return RGBComponents(r: r, g: g, b: b)
        #elseif canImport(AppKit)
        let ns = NSColor(self)
        let conv = ns.usingColorSpace(.deviceRGB) ?? ns
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        conv.getRed(&r, green: &g, blue: &b, alpha: &a)
        return RGBComponents(r: r, g: g, b: b)
        #else
        return RGBComponents(r: 0, g: 0, b: 0)
        #endif
    }
}

// 預覽
#Preview {
    ContentView()
}
