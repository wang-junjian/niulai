import AppKit
import SwiftUI
import IOKit.ps

/// 牛来的行为状态机：决定它什么时候发呆、漫步、坐下、打盹，
/// 并驱动窗口在桌面上移动。点击互动和休息提醒也在这里。
@MainActor
final class PetViewModel: ObservableObject {

    enum State: Equatable {
        case idle            // 发呆站立
        case walking         // 自由漫步
        case walkingTo(CGFloat)  // 朝某个 x 坐标走（用于提醒时走到屏幕中间）
        case walkingToSleep(CGFloat) // 走向屏幕角落趴睡（工作模式）
        case sitting         // 坐下
        case sleeping        // 打盹
        case happy           // 开心（被戳/落地后的短暂反应）
        case dragged         // 被鼠标抓着
        case startled        // 吓一跳（蛇/狼影掠过）
        case chasing         // 追蝴蝶（小跑）
        case pouncing        // 跳起来扑蝴蝶
        case stretching      // 睡醒伸懒腰打哈欠
        case headbutting     // 拿角顶屏幕边缘
        case spinning        // 原地转圈追尾巴
        case dizzy           // 转晕了，晕乎乎坐地上
    }

    /// 休闲：满地漫游；工作：趴角落睡觉做梦，安静不打扰；番茄钟：专注+休息循环
    enum PetMode: String, Hashable {
        case leisure, working, pomodoro
    }

    /// 番茄钟阶段
    enum PomodoroPhase {
        case focus   // 专注：牛来睡觉做梦
        case rest    // 休息：牛来醒来陪你活动
    }

    @Published var state: State = .idle   // 仅 PetViewModel* 扩展内可写（注释约定）
    @Published var facingLeft = false
    @Published var bubbleText: String?
    @Published var isVisible = true

    /// 当前状态的开始时刻（动画按经过时间编排子阶段，如哈欠→伸懒腰）
    private(set) var stateStartedAt = Date()
    var stateElapsed: TimeInterval { Date().timeIntervalSince(stateStartedAt) }

    weak var window: NSWindow?
    weak var companion: CompanionController?
    weak var lark: LarkController?
    weak var snake: SnakeController?
    weak var wolf: WolfController?
    weak var butterfly: ButterflyController?

    private let walkSpeed: CGFloat = 55
    private lazy var ticker = FrameTicker { [weak self] dt in self?.tick(dt: dt) }
    /// 休息提醒：分钟级，间隔随设置变化，每次 configureReminder 重建
    var reminderTicker: FrameTicker?   // internal: +Reminder 写
    var stateUntil = Date()   // internal: +Reminder/+Events 写
    private var bubbleGeneration = 0

    // 彩蛋事件调度
    let demoMode = CommandLine.arguments.contains("--demo")   // internal: +Pomodoro/+Events 用

    // 电量感知
    lazy var batteryTicker = FrameTicker(interval: 30) { [weak self] _ in self?.checkBattery() }
    var wasCharging = false   // internal: +Reminder 写
    var lowBatteryWarned = false   // internal: +Reminder 写

    // 梦到妈妈彩蛋：休闲模式每次入睡掷签，抽中的觉睡到中途必然触发（一觉最多一次）
    private var mamaDreamArmed = false
    private var mamaDreamPlayed = false

    // MARK: - 番茄钟存储属性
    // （Swift 扩展不能持有存储属性，番茄钟的状态集中放这里；方法见 PetViewModel+Pomodoro.swift）
    // 番茄钟
    @Published var pomodoroPhase: PomodoroPhase = .focus
    @Published var pomodoroCountdown = ""
    @Published var pomodoroPaused = false
    @Published var menuBarLabel = "🐮"
    var phaseEndsAt = Date()   // internal: 核心 poke() 读
    var pausedRemaining: TimeInterval = 0   // internal: 仅 +Pomodoro 写
    var completedFocusCount = 0   // internal: 仅 +Pomodoro 写
    lazy var pomodoroTicker = FrameTicker(interval: 1) { [weak self] _ in self?.pomodoroTick() }

    // MARK: - 彩蛋事件存储属性
    // （方法见 PetViewModel+Events.swift）
    // internal: +Events 读写（事件调度与触发都在扩展里）
    lazy var eventTicker = FrameTicker(interval: 5) { [weak self] _ in self?.checkEvents() }
    var nextSnakeAt = Date.distantFuture
    var nextWolfAt = Date.distantFuture
    var nextButterflyAt = Date.distantFuture

    /// 最近一次已响应的模式；tick 里轮询 UserDefaults，发现不一致就补响应，
    /// 保证无论改动来自菜单按钮还是外部（defaults 命令）都能生效
    // internal: 核心 tick() 与 +Mode 读写（存储属性不能放扩展）
    var lastReactedMode: PetMode?

    nonisolated init() {}

    // MARK: - 生命周期

