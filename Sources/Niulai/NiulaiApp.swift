import SwiftUI
import AppKit

@main
struct NiulaiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(viewModel: appDelegate.pet)
        } label: {
            MenuBarLabelView(pet: appDelegate.pet)
        }
        .menuBarExtraStyle(.menu)
    }
}

/// 菜单栏图标：番茄钟运行时显示阶段和倒计时
private struct MenuBarLabelView: View {
    @ObservedObject var pet: PetViewModel

    var body: some View {
        Text(pet.menuBarLabel)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let pet = PetViewModel()
    lazy var companion = CompanionController(pet: pet)
    lazy var lark = LarkController(pet: pet)
    lazy var snake = SnakeController()
    lazy var wolf = WolfController()
    lazy var butterfly = ButterflyController()
    private var windowController: PetWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let controller = PetWindowController(viewModel: pet)
        windowController = controller
        pet.companion = companion
        pet.lark = lark
        pet.snake = snake
        pet.wolf = wolf
        pet.butterfly = butterfly
        butterfly.pet = pet
        controller.show()
        pet.start()
        lark.start()
        // 「豹拉常伴」上次开着且当前是休闲模式，启动就让它登场
        if pet.mode == .leisure, UserDefaults.standard.bool(forKey: "baolaAlways") {
            companion.appear()
        }
    }
}
