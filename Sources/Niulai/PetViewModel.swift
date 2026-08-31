import AppKit
import SwiftUI

/// 牛来的行为状态机：决定它什么时候发呆、漫步、坐下、打盹，
/// 并驱动窗口在桌面上移动。点击互动和休息提醒也在这里。
@MainActor
final class PetViewModel: ObservableObject {

    enum State: Equatable {
        case idle            // 发呆站立
        case walking         // 自由漫步
        case walkingTo(CGFloat)  // 朝某个 x 坐标走（用于提醒时走到屏幕中间）
        case sitting         // 坐下
        case sleeping        // 打盹
        case happy           // 开心（被戳/落地后的短暂反应）
        case dragged         // 被鼠标抓着
    }

    @Published private(set) var state: State = .idle
    @Published var facingLeft = false
    @Published var bubbleText: String?
    @Published var isVisible = true

    weak var window: NSWindow?

    private let walkSpeed: CGFloat = 55
    private var ticker: Timer?
    private var reminderTimer: Timer?
    private var lastTick = Date()
    private var stateUntil = Date()
    private var bubbleGeneration = 0

    nonisolated init() {}

    // MARK: - 台词

    static let pokePhrases = [
        "哞~",
        "勇气已经在我心底了！",
        "今天也要加油呀！",
        "我才不是胆小鬼！",
        "站起来，追上牛群！",
        "豹拉是我的好朋友~",
        "你戳我干嘛啦，哞！",
        "妈妈说过，坚持就会胜利！"
    ]

    static let reminderPhrases = [
        "哞！该休息一下啦，喝口水活动活动~",
        "草原的牛都知道劳逸结合，起来走走吧！",
        "休息是为了更好地出发，哞~"
    ]

    // MARK: - 生命周期

    func start() {
        setState(.idle, duration: 3)
        lastTick = Date()
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.tick() }
        }
        configureReminder()
    }

    // MARK: - 主循环

    private func tick() {
        let now = Date()
        let dt = CGFloat(now.timeIntervalSince(lastTick))
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
        default:
            break
        }

        if now >= stateUntil, state != .dragged {
            pickNextState()
        }
    }

    private func pickNextState() {
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
}
