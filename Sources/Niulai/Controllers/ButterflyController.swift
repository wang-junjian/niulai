import AppKit
import SwiftUI

/// 小蝴蝶：慢悠悠掠过屏幕。牛来注意到会小跑着追，快飞出屏幕时
/// 跳起来扑——多半扑空，蝴蝶加速往上逃走。纯视觉，不响应鼠标。
/// 移动骨架在 ScreenCrosser 基类；这里实现翻飞/逃逸/追扑触发的 hook。
@MainActor
final class ButterflyController: ScreenCrosser {

    @Published private(set) var scheme = ButterflyController.schemes[0]

    /// 翅膀配色方案：主色 / 中间色带 / 眼斑芯 / 远翅深色
    struct ButterflyScheme {
        let wing: Color
        let band: Color
        let spot: Color
        let far: Color
    }

    /// 每次出场随机选一种配色
    nonisolated static let schemes: [ButterflyScheme] = [
        ButterflyScheme(wing: Color(red: 0.36, green: 0.68, blue: 0.94),   // 天蓝粉带
                        band: Color(red: 0.90, green: 0.60, blue: 0.88),
                        spot: Color(red: 0.30, green: 0.70, blue: 0.35),
                        far:  Color(red: 0.28, green: 0.55, blue: 0.82)),
        ButterflyScheme(wing: Color(red: 0.98, green: 0.80, blue: 0.30),   // 明黄橘带
                        band: Color(red: 0.96, green: 0.55, blue: 0.30),
                        spot: Color(red: 0.70, green: 0.35, blue: 0.60),
                        far:  Color(red: 0.88, green: 0.68, blue: 0.22)),
        ButterflyScheme(wing: Color(red: 0.50, green: 0.85, blue: 0.62),   // 薄荷黄带
                        band: Color(red: 0.85, green: 0.90, blue: 0.45),
                        spot: Color(red: 0.30, green: 0.55, blue: 0.75),
                        far:  Color(red: 0.38, green: 0.72, blue: 0.50)),
        ButterflyScheme(wing: Color(red: 0.95, green: 0.55, blue: 0.68),   // 粉红杏带
                        band: Color(red: 0.98, green: 0.78, blue: 0.55),
                        spot: Color(red: 0.55, green: 0.40, blue: 0.80),
                        far:  Color(red: 0.82, green: 0.40, blue: 0.55)),
        ButterflyScheme(wing: Color(red: 0.68, green: 0.55, blue: 0.92),   // 紫罗兰粉带
                        band: Color(red: 0.92, green: 0.65, blue: 0.85),
                        spot: Color(red: 0.95, green: 0.75, blue: 0.30),
                        far:  Color(red: 0.55, green: 0.42, blue: 0.80)),
    ]

    weak var pet: PetViewModel?

    private var baseY: CGFloat = 0
    private var flyTime: TimeInterval = 0
    private var escaping = false      // 被扑之后加速逃走
    private var hasPounced = false    // 一次飞行只被扑一次

    override class var size: NSSize { NSSize(width: 110, height: 95) }
    private let cruiseSpeed: CGFloat = 65
    private let escapeSpeed: CGFloat = 190

    func flyAcross(fromLeft: Bool, groundY: CGFloat) {
        startCrossing(fromLeft: fromLeft, groundY: groundY, referenceWindow: pet?.window)
    }

    // MARK: - ScreenCrosser hook

    override func canStart() -> Bool {
        guard let pet, pet.isVisible, !pet.isPeaceful, pet.window != nil else { return false }
        return true
    }

    override func onWillStart(fromLeft: Bool, groundY: CGFloat) {
        scheme = Self.schemes.randomElement() ?? Self.schemes[0]
        baseY = groundY + 95   // 牛来脑袋的高度，跳一跳够得着
        flyTime = 0
        escaping = false
        hasPounced = false
    }

    override func startOrigin(fromLeft: Bool, vf: NSRect, groundY: CGFloat) -> CGPoint {
        CGPoint(x: fromLeft ? vf.minX - Self.size.width : vf.maxX, y: baseY)
    }

    override func updatePosition(dt: CGFloat, origin: inout CGPoint, vf: NSRect) {
        flyTime += dt
        origin.x += direction * (escaping ? escapeSpeed : cruiseSpeed) * dt
        origin.y = baseY + sin(flyTime * 3) * 16   // 蝴蝶式上下翻飞
        if escaping { baseY += 50 * dt }           // 逃走时往上爬升
    }

    override func afterMove(vf: NSRect) {
        guard let pet, let petWindow = pet.window, let origin = window?.frame.origin else { return }

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
    }

    override func onDidExit() {
        pet?.butterflyGone()
    }

    /// 预览/调试用：直接指定配色
    func setSchemeForPreview(_ scheme: ButterflyScheme) {
        self.scheme = scheme
    }

    override func makeContentView() -> AnyView {
        AnyView(ButterflyView(controller: self))
    }
}

