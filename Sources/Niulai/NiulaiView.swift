import SwiftUI

/// 用 SwiftUI Canvas 纯代码绘制的 Q 版小牛「牛来」。
/// 侧视图：朝右行走，朝左时整体水平翻转。
/// 所有动画由 TimelineView 驱动，状态机只负责切换离散状态。
struct NiulaiView: View {
    @ObservedObject var viewModel: PetViewModel

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let p = AnimationParams(state: viewModel.state, t: t)

            ZStack {
                Canvas { ctx, _ in
                    drawPet(in: ctx, p: p)
                }
                .scaleEffect(
                    x: (viewModel.facingLeft ? -1 : 1) * p.squashX,
                    y: p.squashY,
                    anchor: .bottom
                )
                .rotationEffect(.degrees(p.tilt))
                .offset(y: p.lift)

                if viewModel.state == .sleeping {
                    Text("💤")
                        .font(.system(size: 26))
                        .offset(x: 62, y: -66 + sin(t * 1.6) * 5)
                        .opacity(0.85)
                }
            }
        }
    }

    // MARK: - 动画参数

    struct AnimationParams {
        let lift: CGFloat      // 整体垂直位移：走路颠簸 + 开心跳起
        let legPhase: CGFloat  // 腿部摆动相位
        let legSwing: CGFloat  // 腿部摆动幅度（度）
        let squashX: CGFloat
        let squashY: CGFloat
        let tilt: CGFloat      // 被拎起来时的晃动
        let blinking: Bool
        let tailWag: CGFloat   // 尾巴摆动角度
        let eyesClosed: Bool   // 睡觉或眨眼时闭眼
        let happyMouth: Bool   // 开心时张嘴笑
        let wideEyes: Bool     // 被拎着时瞪大眼睛

        init(state: PetViewModel.State, t: TimeInterval) {
            let isWalking = state == .walking || state.isWalkingTo

            // 走路：小碎步弹跳 + 四肢摆动；开心：原地跳
            if isWalking {
                lift = -abs(sin(t * 10)) * 4
                legPhase = t * 10
                legSwing = 20
            } else if state == .happy {
                lift = -abs(sin(t * 9)) * 16
                legPhase = 0
                legSwing = 12
            } else {
                lift = 0
                legPhase = 0
                legSwing = 0
            }

            // 待机呼吸；坐下时压扁一点；睡觉时呼吸放缓
            switch state {
            case .idle:
                squashX = 1
                squashY = 1 + 0.02 * sin(t * 2)
            case .sitting:
                squashX = 1.06
                squashY = 0.92 + 0.015 * sin(t * 2)
            case .sleeping:
                squashX = 1.04
                squashY = 0.95 + 0.02 * sin(t * 1.2)
            default:
                squashX = 1
                squashY = 1
            }

            // 被拎着：身体轻轻晃荡
            tilt = state == .dragged ? sin(t * 5) * 6 : 0

            // 每 4.3 秒眨一次眼（睡觉和被拎时不眨）
            let cycle = t.truncatingRemainder(dividingBy: 4.3)
            blinking = cycle < 0.12 && state != .sleeping && state != .dragged

            // 开心/走路时尾巴摇得更欢
            let wagSpeed = (state == .happy || isWalking) ? 6.0 : 2.2
            let wagAmount: CGFloat = (state == .happy) ? 20 : 10
            tailWag = sin(t * wagSpeed) * wagAmount

            eyesClosed = state == .sleeping || blinking
            happyMouth = state == .happy
            wideEyes = state == .dragged
        }
    }

    // MARK: - 配色

    enum Palette {
        static let body   = Color(red: 0.85, green: 0.62, blue: 0.40)
        static let farLeg = Color(red: 0.76, green: 0.54, blue: 0.34)
        static let cream  = Color(red: 0.96, green: 0.90, blue: 0.78)
        static let spot   = Color(red: 0.60, green: 0.40, blue: 0.25)
        static let dark   = Color(red: 0.28, green: 0.19, blue: 0.13)
        static let horn   = Color(red: 0.93, green: 0.86, blue: 0.70)
        static let blush  = Color(red: 0.95, green: 0.60, blue: 0.55)
        static let mouth  = Color(red: 0.45, green: 0.22, blue: 0.18)
    }

    // MARK: - 绘制

    private func drawPet(in ctx: GraphicsContext, p: AnimationParams) {
        // 地面阴影
        ctx.fill(
            Path(ellipseIn: CGRect(x: 60, y: 200, width: 120, height: 14)),
            with: .color(.black.opacity(0.12))
        )

        // 尾巴（绕根部摇摆）
        drawRotated(in: ctx, around: CGPoint(x: 56, y: 110), degrees: p.tailWag) { c in
            var tail = Path()
            tail.move(to: CGPoint(x: 56, y: 110))
            tail.addQuadCurve(to: CGPoint(x: 40, y: 158), control: CGPoint(x: 32, y: 132))
            c.stroke(tail, with: .color(Palette.body), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            c.fill(Path(ellipseIn: CGRect(x: 33, y: 152, width: 14, height: 16)), with: .color(Palette.spot))
        }

        // 后腿/远侧前腿（颜色深一档，与近侧错开半步）
        drawLeg(in: ctx, x: 88, degrees: -p.legSwing * sin(p.legPhase), color: Palette.farLeg, swing: p.legSwing)
        drawLeg(in: ctx, x: 162, degrees: p.legSwing * sin(p.legPhase), color: Palette.farLeg, swing: p.legSwing)

        // 远侧耳朵（在头后面）
        drawRotated(in: ctx, around: CGPoint(x: 136, y: 44), degrees: 25) { c in
            c.fill(Path(ellipseIn: CGRect(x: 122, y: 37, width: 28, height: 15)), with: .color(Palette.farLeg))
        }

        // 身体
        ctx.fill(Path(ellipseIn: CGRect(x: 52, y: 92, width: 136, height: 84)), with: .color(Palette.body))

        // 肚皮与花斑
        ctx.fill(Path(ellipseIn: CGRect(x: 78, y: 132, width: 88, height: 40)), with: .color(Palette.cream))
        ctx.fill(Path(ellipseIn: CGRect(x: 64, y: 102, width: 34, height: 22)), with: .color(Palette.spot))
        ctx.fill(Path(ellipseIn: CGRect(x: 130, y: 136, width: 26, height: 16)), with: .color(Palette.spot))
        ctx.fill(Path(ellipseIn: CGRect(x: 100, y: 94, width: 20, height: 12)), with: .color(Palette.spot))

        // 近侧的腿
        drawLeg(in: ctx, x: 68, degrees: p.legSwing * sin(p.legPhase), color: Palette.body, swing: p.legSwing)
        drawLeg(in: ctx, x: 144, degrees: -p.legSwing * sin(p.legPhase), color: Palette.body, swing: p.legSwing)

        // 头
        ctx.fill(Path(ellipseIn: CGRect(x: 126, y: 36, width: 84, height: 84)), with: .color(Palette.body))

        // 牛角
        var horn1 = Path()
        horn1.move(to: CGPoint(x: 148, y: 42))
        horn1.addQuadCurve(to: CGPoint(x: 164, y: 42), control: CGPoint(x: 156, y: 40))
        horn1.addLine(to: CGPoint(x: 157, y: 16))
        horn1.closeSubpath()
        ctx.fill(horn1, with: .color(Palette.horn))
        var horn2 = Path()
        horn2.move(to: CGPoint(x: 180, y: 40))
        horn2.addQuadCurve(to: CGPoint(x: 196, y: 38), control: CGPoint(x: 188, y: 37))
        horn2.addLine(to: CGPoint(x: 189, y: 14))
        horn2.closeSubpath()
        ctx.fill(horn2, with: .color(Palette.horn))

        // 近侧耳朵
        drawRotated(in: ctx, around: CGPoint(x: 200, y: 46), degrees: -25) { c in
            c.fill(Path(ellipseIn: CGRect(x: 185, y: 38, width: 30, height: 16)), with: .color(Palette.body))
            c.fill(Path(ellipseIn: CGRect(x: 190, y: 41, width: 20, height: 10)), with: .color(Palette.cream))
        }

        // 口鼻
        ctx.fill(
            Path(roundedRect: CGRect(x: 170, y: 88, width: 54, height: 38), cornerRadius: 17),
            with: .color(Palette.cream)
        )
        ctx.fill(Path(ellipseIn: CGRect(x: 190, y: 100, width: 5, height: 6)), with: .color(Palette.dark))
        ctx.fill(Path(ellipseIn: CGRect(x: 203, y: 100, width: 5, height: 6)), with: .color(Palette.dark))

        // 嘴巴：开心时张着嘴笑，平时微笑
        if p.happyMouth {
            ctx.fill(Path(ellipseIn: CGRect(x: 192, y: 110, width: 15, height: 10)), with: .color(Palette.mouth))
        } else {
            var smile = Path()
            smile.move(to: CGPoint(x: 188, y: 113))
            smile.addQuadCurve(to: CGPoint(x: 212, y: 113), control: CGPoint(x: 200, y: 121))
            ctx.stroke(smile, with: .color(Palette.dark), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }

        // 眼睛：睡觉/眨眼时是闭着的弧线
        if p.eyesClosed {
            var closed = Path()
            closed.move(to: CGPoint(x: 160, y: 64))
            closed.addQuadCurve(to: CGPoint(x: 184, y: 64), control: CGPoint(x: 172, y: 74))
            ctx.stroke(closed, with: .color(Palette.dark), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        } else {
            ctx.fill(Path(ellipseIn: CGRect(x: 161, y: 55, width: 22, height: 22)), with: .color(.white))
            let pupilR: CGFloat = p.wideEyes ? 7.5 : 6
            ctx.fill(
                Path(ellipseIn: CGRect(x: 174 - pupilR, y: 67 - pupilR, width: pupilR * 2, height: pupilR * 2)),
                with: .color(Palette.dark)
            )
            ctx.fill(Path(ellipseIn: CGRect(x: 175.5, y: 61.5, width: 4.4, height: 4.4)), with: .color(.white))
        }

        // 腮红
        ctx.fill(
            Path(ellipseIn: CGRect(x: 186, y: 80, width: 15, height: 8)),
            with: .color(Palette.blush.opacity(0.45))
        )
    }

    /// 画一条腿，绕腿根旋转。
    private func drawLeg(in ctx: GraphicsContext, x: CGFloat, degrees: CGFloat, color: Color, swing: CGFloat) {
        let pivot = CGPoint(x: x + 8, y: 160)
        drawRotated(in: ctx, around: pivot, degrees: Double(degrees)) { c in
            c.fill(
                Path(roundedRect: CGRect(x: x, y: 158, width: 16, height: 46), cornerRadius: 7),
                with: .color(color)
            )
            // 蹄子
            c.fill(
                Path(roundedRect: CGRect(x: x, y: 194, width: 16, height: 10), cornerRadius: 4),
                with: .color(Palette.dark)
            )
        }
    }

    /// 绕某点旋转后绘制（通过 drawLayer 做变换隔离）。
    private func drawRotated(in ctx: GraphicsContext, around point: CGPoint, degrees: Double,
                             draw: (inout GraphicsContext) -> Void) {
        ctx.drawLayer { layer in
            layer.translateBy(x: point.x, y: point.y)
            layer.rotate(by: .degrees(degrees))
            layer.translateBy(x: -point.x, y: -point.y)
            draw(&layer)
        }
    }
}

// MARK: - 便捷访问

private extension PetViewModel.State {
    var isWalkingTo: Bool {
        if case .walkingTo = self { return true }
        return false
    }
}
