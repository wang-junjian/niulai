import AppKit
import SwiftUI

/// 小蝴蝶：慢悠悠掠过屏幕。牛来注意到会小跑着追，快飞出屏幕时
/// 跳起来扑——多半扑空，蝴蝶加速往上逃走。纯视觉，不响应鼠标。
@MainActor
final class ButterflyController: ObservableObject {

    @Published var flying = false
    @Published var facingLeft = false
    @Published private(set) var wingNear = ButterflyController.colorSchemes[0].near
    @Published private(set) var wingFar = ButterflyController.colorSchemes[0].far

    /// 每次出场随机选一种配色（近翅/远翅）
    nonisolated static let colorSchemes: [(near: Color, far: Color)] = [
        (Color(red: 0.96, green: 0.60, blue: 0.32), Color(red: 0.84, green: 0.44, blue: 0.24)),  // 橘粉
        (Color(red: 0.55, green: 0.65, blue: 0.95), Color(red: 0.40, green: 0.48, blue: 0.82)),  // 蓝紫
        (Color(red: 0.98, green: 0.82, blue: 0.35), Color(red: 0.88, green: 0.66, blue: 0.22)),  // 明黄
        (Color(red: 0.55, green: 0.85, blue: 0.65), Color(red: 0.38, green: 0.70, blue: 0.50)),  // 薄荷
        (Color(red: 0.95, green: 0.55, blue: 0.68), Color(red: 0.82, green: 0.38, blue: 0.52)),  // 粉红
    ]

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
        let scheme = Self.colorSchemes.randomElement() ?? Self.colorSchemes[0]
        wingNear = scheme.near
        wingFar = scheme.far
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

    /// 预览/调试用：直接指定配色
    func setSchemeForPreview(_ scheme: (near: Color, far: Color)) {
        wingNear = scheme.near
        wingFar = scheme.far
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

/// 小蝴蝶（侧视朝右飞）：水平细身体，上下两瓣翅膀绕根部快速扇动，
/// 卷卷触角朝前。翅膀配色由 controller 每次出场随机指定。
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

    private let dark = Color(red: 0.25, green: 0.18, blue: 0.12)

    private func drawButterfly(in ctx: GraphicsContext, flap: CGFloat) {
        let attach = CGPoint(x: 40, y: 31)   // 翅膀根部（身体上侧）

        // 远侧翅膀（深色偏小，先画压在下面）
        drawWings(in: ctx, attach: attach, flap: flap, far: true)

        // 身体：水平胶囊 + 头部圆点（朝右）
        ctx.fill(
            Path(roundedRect: CGRect(x: 30, y: 29, width: 20, height: 5.5), cornerRadius: 2.75),
            with: .color(dark)
        )
        ctx.fill(Path(ellipseIn: CGRect(x: 46, y: 26.5, width: 7, height: 7)), with: .color(dark))

        // 触角：从头顶向前伸出的短须，末端小圆球
        for dy in [0.0, 3.0] {
            var antenna = Path()
            antenna.move(to: CGPoint(x: 50.5, y: 28 + dy))
            antenna.addQuadCurve(
                to: CGPoint(x: 56, y: 23.5 + dy),
                control: CGPoint(x: 54, y: 25 + dy)
            )
            ctx.stroke(antenna, with: .color(dark), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            ctx.fill(Path(ellipseIn: CGRect(x: 54.8, y: 22.3 + dy, width: 2.6, height: 2.6)), with: .color(dark))
        }

        // 近侧翅膀（亮色带斑点）
        drawWings(in: ctx, attach: attach, flap: flap, far: false)
    }

    /// 上下两瓣翅膀，绕根部纵向开合模拟扇动；远翅小一号、位置略靠后
    private func drawWings(in ctx: GraphicsContext, attach: CGPoint, flap: CGFloat, far: Bool) {
        let color = far ? controller.wingFar : controller.wingNear
        let back: CGFloat = far ? 4 : 0    // 远翅靠后
        let shrink: CGFloat = far ? 4 : 0  // 远翅缩小
        ctx.drawLayer { layer in
            layer.translateBy(x: attach.x, y: attach.y)
            layer.scaleBy(x: 1, y: flap)
            layer.translateBy(x: -attach.x, y: -attach.y)
            // 上翅：向后上方展开的大圆瓣
            layer.fill(
                Path(ellipseIn: CGRect(x: attach.x - 31 - back, y: attach.y - 26 + shrink,
                                       width: 28 - shrink, height: 22 - shrink)),
                with: .color(color)
            )
            // 下翅：向后下方的小圆瓣
            layer.fill(
                Path(ellipseIn: CGRect(x: attach.x - 22 - back, y: attach.y + 3,
                                       width: 18 - shrink, height: 14 - shrink)),
                with: .color(color)
            )
            if !far {
                // 近翅白色斑点
                layer.fill(
                    Path(ellipseIn: CGRect(x: attach.x - 25, y: attach.y - 20, width: 5, height: 5)),
                    with: .color(.white.opacity(0.85))
                )
                layer.fill(
                    Path(ellipseIn: CGRect(x: attach.x - 16, y: attach.y + 7, width: 3.5, height: 3.5)),
                    with: .color(.white.opacity(0.85))
                )
            }
        }
    }
}
