import SwiftUI

/// 豹拉——牛来的跨物种挚友。黄底黑斑、白肚皮、圆耳朵的小豹，比牛来小一号。
/// 状态镜像自主人的 CompanionController（复用牛来的动画参数）。
struct BaolaView: View {
    @ObservedObject var controller: CompanionController

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let p = NiulaiView.AnimationParams(state: controller.state, t: t, elapsed: 0,
                                               pupil: pupilOffset(), blinkSeed: 13)

            ZStack {
                Canvas { ctx, _ in
                    drawLeopard(in: ctx, p: p)
                }
                .scaleEffect(
                    x: (controller.facingLeft ? -1 : 1) * p.squashX,
                    y: p.squashY,
                    anchor: .bottom
                )
                .rotationEffect(.degrees(p.tilt))
                .offset(y: p.lift)

                if controller.state == .sleeping {
                    Text("💤")
                        .font(.system(size: 20))
                        .offset(x: 48, y: -50 + sin(t * 1.6) * 4)
                        .opacity(0.85)
                }
            }
        }
    }

    /// 瞳孔看向：护卫时盯狼，平时看着牛来（朋友的眼神）
    private func pupilOffset() -> CGSize {
        guard let midX = controller.midX else { return .zero }
        // 护卫位优先：盯着狼；否则盯着牛来
        let targetX: CGFloat? = controller.pet.wolf?.running == true
            ? controller.pet.wolf?.currentX
            : controller.pet.window?.frame.midX
        guard let targetX else { return .zero }
        let screenDX = max(-1.8, min(1.8, (targetX - midX) / 120))
        // 画布 +x 即面朝方向：屏幕方向的偏移在翻转画布下要翻回来
        return CGSize(width: controller.facingLeft ? -screenDX : screenDX, height: 0)
    }

    enum Palette {
        static let fur   = Color(red: 0.96, green: 0.76, blue: 0.28)   // 豹黄
        static let belly = Color(red: 0.99, green: 0.97, blue: 0.90)   // 白肚皮
        static let spot  = Color(red: 0.42, green: 0.28, blue: 0.15)   // 黑斑
        static let dark  = Color(red: 0.25, green: 0.18, blue: 0.12)
        static let pink  = Color(red: 0.95, green: 0.65, blue: 0.60)
        static let mouth = Color(red: 0.50, green: 0.25, blue: 0.20)
    }

    private func drawLeopard(in ctx: GraphicsContext, p: NiulaiView.AnimationParams) {
        // 阴影
        ctx.fill(Path(ellipseIn: CGRect(x: 62, y: 172, width: 76, height: 11)),
                 with: .color(.black.opacity(0.12)))

        // 尾巴（从身体左侧翘起来，带黑尖）
        drawRotated(in: ctx, around: CGPoint(x: 78, y: 128), degrees: p.tailWag) { c in
            var tail = Path()
            tail.move(to: CGPoint(x: 78, y: 128))
            tail.addQuadCurve(to: CGPoint(x: 54, y: 96), control: CGPoint(x: 56, y: 122))
            c.stroke(tail, with: .color(Palette.fur), style: StrokeStyle(lineWidth: 7, lineCap: .round))
            c.fill(Path(ellipseIn: CGRect(x: 48, y: 88, width: 12, height: 12)), with: .color(Palette.spot))
        }

        // 手臂
        drawLimb(in: ctx, jointX: 78, jointY: 102, w: 8, h: 20,
                 degrees: 12 + p.legSwing * 0.7 * sin(p.legPhase), color: Palette.fur, tipColor: Palette.spot)
        drawLimb(in: ctx, jointX: 122, jointY: 102, w: 8, h: 20,
                 degrees: -12 - p.legSwing * 0.7 * sin(p.legPhase), color: Palette.fur, tipColor: Palette.spot)

        // 腿
        drawLimb(in: ctx, jointX: 92, jointY: 142, w: 10, h: 34,
                 degrees: p.legSwing * sin(p.legPhase), color: Palette.fur, tipColor: Palette.dark)
        drawLimb(in: ctx, jointX: 108, jointY: 142, w: 10, h: 34,
                 degrees: -p.legSwing * sin(p.legPhase), color: Palette.fur, tipColor: Palette.dark)

        // 身体 + 白肚皮
        ctx.fill(Path(ellipseIn: CGRect(x: 76, y: 92, width: 48, height: 60)), with: .color(Palette.fur))
        ctx.fill(Path(ellipseIn: CGRect(x: 84, y: 106, width: 32, height: 42)), with: .color(Palette.belly))

        // 身上的斑点
        for (sx, sy, r) in [(72.0, 100.0, 2.5), (124.0, 96.0, 2.5), (70.0, 122.0, 2.0),
                            (126.0, 118.0, 2.0), (80.0, 134.0, 2.2), (118.0, 136.0, 2.2)] {
            ctx.fill(Path(ellipseIn: CGRect(x: sx - r, y: sy - r, width: r * 2, height: r * 2)),
                     with: .color(Palette.spot))
        }

        // 圆耳朵（外黄内粉）
        for ex in [70.0, 130.0] {
            ctx.fill(Path(ellipseIn: CGRect(x: ex - 10, y: 22 - 10, width: 20, height: 20)), with: .color(Palette.fur))
            ctx.fill(Path(ellipseIn: CGRect(x: ex - 5.5, y: 26 - 5.5, width: 11, height: 11)), with: .color(Palette.pink.opacity(0.7)))
        }

        // 头
        ctx.fill(Path(ellipseIn: CGRect(x: 68, y: 24, width: 64, height: 64)), with: .color(Palette.fur))

        // 额头斑点
        for (sx, sy) in [(86.0, 34.0), (100.0, 30.0), (114.0, 34.0)] {
            ctx.fill(Path(ellipseIn: CGRect(x: sx - 2, y: sy - 2, width: 4, height: 4)), with: .color(Palette.spot))
        }

        // 眼睛：又大又圆的深色无辜眼
        if p.eyesClosed {
            for cx in [88.0, 112.0] {
                var closed = Path()
                closed.move(to: CGPoint(x: cx - 6, y: 52))
                closed.addQuadCurve(to: CGPoint(x: cx + 6, y: 52), control: CGPoint(x: cx, y: 57))
                ctx.stroke(closed, with: .color(Palette.dark), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            }
        } else {
            for cx in [88.0, 112.0] {
                // 纯深色大眼：整颗眼珠连高光一起偏移
                let px = cx + p.pupil.width
                ctx.fill(Path(ellipseIn: CGRect(x: px - 5.5, y: 46, width: 11, height: 11)), with: .color(Palette.dark))
                ctx.fill(Path(ellipseIn: CGRect(x: px - 3.5, y: 47.5, width: 3.2, height: 3.2)), with: .color(.white))
            }
        }

        // 白色吻部 + 小鼻子 + 嘴
        ctx.fill(Path(ellipseIn: CGRect(x: 88, y: 62, width: 24, height: 16)), with: .color(Palette.belly))
        ctx.fill(Path(roundedRect: CGRect(x: 97, y: 64, width: 6, height: 5), cornerRadius: 2), with: .color(Palette.dark))
        if p.happyMouth {
            ctx.fill(Path(ellipseIn: CGRect(x: 95, y: 71, width: 10, height: 7)), with: .color(Palette.mouth))
        } else {
            var m1 = Path()
            m1.move(to: CGPoint(x: 100, y: 69))
            m1.addQuadCurve(to: CGPoint(x: 94, y: 74), control: CGPoint(x: 96, y: 74))
            var m2 = Path()
            m2.move(to: CGPoint(x: 100, y: 69))
            m2.addQuadCurve(to: CGPoint(x: 106, y: 74), control: CGPoint(x: 104, y: 74))
            ctx.stroke(m1, with: .color(Palette.dark), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            ctx.stroke(m2, with: .color(Palette.dark), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }

        // 腮红
        ctx.fill(Path(ellipseIn: CGRect(x: 74, y: 58, width: 9, height: 5)), with: .color(Palette.pink.opacity(0.4)))
        ctx.fill(Path(ellipseIn: CGRect(x: 117, y: 58, width: 9, height: 5)), with: .color(Palette.pink.opacity(0.4)))
    }

    private func drawLimb(in ctx: GraphicsContext, jointX: CGFloat, jointY: CGFloat,
                          w: CGFloat, h: CGFloat, degrees: Double, color: Color, tipColor: Color) {
        let pivot = CGPoint(x: jointX, y: jointY)
        drawRotated(in: ctx, around: pivot, degrees: degrees) { c in
            c.fill(Path(roundedRect: CGRect(x: jointX - w / 2, y: jointY - 2, width: w, height: h),
                          cornerRadius: w / 2),
                   with: .color(color))
            c.fill(Path(ellipseIn: CGRect(x: jointX - w / 2 + 0.5, y: jointY + h - w, width: w - 1, height: w - 1)),
                   with: .color(tipColor))
        }
    }

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

/// 豹拉的容器：气泡悬浮头顶（不参与布局），本体锚定底部，点击有反应。
struct BaolaContainerView: View {
    @ObservedObject var controller: CompanionController

    var body: some View {
        BaolaView(controller: controller)
            .frame(width: 200, height: 190)
            .contentShape(Rectangle())
            .onTapGesture {
                controller.poke()
            }
            .frame(width: 200, height: 250, alignment: .bottom)
            .overlay(alignment: .top) {
                SpeechBubbleView(text: controller.bubbleText)
                    .frame(height: 60)
                    .allowsHitTesting(false)
            }
    }
}
