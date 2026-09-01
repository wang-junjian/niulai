import AppKit
import SwiftUI

/// 「小绳头」道具：一根躺在地上、微微扭动的绳子。
/// 牛来被蛇咬过，最怕这种像绳子的东西——但其实它只是根绳子。
@MainActor
final class RopeController: ObservableObject {

    private var window: NSWindow?

    static let size = NSSize(width: 110, height: 50)

    /// 绳子的中心点（屏幕坐标），供牛来靠近时定位
    private(set) var centerX: CGFloat = 0

    nonisolated init() {}

    /// 在牛来附近的地面上出现
    func spawn(nearPet petFrame: NSRect) {
        ensureWindow()
        guard let window else { return }
        let vf = window.screen?.visibleFrame ?? petWindowScreen(petFrame) ?? .zero

        let side: CGFloat = Bool.random() ? 1 : -1
        var x = petFrame.midX + side * CGFloat.random(in: 200...380) - Self.size.width / 2
        x = min(max(x, vf.minX), vf.maxX - Self.size.width)
        window.setFrameOrigin(NSPoint(x: x, y: petFrame.minY))
        centerX = x + Self.size.width / 2
        window.orderFrontRegardless()
    }

    func dismiss() {
        window?.orderOut(nil)
    }

    var isPresent: Bool { window?.isVisible ?? false }

    func setVisible(_ visible: Bool) {
        if !visible { window?.orderOut(nil) }
    }

    private func petWindowScreen(_ petFrame: NSRect) -> NSRect? {
        NSScreen.screens.first { $0.frame.intersects(petFrame) }?.visibleFrame
    }

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
        w.ignoresMouseEvents = true
        w.contentView = NSHostingView(rootView: RopeView())
        w.setContentSize(Self.size)
        window = w
    }
}

/// 微微扭动的绳子（也会被人看成蛇……）
struct RopeView: View {
    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, _ in
                // 蛇形扭动：控制点随时间微微起伏
                var rope = Path()
                rope.move(to: CGPoint(x: 10, y: 38))
                var x: CGFloat = 10
                for i in 1...5 {
                    let nextX: CGFloat = 10 + CGFloat(i) * 18
                    let wobble = sin(t * 2.5 + Double(i) * 1.3) * 3
                    let control = CGPoint(x: x + 9, y: 38 + (i % 2 == 0 ? -7 : 7) + wobble)
                    rope.addQuadCurve(to: CGPoint(x: nextX, y: 38), control: control)
                    x = nextX
                }
                ctx.stroke(
                    rope,
                    with: .color(Color(red: 0.48, green: 0.40, blue: 0.31)),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                // 绳头散开的绳茬
                ctx.fill(
                    Path(ellipseIn: CGRect(x: 97, y: 34, width: 7, height: 7)),
                    with: .color(Color(red: 0.55, green: 0.47, blue: 0.37))
                )
            }
        }
    }
}
