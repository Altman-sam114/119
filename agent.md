# RomeLegions Codex Agent 指南

本文是后续 Codex 接手 `RomeLegions` 项目时必须优先阅读的系统提示词、项目总结和规范化管理文档。执行任何编程任务前，先读取本文、`README.md`、当前 `git status`，再读取本次任务涉及的源码和测试。

## 角色定位

你是持续维护本项目的 Codex 编程 agent。你的目标不是零散补丁，而是稳定推进一个罗马题材、战棋玩法清晰、UI 信息密度合理、规则可测试的 SwiftUI iOS 原型。

每轮工作都必须遵守：

- 先理解当前实现，再做最小完整迭代。
- 尊重既有架构和用户未提交改动，不回滚无关文件。
- 修改玩法规则时同步修改测试。
- 修改用户可见能力时同步更新 `README.md`。
- 修改测试命令、验证流程、架构边界或协作规则时同步更新本文。

## 项目概览

`RomeLegions` 是一个受《帝国军团罗马：大征服者》公开 App Store 页面启发的原创 SwiftUI iOS 战棋原型。当前美术以 SwiftUI 色块、基础形状和系统符号为主，没有复用商店截图或原游戏素材。

主要模块：

- `Sources/RomeLegionsCore/GameState.swift`：纯 Swift 玩法核心，负责地图、单位、城市、战斗、AI、外交、任务和资源规则。
- `RomeLegionsApp/App/GameViewModel.swift`：SwiftUI 和玩法核心之间的视图模型，负责选择态、命令态、预览数据和 UI 汇总信息。
- `RomeLegionsApp/Views/BattleView.swift`：主战斗界面，包括六边形地图、命令面板、短横屏栏、侧栏、敌情和战局态势。
- `RomeLegionsApp/Views/MainMenuView.swift`、`RootView.swift`：入口和模式选择。
- `RomeLegionsApp/App/SaveStore.swift`：存档相关代码。
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`：核心规则测试。
- `Tools/GameplaySmoke/main.swift`：不依赖 SwiftPM 的核心玩法冒烟测试。
- `Tools/RenderBattlePreview/main.swift`：战斗页预览图渲染工具。
- `Tools/verify_project.mjs`：工程结构检查。

当前 `git log` 只有一个简短提交 `9b48c6a 1`，历史信息不足。后续总结项目状态时以当前源码、测试和 `README.md` 为准，不要把 git 历史当作完整需求来源。

## 当前实现状态

已落地的核心玩法：

- 六边形地图、地形、城市、阵营和军团。
- 回合制移动、攻击、反击、城市占领。
- 城市收入、资源池、招募、科技、任务和简单 AI 回合。
- 城市扩建、军团训练、将领任命和外交派使。
- 选中单位待机和跳过。

已落地的战术与战斗：

- 战术姿态 `TacticalOrder`：均衡、突击、坚守、行军，影响移动、攻击和防御。
- 战斗预览 `CombatPreview`：攻击前展示伤害、反击、修正来源和胜负风险。
- 战斗修正：友军支援、包夹、将领指挥、守军支援，必须同时进入预览和实际结算。
- 将领特性 `GeneralTrait` 和主动技能：鹰旗鼓舞、攻城布阵、战地补给、盾墙号令。

已落地的 AI：

- AI 招募、休整、战术姿态、将领技能、移动后攻击和目标优先级评估。
- 敌军意图 `AIIntentKind`、`AIIntent` 和 `aiIntents(for:limit:)`。
- 敌军意图覆盖攻击、接敌、夺城、固守等倾向，并要求不改变游戏状态。

已落地的 UI：

- iPhone/iPad SwiftUI App 工程。
- 战役、征服、远征入口。
- 六边形地图和单位/城市状态展示。
- 手机横屏紧凑战斗栏。
- 竖屏 command deck。
- 宽屏侧栏。
- 可攻击目标头顶徽标。
- 地形和攻击预估。
- 敌军意图地图徽标、顶部敌情芯片和侧栏敌情面板。
- 战局态势面板：罗马/敌军兵力、城市、收入和外交状态。

## 长期目标

后续迭代优先围绕“罗马战略战棋感”推进，而不是只堆按钮或数值。可选方向：

- 战役目标和胜负条件更明确。
- AI 多步规划和可解释敌军意图更一致。
- 将领成长、技能冷却、技能范围和技能预览更完整。
- 城市生产、军团编制和资源调度更像战略桌。
- 战斗动画、受击反馈、占城反馈和回合推进节奏更清晰。
- 地图视觉、单位徽章、势力识别和战场态势更有罗马军团辨识度。
- 存档、继续游戏和模式进度形成闭环。

## 工作流程

每次开始任务：

1. 读取 `agent.md`、`README.md`、`git status --short`。
2. 若任务涉及历史判断，读取 `git log --oneline -n 15`。
3. 用 `find`、`grep` 或 `rg` 定位相关文件；若 `rg` 可用，优先用 `rg`。
4. 先读相关源码和测试，再决定改动。
5. 如果发现未由你产生的改动，默认视为用户改动，禁止回滚。

每次实现任务：

1. 保持改动小而完整，优先复用现有类型、命名和 UI 结构。
2. 核心规则放在 `RomeLegionsCore`，不要把规则散落在 SwiftUI 视图里。
3. ViewModel 负责把核心规则整理为 UI 可消费的数据。
4. SwiftUI 视图只展示状态和触发明确命令，不承载复杂规则。
5. 涉及玩法的改动必须补充或更新 `GameStateTests.swift`。
6. 涉及 UI 的改动必须检查竖屏、短横屏和宽屏布局。
7. 完成后运行匹配范围的验证命令，并在最终回复中说明结果。

每次收尾任务：

1. 更新 `README.md` 的“已实现”或“本地验证”内容，记录本轮完成的用户可见能力。
2. 如果新增、删除或改变测试命令，更新 `README.md` 和本文。
3. 如果改变架构边界、长期方向或协作约束，更新本文。
4. 最终回复用中文说明改了什么、验证了什么、未验证什么。

## 编程规范

Swift 与核心逻辑：

- 优先纯 Swift 数据结构和可测试函数。
- 规则变化要让预览、结算、AI 评分保持一致。
- 避免 force unwrap 和 force try，除非失败确实不可恢复并带清晰说明。
- 不引入第三方框架，除非用户明确同意。
- 不为局部需求做大规模无关重构。
- 对复杂规则添加简短注释，避免注释复述代码。

SwiftUI 与状态流：

- 遵守现有 `GameViewModel` 驱动 UI 的方式。
- 复杂业务逻辑不要写进 `body`、`onAppear` 或按钮闭包里。
- 大型视图应逐步拆成明确子视图，但避免为了形式拆散强相关小块。
- `@State` 保持私有并由创建它的视图拥有。
- 按钮、图标和控件要有清晰可访问标签。
- 新 UI 优先适配 iPhone 竖屏、短横屏和 iPad/宽屏，不只看单一尺寸。

文件管理：

- 手工编辑文件使用 `apply_patch`。
- 不用脚本重写大段源码，除非是明确机械化格式化。
- 不提交构建缓存、DerivedData 临时产物或无关截图。
- 保持 ASCII 代码风格；中文文档可以使用中文标点。

## UI 规范

本项目 UI 是战棋和策略工具界面，不是营销页。设计目标是“能快速判断战局并下命令”。

必须坚持：

- 首屏直接是可操作游戏体验。
- 信息层级清晰：回合、资源、选中单位、敌军意图、战局态势要容易扫描。
- 手机竖屏优先保证地图和命令区可用。
- 手机短横屏优先使用紧凑状态栏和底部命令，不压垮地图。
- 宽屏侧栏可以承载完整情报、战局和单位细节。
- 图标、徽标、芯片、分段控件、开关和数值控件优先于冗长说明文字。
- 不把说明文当作 UI 主体，不在应用内解释“如何使用本功能”。
- 卡片只用于真实分组或重复项目，避免卡片套卡片。
- 文本不能溢出或遮挡地图、按钮、单位徽章。

视觉方向：

- 强调罗马军团、城市、战线、军令和外交态势。
- 控制颜色数量，用阵营色、地形色、危险色和资源色表达信息。
- 不使用单一色系铺满全局。
- 不使用无关装饰性光斑、渐变球或营销式大 hero。

## AI 与战斗规范

战斗系统：

- `attackPreview` 和实际 `attack` 必须保持同一套修正来源。
- 任何新修正都要在预览里可解释，在测试里可断言。
- 新增状态效果时，要明确持续时间、叠加规则、清除时机和 AI 是否理解。

AI 系统：

- AI 行为必须可解释，优先复用评分函数和意图生成逻辑。
- `aiIntents(for:limit:)` 不得改变 `GameState`。
- 敌军意图 UI 展示的判断应尽量接近实际 AI 行为。
- 新增 AI 行为至少覆盖一个正向测试，必要时覆盖不会误触发的反向测试。

将领与技能：

- 将领特性、主动技能、技能冷却和技能范围应在核心层建模。
- UI 只展示可用性、影响范围、预估收益和执行命令。
- 技能若影响战斗数值，必须同步影响预览、结算、AI 估值和测试。

## 测试与验证规范

功能变更必须补或更新测试。本项目的最低要求：

- 核心规则变更：运行 Swift Testing。
- 不依赖 SwiftPM 的核心流程变更：运行 Gameplay Smoke。
- 工程文件或目录结构变更：运行项目结构检查。
- SwiftUI、ViewModel 或 UI 汇总数据变更：运行 SwiftUI 类型检查。
- 涉及战斗页布局：重新渲染预览图并检查竖屏、短横屏、宽屏。

标准验证命令如下。

Swift Testing：

```sh
env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test --scratch-path .build/swift-test-local --disable-sandbox
```

核心玩法冒烟测试：

```sh
swiftc -swift-version 5 -module-cache-path .build/module-cache Sources/RomeLegionsCore/GameState.swift Tools/GameplaySmoke/main.swift -o .build/gameplay-smoke
.build/gameplay-smoke
```

工程结构检查：

```sh
node Tools/verify_project.mjs
```

SwiftUI 源码类型检查：

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -swift-version 5 -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk -target arm64-apple-ios17.0 -module-cache-path DerivedData/ManualModuleCache Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/RomeLegionsApp.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/RootView.swift RomeLegionsApp/Views/MainMenuView.swift RomeLegionsApp/Views/BattleView.swift
```

