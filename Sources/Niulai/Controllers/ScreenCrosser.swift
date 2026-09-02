import AppKit
import SwiftUI

/// 横穿屏幕类角色的基类：蛇 / 狼影 / 蝴蝶 / 云雀共用
/// 「从屏幕一侧入场 → 每帧移动 → 出另一侧后一次性回调」的骨架。
/// 子类用 hook 定制行为，模板方法 startCrossing / tick 不可覆写。
/// （协议扩展给不了 @Published 存储属性，所以用基类。）
@MainActor
class ScreenCrosser: ObservableObject {

    @Published var running = false
    @Published var facingLeft = false

    /// 出屏后的一次性回调（调用后置 nil）：蛇/狼让牛来说感想，云雀排下一班
    var onExit: (() -> Void)?

    /// 横向速度（默认直线移动用；子类覆写）
    var speed: CGFloat { 0 }

    /// 窗口尺寸（子类覆写）
    class var size: NSSize { .zero }

    /// 当前屏幕 x 坐标（牛来追蝴蝶要读）
    var currentX: CGFloat { window?.frame.midX ?? 0 }

    /// 子类 hook 里可读（如歇脚判定要看参考窗位置）
    private(set) var window: NSWindow?
    private var referenceWindow: NSWindow?
    private lazy var ticker = FrameTicker { [weak self] dt in self?.tick(dt: dt) }

    /// 移动方向：+1 向右，-1 向左（startCrossing 按 fromLeft 设置）
    var direction: CGFloat = 1

    nonisolated init() {}

    // MARK: - 子类 hook（默认实现 = 贴地直线横穿）

    /// 出发前检查（蝴蝶要求牛来在场且非安静期），false 则放弃本次出场
    func canStart() -> Bool { true }

    /// 入场前重置状态（蝴蝶的配色/逃逸标志、云雀的歇脚意愿等）
    func onWillStart(fromLeft: Bool, groundY: CGFloat) {}

    /// 出生点：默认从屏幕外贴地入场
    func startOrigin(fromLeft: Bool, vf: NSRect, groundY: CGFloat) -> CGPoint {
        CGPoint(x: fromLeft ? vf.minX - Self.size.width : vf.maxX, y: groundY)
    }

    /// 每帧移动：默认直线
    func updatePosition(dt: CGFloat, origin: inout CGPoint, vf: NSRect) {
        origin.x += direction * speed * dt
    }

    /// 窗口落位后的判定（蝴蝶触发牛来追/扑）
    func afterMove(vf: NSRect) {}

    /// 出屏清理后回调（云雀排下一班）
    func onDidExit() {}

    /// 窗口内容（子类给各自的 View）
    func makeContentView() -> AnyView { AnyView(EmptyView()) }

    // MARK: - 模板

    final func startCrossing(fromLeft: Bool, groundY: CGFloat, referenceWindow: NSWindow? = nil) {
        guard canStart() else { return }
        ensureWindow()
        guard let window else { return }
        self.referenceWindow = referenceWindow
        let vf = ScreenGeometry.visibleFrame(of: referenceWindow ?? window)

        direction = fromLeft ? 1 : -1
        facingLeft = !fromLeft
        onWillStart(fromLeft: fromLeft, groundY: groundY)
        window.setFrameOrigin(startOrigin(fromLeft: fromLeft, vf: vf, groundY: groundY))
        running = true
        window.orderFrontRegardless()
        ticker.start()
    }

    private func tick(dt: CGFloat) {
        guard running, let window else { return }
        let vf = ScreenGeometry.visibleFrame(of: referenceWindow ?? window)

        var origin = window.frame.origin
        updatePosition(dt: dt, origin: &origin, vf: vf)
        window.setFrameOrigin(origin)
        afterMove(vf: vf)

        if origin.x > vf.maxX + 10 || origin.x + Self.size.width < vf.minX - 10 {
            running = false
            window.orderOut(nil)
            ticker.stop()
            onDidExit()
            let callback = onExit
            onExit = nil
            callback?()
        }
    }

    func setVisible(_ visible: Bool) {
        if !visible { window?.orderOut(nil) }
    }

    private func ensureWindow() {
        guard window == nil else { return }
        window = WindowFactory.makeFloatingWindow(
            size: Self.size,
            ignoresMouseEvents: true,   // 横穿类角色一律纯视觉，不挡点击
            rootView: makeContentView()
        )
    }
}