    func start() {
        ticker.start()
        configureReminder()
        scheduleEvents()
        startBatteryMonitor()
        switch mode {
        case .working:
            settleIntoCorner()
        case .pomodoro:
            startPomodoro()
        case .leisure:
            setState(.idle, duration: 3)
        }
        lastReactedMode = mode   // 启动分支已处理，避免 tick 第一帧重复响应
    }

    // MARK: - 主循环

    private func tick(dt: CGFloat) {
        let now = Date()

        // 模式是 UserDefaults 背书的：发现变化（菜单按钮或外部改动）立刻响应
        if mode != lastReactedMode { reactToModeChange() }

        guard isVisible, let window else { return }

        switch state {
        case .walking:
            move(dx: walkSpeed * dt * (facingLeft ? -1 : 1))
            bounceOffScreenEdge(allowHeadbutt: true)   // 偶尔把屏幕边当对手顶两下
        case .walkingTo(let target):
            let dir: CGFloat = target > window.frame.minX ? 1 : -1
            facingLeft = dir < 0
            move(dx: walkSpeed * 1.6 * dt * dir)
            if abs(window.frame.minX - target) < 24 {
                arriveAtReminderSpot()
            }
        case .walkingToSleep(let target):
            let dir: CGFloat = target > window.frame.minX ? 1 : -1
            facingLeft = dir < 0
            move(dx: walkSpeed * 1.2 * dt * dir)
            if abs(window.frame.minX - target) < 24 {
                setState(.sleeping, duration: 3600)
            }
        case .chasing:
            // 小跑追蝴蝶：蝴蝶没了就收手
            guard let butterfly, butterfly.flying else {
                butterflyGone()
                break
            }
            // 死区：追到蝴蝶正下方附近就稳住朝向不再横跳（否则每帧翻转闪烁）
            let dx = butterfly.currentX - window.frame.midX
            if abs(dx) > 24 {
                facingLeft = dx < 0
                let step = min(walkSpeed * 2.2 * dt, abs(dx))
                move(dx: dx > 0 ? step : -step)
            }
            bounceOffScreenEdge()
        case .pouncing:
            // 向前小跳一步
            move(dx: (facingLeft ? -1 : 1) * 35 * dt)
            bounceOffScreenEdge()
        default:
            break
        }

        // 状态到点后的去向
        if now >= stateUntil, state != .dragged {
            switch state {
            case .sleeping where !isPeaceful:
                // 睡醒先伸个大懒腰（番茄钟专注期的长睡由番茄钟自己接管）
                if Double.random(in: 0..<1) < 0.6 {
                    setState(.stretching, duration: 2.8)
                } else {
                    pickNextState()
                }
            case .spinning:
                setState(.sitting, duration: .random(in: 3...6))   // 转完坐下歇会儿
            case .headbutting:
                setState(.dizzy, duration: 1.8)   // 顶到墙，把自己撞晕了
            case .dizzy:
                facingLeft = !facingLeft   // 晕完掉头就走
                setState(.walking, duration: .random(in: 4...8))
            case .pouncing:
                // 扑空了，若无其事
                showBubble("嘿嘿……差点就抓到了", duration: 2.5)
                setState(.idle, duration: 2.5)
            case .chasing:
                butterflyGone()   // 追太久，追丢了
            default:
                pickNextState()
            }
        }

        // 被抽中的休闲小睡（约 1/4）：睡到中途必然梦到妈妈，低音量呢喃原声
        // ——不赌随机梦话的时机（小睡只有 4-9 秒，随机梦话大概率来不及触发）
        if state == .sleeping, mamaDreamArmed, !mamaDreamPlayed,
           bubbleText == nil, stateElapsed > 1.2 {
            mamaDreamPlayed = true
            showBubble("（梦话）妈妈，快跑……", duration: 3.5)
            SoundPlayer.play(SoundPlayer.mama, volume: 0.3)
        }

        // 打盹时偶尔说梦话（平均约 20 秒一句）
        if state == .sleeping, bubbleText == nil, Int.random(in: 0..<1200) == 0 {
            let phrase = Self.dreamPhrases.randomElement() ?? "（梦话）哞……"
            showBubble(phrase, duration: 3.5)
        }
    }

    private func pickNextState() {
        // 安静时期（工作模式 / 番茄钟专注中）：不漫游，回角落继续做梦
        if isPeaceful {
            settleIntoCorner()
            return
        }
        let roaming = Settings.roamingEnabled
        guard roaming else {
            setState(.sitting, duration: 60)
            return
        }
        let pool: [(State, Double)] = [
            (.idle, 3),
            (.walking, 3.5),
            (.sitting, 2),
            (.sleeping, 1),
            (.spinning, 0.7)   // 偶尔犯傻：转圈追自己尾巴
        ]
        let total = pool.reduce(0) { $0 + $1.1 }
        var r = Double.random(in: 0..<total)
        var picked = pool[0].0
        for (s, w) in pool {
            r -= w
            if r <= 0 { picked = s; break }
        }
        switch picked {
        case .walking:
            facingLeft = Bool.random()
            setState(.walking, duration: Double.random(in: 5...12))
        case .spinning:
            setState(.spinning, duration: 1.6)
        default:
            setState(picked, duration: Double.random(in: 4...9))
        }
    }

