import AppKit
import SwiftUI

/// 狼影：贴着地面快速横穿屏幕的狼的剪影。纯视觉威胁，不响应鼠标。
@MainActor
final class WolfController: ObservableObject {

    @Published var running = false
    @Published var facingLeft = false

    private var window: NSWindow?
    private var timer: Timer?
    private var lastTick = Date()
    private var direction: CGFloat = 1

    /// 狼跑出屏幕后回调（牛来用于说感想）
    var onExit: (() -> Void)?

    static let size = NSSize(width: 150, height: 80)
    private let runSpeed: CGFloat = 300

    nonisolated init() {}

    func runAcross(fromLeft: Bool, groundY: CGFloat) {
        ensureWindow()
        guard let window else { return }
        let vf = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero

        direction = fromLeft ? 1 : -1
        facingLeft = !fromLeft
        window.setFrameOrigin(NSPoint(
            x: fromLeft ? vf.minX - Self.size.width : vf.maxX,
            y: groundY
        ))
        running = true
        window.orderFrontRegardless()

        lastTick = Date()
        timer?.invalidate()
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        let now = Date()
        let dt = min(CGFloat(now.timeIntervalSince(lastTick)), 0.1)
        lastTick = now
        guard running, let window else { return }
        let vf = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero

        var origin = window.frame.origin
        origin.x += direction * runSpeed * dt
        window.setFrameOrigin(origin)

        if origin.x > vf.maxX + 10 || origin.x + Self.size.width < vf.minX - 10 {
            running = false
            window.orderOut(nil)
            timer?.invalidate()
            timer = nil
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
        w.contentView = NSHostingView(rootView: WolfView(controller: self))
        w.setContentSize(Self.size)
        window = w
    }
}

/// 狼的剪影（侧视奔跑，红眼睛），朝右跑，朝左时翻转。
struct WolfView: View {
    @ObservedObject var controller: WolfController

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let legPhase = sin(t * 16) * 28
            let bob = -abs(sin(t * 16)) * 3

            Canvas { ctx, _ in
                drawWolf(in: ctx, legPhase: legPhase)
            }
            .scaleEffect(x: controller.facingLeft ? -1 : 1)
            .offset(y: bob)
        }
    }

    private let ink = Color(red: 0.24, green: 0.24, blue: 0.29).opacity(0.85)

    private func drawWolf(in ctx: GraphicsContext, legPhase: Double) {
        // 尾巴（向后上方翘起）
        var tail = Path()
        tail.move(to: CGPoint(x: 42, y: 36))
        tail.addQuadCurve(to: CGPoint(x: 18, y: 20), control: CGPoint(x: 28, y: 22))
        ctx.stroke(tail, with: .color(ink), style: StrokeStyle(lineWidth: 7, lineCap: .round))

        // 四条腿（快速交替）
        for (lx, phase) in [(52.0, legPhase), (64.0, -legPhase), (92.0, -legPhase), (104.0, legPhase)] {
            ctx.drawLayer { layer in
                layer.translateBy(x: lx, y: 50)
                layer.rotate(by: .degrees(phase))
                layer.translateBy(x: -lx, y: -50)
                layer.fill(
                    Path(roundedRect: CGRect(x: lx - 3, y: 48, width: 6, height: 28), cornerRadius: 3),
                    with: .color(ink)
                )
            }
        }

        // 身体（低伏奔跑姿态）
        ctx.fill(Path(ellipseIn: CGRect(x: 38, y: 30, width: 74, height: 26)), with: .color(ink))

        // 头 + 尖吻
        ctx.fill(Path(ellipseIn: CGRect(x: 98, y: 22, width: 32, height: 24)), with: .color(ink))
        var snout = Path()
        snout.move(to: CGPoint(x: 124, y: 30))
        snout.addLine(to: CGPoint(x: 144, y: 37))
        snout.addLine(to: CGPoint(x: 124, y: 43))
        snout.closeSubpath()
        ctx.fill(snout, with: .color(ink))

        // 尖耳朵
        var ear = Path()
        ear.move(to: CGPoint(x: 104, y: 26))
        ear.addLine(to: CGPoint(x: 108, y: 12))
        ear.addLine(to: CGPoint(x: 115, y: 24))
        ear.closeSubpath()
        ctx.fill(ear, with: .color(ink))

        // 红眼睛（夜里那一抹凶光）
        ctx.fill(
            Path(ellipseIn: CGRect(x: 113, y: 30, width: 4, height: 4)),
            with: .color(Color(red: 0.85, green: 0.25, blue: 0.15))
        )
    }
}
