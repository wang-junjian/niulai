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
    private var windowController: PetWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let controller = PetWindowController(viewModel: pet)
        windowController = controller
        controller.show()
        pet.start()
    }
}