    func setState(_ s: State, duration: TimeInterval) {   // internal: +Pomodoro/+Events/+Reminder/+Mode 用 {
        state = s
        stateStartedAt = Date()
        stateUntil = Date().addingTimeInterval(duration)
        // 通知豹拉：牛来出发散步 / 睡着了
        if s == .walking { companion?.onPetStartedWalking() }
        if s == .sleeping {
            companion?.onPetStartedSleeping()
            // 休闲打盹约 1/4 概率被抽中梦到妈妈（工作/番茄钟的睡绝不播放，不打扰）
            mamaDreamArmed = mode == .leisure && Double.random(in: 0..<1) < 0.25
            mamaDreamPlayed = false
        }
    }

    // MARK: - 窗口移动

    var visibleFrame: NSRect {   // internal: +Reminder/+Mode 用
        ScreenGeometry.visibleFrame(
            of: window,
            fallback: NSRect(x: 0, y: 0, width: 1440, height: 900)   // 锁屏时坐标可能是垃圾值，兜底
        )
    }

    private func move(dx: CGFloat) {
        guard let window else { return }
        var origin = window.frame.origin
        origin.x += dx
        origin.y = visibleFrame.minY + 24   // 贴着屏幕底部走
        window.setFrameOrigin(origin)
    }

    private func bounceOffScreenEdge(allowHeadbutt: Bool = false) {
        guard let window else { return }
        let vf = visibleFrame
        var origin = window.frame.origin
        let hitLeft = origin.x < vf.minX
        let hitRight = origin.x + window.frame.width > vf.maxX
        guard hitLeft || hitRight else { return }

        origin.x = hitLeft ? vf.minX : vf.maxX - window.frame.width
        window.setFrameOrigin(origin)

        // 偶尔把屏幕边缘当成较劲的对手，低头顶两下
        if allowHeadbutt, Double.random(in: 0..<1) < 0.3 {
            facingLeft = hitLeft
            enterHeadbutt()
            return
        }
        facingLeft = hitRight
    }

    private func enterHeadbutt() {
        setState(.headbutting, duration: 1.3)   // 低头顶一下，把自己顶晕
        if Double.random(in: 0..<1) < 0.5 {
            showBubble("哞！这堵墙跟我较劲！", duration: 2.2)
        }
    }

    // MARK: - 互动

    /// 点击/戳一下
    func poke() {
        guard state != .dragged else { return }
        // 番茄钟专注中被戳：不吵醒它（保持睡觉姿势），只冒出气泡报个倒计时
        if mode == .pomodoro, pomodoroPhase == .focus {
            if pomodoroPaused {
                showBubble("哞……番茄钟暂停着呢，要继续吗？", duration: 3)
            } else {
                let remain = max(0, phaseEndsAt.timeIntervalSinceNow)
                showBubble(String(format: "哞……还剩 %d:%02d", Int(remain) / 60, Int(remain) % 60), duration: 3)
            }
            return
        }
        if isPeaceful {
            // 被吵醒一下，迷迷糊糊应一声，很快又睡回去
            setState(.happy, duration: 0.8)
            showBubble(Self.workingPokePhrases.randomElement() ?? "哞……", duration: 2.5)
            return
        }
        setState(.happy, duration: 1.4)
        showBubble(Self.pokePhrases.randomElement() ?? "哞~", duration: 2.5)
    }

    func beginDrag() {
        state = .dragged
        bubbleText = nil
    }

    func endDrag() {
        setState(.happy, duration: 0.9)
    }

    // MARK: - 气泡

    func showBubble(_ text: String, duration: TimeInterval = 3) {
        bubbleGeneration += 1
        let gen = bubbleGeneration
        bubbleText = text
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard let self, !Task.isCancelled, self.bubbleGeneration == gen else { return }
            self.bubbleText = nil
        }
    }

    // MARK: - 菜单控制

    func setVisible(_ visible: Bool) {
        isVisible = visible
        if visible {
            window?.orderFrontRegardless()
        } else {
            window?.orderOut(nil)
        }
        companion?.setVisible(visible)
        lark?.setVisible(visible)
        snake?.setVisible(visible)
        wolf?.setVisible(visible)
        butterfly?.setVisible(visible)
    }

    /// “自由走动”开关变化后调用
    func applyRoaming() {
        let roaming = Settings.roamingEnabled
        if roaming {
            stateUntil = Date()   // 立刻重新决策
        } else {
            setState(.sitting, duration: 3600)
        }
    }
}