/// 小蝴蝶（侧视朝右飞）：卡通角色风——奶油色大头大眼睛、螺旋卷触角、
/// 小手小脚，分层彩色大翅膀（主色+色带+眼斑）绕根部扇动。
/// 翅膀配色由 controller 每次出场随机指定。
struct ButterflyView: View {
    @ObservedObject var controller: ButterflyController

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let flap = 0.30 + 0.70 * abs(sin(t * 15))   // 翅膀开合比例

            Canvas { ctx, _ in
                drawButterfly(in: ctx, flap: flap)
            }
            .scaleEffect(x: controller.facingLeft ? -1 : 1)
        }
    }

    // MARK: - 配色（身体固定奶油色，翅膀由 scheme 决定）

    private let cream = Color(red: 0.99, green: 0.88, blue: 0.66)
    private let creamShade = Color(red: 0.94, green: 0.78, blue: 0.52)
    private let dark = Color(red: 0.35, green: 0.24, blue: 0.14)
    private let shoe = Color(red: 0.85, green: 0.25, blue: 0.20)

    // 翅膀根部（身体上侧的扇动支点）
    private var attach: CGPoint { CGPoint(x: 54, y: 52) }

    // MARK: - 绘制

    private func drawButterfly(in ctx: GraphicsContext, flap: CGFloat) {
        let s = controller.scheme

        // 远侧翅膀（深色小一号，压在最底）
        drawWings(in: ctx, flap: flap, wing: s.far, band: s.far, spot: s.far,
                  shift: CGPoint(x: -7, y: 5), scale: 0.82, decorated: false)

        // 腹部：从胸后向左下伸出的奶油色节段尾巴
        ctx.drawLayer { layer in
            layer.translateBy(x: 42, y: 60)
            layer.rotate(by: .degrees(38))
            layer.translateBy(x: -42, y: -60)
            layer.fill(
                Path(roundedRect: CGRect(x: 24, y: 55, width: 22, height: 11), cornerRadius: 5.5),
                with: .color(creamShade)
            )
            // 腹部环节
            for sx in [30.0, 36.0] {
                layer.fill(
                    Path(roundedRect: CGRect(x: sx, y: 56, width: 2, height: 9), cornerRadius: 1),
                    with: .color(dark.opacity(0.35))
                )
            }
        }

        // 小腿小脚（吊在胸下）
        for (lx, spread) in [(50.0, -4.0), (57.0, 3.0)] {
            var leg = Path()
            leg.move(to: CGPoint(x: lx, y: 62))
            leg.addQuadCurve(to: CGPoint(x: lx + spread, y: 74), control: CGPoint(x: lx + spread * 0.3, y: 69))
            ctx.stroke(leg, with: .color(creamShade), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            // 小红鞋
            ctx.fill(
                Path(ellipseIn: CGRect(x: lx + spread - 3.5, y: 72, width: 8, height: 6)),
                with: .color(shoe)
            )
        }

        // 胸部
        ctx.fill(Path(ellipseIn: CGRect(x: 47, y: 46, width: 15, height: 17)), with: .color(cream))

        // 小手（向前伸，要抓东西的样子）
        for (ay, reach) in [(52.0, 14.0), (57.0, 11.0)] {
            var arm = Path()
            arm.move(to: CGPoint(x: 56, y: ay))
            arm.addQuadCurve(to: CGPoint(x: 56 + reach, y: ay + 5), control: CGPoint(x: 56 + reach * 0.6, y: ay + 1))
            ctx.stroke(arm, with: .color(creamShade), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            ctx.fill(
                Path(ellipseIn: CGRect(x: 56 + reach - 2.5, y: ay + 2.5, width: 5.5, height: 5)),
                with: .color(cream)
            )
        }

        // 大头
        ctx.fill(Path(ellipseIn: CGRect(x: 56, y: 24, width: 30, height: 30)), with: .color(cream))

        // 大眼睛（白底 + 蓝瞳 + 高光）
        ctx.fill(Path(ellipseIn: CGRect(x: 66, y: 28, width: 15, height: 16)), with: .color(.white))
        ctx.fill(Path(ellipseIn: CGRect(x: 68.5, y: 31, width: 10, height: 10.5)),
                 with: .color(Color(red: 0.35, green: 0.55, blue: 0.90)))
        ctx.fill(Path(ellipseIn: CGRect(x: 70.5, y: 33, width: 6, height: 6.5)), with: .color(dark))
        ctx.fill(Path(ellipseIn: CGRect(x: 69.5, y: 31.5, width: 3, height: 3)), with: .color(.white))

        // 微笑 + 腮红
        var smile = Path()
        smile.move(to: CGPoint(x: 72, y: 47))
        smile.addQuadCurve(to: CGPoint(x: 79, y: 45), control: CGPoint(x: 76, y: 49))
        ctx.stroke(smile, with: .color(dark), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        ctx.fill(
            Path(ellipseIn: CGRect(x: 60, y: 44, width: 7, height: 4)),
            with: .color(Color(red: 0.95, green: 0.55, blue: 0.50).opacity(0.5))
        )

        // 螺旋卷触角
        drawAntenna(in: ctx, from: CGPoint(x: 64, y: 26), curlAt: CGPoint(x: 58, y: 12), mirror: false)
        drawAntenna(in: ctx, from: CGPoint(x: 72, y: 25), curlAt: CGPoint(x: 72, y: 10), mirror: true)

        // 近侧翅膀（完整配色 + 眼斑），略往身体靠避免脱节
        drawWings(in: ctx, flap: flap, wing: s.wing, band: s.band, spot: s.spot,
                  shift: CGPoint(x: 3, y: 0), scale: 1, decorated: true)
    }

    /// 触角：细线引出，末端一个小螺旋卷
    private func drawAntenna(in ctx: GraphicsContext, from: CGPoint, curlAt: CGPoint, mirror: Bool) {
        var stem = Path()
        stem.move(to: from)
        stem.addQuadCurve(to: curlAt, control: CGPoint(x: from.x - 4, y: (from.y + curlAt.y) / 2))
        ctx.stroke(stem, with: .color(dark), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        ctx.stroke(
            spiralPath(center: curlAt, maxR: 4.5, turns: 1.6, mirror: mirror),
            with: .color(dark),
            style: StrokeStyle(lineWidth: 1.4, lineCap: .round)
        )
    }

    /// 上下两瓣翅膀绕根部纵向开合；带中间色带和沿外缘的眼斑（黄圈+彩芯）
    private func drawWings(in ctx: GraphicsContext, flap: CGFloat,
                           wing: Color, band: Color, spot: Color,
                           shift: CGPoint, scale: CGFloat, decorated: Bool) {
        let a = attach
        ctx.drawLayer { layer in
            // 扇动：绕根部纵向缩放
            layer.translateBy(x: a.x, y: a.y)
            layer.scaleBy(x: 1, y: flap)
            layer.translateBy(x: -a.x, y: -a.y)
            // 出场偏移/缩放（远翅用）
            layer.translateBy(x: a.x, y: a.y)
            layer.scaleBy(x: scale, y: scale)
            layer.translateBy(x: -a.x + shift.x, y: -a.y + shift.y)

            // 上翅：向后上方展开的大椭圆瓣（略倾斜）
            layer.translateBy(x: 34, y: 24)
            layer.rotate(by: .degrees(-26))
            layer.translateBy(x: -34, y: -24)
            layer.fill(Path(ellipseIn: CGRect(x: 12, y: 8, width: 46, height: 32)), with: .color(wing))
            layer.fill(Path(ellipseIn: CGRect(x: 20, y: 15, width: 30, height: 19)), with: .color(band))
            if decorated {
                // 上翅外缘眼斑：黄圈 + 彩芯
                for (sx, sy, r) in [(17.0, 14.0, 4.2), (26.0, 10.5, 3.6), (35.0, 8.5, 3.0)] {
                    layer.fill(Path(ellipseIn: CGRect(x: sx - r, y: sy - r, width: r * 2, height: r * 2)),
                               with: .color(Color(red: 0.98, green: 0.90, blue: 0.40)))
                    layer.fill(Path(ellipseIn: CGRect(x: sx - r * 0.55, y: sy - r * 0.55, width: r * 1.1, height: r * 1.1)),
                               with: .color(spot))
                }
            }
            // 撤销上翅的旋转，画下翅
            layer.translateBy(x: 34, y: 24)
            layer.rotate(by: .degrees(26))
            layer.translateBy(x: -34, y: -24)

            // 下翅：向后下方的小圆瓣
            layer.translateBy(x: 40, y: 62)
            layer.rotate(by: .degrees(-10))
            layer.translateBy(x: -40, y: -62)
            layer.fill(Path(ellipseIn: CGRect(x: 22, y: 52, width: 34, height: 22)), with: .color(wing))
            layer.fill(Path(ellipseIn: CGRect(x: 29, y: 57, width: 21, height: 13)), with: .color(band))
            if decorated {
                layer.fill(Path(ellipseIn: CGRect(x: 25, y: 55, width: 7, height: 7)),
                           with: .color(Color(red: 0.98, green: 0.90, blue: 0.40)))
                layer.fill(Path(ellipseIn: CGRect(x: 27, y: 57, width: 3.5, height: 3.5)), with: .color(spot))
            }
        }
    }

    /// 小螺旋（触角卷）
    private func spiralPath(center: CGPoint, maxR: CGFloat, turns: Double, mirror: Bool) -> Path {
        var path = Path()
        let total = turns * .pi * 2
        for i in 0...20 {
            let frac = Double(i) / 20
            let a = frac * total * (mirror ? -1 : 1)
            let r = maxR * (1 - frac * 0.75)
            let pt = CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        return path
    }
}
