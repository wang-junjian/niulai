# Pet（核心状态机）

牛来的「大脑」是一个 `PetViewModel` 类 + 五个按职责拆分的扩展（Swift 扩展不能持有存储属性，共享状态集中在主文件）。

* [PetViewModel 核心状态机](pet-view-model.md) - 15 个状态、主循环 tick、行为权重池、互动与气泡。
* [模式扩展 +Mode](pet-vm-mode.md) - mode 计算属性、切换响应、安静期与角落归宿。
* [番茄钟 +Pomodoro](pomodoro.md) - 25+5 分钟循环、长休、暂停 / 跳过、菜单栏倒计时。
* [彩蛋调度 +Events](events-scheduler.md) - 蛇 / 狼 / 蝴蝶的随机出场、互斥与忙碌延后。
* [提醒与电量 +Reminder](reminder-battery.md) - 休息提醒、IOKit 电量感知。
* [开场呼唤 +Opening](opening-call.md) - 「妈妈——！」/「牛来——！」的时序编排。
* [台词库](pet-phrases.md) - 戳 / 梦话 / 工作戳 / 提醒四组台词。
* [PetWindowController](pet-window-controller.md) - 牛来窗口：鼠标所在屏出生。
* [Settings](settings.md) - UserDefaults key 与默认值集中管理。
