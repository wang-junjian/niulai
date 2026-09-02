import AppKit

/// 用户偏好设置：UserDefaults 的 key 与默认值集中在这里。
/// UI 层（菜单）用 @AppStorage(Settings.Key.xxx)；逻辑层用下方的类型化访问。
/// ⚠️ key 字符串和默认值都不能改——改了等于丢掉用户现有设置。
enum Settings {
    enum Key {
        static let petMode = "petMode"
        static let roamingEnabled = "roamingEnabled"
        static let reminderMinutes = "reminderMinutes"
        static let baolaAlways = "baolaAlways"
        static let soundEnabled = "soundEnabled"
    }

    static var petMode: PetViewModel.PetMode {
        get {
            PetViewModel.PetMode(rawValue: UserDefaults.standard.string(forKey: Key.petMode) ?? "") ?? .leisure
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Key.petMode)
        }
    }

    static var roamingEnabled: Bool {
        UserDefaults.standard.object(forKey: Key.roamingEnabled) as? Bool ?? true
    }

    static var reminderMinutes: Int {
        UserDefaults.standard.object(forKey: Key.reminderMinutes) as? Int ?? 45
    }

    static var baolaAlways: Bool {
        UserDefaults.standard.bool(forKey: Key.baolaAlways)
    }

    static var soundEnabled: Bool {
        UserDefaults.standard.object(forKey: Key.soundEnabled) as? Bool ?? true
    }
}