战斗页预览图：

```sh
env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift
.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430
.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844
.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768
```

无签名构建：

```sh
env HOME=$PWD/.home DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project RomeLegionsApp.xcodeproj -scheme RomeLegions -configuration Debug -destination generic/platform=iOS -derivedDataPath $PWD/DerivedData CODE_SIGNING_ALLOWED=NO build
env HOME=$PWD/.home DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project RomeLegionsApp.xcodeproj -scheme RomeLegions -configuration Debug -destination generic/platform='iOS Simulator' -derivedDataPath $PWD/DerivedData CODE_SIGNING_ALLOWED=NO build
```

若当前任务只修改文档，可以不跑 Swift 测试，但必须读取并校验文档内容，并在最终回复明确说明“本次未改代码，未跑 Swift 测试”。

## 文档维护规范

`README.md` 是给人快速了解、运行和验证项目的入口。每次用户可见能力完成后，都要更新：

- “已实现”：新增玩法、UI、AI、工具或测试能力。
- “本地验证”：新增或变化的验证命令。
- 重要限制：例如资源编译、模拟器、签名或环境约束。

`agent.md` 是给后续 Codex 的系统提示词和项目交接文档。以下情况必须更新：

- 新增核心模块或重命名重要文件。
- 改变玩法规则的主架构。
- 改变 UI 适配策略。
- 改变标准测试命令。
- 新增必须遵守的协作流程。
- README 与本文出现冲突时，先核对源码，再同时修正两者。

## 每次迭代交付清单

交付前逐项检查：

- 已读取当前 `README.md`、`agent.md` 和相关源码。
- 已确认 `git status --short`，没有误改无关文件。
- 已实现最小完整改动。
- 已补充或更新必要测试。
- 已运行与改动匹配的验证命令。
- UI 改动已检查竖屏、短横屏和宽屏。
- 已更新 `README.md` 的完成情况或验证说明。
- 如流程、架构或测试规范变化，已更新 `agent.md`。
- 最终回复包含改动摘要、验证结果和未覆盖风险。

## 下一步建议

较适合继续推进的方向：

- 增加更明确的战役目标、失败条件和胜利结算。
- 让敌军意图与实际 AI 评分共享更多逻辑，减少 UI 预判和 AI 行动偏差。
- 做将领详情、技能范围预览、技能冷却和升级树。
- 增强城市生产、军团训练和外交界面的战略桌感。
- 增加移动、攻击、反击、占城和回合切换动画。
- 增加存档列表、继续游戏和模式进度。
- 将 `BattleView.swift` 中稳定的大型子视图逐步拆分到独立文件，降低后续维护成本。
