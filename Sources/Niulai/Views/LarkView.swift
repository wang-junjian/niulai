import SwiftUI

/// 云雀「云丁」——翅膀受过伤，飞得慢。侧视图，朝右飞，朝左时翻转。
struct LarkView: View {
    @ObservedObject var controller: LarkController

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            // 飞行时扇翅（伤翅幅度小、略下垂），歇脚时收翅
            let flap = controller.perched ? 0 : sin(t * 12) * 34 - 8
            let bob: CGFloat = controller.perched ? sin(t * 2) * 1.5 : sin(t * 6) * 4

            Canvas { ctx, _ in
                drawLark(in: ctx, flapDegrees: flap)
            }
            .scaleEffect(x: controller.facingLeft ? -1 : 1)
            .offset(y: bob)
        }
    }

    enum Palette {
        static let feather = Color(red: 0.55, green: 0.42, blue: 0.30)  // 棕褐
        static let wing    = Color(red: 0.45, green: 0.33, blue: 0.23)
        static let belly   = Color(red: 0.93, green: 0.87, blue: 0.74)
        static let beak    = Color(red: 0.90, green: 0.60, blue: 0.20)
        static let dark    = Color(red: 0.22, green: 0.16, blue: 0.12)
    }

    private func drawLark(in ctx: GraphicsContext, flapDegrees: Double) {
        // 尾羽
        for (angle, len) in [(-8.0, 20.0), (4.0, 18.0)] {
            ctx.drawLayer { layer in
                layer.translateBy(x: 40, y: 50)
                layer.rotate(by: .degrees(angle))
                layer.translateBy(x: -40, y: -50)
                layer.fill(
                    Path(roundedRect: CGRect(x: 40 - len, y: 47, width: len, height: 6), cornerRadius: 3),
                    with: .color(Palette.wing)
                )
            }
        }

        // 身体与肚皮
        ctx.fill(Path(ellipseIn: CGRect(x: 34, y: 34, width: 44, height: 28)), with: .color(Palette.feather))
        ctx.fill(Path(ellipseIn: CGRect(x: 44, y: 44, width: 26, height: 16)), with: .color(Palette.belly))

        // 头
        ctx.fill(Path(ellipseIn: CGRect(x: 66, y: 24, width: 24, height: 24)), with: .color(Palette.feather))

        // 眼睛
        ctx.fill(Path(ellipseIn: CGRect(x: 76, y: 31, width: 5, height: 5)), with: .color(Palette.dark))
        ctx.fill(Path(ellipseIn: CGRect(x: 77.2, y: 32.2, width: 1.6, height: 1.6)), with: .color(.white))

        // 喙
        var beak = Path()
        beak.move(to: CGPoint(x: 88, y: 36))
        beak.addLine(to: CGPoint(x: 99, y: 39.5))
        beak.addLine(to: CGPoint(x: 88, y: 43))
        beak.closeSubpath()
        ctx.fill(beak, with: .color(Palette.beak))

        // 翅膀（绕肩部扇动）
        ctx.drawLayer { layer in
            layer.translateBy(x: 48, y: 42)
            layer.rotate(by: .degrees(flapDegrees))
            layer.translateBy(x: -48, y: -42)
            layer.fill(Path(ellipseIn: CGRect(x: 40, y: 36, width: 28, height: 13)), with: .color(Palette.wing))
        }
    }
}
