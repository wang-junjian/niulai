import SwiftUI

/// 用 SwiftUI Canvas 纯代码绘制的「牛来」——电影直立版形象。
/// 正面视角：橙黄身体、标志性灰白大嘴套、细眉耷拉眼的丧萌表情。
/// 所有动画由 TimelineView 驱动，状态机只负责切换离散状态。
struct NiulaiView: View {
    @ObservedObject var viewModel: PetViewModel

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let p = AnimationParams(state: viewModel.state, t: t, elapsed: viewModel.stateElapsed)

            ZStack {
                Canvas { ctx, _ in
                    drawPet(in: ctx, p: p)
                }
                .scaleEffect(
                    // spinFlip：转圈追尾巴时快速左右翻转
                    x: ((viewModel.facingLeft != p.spinFlip) ? -1 : 1) * p.squashX,
                    y: p.squashY,
                    anchor: .bottom
                )
                .rotationEffect(.degrees(p.tilt + p.lean * (viewModel.facingLeft ? -1 : 1)))
                .offset(
                    x: p.buttLunge * (viewModel.facingLeft ? -6 : 6),
                    y: p.lift
                )

                if viewModel.state == .sleeping {
                    Text("💤")
                        .font(.system(size: 26))
                        .offset(x: 62, y: -66 + sin(t * 1.6) * 5)
                        .opacity(0.85)
                }
                if viewModel.state == .dizzy {
                    Text("💫")
                        .font(.system(size: 24))
                        .offset(x: 58, y: -62 + sin(t * 3) * 4)
                        .opacity(0.9)
                }
            }
        }
    }

    // MARK: - 动画参数

    struct AnimationParams {
        let lift: CGFloat      // 整体垂直位移：走路颠簸 + 开心跳起 + 扑蝶腾跃
        let legPhase: CGFloat  // 四肢摆动相位
        let legSwing: CGFloat  // 腿部摆动幅度（度）
        let squashX: CGFloat
        let squashY: CGFloat
        let tilt: CGFloat      // 被拎起来/转圈时的晃动
        let lean: CGFloat      // 朝面向方向的前倾（追蝴蝶、顶墙）
        let buttLunge: CGFloat // 顶墙的前冲量（0-1，向面向方向小冲）
        let blinking: Bool
        let eyesClosed: Bool   // 睡觉或眨眼时闭眼
        let yawning: Bool      // 打哈欠：嘴大张
        let dizzyEyes: Bool    // 眩晕螺旋眼
        let happyMouth: Bool   // 开心时张嘴笑
        let wideEyes: Bool     // 被拎着时瞪大眼睛
        let armRaise: CGFloat  // 手臂上举程度 0-1（被拎=1，伸懒腰=渐入渐出）
        let spinFlip: Bool     // 转圈追尾巴时的左右翻转
        let tailWag: CGFloat   // 尾巴摆动角度（牛来正面视角不可见，供豹拉复用）

        init(state: PetViewModel.State, t: TimeInterval, elapsed: TimeInterval) {
            let isWalking = state == .walking || state.isWalkingTo

            // 走路：小碎步弹跳 + 四肢摆动；开心：原地跳
            if isWalking {
                lift = -abs(sin(t * 10)) * 4
                legPhase = t * 10
                legSwing = 22
            } else if state == .chasing {
                // 小跑追蝴蝶：步子更快更大
                lift = -abs(sin(t * 15)) * 5
                legPhase = t * 15
                legSwing = 32
            } else if state == .pouncing {
                // 扑蝶：一次腾跃弧线
                let frac = min(elapsed / 0.9, 1)
                lift = -sin(frac * .pi) * 34
                legPhase = 0
                legSwing = 0
            } else if state == .startled {
                // 吓一跳：原地快速连跳
                lift = -abs(sin(t * 14)) * 10
                legPhase = 0
                legSwing = 0
            } else if state == .happy {
                lift = -abs(sin(t * 9)) * 16
                legPhase = t * 9
                legSwing = 10
            } else {
                lift = 0
                legPhase = 0
                legSwing = 0
            }

            // 待机呼吸；坐下时压扁一点；睡觉时呼吸放缓
            var sx: CGFloat = 1
            var sy: CGFloat = 1
            switch state {
            case .idle:
                sy = 1 + 0.02 * sin(t * 2)
            case .sitting, .sleeping, .dizzy:
                sx = 1.05
                sy = 0.93 + 0.015 * sin(t * (state == .sleeping ? 1.2 : 2))
            default:
                break
            }
            // 伸懒腰：身体拉长变细
            let stretch: CGFloat = {
                guard state == .stretching else { return 0 }
                let rampIn = min(CGFloat(elapsed) / 0.4, 1)
                let rampOut = elapsed > 2.2 ? max(0, 1 - CGFloat(elapsed - 2.2) / 0.5) : 1
                return rampIn * rampOut
            }()
            sy *= 1 + stretch * 0.09
            sx *= 1 - stretch * 0.05
            squashX = sx
            squashY = sy

            // 被拎着：身体轻轻晃荡；转圈追尾巴：快速摇摆
            if state == .dragged {
                tilt = sin(t * 5) * 6
            } else if state == .spinning {
                tilt = sin(t * 20) * 8
            } else {
                tilt = 0
            }

            // 前倾：追蝴蝶/扑蝶时朝目标探身，顶墙时低头用角
            // 顶墙只顶一次：单次前冲脉冲（顶出去→收回来）
            buttLunge = state == .headbutting ? sin(min(elapsed / 0.7, 1) * .pi) : 0
            switch state {
            case .chasing: lean = 6
            case .pouncing: lean = 8
            case .headbutting: lean = 14 + 8 * buttLunge
            default: lean = 0
            }

            // 每 4.3 秒眨一次眼（睡觉、被拎、惊吓时不眨）
            let cycle = t.truncatingRemainder(dividingBy: 4.3)
            blinking = cycle < 0.12 && state != .sleeping && state != .dragged && state != .startled

            yawning = state == .stretching && elapsed < 1.2
            dizzyEyes = state == .dizzy
            eyesClosed = state == .sleeping || yawning || blinking
            happyMouth = state == .happy || state == .pouncing
            wideEyes = state == .dragged || state == .startled
            armRaise = state == .dragged ? 1 : stretch
            spinFlip = state == .spinning && Int(elapsed / 0.18) % 2 == 1

            // 开心/走路时尾巴摇得更欢
            let wagSpeed = (state == .happy || isWalking) ? 6.0 : 2.2
            let wagAmount: CGFloat = (state == .happy) ? 16 : 8
            tailWag = sin(t * wagSpeed) * wagAmount
        }
    }

    // MARK: - 配色

    enum Palette {
        static let body   = Color(red: 0.90, green: 0.56, blue: 0.20)   // 牛来的橙黄
        static let belly  = Color(red: 0.98, green: 0.90, blue: 0.72)   // 奶黄肚皮
        static let muzzle = Color(red: 0.87, green: 0.84, blue: 0.82)   // 灰白大嘴套
        static let dark   = Color(red: 0.32, green: 0.24, blue: 0.18)   // 蹄子/瞳孔
        static let horn   = Color(red: 0.50, green: 0.50, blue: 0.56)   // 小灰角
        static let blush  = Color(red: 0.95, green: 0.55, blue: 0.50)
        static let mouth  = Color(red: 0.50, green: 0.25, blue: 0.20)
    }

    // MARK: - 绘制（正面视角，头部在上、腿在下）

    private func drawPet(in ctx: GraphicsContext, p: AnimationParams) {
        // 地面阴影
        ctx.fill(
            Path(ellipseIn: CGRect(x: 84, y: 202, width: 72, height: 12)),
            with: .color(.black.opacity(0.12))
        )

        // 手臂（在身体后面）
        drawArm(in: ctx, shoulderX: 96, restDegrees: 14,
                swingDegrees: p.legSwing * 0.8 * sin(p.legPhase), raise: p.armRaise)
        drawArm(in: ctx, shoulderX: 144, restDegrees: -14,
                swingDegrees: -p.legSwing * 0.8 * sin(p.legPhase), raise: p.armRaise)

        // 腿（在身体后面）
        drawLeg(in: ctx, hipX: 106, degrees: p.legSwing * sin(p.legPhase), sitting: p.isSquashed)
        drawLeg(in: ctx, hipX: 134, degrees: -p.legSwing * sin(p.legPhase), sitting: p.isSquashed)

        // 身体与肚皮
        ctx.fill(Path(ellipseIn: CGRect(x: 92, y: 96, width: 56, height: 76)), with: .color(Palette.body))
        ctx.fill(Path(ellipseIn: CGRect(x: 100, y: 118, width: 40, height: 50)), with: .color(Palette.belly))

        // 耳朵（在头后面一点）
        drawRotated(in: ctx, around: CGPoint(x: 83, y: 58), degrees: 15) { c in
            c.fill(Path(ellipseIn: CGRect(x: 74, y: 52, width: 18, height: 12)), with: .color(Palette.body))
        }
        drawRotated(in: ctx, around: CGPoint(x: 157, y: 58), degrees: -15) { c in
            c.fill(Path(ellipseIn: CGRect(x: 148, y: 52, width: 18, height: 12)), with: .color(Palette.body))
        }

        // 头
        ctx.fill(Path(ellipseIn: CGRect(x: 82, y: 24, width: 76, height: 76)), with: .color(Palette.body))

        // 小灰角
        var horn1 = Path()
        horn1.move(to: CGPoint(x: 94, y: 32))
        horn1.addQuadCurve(to: CGPoint(x: 108, y: 32), control: CGPoint(x: 101, y: 30))
        horn1.addLine(to: CGPoint(x: 100, y: 10))
        horn1.closeSubpath()
        ctx.fill(horn1, with: .color(Palette.horn))
        var horn2 = Path()
        horn2.move(to: CGPoint(x: 132, y: 32))
        horn2.addQuadCurve(to: CGPoint(x: 146, y: 32), control: CGPoint(x: 139, y: 30))
        horn2.addLine(to: CGPoint(x: 140, y: 10))
        horn2.closeSubpath()
        ctx.fill(horn2, with: .color(Palette.horn))

        // 眼睛（丧萌的关键：眼皮耷拉盖住眼球上半）
        if p.dizzyEyes {
            // 转晕了：螺旋眼
            for cx in [108.0, 132.0] {
                ctx.fill(Path(ellipseIn: CGRect(x: cx - 8, y: 50, width: 16, height: 13)), with: .color(.white))
                ctx.stroke(
                    spiralPath(center: CGPoint(x: cx, y: 56.5), maxR: 5.5),
                    with: .color(Palette.dark),
                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round)
                )
            }
        } else if p.eyesClosed {
            for cx in [108.0, 132.0] {
                var closed = Path()
                closed.move(to: CGPoint(x: cx - 7, y: 56))
                closed.addQuadCurve(to: CGPoint(x: cx + 7, y: 56), control: CGPoint(x: cx, y: 62))
                ctx.stroke(closed, with: .color(Palette.dark), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            }
        } else {
            for cx in [108.0, 132.0] {
                ctx.fill(Path(ellipseIn: CGRect(x: cx - 8, y: 50, width: 16, height: 13)), with: .color(.white))
                let r: CGFloat = p.wideEyes ? 4.5 : 3.5
                ctx.fill(
                    Path(ellipseIn: CGRect(x: cx - r, y: 58 - r, width: r * 2, height: r * 2)),
                    with: .color(Palette.dark)
                )
                ctx.fill(Path(ellipseIn: CGRect(x: cx - 1, y: 54.5, width: 2.2, height: 2.2)), with: .color(.white))
                if !p.wideEyes {
                    // 耷拉的眼皮：用身体色盖住眼睛上半
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: cx - 9, y: 43, width: 18, height: 10)),
                        with: .color(Palette.body)
                    )
                }
            }
            // 细眉，内端上挑的八字眉（委屈/丧萌）
            var brow1 = Path()
            brow1.move(to: CGPoint(x: 100, y: 46))
            brow1.addLine(to: CGPoint(x: 114, y: 42))
            ctx.stroke(brow1, with: .color(Palette.dark), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            var brow2 = Path()
            brow2.move(to: CGPoint(x: 126, y: 42))
            brow2.addLine(to: CGPoint(x: 140, y: 46))
            ctx.stroke(brow2, with: .color(Palette.dark), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }

        // 腮红
        ctx.fill(Path(ellipseIn: CGRect(x: 94, y: 62, width: 11, height: 6)), with: .color(Palette.blush.opacity(0.4)))
        ctx.fill(Path(ellipseIn: CGRect(x: 135, y: 62, width: 11, height: 6)), with: .color(Palette.blush.opacity(0.4)))

        // 标志性大灰白嘴套
        ctx.fill(
            Path(roundedRect: CGRect(x: 92, y: 66, width: 56, height: 30), cornerRadius: 14),
            with: .color(Palette.muzzle)
        )
        // 鼻孔
        ctx.fill(Path(ellipseIn: CGRect(x: 107, y: 74, width: 4.5, height: 7)), with: .color(Palette.dark))
        ctx.fill(Path(ellipseIn: CGRect(x: 128.5, y: 74, width: 4.5, height: 7)), with: .color(Palette.dark))

        // 嘴巴：打哈欠张最大，开心时张嘴笑，平时抿嘴
        if p.yawning {
            ctx.fill(Path(ellipseIn: CGRect(x: 110, y: 81, width: 20, height: 15)), with: .color(Palette.mouth))
            ctx.fill(Path(ellipseIn: CGRect(x: 114, y: 89, width: 12, height: 6)), with: .color(Palette.blush))
        } else if p.happyMouth {
            ctx.fill(Path(ellipseIn: CGRect(x: 113, y: 85, width: 14, height: 9)), with: .color(Palette.mouth))
        } else {
            var smile = Path()
            smile.move(to: CGPoint(x: 112, y: 87))
            smile.addQuadCurve(to: CGPoint(x: 128, y: 87), control: CGPoint(x: 120, y: 92))
            ctx.stroke(smile, with: .color(Palette.dark), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }

    /// 画一条手臂，绕肩部旋转。raise 0-1 从自然下垂渐变到高举（被拎/伸懒腰）。
    private func drawArm(in ctx: GraphicsContext, shoulderX: CGFloat, restDegrees: Double,
                         swingDegrees: CGFloat, raise: CGFloat) {
        let pivot = CGPoint(x: shoulderX, y: 112)
        // 左手/右手镜像：举起时方向相反
        let raised: Double = shoulderX < 120 ? 140 : -140
        let rest = restDegrees + Double(swingDegrees)
        let angle = rest + (raised - rest) * Double(raise)
        drawRotated(in: ctx, around: pivot, degrees: angle) { c in
            c.fill(
                Path(roundedRect: CGRect(x: shoulderX - 5, y: 110, width: 10, height: 26), cornerRadius: 5),
                with: .color(Palette.body)
            )
            c.fill(
                Path(ellipseIn: CGRect(x: shoulderX - 4.5, y: 130, width: 9, height: 9)),
                with: .color(Palette.dark)
            )
        }
    }

    /// 画一条腿，绕胯部旋转。坐下时向外撇开。
    private func drawLeg(in ctx: GraphicsContext, hipX: CGFloat, degrees: CGFloat, sitting: Bool) {
        let pivot = CGPoint(x: hipX, y: 166)
        let splay: CGFloat = hipX < 120 ? -75 : 75
        let angle = sitting ? Double(splay) : Double(degrees)
        drawRotated(in: ctx, around: pivot, degrees: angle) { c in
            c.fill(
                Path(roundedRect: CGRect(x: hipX - 6.5, y: 164, width: 13, height: 40), cornerRadius: 6),
                with: .color(Palette.body)
            )
            // 蹄子
            c.fill(
                Path(roundedRect: CGRect(x: hipX - 6.5, y: 194, width: 13, height: 10), cornerRadius: 4),
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

    /// 以 center 为中心的阿基米德螺旋（眩晕眼）
    private func spiralPath(center: CGPoint, maxR: CGFloat) -> Path {
        var path = Path()
        for i in 0...24 {
            let a = Double(i) / 24 * .pi * 3.6
            let r = maxR * CGFloat(a / (.pi * 3.6))
            let pt = CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        return path
    }
}

// MARK: - 便捷访问

private extension PetViewModel.State {
    var isWalkingTo: Bool {
        if case .walkingTo = self { return true }
        if case .walkingToSleep = self { return true }
        return false
    }
}

private extension NiulaiView.AnimationParams {
    var isSquashed: Bool { squashY < 0.98 }
}
