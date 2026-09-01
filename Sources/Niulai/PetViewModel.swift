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

    /// 直接读写 UserDefaults 的计算属性，避免 @Published 在 nonisolated init 中的隔离问题
    var mode: PetMode {
        get {
            PetMode(rawValue: UserDefaults.standard.string(forKey: "petMode") ?? "") ?? .leisure
        }
        set {
            objectWillChange.send()
            UserDefaults.standard.set(newValue.rawValue, forKey: "petMode")
            reactToModeChange()
        }
    }

    @Published private(set) var state: State = .idle
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
    private var ticker: Timer?
    private var reminderTimer: Timer?
    private var lastTick = Date()
    private var stateUntil = Date()
    private var bubbleGeneration = 0

    // 彩蛋事件调度
    private let demoMode = CommandLine.arguments.contains("--demo")
    private var eventTimer: Timer?
    private var nextSnakeAt = Date.distantFuture
    private var nextWolfAt = Date.distantFuture
    private var nextButterflyAt = Date.distantFuture

    // 电量感知
    private var batteryTimer: Timer?
    private var wasCharging = false
    private var lowBatteryWarned = false

    // 番茄钟
    @Published private(set) var pomodoroPhase: PomodoroPhase = .focus
    @Published private(set) var pomodoroCountdown = ""
    @Published private(set) var pomodoroPaused = false
    @Published private(set) var menuBarLabel = "🐮"
    private var phaseEndsAt = Date()
    private var pausedRemaining: TimeInterval = 0
    private var completedFocusCount = 0
    private var pomodoroTimer: Timer?

    private var focusDuration: TimeInterval { demoMode ? 30 : 25 * 60 }
    private var restDuration: TimeInterval { demoMode ? 15 : 5 * 60 }
    private var longRestDuration: TimeInterval { demoMode ? 45 : 15 * 60 }

    nonisolated init() {}

    // MARK: - 模式切换

    private func reactToModeChange() {
        lastReactedMode = mode
        objectWillChange.send()
        switch mode {
        case .working:
            stopPomodoro()
            companion?.onPetModeChanged(mode)
            showBubble("我去做个勇敢的梦啦，你专心工作~", duration: 3)
            settleIntoCorner()
        case .pomodoro:
            startPomodoro()
        case .leisure:
            stopPomodoro()
            companion?.onPetModeChanged(mode)
            showBubble("我醒啦！梦里的我可勇敢了！", duration: 3)
            stateUntil = Date()   // 立刻恢复自由行为
        }
    }

    /// 需要安静做梦的时期：工作模式，或番茄钟的专注阶段。
    /// 云雀/蛇/狼彩蛋、戳一戳反应、漫游都以此为准。
    var isPeaceful: Bool {
        switch mode {
        case .leisure: return false
        case .working: return true
        case .pomodoro: return pomodoroPhase == .focus
        }
    }

    /// 最近一次已响应的模式；tick 里轮询 UserDefaults，发现不一致就补响应，
    /// 保证无论改动来自菜单按钮还是外部（defaults 命令）都能生效
    private var lastReactedMode: PetMode?

    /// 工作模式的归宿：走到屏幕右下角趴睡；已经在角落就直接睡
    private func settleIntoCorner() {
        let cornerX = visibleFrame.maxX - (window?.frame.width ?? 240) - 30
        let currentX = window?.frame.minX ?? cornerX
        if abs(currentX - cornerX) > 40 {
            state = .walkingToSleep(cornerX)
            stateUntil = Date().addingTimeInterval(30)
        } else {
            setState(.sleeping, duration: 3600)
        }
    }

    // MARK: - 台词

    static let pokePhrases = [
        "哞~",
        "勇气已经在我心底了！",
        "今天也要加油呀！",
        "我才不是胆小鬼！",
        "七天站不起来就会被抛弃……但我做到了！",
        "豹拉才不是野兽，它是我最好的朋友！",
        "牛二，我不怕你。",
        "妈妈在等我，我要站起来！",
        "你戳我干嘛啦，哞！",
        "梦里的我，可勇敢了。"
    ]

    static let dreamPhrases = [
        "（梦话）豹拉，别走……",
        "（梦话）我能站起来了！",
        "（梦话）妈妈，快跑……",
        "（梦话）狼来了也不怕……",
        "（梦话）哞……云雀，你也做梦吗？"
    ]

    /// 工作模式下被戳：迷迷糊糊应一声
    static let workingPokePhrases = [
        "（迷迷糊糊）哞……我再睡会儿",
        "（揉眼睛）唔……还没到休息时间吗？",
        "（梦话）嗯……豹拉……哦，是你呀",
        "（翻身）嘘……梦里正精彩呢"
    ]

    static let reminderPhrases = [
        "哞！该休息一下啦，喝口水活动活动~",
        "草原的牛都知道劳逸结合，起来走走吧！",
        "妈妈说过，坚持就会胜利——先站起来走走！",
        "休息是为了更好地出发，哞~"
    ]

    // MARK: - 生命周期

    func start() {
        lastTick = Date()
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)   // 菜单打开时也保持运行
        ticker = timer
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

    private func tick() {
        let now = Date()
        let dt = min(CGFloat(now.timeIntervalSince(lastTick)), 0.1)   // 封顶，防补帧瞬移
        lastTick = now

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

        // 打盹时偶尔说梦话（平均约 20 秒一句）
        if state == .sleeping, bubbleText == nil, Int.random(in: 0..<1200) == 0 {
            let phrase = Self.dreamPhrases.randomElement() ?? "（梦话）哞……"
            showBubble(phrase, duration: 3.5)
            // 梦到妈妈的那句：低音量同步播放电影里呢喃的「妈妈」
            if phrase.contains("妈妈") {
                SoundPlayer.play(SoundPlayer.mama, volume: 0.3)
            }
        }
    }

    private func pickNextState() {
        // 安静时期（工作模式 / 番茄钟专注中）：不漫游，回角落继续做梦
        if isPeaceful {
            settleIntoCorner()
            return
        }
        let roaming = UserDefaults.standard.object(forKey: "roamingEnabled") as? Bool ?? true
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

    private func setState(_ s: State, duration: TimeInterval) {
        state = s
        stateStartedAt = Date()
        stateUntil = Date().addingTimeInterval(duration)
        // 通知豹拉：牛来出发散步 / 睡着了
        if s == .walking { companion?.onPetStartedWalking() }
        if s == .sleeping { companion?.onPetStartedSleeping() }
    }

    // MARK: - 窗口移动

    private var visibleFrame: NSRect {
        window?.screen?.visibleFrame ?? NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
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
        let roaming = UserDefaults.standard.object(forKey: "roamingEnabled") as? Bool ?? true
        if roaming {
            stateUntil = Date()   // 立刻重新决策
        } else {
            setState(.sitting, duration: 3600)
        }
    }

    // MARK: - 休息提醒

    /// 读取设置并（重新）安排提醒定时器。reminderMinutes == 0 表示关闭。
    func configureReminder() {
        reminderTimer?.invalidate()
        reminderTimer = nil
        let minutes = UserDefaults.standard.object(forKey: "reminderMinutes") as? Int ?? 45
        guard minutes > 0 else { return }
        reminderTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.beginReminder() }
        }
    }

    private func beginReminder() {
        guard isVisible, state != .dragged else { return }
        let target = visibleFrame.midX - (window?.frame.width ?? 240) / 2
        state = .walkingTo(target)
        stateUntil = Date().addingTimeInterval(20)   // 兜底：走太久就放弃
    }

    private func arriveAtReminderSpot() {
        setState(.happy, duration: 2.5)
        showBubble(Self.reminderPhrases.randomElement() ?? "休息一下吧~", duration: 6)
    }

    // MARK: - 彩蛋事件（蛇 / 狼影）

    private func scheduleEvents() {
        let now = Date()
        // --demo：8 秒来蛇、15 秒来蝴蝶、30 秒来狼，方便演示
        nextSnakeAt = now.addingTimeInterval(demoMode ? 8 : .random(in: 300...900))
        nextButterflyAt = now.addingTimeInterval(demoMode ? 15 : .random(in: 240...720))
        nextWolfAt = now.addingTimeInterval(demoMode ? 30 : .random(in: 600...1500))
        let timer = Timer(timeInterval: 5, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.checkEvents() }
        }
        RunLoop.main.add(timer, forMode: .common)
        eventTimer = timer
    }

    private func checkEvents() {
        guard !isPeaceful, isVisible else { return }
        let now = Date()
        // 蛇和狼不同时出现：对方还在屏幕上时就延后
        if now >= nextSnakeAt {
            if isBusyForEvent || wolf?.running == true {
                nextSnakeAt = now.addingTimeInterval(20)   // 忙就 20 秒后再试
            } else {
                nextSnakeAt = now.addingTimeInterval(.random(in: 300...900))
                triggerSnakeEvent()
            }
        }
        if now >= nextWolfAt {
            if isBusyForEvent || snake?.running == true {
                nextWolfAt = now.addingTimeInterval(20)
            } else {
                nextWolfAt = now.addingTimeInterval(.random(in: 600...1500))
                triggerWolfEvent()
            }
        }
        if now >= nextButterflyAt {
            if isBusyForEvent {
                nextButterflyAt = now.addingTimeInterval(20)
            } else {
                nextButterflyAt = now.addingTimeInterval(.random(in: 240...720))
                if let window {
                    butterfly?.flyAcross(fromLeft: Bool.random(), groundY: window.frame.minY)
                }
            }
        }
    }

    /// 忙碌中（被拎/正在惊吓/正在追蝴蝶等）不触发彩蛋
    private var isBusyForEvent: Bool {
        switch state {
        case .dragged, .startled, .walkingTo, .walkingToSleep, .happy,
             .chasing, .pouncing, .stretching, .headbutting, .spinning, .dizzy:
            return true
        default:
            return false
        }
    }

    private func triggerSnakeEvent() {
        guard !isBusyForEvent, let snake, let window else { return }
        let fromLeft = Bool.random()
        snake.slitherAcross(fromLeft: fromLeft, groundY: window.frame.minY)
        facingLeft = fromLeft
        setState(.startled, duration: 2.0)
        showBubble("蛇……蛇！！", duration: 2)
        companion?.onPetStartled()
        snake.onExit = { [weak self] in
            MainActor.assumeIsolated { self?.afterSnake() }
        }
    }

    private func afterSnake() {
        showBubble("呼……爬走了爬走了，我不怕", duration: 3)
        setState(.happy, duration: 1.5)
    }

    // MARK: - 追蝴蝶

    /// 蝴蝶路过附近：开追！
    func startChasingButterfly() {
        guard !isPeaceful, isVisible, !isBusyForEvent, butterfly != nil else { return }
        showBubble("蝴蝶！等等我！", duration: 2)
        setState(.chasing, duration: 8)   // 兜底：追不上自己停下
    }

    /// 蝴蝶快到屏幕边了：跳起来扑
    func pounceAtButterfly() {
        guard state == .chasing else { return }
        setState(.pouncing, duration: 0.9)
    }

    /// 蝴蝶飞出屏幕（可能在追/扑中途消失）
    func butterflyGone() {
        switch state {
        case .chasing:
            showBubble("咦？蝴蝶呢……", duration: 2)
            setState(.idle, duration: 2)
        case .pouncing:
            showBubble("嘿嘿……差点就抓到了", duration: 2.5)
            setState(.idle, duration: 2.5)
        default:
            break
        }
    }

    private func triggerWolfEvent() {
        guard !isBusyForEvent, let wolf, let window else { return }
        let fromLeft = Bool.random()
        wolf.runAcross(fromLeft: fromLeft, groundY: window.frame.minY)
        facingLeft = fromLeft
        setState(.startled, duration: 2.2)
        showBubble("狼……狼！！", duration: 2.2)
        if companion?.present == true {
            companion?.guardAgainst(fromLeft: fromLeft)
        }
        wolf.onExit = { [weak self] in
            MainActor.assumeIsolated { self?.afterWolf() }
        }
    }

    private func afterWolf() {
        companion?.endGuard()
        let protected = companion?.present == true
        showBubble(protected ? "豹拉……谢谢你保护我" : "呼……它跑掉了，我不怕我不怕", duration: 3)
        setState(.happy, duration: 1.5)
    }

    // MARK: - 电量感知

    private func startBatteryMonitor() {
        checkBattery()
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.checkBattery() }
        }
        RunLoop.main.add(timer, forMode: .common)
        batteryTimer = timer
    }

    private func checkBattery() {
        guard let (percent, charging) = Self.readBattery() else { return }

        if charging, !wasCharging {
            setState(.happy, duration: 1.5)
            showBubble("来电啦！⚡ 满血复活！", duration: 3)
        }
        if !charging, percent <= 20, !lowBatteryWarned {
            lowBatteryWarned = true
            showBubble("你快没电了……我也饿得没力气了……记得充电", duration: 5)
            if !isPeaceful, !isBusyForEvent {
                setState(.sitting, duration: 60)   // 没精打采
            }
        }
        if percent > 30 { lowBatteryWarned = false }
        wasCharging = charging
    }

    // MARK: - 番茄钟

    /// 进入番茄钟：立刻开始第一个专注阶段
    private func startPomodoro() {
        pomodoroPhase = .focus
        completedFocusCount = 0
        pomodoroPaused = false
        phaseEndsAt = Date().addingTimeInterval(focusDuration)
        companion?.onPetModeChanged(.working)   // 专注时豹拉不打扰
        showBubble("番茄钟开始！专注 25 分钟，我去梦里陪你~", duration: 4)
        settleIntoCorner()
        pomodoroTimer?.invalidate()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.pomodoroTick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        pomodoroTimer = timer
        pomodoroTick()
    }

    private func stopPomodoro() {
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        pomodoroPaused = false
        pomodoroCountdown = ""
        menuBarLabel = "🐮"
    }

    private func pomodoroTick() {
        guard mode == .pomodoro else { return }
        if pomodoroPaused {
            if pomodoroCountdown != "已暂停" { pomodoroCountdown = "已暂停" }
            return
        }
        let remain = max(0, phaseEndsAt.timeIntervalSinceNow)
        // 菜单栏图标静态化、菜单内倒计时分钟级：都不每秒变，避免打开的菜单被反复重渲染闪白。
        // 相同字符串不重复赋值（@Published 每次赋值都触发 objectWillChange）。
        let label = pomodoroPhase == .focus ? "🐮🍅" : "🐮☕️"
        if menuBarLabel != label { menuBarLabel = label }
        let minutes = Int(remain) / 60
        let text = minutes >= 1 ? "还剩 \(minutes) 分钟" : "不到 1 分钟"
        if pomodoroCountdown != text { pomodoroCountdown = text }
        if remain <= 0 { advancePomodoroPhase() }
    }

    /// 阶段切换：专注→休息（每 4 轮一次 15 分钟长休息），休息→专注
    private func advancePomodoroPhase() {
        SoundPlayer.play(SoundPlayer.niulai, volume: 0.8)   // 一声「牛来！」叫你换阶段
        switch pomodoroPhase {
        case .focus:
            completedFocusCount += 1
            pomodoroPhase = .rest
            let longRest = completedFocusCount % 4 == 0
            phaseEndsAt = Date().addingTimeInterval(longRest ? longRestDuration : restDuration)
            companion?.onPetModeChanged(.leisure)   // 休息时豹拉可以来玩
            setState(.stretching, duration: 3)   // 睡醒伸个大懒腰
            showBubble(
                longRest
                    ? "哞！四轮专注完成！好好休息 15 分钟，你太棒了！"
                    : "哞！休息 5 分钟！站起来活动活动，喝口水~",
                duration: 5
            )
        case .rest:
            pomodoroPhase = .focus
            phaseEndsAt = Date().addingTimeInterval(focusDuration)
            companion?.onPetModeChanged(.working)
            showBubble("继续专注！我去梦里给你加油，待会儿见~", duration: 4)
            settleIntoCorner()
        }
    }

    func togglePomodoroPause() {
        guard mode == .pomodoro else { return }
        if pomodoroPaused {
            pomodoroPaused = false
            phaseEndsAt = Date().addingTimeInterval(pausedRemaining)
        } else {
            pomodoroPaused = true
            pausedRemaining = max(0, phaseEndsAt.timeIntervalSinceNow)
            menuBarLabel = "🐮 ⏸"
        }
        pomodoroTick()
    }

    func skipPomodoroPhase() {
        guard mode == .pomodoro else { return }
        pomodoroPaused = false
        advancePomodoroPhase()
        pomodoroTick()
    }

    /// 通过 IOKit 读取内置电池（台式机无电池时返回 nil）
    private static func readBattery() -> (percent: Int, charging: Bool)? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
              (desc[kIOPSTypeKey] as? String) == kIOPSInternalBatteryType,
              let capacity = desc[kIOPSCurrentCapacityKey] as? Int,
              let charging = desc[kIOPSIsChargingKey] as? Bool
        else { return nil }
        return (capacity, charging)
    }
}
