import SwiftUI

/// 桌宠内容容器：上方是对话气泡，下方是牛来本体。
/// 点击 = 戳它一下，拖拽 = 拎起来放到别处。
struct PetContainerView: View {
    @ObservedObject var viewModel: PetViewModel
    @State private var grabOffset: CGPoint?

    var body: some View {
        NiulaiView(viewModel: viewModel)
            .frame(width: 240, height: 230)
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .onTapGesture {
                viewModel.poke()
            }
            .frame(width: 240, height: 300, alignment: .bottom)   // 牛来锚定窗口底部
            .overlay(alignment: .top) {
                // 气泡悬浮在头顶，不参与布局：出现/消失时牛来原地不动
                SpeechBubbleView(text: viewModel.bubbleText)
                    .frame(height: 70)
                    .allowsHitTesting(false)
            }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { _ in
                guard let window = viewModel.window else { return }
                let mouse = NSEvent.mouseLocation
                if let grab = grabOffset {
                    window.setFrameOrigin(NSPoint(x: mouse.x - grab.x, y: mouse.y - grab.y))
                } else {
                    viewModel.beginDrag()
                    let origin = window.frame.origin
                    grabOffset = CGPoint(x: mouse.x - origin.x, y: mouse.y - origin.y)
                }
            }
            .onEnded { _ in
                grabOffset = nil
                viewModel.endDrag()
            }
    }
}
