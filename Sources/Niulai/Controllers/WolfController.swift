import AppKit
import SwiftUI

/// 狼影：贴着地面飞奔横穿屏幕的狼。纯视觉威胁，不响应鼠标。
@MainActor
final class WolfController: ObservableObject {

    @Published var running = false
    @Published var facingLeft = false

    private var window: NSWindow?
    private lazy var ticker = FrameTicker { [weak self] dt in self?.tick(dt: dt) }
    private var direction: CGFloat = 1

    /// 狼跑出屏幕后回调（牛来用于说感想）
    var onExit: (() -> Void)?

    static let size = NSSize(width: 170, height: 95)
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
        ticker.start()
    }

    private func tick(dt: CGFloat) {
        guard running, let window else { return }
        let vf = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero

        var origin = window.frame.origin
        origin.x += direction * runSpeed * dt
        window.setFrameOrigin(origin)

        if origin.x > vf.maxX + 10 || origin.x + Self.size.width < vf.minX - 10 {
            running = false
            window.orderOut(nil)
            ticker.stop()
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

/// 狼（侧视飞奔）：灰蓝毛色三层（背深/躯干/腹浅），两节式腿做奔驰步态，
/// 鬃毛锯齿、大尾巴拖尾摆动、尖耳长吻、琥珀色眼睛。朝右跑，朝左时翻转。
struct WolfView: View {
    @ObservedObject var controller: WolfController

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let phase = sin(t * 11)            // 奔驰主相位
            let lift = -abs(cos(t * 11)) * 3   // 四腿腾空时身体上抛

            Canvas { ctx, _ in
                drawWolf(in: ctx, phase: phase)
            }
            .scaleEffect(x: controller.facingLeft ? -1 : 1)
            .offset(y: lift)
        }
    }

    // MARK: - 配色

    private let fur      = Color(red: 0.47, green: 0.49, blue: 0.56)   // 躯干
    private let backDark = Color(red: 0.31, green: 0.32, blue: 0.40)   // 背/鬃毛
    private let belly    = Color(red: 0.76, green: 0.76, blue: 0.79)   // 腹/吻
    private let legShade = Color(red: 0.36, green: 0.37, blue: 0.44)   // 近侧腿（与躯干拉开反差）
    private let farShade = Color(red: 0.29, green: 0.30, blue: 0.36)   // 远侧腿
    private let nose     = Color(red: 0.14, green: 0.14, blue: 0.17)
    private let amber    = Color(red: 0.95, green: 0.62, blue: 0.12)

    // MARK: - 绘制（头朝右）

    private func drawWolf(in ctx: GraphicsContext, phase: Double) {
        let p = phase

        // 地面阴影
        ctx.fill(
            Path(ellipseIn: CGRect(x: 45, y: 82, width: 85, height: 9)),
            with: .color(.black.opacity(0.12))
        )

        // 大尾巴：从臀部向后上方甩出，锯齿毛边，随步态摆动
        drawTail(in: ctx, sway: -8 + p * 12)

        // 远侧腿（颜色深、相位稍滞后，营造纵深）
        drawLeg(in: ctx, pivot: CGPoint(x: 102, y: 54), swing: p * 34 - 22, bend: -18, color: farShade)
        drawLeg(in: ctx, pivot: CGPoint(x: 61, y: 56), swing: -p * 40 + 20, bend: 22, color: farShade)

        // 躯干 + 胸 + 腹部
        ctx.drawLayer { layer in
            layer.translateBy(x: 84, y: 44)
            layer.rotate(by: .degrees(p * 3))      // 奔驰时身体轻微俯仰
            layer.translateBy(x: -84, y: -44)
            layer.fill(Path(ellipseIn: CGRect(x: 50, y: 30, width: 68, height: 30)), with: .color(fur))
            layer.fill(Path(ellipseIn: CGRect(x: 96, y: 38, width: 28, height: 24)), with: .color(fur)) // 胸
            layer.fill(Path(ellipseIn: CGRect(x: 62, y: 45, width: 48, height: 16)), with: .color(belly))
        }

        // 背部深色披毛 + 肩颈鬃毛锯齿
        var cape = Path()
        cape.move(to: CGPoint(x: 52, y: 38))
        cape.addQuadCurve(to: CGPoint(x: 112, y: 30), control: CGPoint(x: 82, y: 26))
        cape.addLine(to: CGPoint(x: 116, y: 42))
        cape.addQuadCurve(to: CGPoint(x: 58, y: 48), control: CGPoint(x: 86, y: 42))
        cape.closeSubpath()
        ctx.fill(cape, with: .color(backDark))
        for (hx, hy, s) in [(100.0, 28.0, 7.0), (108.0, 27.0, 8.0), (116.0, 29.0, 7.0), (92.0, 30.0, 6.0)] {
            var hackle = Path()
            hackle.move(to: CGPoint(x: hx - s / 2, y: hy + s))
            hackle.addLine(to: CGPoint(x: hx, y: hy))
            hackle.addLine(to: CGPoint(x: hx + s / 2, y: hy + s))
            hackle.closeSubpath()
            ctx.fill(hackle, with: .color(backDark))
        }

        // 近侧腿（比躯干深一号，画在身体前面才看得见）
        drawLeg(in: ctx, pivot: CGPoint(x: 106, y: 54), swing: p * 38, bend: -22, color: legShade)
        drawLeg(in: ctx, pivot: CGPoint(x: 64, y: 56), swing: -p * 44, bend: 26, color: legShade)

        // 脖子 + 头
        var neck = Path()
        neck.move(to: CGPoint(x: 106, y: 36))
        neck.addLine(to: CGPoint(x: 124, y: 20))
        neck.addLine(to: CGPoint(x: 132, y: 32))
        neck.addLine(to: CGPoint(x: 112, y: 48))
        neck.closeSubpath()
        ctx.fill(neck, with: .color(fur))

        // 头颅：楔形 + 长吻
        ctx.fill(Path(ellipseIn: CGRect(x: 118, y: 14, width: 26, height: 22)), with: .color(fur))
        var muzzle = Path()
        muzzle.move(to: CGPoint(x: 134, y: 24))
        muzzle.addLine(to: CGPoint(x: 156, y: 31))
        muzzle.addQuadCurve(to: CGPoint(x: 134, y: 36), control: CGPoint(x: 148, y: 38))
        muzzle.closeSubpath()
        ctx.fill(muzzle, with: .color(fur))
        // 吻部浅色下缘
        var lip = Path()
        lip.move(to: CGPoint(x: 136, y: 32))
        lip.addQuadCurve(to: CGPoint(x: 152, y: 33.5), control: CGPoint(x: 144, y: 37))
        ctx.stroke(lip, with: .color(belly), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        // 鼻尖
        ctx.fill(Path(ellipseIn: CGRect(x: 152, y: 28.5, width: 6, height: 5)), with: .color(nose))

        // 尖耳朵（远耳深、近耳亮，带耳廓）
        var earFar = Path()
        earFar.move(to: CGPoint(x: 122, y: 18))
        earFar.addLine(to: CGPoint(x: 124, y: 4))
        earFar.addLine(to: CGPoint(x: 131, y: 15))
        earFar.closeSubpath()
        ctx.fill(earFar, with: .color(backDark))
        var ear = Path()
        ear.move(to: CGPoint(x: 130, y: 17))
        ear.addLine(to: CGPoint(x: 135, y: 3))
        ear.addLine(to: CGPoint(x: 141, y: 16))
        ear.closeSubpath()
        ctx.fill(ear, with: .color(fur))
        var inner = Path()
        inner.move(to: CGPoint(x: 132.5, y: 15))
        inner.addLine(to: CGPoint(x: 135, y: 7))
        inner.addLine(to: CGPoint(x: 138.5, y: 15))
        inner.closeSubpath()
        ctx.fill(inner, with: .color(backDark))

        // 眼睛：琥珀杏仁眼 + 黑瞳 + 高光
        ctx.fill(Path(ellipseIn: CGRect(x: 129, y: 22, width: 6.5, height: 5)), with: .color(amber))
        ctx.fill(Path(ellipseIn: CGRect(x: 131, y: 23, width: 2.6, height: 3.2)), with: .color(.black))
        ctx.fill(Path(ellipseIn: CGRect(x: 130, y: 22.8, width: 1.2, height: 1.2)), with: .color(.white))
    }

    /// 大尾巴：臀部向后甩出的蓬松尾巴，细锯齿表现毛感
    private func drawTail(in ctx: GraphicsContext, sway: Double) {
        ctx.drawLayer { layer in
            layer.translateBy(x: 52, y: 42)
            layer.rotate(by: .degrees(sway))
            layer.translateBy(x: -52, y: -42)
            var tail = Path()
            tail.move(to: CGPoint(x: 54, y: 38))
            // 上缘：细密锯齿
            tail.addLine(to: CGPoint(x: 47, y: 31))
            tail.addLine(to: CGPoint(x: 44, y: 34))
            tail.addLine(to: CGPoint(x: 38, y: 27))
            tail.addLine(to: CGPoint(x: 35, y: 31))
            tail.addLine(to: CGPoint(x: 29, y: 24))
            tail.addLine(to: CGPoint(x: 26, y: 29))
            tail.addLine(to: CGPoint(x: 20, y: 24))
            tail.addLine(to: CGPoint(x: 17, y: 28))
            // 尾尖
            tail.addQuadCurve(to: CGPoint(x: 19, y: 38), control: CGPoint(x: 11, y: 33))
            // 下缘
            tail.addLine(to: CGPoint(x: 30, y: 43))
            tail.addLine(to: CGPoint(x: 34, y: 39))
            tail.addLine(to: CGPoint(x: 46, y: 48))
            tail.closeSubpath()
            layer.fill(tail, with: .color(backDark))
            // 尾尖一撮浅色
            layer.fill(
                Path(ellipseIn: CGRect(x: 13, y: 27, width: 8, height: 8)),
                with: .color(belly.opacity(0.9))
            )
        }
    }

    /// 两节式腿：大腿绕 pivot 摆 swing 度，小腿再折 bend 度，末端画爪。
    /// swing 0° = 垂直向下，正值向前（+x）摆。
    private func drawLeg(in ctx: GraphicsContext, pivot: CGPoint, swing: Double, bend: Double, color: Color) {
        let a1 = swing * .pi / 180
        let knee = CGPoint(x: pivot.x + sin(a1) * 17, y: pivot.y + cos(a1) * 17)
        let a2 = (swing + bend) * .pi / 180
        let paw = CGPoint(x: knee.x + sin(a2) * 16, y: knee.y + cos(a2) * 16)

        var upper = Path()
        upper.move(to: pivot)
        upper.addLine(to: knee)
        ctx.stroke(upper, with: .color(color), style: StrokeStyle(lineWidth: 9, lineCap: .round))
        var lower = Path()
        lower.move(to: knee)
        lower.addLine(to: paw)
        ctx.stroke(lower, with: .color(color), style: StrokeStyle(lineWidth: 6, lineCap: .round))
        // 爪
        ctx.fill(
            Path(ellipseIn: CGRect(x: paw.x - 2, y: paw.y - 2.5, width: 10, height: 5)),
            with: .color(color)
        )
    }
}
