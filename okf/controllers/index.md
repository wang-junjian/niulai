# Controllers（角色控制器）

蛇 / 狼 / 蝴蝶 / 云雀共用 [ScreenCrosser](screen-crosser.md) 横穿骨架；[豹拉](companion-controller.md)不横穿、独立实现跟随逻辑。

* [ScreenCrosser 基类](screen-crosser.md) - 模板方法：入场 → 每帧移动 → 出屏回调，hook 定制行为。
* [SnakeController](snake-controller.md) - 青蛇：贴地蜿蜒爬过，牛来吓一跳。
* [WolfController](wolf-controller.md) - 狼影：飞奔横穿，触发豹拉护卫联动。
* [ButterflyController](butterfly-controller.md) - 蝴蝶：翻飞 / 逃逸 / 追扑触发，五种随机配色。
* [LarkController](lark-controller.md) - 云雀：飞行调度 + 落头顶歇脚子状态机。
* [CompanionController](companion-controller.md) - 豹拉：跟随走位 / 登场离场 / 护卫，独立于 ScreenCrosser。
