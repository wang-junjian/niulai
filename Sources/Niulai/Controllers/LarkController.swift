import AppKit
import SwiftUI

/// 云雀的飞行调度：每隔几分钟随机横穿屏幕一次，
/// 有 30% 概率中途落在牛来头顶歇脚，然后继续飞走。
/// 纯视觉彩蛋，窗口不响应鼠标。
/// 移动骨架在 ScreenCrosser 基类；这里留调度（scheduleNext/beginFlight）
/// 和歇脚子状态机（updatePosition / perched）。
@MainActor
final class LarkController: ScreenCrosser {

    @Published var perched = false

    let pet: PetViewModel

    /// `--demo` 启动参数：首次 5 秒就飞、必定歇脚，方便调试
    private let demoMode = CommandLine.arguments.contains("--demo")

    private var willPerch = false
    private var perchUntil = Date.distantPast

    override class var size: NSSize { NSSize(width: 120, height: 90) }
    private let flySpeed: CGFloat = 85   // 翅膀受过伤，飞得慢

    nonisolated init(pet: PetViewModel) {
        self.pet = pet
    }

    func start() {
        scheduleNext(after: demoMode ? 5 : .random(in: 180...480))
    }

    private func scheduleNext(after interval: TimeInterval) {
        // .common 模式：菜单打开期间也照常吃时（默认 mode 的 scheduledTimer 会暂停）
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.beginFlight() }
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    // MARK: - 飞行

    private func beginFlight() {
        // 安静时期（工作模式 / 番茄钟专注中）云雀不打扰，过会儿再来看看
        guard !pet.isPeaceful else {
            scheduleNext(after: .random(in: 120...240))
            return
        }
        guard pet.isVisible, let petWindow = pet.window else {
            scheduleNext(after: .random(in: 120...300))
            return
        }
        let vf = ScreenGeometry.visibleFrame(of: petWindow)
        let fromLeft = Bool.random()
        let y = vf.minY + CGFloat.random(in: vf.height * 0.4...vf.height * 0.7)
        startCrossing(fromLeft: fromLeft, groundY: y, referenceWindow: petWindow)
    }

    // MARK: - ScreenCrosser hook

    override func onWillStart(fromLeft: Bool, groundY: CGFloat) {
        willPerch = demoMode || Double.random(in: 0..<1) < 0.3
        perched = false
    }

    override func updatePosition(dt: CGFloat, origin: inout CGPoint, vf: NSRect) {
        let now = Date()

        if perched {
            // 歇在牛来头顶，跟着它走
            if let petWindow = pet.window {
                origin = perchOrigin(on: petWindow)
            }
            if now >= perchUntil {
                perched = false
                willPerch = false   // 歇够了继续飞走，不再回头落第二次
            }
            return
        }

        origin.x += direction * flySpeed * dt

        if willPerch, let petWindow = pet.window {
            // 接近牛来头顶时落下
            let perch = perchOrigin(on: petWindow)
            let approaching = direction > 0 ? origin.x >= perch.x : origin.x <= perch.x
            if approaching {
                origin = perch
                perched = true
                perchUntil = now.addingTimeInterval(.random(in: 20...60))
            }
        }
    }

    override func onDidExit() {
        scheduleNext(after: demoMode ? 30 : .random(in: 180...480))
    }

    /// 牛来头顶的位置（窗口顶部偏前）
    private func perchOrigin(on petWindow: NSWindow) -> NSPoint {
        NSPoint(
            x: petWindow.frame.midX - Self.size.width / 2,
            y: petWindow.frame.maxY - 40
        )
    }

    override func setVisible(_ visible: Bool) {
        if visible {
            if running { window?.orderFrontRegardless() }
        } else {
            window?.orderOut(nil)
        }
    }

    override func makeContentView() -> AnyView {
        AnyView(LarkView(controller: self))
    }
}
