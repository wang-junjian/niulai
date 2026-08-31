import SwiftUI

/// 菜单栏（🐮 图标）点开后的控制菜单。
struct MenuBarContentView: View {
    @ObservedObject var viewModel: PetViewModel

    @AppStorage("roamingEnabled") private var roamingEnabled = true
    @AppStorage("reminderMinutes") private var reminderMinutes = 45

    var body: some View {
        Button(viewModel.isVisible ? "隐藏牛来" : "显示牛来") {
            viewModel.setVisible(!viewModel.isVisible)
        }

        Toggle("自由走动", isOn: $roamingEnabled)
            .onChange(of: roamingEnabled) {
                viewModel.applyRoaming()
            }

        Picker("休息提醒", selection: $reminderMinutes) {
            Text("关闭").tag(0)
            Text("每 30 分钟").tag(30)
            Text("每 45 分钟").tag(45)
            Text("每 1 小时").tag(60)
        }
        .onChange(of: reminderMinutes) {
            viewModel.configureReminder()
        }

        Divider()

        Button("戳一下牛来") {
            viewModel.poke()
        }

        Divider()

        Button("退出牛来") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
