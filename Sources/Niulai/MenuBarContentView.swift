import SwiftUI

/// 菜单栏（🐮 图标）点开后的控制菜单。
struct MenuBarContentView: View {
    @ObservedObject var viewModel: PetViewModel

    @AppStorage("roamingEnabled") private var roamingEnabled = true
    @AppStorage("reminderMinutes") private var reminderMinutes = 45
    @AppStorage("baolaAlways") private var baolaAlways = false

    var body: some View {
        Text("模式")
        modeButton("休闲", .leisure)
        modeButton("工作", .working)
        modeButton("番茄钟", .pomodoro)

        if viewModel.mode == .pomodoro {
            Divider()
            Text(viewModel.pomodoroPhase == .focus
                 ? "🍅 专注中 · \(viewModel.pomodoroCountdown)"
                 : "☕️ 休息中 · \(viewModel.pomodoroCountdown)")
            Button(viewModel.pomodoroPaused ? "继续番茄钟" : "暂停番茄钟") {
                viewModel.togglePomodoroPause()
            }
            Button(viewModel.pomodoroPhase == .focus ? "提前进入休息" : "提前开始专注") {
                viewModel.skipPomodoroPhase()
            }
        }

        Divider()

        Button(viewModel.isVisible ? "隐藏牛来" : "显示牛来") {
            viewModel.setVisible(!viewModel.isVisible)
        }

        Toggle("自由走动", isOn: $roamingEnabled)
            .onChange(of: roamingEnabled) {
                viewModel.applyRoaming()
            }

        Toggle("豹拉常伴", isOn: $baolaAlways)
            .onChange(of: baolaAlways) {
                viewModel.companion?.setAlways(baolaAlways)
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

    /// 模式切换按钮：当前模式带勾选标记。
    /// （原来用 Picker，但 Picker 在 menu 样式的 MenuBarExtra 里选择不生效，换成按钮）
    private func modeButton(_ title: String, _ mode: PetViewModel.PetMode) -> some View {
        Button {
            viewModel.mode = mode
        } label: {
            Label(title, systemImage: viewModel.mode == mode ? "checkmark.circle.fill" : "circle")
        }
    }
}
