import AppKit
import SwiftUI

/// 小蝴蝶：慢悠悠掠过屏幕。牛来注意到会小跑着追，快飞出屏幕时
/// 跳起来扑——多半扑空，蝴蝶加速往上逃走。纯视觉，不响应鼠标。
@MainActor
final class ButterflyController: ObservableObject {

    @Published var flying = false
    @Published var facingLeft = false

    weak var pet: PetViewModel?

    private var window: NSWindow?
    private var timer: Timer?
    private var lastTick = Date()
    private var direction: CGFloat = 1
    private var baseY: CGFloat = 0
    private var flyTime: TimeInterval = 0
    private var escaping = false      // 被扑之后加速逃走
    private var hasPounced = false    // 一次飞行只被扑一次

    /// 蝴蝶当前的屏幕 x 坐标（牛来追它用）
    var currentX: CGFloat { window?.frame.midX ?? 0 }

    static let size = NSSize(width: 70, height: 55)
    private let cruiseSpeed: CGFloat = 65
    private let escapeSpeed: CGFloat = 190

    nonisolated init() {}

    func flyAcross(fromLeft: Bool, groundY: CGFloat) {
        guard let pet, pet.isVisible, !pet.isPeaceful, let petWindow = pet.window else { return }
        ensureWindow()
        guard let window else { return }
        let vf = petWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero

        direction = fromLeft ? 1 : -1
        facingLeft = !fromLeft
        baseY = groundY + 95   // 牛来脑袋的高度，跳一跳够得着
        flyTime = 0
        escaping = false
        hasPounced = false
        window.setFrameOrigin(NSPoint(
            x: fromLeft ? vf.minX - Self.size.width : vf.maxX,
            y: baseY
        ))
        flying = true
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
        guard flying, let window, let pet, let petWindow = pet.window else { return }
        let vf = petWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero

        flyTime += dt
        var origin = window.frame.origin
        origin.x += direction * (escaping ? escapeSpeed : cruiseSpeed) * dt
        origin.y = baseY + sin(flyTime * 3) * 16   // 蝴蝶式上下翻飞
        if escaping { baseY += 50 * dt }           // 逃走时往上爬升
        window.setFrameOrigin(origin)

        // 路过牛来附近：牛来注意到了，开始追
        if !escaping, pet.state != .chasing, abs(currentX - petWindow.frame.midX) < 340 {
            pet.startChasingButterfly()
        }

        // 快到出口：牛来起跳扑蝶，蝴蝶受惊加速逃走
        if !escaping, !hasPounced, pet.state == .chasing {
            let remaining = direction > 0
                ? vf.maxX - origin.x
                : origin.x + Self.size.width - vf.minX
            if remaining < 380 {
                hasPounced = true
                escaping = true
                pet.pounceAtButterfly()
            }
        }

        // 飞出屏幕，本次造访结束
        if origin.x > vf.maxX + 10 || origin.x + Self.size.width < vf.minX - 10 {
            flying = false
            window.orderOut(nil)
            timer?.invalidate()
            timer = nil
            pet.butterflyGone()
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
        w.contentView = NSHostingView(rootView: ButterflyView(controller: self))
        w.setContentSize(Self.size)
        window = w
    }
}

/// 小蝴蝶（侧视朝右飞）：橘粉色四片翅膀快速扇动，深色细身子，卷卷触角。
struct ButterflyView: View {
    @ObservedObject var controller: ButterflyController

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let flap = 0.25 + 0.75 * abs(sin(t * 16))   // 翅膀开合比例

            Canvas { ctx, _ in
                drawButterfly(in: ctx, flap: flap)
            }
            .scaleEffect(x: controller.facingLeft ? -1 : 1)
        }
    }

    private let wingNear = Color(red: 0.96, green: 0.60, blue: 0.32)   // 橘粉近翅
    private let wingFar  = Color(red: 0.84, green: 0.44, blue: 0.24)   // 远翅深色
    private let dark     = Color(red: 0.25, green: 0.18, blue: 0.12)

    private func drawButterfly(in ctx: GraphicsContext, flap: CGFloat) {
        let bodyX: CGFloat = 35   // 身体中线

        // 远侧翅膀（先画，压在近翅下面）
        drawWing(in: ctx, bodyX: bodyX, flap: flap, far: true)

        // 身体 + 头
        ctx.fill(
            Path(roundedRect: CGRect(x: bodyX - 2.5, y: 22, width: 5, height: 18), cornerRadius: 2.5),
            with: .color(dark)
        )
        ctx.fill(Path(ellipseIn: CGRect(x: bodyX - 3.5, y: 16, width: 7, height: 7)), with: .color(dark))

        // 卷卷触角
        for side in [-1.0, 1.0] {
            var antenna = Path()
            antenna.move(to: CGPoint(x: bodyX + side, y: 17))
            antenna.addQuadCurve(
                to: CGPoint(x: bodyX + side * 6 + 3, y: 9),
                control: CGPoint(x: bodyX + side * 5 + 2, y: 13)
            )
            ctx.stroke(antenna, with: .color(dark), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            ctx.fill(
                Path(ellipseIn: CGRect(x: bodyX + side * 6 + 1.5, y: 7, width: 3, height: 3)),
                with: .color(dark)
            )
        }

        // 近侧翅膀（亮色带斑点）
        drawWing(in: ctx, bodyX: bodyX, flap: flap, far: false)
    }

    /// 画一侧上下两片翅膀，绕身体中线纵向开合模拟扇动
    private func drawWing(in ctx: GraphicsContext, bodyX: CGFloat, flap: CGFloat, far: Bool) {
        let color = far ? wingFar : wingNear
        let inset: CGFloat = far ? 5 : 0   // 远翅略小
        ctx.drawLayer { layer in
            layer.translateBy(x: bodyX, y: 28)
            layer.scaleBy(x: 1, y: flap)
            layer.translateBy(x: -bodyX, y: -28)
            // 上翅：大圆瓣
            layer.fill(
                Path(ellipseIn: CGRect(x: bodyX - 24 + inset, y: 6 + inset, width: 23 - inset, height: 22 - inset)),
                with: .color(color)
            )
            // 下翅：小圆瓣
            layer.fill(
                Path(ellipseIn: CGRect(x: bodyX - 18 + inset, y: 27, width: 17 - inset, height: 15 - inset)),
                with: .color(color)
            )
            if !far {
                // 近翅白色斑点
                layer.fill(
                    Path(ellipseIn: CGRect(x: bodyX - 19, y: 11, width: 5, height: 5)),
                    with: .color(.white.opacity(0.85))
                )
                layer.fill(
                    Path(ellipseIn: CGRect(x: bodyX - 13, y: 31, width: 3.5, height: 3.5)),
                    with: .color(.white.opacity(0.85))
                )
            }
        }
    }
}
