import SwiftUI
import AppKit

@main
struct NiulaiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(viewModel: appDelegate.pet)
        } label: {
            Text("🐮")
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let pet = PetViewModel()
    lazy var companion = CompanionController(pet: pet)
    lazy var lark = LarkController(pet: pet)
    lazy var snake = SnakeController()
    lazy var wolf = WolfController()
    private var windowController: PetWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let controller = PetWindowController(viewModel: pet)
        windowController = controller
        pet.companion = companion
        pet.lark = lark
        pet.snake = snake
        pet.wolf = wolf
        controller.show()
        pet.start()
        lark.start()
        // 「豹拉常伴」上次开着且当前是休闲模式，启动就让它登场
        if pet.mode == .leisure, UserDefaults.standard.bool(forKey: "baolaAlways") {
            companion.appear()
        }
    }
}
