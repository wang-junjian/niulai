import AppKit
import SwiftUI

/// 蛇：贴着地面蜿蜒爬过屏幕。纯视觉威胁，不响应鼠标。
@MainActor
final class SnakeController: ObservableObject {

    @Published var running = false
    @Published var facingLeft = false

    private var window: NSWindow?
    private lazy var ticker = FrameTicker { [weak self] dt in self?.tick(dt: dt) }
    private var direction: CGFloat = 1

    /// 蛇爬出屏幕后回调（牛来用于说感想）
    var onExit: (() -> Void)?

    static let size = NSSize(width: 170, height: 70)
    private let crawlSpeed: CGFloat = 110

    nonisolated init() {}

    func slitherAcross(fromLeft: Bool, groundY: CGFloat) {
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
        origin.x += direction * crawlSpeed * dt
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
        w.contentView = NSHostingView(rootView: SnakeView(controller: self))
        w.setContentSize(Self.size)
        window = w
    }
}

/// 青蛇（侧视爬行）：身体由脊线采样点生成变宽轮廓，波从头部向尾部传播，
/// 头部昂起微微晃动，吐信子。朝右爬，朝左时整体翻转。
struct SnakeView: View {
    @ObservedObject var controller: SnakeController

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate

            Canvas { ctx, _ in
                drawSnake(in: ctx, t: t)
            }
            .scaleEffect(x: controller.facingLeft ? -1 : 1)
        }
    }

    // MARK: - 配色

    private let bodyColor  = Color(red: 0.42, green: 0.58, blue: 0.30)   // 青绿
    private let darkColor  = Color(red: 0.28, green: 0.42, blue: 0.20)   // 背纹
    private let bellyColor = Color(red: 0.80, green: 0.81, blue: 0.60)   // 肚皮
    private let tongueColor = Color(red: 0.85, green: 0.25, blue: 0.25)

    // MARK: - 脊线

    private let sampleCount = 26

    /// 从尾（左，i=0）到头（右，i=N）的脊线采样；行进的横波向尾部传播
    private func spine(_ t: Double) -> [CGPoint] {
        (0...sampleCount).map { i in
            let f = Double(i) / Double(sampleCount)
            let x = 14 + f * 114
            let amp = 9 * (0.3 + 0.7 * (1 - f))   // 越靠尾摆幅越大，头部稳
            let y = 48 + sin(f * 5.4 - t * 8.0) * amp
            return CGPoint(x: x, y: y)
        }
    }

    /// 每一点的半宽：尾尖细、躯干粗、近头收窄
    private func halfWidth(_ f: Double) -> Double {
        1.2 + sin(f * .pi * 0.82) * 5.8
    }

    private func tangentNormal(_ pts: [CGPoint], _ i: Int) -> CGVector {
        let a = pts[max(0, i - 1)], b = pts[min(pts.count - 1, i + 1)]
        let dx = b.x - a.x, dy = b.y - a.y
        let len = max(0.001, hypot(dx, dy))
        return CGVector(dx: -dy / len, dy: dx / len)   // 单位法线
    }

    // MARK: - 绘制

    private func drawSnake(in ctx: GraphicsContext, t: Double) {
        let pts = spine(t)

        // 地面阴影（跟着身体中段）
        let mid = pts[sampleCount / 2]
        ctx.fill(
            Path(ellipseIn: CGRect(x: mid.x - 45, y: 58, width: 100, height: 8)),
            with: .color(.black.opacity(0.10))
        )

        // 身体轮廓：脊线两侧按半宽偏移，拼成闭合路径
        var outline = Path()
        for i in 0...sampleCount {
            let f = Double(i) / Double(sampleCount)
            let n = tangentNormal(pts, i)
            let w = halfWidth(f)
            let p = CGPoint(x: pts[i].x + n.dx * w, y: pts[i].y + n.dy * w)
            if i == 0 { outline.move(to: p) } else { outline.addLine(to: p) }
        }
        for i in (0...sampleCount).reversed() {
            let f = Double(i) / Double(sampleCount)
            let n = tangentNormal(pts, i)
            let w = halfWidth(f)
            outline.addLine(to: CGPoint(x: pts[i].x - n.dx * w, y: pts[i].y - n.dy * w))
        }
        outline.closeSubpath()
        ctx.fill(outline, with: .color(bodyColor))

        // 肚皮：沿脊线偏下描一条浅色带
        var belly = Path()
        for i in 0...sampleCount {
            let n = tangentNormal(pts, i)
            let p = CGPoint(x: pts[i].x - n.dx * 3, y: pts[i].y - n.dy * 3 + 1.5)
            if i == 0 { belly.move(to: p) } else { belly.addLine(to: p) }
        }
        ctx.stroke(belly, with: .color(bellyColor), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))

        // 背部菱形斑纹
        for k in stride(from: 2, through: sampleCount - 4, by: 3) {
            let f = Double(k) / Double(sampleCount)
            let n = tangentNormal(pts, k)
            let w = halfWidth(f)
            let c = CGPoint(x: pts[k].x + n.dx * w * 0.45, y: pts[k].y + n.dy * w * 0.45)
            ctx.drawLayer { layer in
                layer.translateBy(x: c.x, y: c.y)
                layer.rotate(by: .radians(atan2(n.dy, n.dx) + .pi / 2))
                layer.translateBy(x: -c.x, y: -c.y)
                layer.fill(
                    Path(ellipseIn: CGRect(x: c.x - 3.2, y: c.y - 2.1, width: 6.4, height: 4.2)),
                    with: .color(darkColor)
                )
            }
        }

        // 昂起的头：接在脊线末端，微微晃动
        let neck = pts[sampleCount]
        let sway = sin(t * 8.0 - 5.0) * 2
        let head = CGPoint(x: neck.x + 9, y: neck.y - 9 + sway)

        var neckBridge = Path()
        neckBridge.move(to: CGPoint(x: neck.x - 2, y: neck.y + 3))
        neckBridge.addLine(to: CGPoint(x: head.x - 6, y: head.y + 5))
        neckBridge.addLine(to: CGPoint(x: head.x + 2, y: head.y - 6))
        neckBridge.addLine(to: CGPoint(x: neck.x + 4, y: neck.y - 3))
        neckBridge.closeSubpath()
        ctx.fill(neckBridge, with: .color(bodyColor))

        ctx.drawLayer { layer in
            layer.translateBy(x: head.x, y: head.y)
            layer.rotate(by: .degrees(-18))
            layer.translateBy(x: -head.x, y: -head.y)
            // 椭圆脑袋，吻部略尖
            layer.fill(
                Path(ellipseIn: CGRect(x: head.x - 8, y: head.y - 6, width: 19, height: 12)),
                with: .color(bodyColor)
            )
            var snout = Path()
            snout.move(to: CGPoint(x: head.x + 8, y: head.y - 4))
            snout.addQuadCurve(
                to: CGPoint(x: head.x + 8, y: head.y + 4),
                control: CGPoint(x: head.x + 15, y: head.y)
            )
            snout.closeSubpath()
            layer.fill(snout, with: .color(bodyColor))
            // 头顶深色斑
            layer.fill(
                Path(ellipseIn: CGRect(x: head.x - 4, y: head.y - 5.5, width: 9, height: 4)),
                with: .color(darkColor)
            )
        }

        // 眼睛：琥珀色 + 竖瞳 + 高光
        let eye = CGPoint(x: head.x + 1.5, y: head.y - 2.5)
        ctx.fill(Path(ellipseIn: CGRect(x: eye.x - 2.6, y: eye.y - 2.6, width: 5.2, height: 5.2)),
                 with: .color(Color(red: 0.95, green: 0.72, blue: 0.18)))
        ctx.fill(Path(ellipseIn: CGRect(x: eye.x - 0.7, y: eye.y - 2.2, width: 1.4, height: 4.4)),
                 with: .color(.black))
        ctx.fill(Path(ellipseIn: CGRect(x: eye.x - 1.4, y: eye.y - 1.8, width: 1.1, height: 1.1)),
                 with: .color(.white))

        // 吐信子：周期性地伸出分叉的舌头
        let flick = max(0, sin(t * 2.6))
        let tongueLen = flick * 7
        if tongueLen > 1 {
            let base = CGPoint(x: head.x + 13, y: head.y + 1.5 + sway * 0.3)
            var tongue = Path()
            tongue.move(to: base)
            tongue.addLine(to: CGPoint(x: base.x + tongueLen, y: base.y - 1))
            tongue.move(to: CGPoint(x: base.x + tongueLen, y: base.y - 1))
            tongue.addLine(to: CGPoint(x: base.x + tongueLen + 3, y: base.y - 3.5))
            tongue.move(to: CGPoint(x: base.x + tongueLen, y: base.y - 1))
            tongue.addLine(to: CGPoint(x: base.x + tongueLen + 3, y: base.y + 1))
            ctx.stroke(tongue, with: .color(tongueColor),
                       style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        }
    }
}
