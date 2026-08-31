import AppKit
import SwiftUI

/// 云雀的飞行调度：每隔几分钟随机横穿屏幕一次，
/// 有 30% 概率中途落在牛来头顶歇脚，然后继续飞走。
/// 纯视觉彩蛋，窗口不响应鼠标。
@MainActor
final class LarkController: ObservableObject {

    @Published var flying = false
    @Published var perched = false
    @Published var facingLeft = true

    let pet: PetViewModel

    /// `--demo` 启动参数：首次 5 秒就飞、必定歇脚，方便调试
    private let demoMode = CommandLine.arguments.contains("--demo")

    private var window: NSWindow?
    private var moveTimer: Timer?
    private var lastTick = Date()
    private var direction: CGFloat = -1
    private var willPerch = false
    private var perchUntil = Date.distantPast

    static let size = NSSize(width: 120, height: 90)
    private let flySpeed: CGFloat = 85   // 翅膀受过伤，飞得慢

    nonisolated init(pet: PetViewModel) {
        self.pet = pet
    }

    func start() {
        scheduleNext(after: demoMode ? 5 : .random(in: 180...480))
    }

    private func scheduleNext(after interval: TimeInterval) {
        Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.beginFlight() }
        }
    }

    // MARK: - 飞行

    private func beginFlight() {
        guard pet.isVisible, let petWindow = pet.window else {
            scheduleNext(after: .random(in: 120...300))
            return
        }
        ensureWindow()
        guard let window else { return }

        let vf = petWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let fromLeft = Bool.random()
        direction = fromLeft ? 1 : -1
        facingLeft = !fromLeft

        let y = vf.minY + CGFloat.random(in: vf.height * 0.4...vf.height * 0.7)
        window.setFrameOrigin(NSPoint(x: fromLeft ? vf.minX - Self.size.width : vf.maxX, y: y))

        willPerch = demoMode || Double.random(in: 0..<1) < 0.3
        flying = true
        perched = false
        window.orderFrontRegardless()
        startMoveTimer()
    }

    private func tick() {
        let now = Date()
        let dt = CGFloat(now.timeIntervalSince(lastTick))
        lastTick = now
        guard flying, let window, let petWindow = pet.window else { return }
        let vf = petWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero

        if perched {
            // 歇在牛来头顶，跟着它走
            window.setFrameOrigin(perchOrigin(on: petWindow))
            if now >= perchUntil {
                perched = false   // 歇够了，继续飞
            }
            return
        }

        var origin = window.frame.origin
        origin.x += direction * flySpeed * dt

        if willPerch {
            // 接近牛来头顶时落下
            let perch = perchOrigin(on: petWindow)
            let approaching = direction > 0 ? origin.x >= perch.x : origin.x <= perch.x
            if approaching {
                origin = perch
                perched = true
                perchUntil = now.addingTimeInterval(.random(in: 20...60))
            }
        }
        window.setFrameOrigin(origin)

        // 飞出屏幕，本次航班结束
        if origin.x > vf.maxX + 10 || origin.x + Self.size.width < vf.minX - 10 {
            flying = false
            perched = false
            window.orderOut(nil)
            moveTimer?.invalidate()
            moveTimer = nil
            scheduleNext(after: demoMode ? 30 : .random(in: 180...480))
        }
    }

    /// 牛来头顶的位置（窗口顶部偏前）
    private func perchOrigin(on petWindow: NSWindow) -> NSPoint {
        NSPoint(
            x: petWindow.frame.midX - Self.size.width / 2,
            y: petWindow.frame.maxY - 40
        )
    }

    func setVisible(_ visible: Bool) {
        if visible {
            if flying { window?.orderFrontRegardless() }
        } else {
            window?.orderOut(nil)
        }
    }

    // MARK: - 窗口

    private func ensureWindow() {
        guard window == nil else { return }
        let w = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.level = .floating
        w.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        w.isReleasedWhenClosed = false
        w.ignoresMouseEvents = true   // 纯路过，不挡点击
        w.contentView = NSHostingView(rootView: LarkView(controller: self))
        w.setContentSize(Self.size)
        window = w
    }

    private func startMoveTimer() {
        lastTick = Date()
        moveTimer?.invalidate()
        moveTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.tick() }
        }
    }
}
