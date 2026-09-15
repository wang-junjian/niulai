# Core（基础设施）

* [FrameTicker](frame-ticker.md) - 定频回调器：60fps 动画驱动与低频调度统一走这里。
* [WindowFactory](window-factory.md) - 无边框透明悬浮窗工厂，所有角色窗口的唯一创建入口。
* [ScreenGeometry](screen-geometry.md) - visibleFrame 回退链，锁屏垃圾坐标兜底。
* [EyeBlink](eye-blink.md) - 确定性伪随机不规则眨眼，各角色 seed 错开节奏。
* [SoundPlayer](sound-player.md) - 电影原声 mp3 播放，受菜单「音效」开关控制。
