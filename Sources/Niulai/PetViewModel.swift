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
        case startled        // 吓一跳（小绳头/狼影）
        case investigating(CGFloat)  // 鼓起勇气凑近看（小绳头）
    }

    /// 休闲：满地漫游；工作：趴角落睡觉做梦，安静不打扰
    enum PetMode: String, Hashable {
        case leisure, working
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

    weak var window: NSWindow?
    weak var companion: CompanionController?
    weak var lark: LarkController?
    weak var rope: RopeController?
    weak var wolf: WolfController?

    private let walkSpeed: CGFloat = 55
    private var ticker: Timer?
    private var reminderTimer: Timer?
    private var lastTick = Date()
    private var stateUntil = Date()
    private var bubbleGeneration = 0

    // 彩蛋事件调度
    private let demoMode = CommandLine.arguments.contains("--demo")
    private var eventTimer: Timer?
    private var nextRopeAt = Date.distantFuture
    private var nextWolfAt = Date.distantFuture
    private var pendingRopeX: CGFloat?

    // 电量感知
    private var batteryTimer: Timer?
    private var wasCharging = false
    private var lowBatteryWarned = false

    nonisolated init() {}

    // MARK: - 模式切换

    private func reactToModeChange() {
        companion?.onPetModeChanged(mode)
        switch mode {
        case .working:
            showBubble("我去做个勇敢的梦啦，你专心工作~", duration: 3)
            settleIntoCorner()
        case .leisure:
            showBubble("我醒啦！梦里的我可勇敢了！", duration: 3)
            stateUntil = Date()   // 立刻恢复自由行为
        }
    }

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
        if mode == .working {
            settleIntoCorner()
        } else {
            setState(.idle, duration: 3)
        }
    }

    // MARK: - 主循环

    private func tick() {
        let now = Date()
        let dt = min(CGFloat(now.timeIntervalSince(lastTick)), 0.1)   // 封顶，防补帧瞬移
        lastTick = now

        guard isVisible, let window else { return }

        switch state {
        case .walking:
            move(dx: walkSpeed * dt * (facingLeft ? -1 : 1))
            bounceOffScreenEdge()
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
        case .investigating(let ropeX):
            // 蹑手蹑脚地凑近看
            let dir: CGFloat = ropeX > window.frame.midX ? 1 : -1
            facingLeft = dir < 0
            let step = walkSpeed * 0.55 * dt * dir
            move(dx: step)
            bounceOffScreenEdge()
            if abs(window.frame.midX - ropeX) < 70 {
                pendingRopeX = nil
                rope?.dismiss()
                showBubble("呼……只是根绳子，不怕不怕", duration: 3)
                setState(.happy, duration: 2)
            }
        default:
            break
        }

        // 惊吓结束 → 鼓起勇气去查看绳子
        if state == .startled, now >= stateUntil, let ropeX = pendingRopeX {
            state = .investigating(ropeX)
            stateUntil = now.addingTimeInterval(25)
        }

        // 绳子事件被打断（比如被拎走）：把绳子收走，别留在屏幕上
        if pendingRopeX != nil, state != .startled, !state.isInvestigating {
            pendingRopeX = nil
            rope?.dismiss()
        }

        if now >= stateUntil, state != .dragged, !state.isInvestigating {
            pickNextState()
        }

        // 打盹时偶尔说梦话（平均约 20 秒一句）
        if state == .sleeping, bubbleText == nil, Int.random(in: 0..<1200) == 0 {
            showBubble(Self.dreamPhrases.randomElement() ?? "（梦话）哞……", duration: 3.5)
        }
    }

    private func pickNextState() {
        // 工作模式：不漫游，回角落继续做梦
        if mode == .working {
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
            (.sleeping, 1)
        ]
        let total = pool.reduce(0) { $0 + $1.1 }
        var r = Double.random(in: 0..<total)
        var picked = pool[0].0
        for (s, w) in pool {
            r -= w
            if r <= 0 { picked = s; break }
        }
        if picked == .walking {
            facingLeft = Bool.random()
            setState(.walking, duration: Double.random(in: 5...12))
        } else {
            setState(picked, duration: Double.random(in: 4...9))
        }
    }

    private func setState(_ s: State, duration: TimeInterval) {
        state = s
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

    private func bounceOffScreenEdge() {
        guard let window else { return }
        let vf = visibleFrame
        var origin = window.frame.origin
        if origin.x < vf.minX {
            origin.x = vf.minX
            facingLeft = false
            window.setFrameOrigin(origin)
        } else if origin.x + window.frame.width > vf.maxX {
            origin.x = vf.maxX - window.frame.width
            facingLeft = true
            window.setFrameOrigin(origin)
        }
    }

    // MARK: - 互动

    /// 点击/戳一下
    func poke() {
        guard state != .dragged else { return }
        if mode == .working {
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
        rope?.setVisible(visible)
        wolf?.setVisible(visible)
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

    // MARK: - 彩蛋事件（小绳头 / 狼影）

    private func scheduleEvents() {
        let now = Date()
        // --demo：8 秒后来绳子，25 秒后来狼，方便演示
        nextRopeAt = now.addingTimeInterval(demoMode ? 8 : .random(in: 300...900))
        nextWolfAt = now.addingTimeInterval(demoMode ? 25 : .random(in: 600...1500))
        let timer = Timer(timeInterval: 5, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.checkEvents() }
        }
        RunLoop.main.add(timer, forMode: .common)
        eventTimer = timer
    }

    private func checkEvents() {
        guard mode == .leisure, isVisible else { return }
        let now = Date()
        if now >= nextRopeAt {
            if isBusyForEvent {
                nextRopeAt = now.addingTimeInterval(20)   // 忙就 20 秒后再试
            } else {
                nextRopeAt = now.addingTimeInterval(.random(in: 300...900))
                triggerRopeEvent()
            }
        }
        if now >= nextWolfAt {
            if isBusyForEvent {
                nextWolfAt = now.addingTimeInterval(20)
            } else {
                nextWolfAt = now.addingTimeInterval(.random(in: 600...1500))
                triggerWolfEvent()
            }
        }
    }

    /// 忙碌中（被拎/正在惊吓/正在赶路）不触发彩蛋
    private var isBusyForEvent: Bool {
        switch state {
        case .dragged, .startled, .investigating, .walkingTo, .walkingToSleep, .happy:
            return true
        default:
            return false
        }
    }

    private func triggerRopeEvent() {
        guard !isBusyForEvent, let rope, let window else { return }
        rope.spawn(nearPet: window.frame)
        pendingRopeX = rope.centerX
        facingLeft = rope.centerX < window.frame.midX
        setState(.startled, duration: 1.6)
        showBubble("啊！是小绳头！！", duration: 1.8)
        companion?.onPetStartled()
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
            if mode == .leisure, !isBusyForEvent {
                setState(.sitting, duration: 60)   // 没精打采
            }
        }
        if percent > 30 { lowBatteryWarned = false }
        wasCharging = charging
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

private extension PetViewModel.State {
    var isInvestigating: Bool {
        if case .investigating = self { return true }
        return false
    }
}
