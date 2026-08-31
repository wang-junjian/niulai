import SwiftUI

/// 工作模式下牛来头顶的梦境泡泡：云状泡泡 + 小圆点连线指向它，
/// 泡泡里循环上演剪影小剧场——梦中勇敢的牛来在草原上奔跑、跳跃。
struct DreamBubbleView: View {
    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate

            Canvas { ctx, _ in
                drawCloud(in: ctx, t: t)
                drawDreamScene(in: ctx, t: t)
            }
            .scaleEffect(1 + 0.025 * sin(t * 1.4), anchor: .bottom)
        }
    }

    /// 云状泡泡：三个圆 + 底部补齐，以及指向牛来的渐小圆点
    private func drawCloud(in ctx: GraphicsContext, t: TimeInterval) {
        let cloud = Color.white.opacity(0.85)
        ctx.fill(Path(ellipseIn: CGRect(x: 29, y: 10, width: 32, height: 32)), with: .color(cloud))
        ctx.fill(Path(ellipseIn: CGRect(x: 50, y: 2, width: 40, height: 40)), with: .color(cloud))
        ctx.fill(Path(ellipseIn: CGRect(x: 79, y: 10, width: 32, height: 32)), with: .color(cloud))
        ctx.fill(Path(roundedRect: CGRect(x: 33, y: 24, width: 74, height: 20), cornerRadius: 10),
                 with: .color(cloud))

        // 梦境泡泡的经典圆点尾巴（指向右下方牛来的头）
        let pulse = 0.6 + 0.25 * sin(t * 2.2)
        ctx.fill(Path(ellipseIn: CGRect(x: 104, y: 48, width: 7, height: 7)), with: .color(.white.opacity(pulse)))
        ctx.fill(Path(ellipseIn: CGRect(x: 113, y: 59, width: 4.5, height: 4.5)), with: .color(.white.opacity(pulse - 0.1)))
    }

    /// 泡泡里的小剧场：深色剪影小牛从左跑到右，中途纵身一跳
    private func drawDreamScene(in ctx: GraphicsContext, t: TimeInterval) {
        let ink = Color(red: 0.30, green: 0.24, blue: 0.35).opacity(0.42)

        // 两颗忽明忽暗的小星星
        for (sx, sy, phase) in [(38.0, 12.0, 0.0), (102.0, 10.0, 1.8)] {
            let twinkle = 0.25 + 0.25 * sin(t * 2.5 + phase)
            ctx.fill(Path(ellipseIn: CGRect(x: sx - 1.5, y: sy - 1.5, width: 3, height: 3)),
                     with: .color(ink.opacity(twinkle)))
        }

        // 8 秒一个循环：跑 5.4 秒，跳 1.6 秒，落地继续
        let period = 8.0
        let progress = t.truncatingRemainder(dividingBy: period) / period
        let x = 46 + progress * 52
        var jump: CGFloat = 0
        if progress > 0.68, progress < 0.88 {
            jump = sin((progress - 0.68) / 0.20 * .pi) * 9
        }
        let groundY: CGFloat = 40
        let baseY = groundY - jump

        // 剪影小牛（侧视，朝右跑）
        // 尾巴
        var tail = Path()
        tail.move(to: CGPoint(x: x - 10, y: baseY - 7))
        tail.addQuadCurve(to: CGPoint(x: x - 15, y: baseY - 3), control: CGPoint(x: x - 14, y: baseY - 8))
        ctx.stroke(tail, with: .color(ink), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))

        // 两条腿（交替摆动）
        let legSwing = sin(t * 9) * 22
        for (lx, phase) in [(x - 4.0, legSwing), (x + 4.0, -legSwing)] {
            ctx.drawLayer { layer in
                layer.translateBy(x: lx, y: baseY)
                layer.rotate(by: .degrees(phase))
                layer.translateBy(x: -lx, y: -baseY)
                layer.fill(
                    Path(roundedRect: CGRect(x: lx - 1.3, y: baseY - 1, width: 2.6, height: 8), cornerRadius: 1.3),
                    with: .color(ink)
                )
            }
        }

        // 身体
        ctx.fill(Path(ellipseIn: CGRect(x: x - 11, y: baseY - 13, width: 22, height: 12)), with: .color(ink))
        // 头 + 小角
        ctx.fill(Path(ellipseIn: CGRect(x: x + 4, y: baseY - 20, width: 12, height: 12)), with: .color(ink))
        var horn = Path()
        horn.move(to: CGPoint(x: x + 7, y: baseY - 19))
        horn.addLine(to: CGPoint(x: x + 9, y: baseY - 25))
        horn.addLine(to: CGPoint(x: x + 11, y: baseY - 19))
        horn.closeSubpath()
        ctx.fill(horn, with: .color(ink))
    }
}
