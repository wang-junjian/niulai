import SwiftUI

/// 牛来头顶的对话气泡。
struct SpeechBubbleView: View {
    let text: String?

    var body: some View {
        Group {
            if let text {
                VStack(spacing: 0) {
                    Text(text)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(red: 0.30, green: 0.20, blue: 0.14))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(red: 1.0, green: 0.98, blue: 0.92))
                                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        )
                    BubbleTail()
                        .fill(Color(red: 1.0, green: 0.98, blue: 0.92))
                        .frame(width: 14, height: 8)
                        .offset(x: 40)   // 指向牛来的头
                }
                .padding(.horizontal, 16)
                .transition(.scale(scale: 0.5, anchor: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: text)
    }
}

/// 气泡下面的小三角尾巴。
private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
