# 项目版本更新记录

本文记录 `RomeLegions` 的正式版本、重要维护事项、关键决策和遗留问题。它不是流水账；只记录会影响后续 Agent 判断的事实。

## 维护规则

- 每完成一个正式版本或重要任务后追加记录。
- 记录必须包含：版本/任务名、日期、核心变更、关键文件、验证结果、遗留事项。
- 文档整理、目录迁移、回滚、打捞等不伪装成功能版本，可写入“历史维护记录”。
- 若核心逻辑、测试规范或项目行为变化，必须同步更新本日志。
- 测试结果必须写具体命令和结果；未运行的测试必须说明原因。

## 当前状态

- 项目类型：原创 SwiftUI iOS 罗马题材战棋原型。
- 核心架构：纯 Swift `RomeLegionsCore` 负责玩法规则；`GameViewModel` 负责 UI 状态和派生数据；SwiftUI 视图负责展示和命令入口。
- 当前玩法：六边形地图、地形、城市、阵营、军团、移动、攻击、反击、占城、招募、科技、任务 requirement、战役目标、胜负结算、结束保护、外交、城市扩建、城市经营与招募读板、军团训练、将领任命、主动技能、技能冷却、将领详情读板、被动贡献、战功状态、战术姿态与姿态预览、AI 回合、敌军意图预判、敌军意图六边形路径/目标叠层、战线压力读板、战局态势面板。
- 当前测试入口：Swift Testing、Gameplay Smoke、项目结构检查、SwiftUI 类型检查、战斗页预览图渲染、无签名 Xcode 构建。
- 当前协作系统：已建立 `AGENTS.md`、`update_log.md`、`md/prompt/`、`md/test/test.md`、`md/flow/flow.md`、`md/flow/flowchart.md`，默认按 `main` 直推、GitHub Actions 云端重验证、Agent C 下载未加密结果包复判，并具备未来由 Agent X 主控调度 Agent A/B/C 多轮循环的文档基线。
- 当前 CI 入口：`.github/workflows/ci-results.yml`，在 `main` push 和手动触发时运行结构检查、SwiftPM 测试、Gameplay Smoke 和无签名 Xcode build，并上传 CI 结果包。

## 历史记录

### v0.14 / 战线压力与 AI 战略意图读板

日期：2026-07-05

核心变更：

- `GameState` 新增 `FrontlinePressureLevel`、`FrontlinePressureTargetKind` 和 `FrontlinePressureReport`，通过 `frontlinePressureReports(against:perFactionLimit:limit:)` 只读聚合交战敌军 `AIIntent`，按罗马单位或城市展示来源单位、来源阵营、意图数量、攻击/夺城数量、预计伤害合计、最高威胁值、压力分和压力等级。
- 战线压力报告不新增 `AIIntent` 存储字段，不改变 `performSimpleAI(for:)`、AI 权重、真实移动、战斗结算或 Codable 存档结构；压力等级只用于 UI 读板。
- `GameViewModel` 新增 `FrontlinePressureSummary`、`frontlinePressureSummaries` 和 `primaryFrontlinePressureSummary`，把核心报告整理成目标、来源、压力标签、影响文案和无障碍说明。
- `BattleView` 在地图顶部状态条显示首要“战线”chip，在完整战局面板展示最多三条战线压力行，在紧凑战场面板只显示一条短摘要，避免挤占手机竖屏和短横屏军令入口。
- Swift Testing 增加多路敌军集火同一罗马单位、敌军夺取罗马城市、停战势力过滤和只读不变性覆盖；Gameplay Smoke 增加多路压力主链路断言。
- `Tools/RenderBattlePreview` 在既有敌军路径、将领、姿态和城市读板断言基础上，新增首要战线压力摘要断言，并继续输出城市场景 PNG 和 `*-unit.png` 单位场景 PNG。
- README、flow、flowchart、test 文档同步战线压力边界、UI 展示和 v0.14 artifact 版本，并新增 v0.14 Agent A 提示词。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（玩法推进）/v0.14（战线压力与AI战略意图读板）.md`
- `update_log.md`

验证结果：

- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test --scratch-path .build/swift-test-local --disable-sandbox`：通过，48 个 Swift Testing 用例通过；本机 SwiftPM cache 目录只读警告不影响测试结果。
- `swiftc -swift-version 5 -module-cache-path .build/module-cache Sources/RomeLegionsCore/GameState.swift Tools/GameplaySmoke/main.swift -o .build/gameplay-smoke`：通过，无错误输出。
- `.build/gameplay-smoke`：通过，输出 `Gameplay smoke test passed.`
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -swift-version 5 -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk -target arm64-apple-ios17.0 -module-cache-path DerivedData/ManualModuleCache Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/RomeLegionsApp.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/RootView.swift RomeLegionsApp/Views/MainMenuView.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430`：通过，短横屏城市场景和 `DerivedData/battle-landscape-preview-unit.png` 单位场景生成成功；单位场景顶部显示战线 chip，军令入口仍在首屏。
- `.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844`：通过，竖屏城市场景和 `DerivedData/battle-portrait-preview-unit.png` 单位场景生成成功；地图、战线 chip、军令和情报面板无明显裁切或重叠。
- `.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768`：通过，宽屏城市场景和 `DerivedData/battle-wide-preview-unit.png` 单位场景生成成功；单位场景显示战线压力、敌军路线、目标叠层、将领详情和姿态预览。
- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：通过，输出 `yaml ok`。
- `plutil -lint RomeLegionsApp.xcodeproj/project.pbxproj`：通过，输出 `RomeLegionsApp.xcodeproj/project.pbxproj: OK`。

遗留事项：

- 本轮没有实现多回合 AI 搜索、战略路线规划、AI 权重调整、建筑树、人口、军团编制、存档 UI 或外交界面。
- 完整战局面板里的压力列表只展示核心只读报告，不参与招募、扩建、攻击或 AI 决策。
- 本轮没有默认本机跑完整 `xcodebuild build`；按项目规则交给 `origin/main` 最新 commit 的 GitHub Actions 重验证。
- CI 仍只上传必要 manifest、JUnit、日志和 xcresult，不上传本地 PNG；三尺寸城市场景 PNG 与 `*-unit.png` 单位场景 PNG 只用于本地目视检查，不提交版本库。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.14 run id、run attempt 和 artifact；不能使用 v0.13 旧结果包。

### v0.13 / 城市经营与招募预览读板

日期：2026-07-05

核心变更：

- `GameState` 新增 `CityDevelopmentPreview` 和 `CityRecruitmentPreview`，公开城市扩建成本/收益、招募成本、预计部署位置、可执行状态和阻塞原因。
- `developCity(id:)` 和 `recruit(_:at:)` 改为复用核心预览中的成本、收益和部署位置，避免 UI 预览与真实结算分叉；本轮不改变既有数值、部署顺序、AI 招募策略或存档字段。
- `GameViewModel` 新增 `SelectedCityBrief` 和 `CityRecruitmentOptionPreview`，把核心城市预览整理为本城产出、所属势力收入、罗马库存、部署摘要、扩建收益和四类兵种招募文案。
- `BattleView` 的完整/紧凑情报栏展示城市经营读板；完整/紧凑军令面板的扩建和招募按钮改为消费 ViewModel 预览，资源不足、缺少港口或无部署格时禁用并显示原因。
- Swift Testing 增加城市扩建预览、招募部署预览、资源不足、舰队港口、舰队港口被占和预览只读覆盖；Gameplay Smoke 增加城市扩建和招募预览主链路断言。
- `Tools/RenderBattlePreview` 保留 v0.11/v0.12 单位、将领、姿态和敌军路径断言，并追加那不勒斯城市读板、扩建收益、四类招募选项和舰队港口部署断言；每次渲染同时输出请求路径的城市场景图和 `*-unit.png` 单位场景图，避免城市截图覆盖单位 UI 视觉回归。
- README、flow、flowchart、test 文档同步城市读板、核心预览边界和 v0.13 artifact 版本，并新增 v0.13 Agent A 提示词。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（玩法推进）/v0.13（城市经营与招募预览读板）.md`
- `update_log.md`

验证结果：

- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test --scratch-path .build/swift-test-local --disable-sandbox`：通过，45 个 Swift Testing 用例通过；本机 SwiftPM cache 目录只读警告不影响测试结果。
- `swiftc -swift-version 5 -module-cache-path .build/module-cache Sources/RomeLegionsCore/GameState.swift Tools/GameplaySmoke/main.swift -o .build/gameplay-smoke`：通过，无错误输出。
- `.build/gameplay-smoke`：通过，输出 `Gameplay smoke test passed.`
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -swift-version 5 -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk -target arm64-apple-ios17.0 -module-cache-path DerivedData/ManualModuleCache Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/RomeLegionsApp.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/RootView.swift RomeLegionsApp/Views/MainMenuView.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430`：通过，短横屏城市场景和 `DerivedData/battle-landscape-preview-unit.png` 单位场景生成成功；军令区显示扩建和四类招募按钮，单位场景保留将领、姿态和敌军路线视觉覆盖。
- `.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844`：通过，竖屏城市场景和 `DerivedData/battle-portrait-preview-unit.png` 单位场景生成成功；地图、军令、城市情报顺序清楚，招募按钮无明显裁切。
- `.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768`：通过，宽屏城市场景和 `DerivedData/battle-wide-preview-unit.png` 单位场景生成成功；完整侧栏显示城市经营、扩建预览、四类招募选项和舰队港口部署，单位场景保留将领和敌军路径视觉覆盖。
- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：通过，输出 `yaml ok`。
- `plutil -lint RomeLegionsApp.xcodeproj/project.pbxproj`：通过，输出 `RomeLegionsApp.xcodeproj/project.pbxproj: OK`。

遗留事项：

- 本轮没有新增建筑树、城市等级、人口、军团编制、外交界面或 AI 招募策略；城市读板只公开并复用已有核心规则。
- 本轮没有默认本机跑完整 `xcodebuild build`；按项目规则交给 `origin/main` 最新 commit 的 GitHub Actions 重验证。
- CI 仍只上传必要 manifest、JUnit、日志和 xcresult，不上传本地 PNG；三尺寸城市场景 PNG 与 `*-unit.png` 单位场景 PNG 只用于本地目视检查，不提交版本库。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.13 run id、run attempt 和 artifact；不能使用 v0.12 旧结果包。

### v0.12 / 敌军意图路径贴合六边形地图

日期：2026-07-04

核心变更：

- `GameViewModel.enemyIntentMapOverlays(for:)` 不再只透传 `EnemyIntentSummary` 的直线路线，而是为每条敌军意图只读派生地图路线段。
- 敌军移动路线现在按 `Position.neighbors(width:height:)`、地形进入能力、地形移动成本、单位占用和该意图战术姿态后的有效机动生成相邻六边形路径；找不到合法路径时保留旧直线兜底，避免叠层消失。
- 目标段继续显示为 `destination -> target` 的 target leg，不和移动路径混淆；`BattleView` 仍只消费 `EnemyIntentMapOverlay.routeSegments`，不参与路径算法。
- `Tools/RenderBattlePreview` 增加路径断言：移动后攻击路线必须包含多个非 targetLeg 段，每段 `from` / `to` 都必须是六边形邻居，最后一段到达 `AIIntent.destination`，target leg 从 destination 指向目标格；同时保留 v0.11 将领详情、姿态预览和紧凑命令区像素检查。
- README、flow、flowchart、test 文档同步敌军意图六边形路径、ViewModel 只读派生边界和 v0.12 artifact 版本，并新增 v0.12 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（玩法推进）/v0.12（敌军意图路径贴合六边形地图）.md`
- `update_log.md`

验证结果：

- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -swift-version 5 -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk -target arm64-apple-ios17.0 -module-cache-path DerivedData/ManualModuleCache Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/RomeLegionsApp.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/RootView.swift RomeLegionsApp/Views/MainMenuView.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430`：通过，短横屏预览图生成成功；敌军路线显示为相邻六边形折线，军令入口仍在首屏。
- `.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844`：通过，竖屏预览图生成成功；地图路线折线、目标线和地图叠层可读，命令入口无回归。
- `.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768`：通过，宽屏预览图生成成功；路线从敌军位置按格点折向目的地，再以目标段指向罗马单位。
- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：通过，输出 `yaml ok`。
- `plutil -lint RomeLegionsApp.xcodeproj/project.pbxproj`：通过，输出 `RomeLegionsApp.xcodeproj/project.pbxproj: OK`。

遗留事项：

- 本轮没有改变 `GameState` 核心 AI 决策、评分、真实移动、战斗结算、Codable 存档字段或 Swift Testing 用例数量；路径只是 `GameViewModel` 的 UI 派生。
- 本轮没有默认本机跑完整 SwiftPM `swift test`、Gameplay Smoke 或 `xcodebuild build`；按项目规则交给 `origin/main` 最新 commit 的 GitHub Actions 重验证。
- 路线按核心 `Position.neighbors` 计算；未来如果要进一步提升视觉贴合度，应单独审查核心邻接和 `HexMetrics.center(for:)` 的坐标系一致性，不能在本轮顺手大改地图坐标。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.12 run id、run attempt 和 artifact；不能使用 v0.11 旧结果包。

### v0.11 / 将领详情与战术指挥可读化

日期：2026-07-04

核心变更：

- `GameViewModel` 新增选中单位指挥派生模型：`SelectedCommanderBrief`、`GeneralPassiveContribution` 和 `SelectedTacticalOrderPreview`，集中提供将领名、特性、被动贡献、技能状态、预计效果、战功摘要、各姿态攻防移、变化值和阻塞原因。
- 战术姿态预览通过局部复制选中单位并替换 `tacticalOrder`，再调用 `GameState.effectiveAttack/Defense/Movement` 计算，不写回 `GameState`，不改变核心数值、AI、结算或存档字段。
- `BattleView` 在完整侧栏、紧凑情报栏和战术姿态按钮中展示将领被动贡献、技能可用/冷却/阻塞状态、战功信息、均衡/突击/坚守/行军的攻防移预览和不可切换原因。
- 无将领单位会明确显示“无将领 / 无被动贡献”，避免把空状态伪装成加成。
- 紧凑命令栈在 iOS 上改为可滚动，并将“军令”置于手机竖屏和短横屏首屏，避免新增将领读板后挤掉攻击、姿态、技能、休整和跳过入口；macOS 预览渲染路径继续使用固定栈，规避 `ImageRenderer` 对紧凑 `ScrollView` 的空白渲染问题。
- `Tools/RenderBattlePreview` 的确定性场景加入凯撒鹰旗和非零经验，渲染前断言敌军意图路线仍存在，同时断言将领详情、鹰旗攻击被动、技能状态、战功摘要和完整战术姿态预览存在；渲染后对紧凑视口命令区域做轻量像素检查，防止命令区空白仍误判通过。
- README、flow、flowchart、test 文档同步选中单位指挥读板、姿态预览数据流和 v0.11 artifact 版本，并新增 v0.11 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（玩法推进）/v0.11（将领详情与战术指挥可读化）.md`
- `update_log.md`

验证结果：

- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：通过，输出 `yaml ok`。
- `plutil -lint RomeLegionsApp.xcodeproj/project.pbxproj`：通过，输出 `RomeLegionsApp.xcodeproj/project.pbxproj: OK`。
- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430`：通过，短横屏预览图生成成功；右侧首屏显示军令、姿态预览、技能、休整和跳过，敌军路线可读，情报可继续向下查看。
- `.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844`：通过，竖屏预览图生成成功；地图下方首屏显示军令、姿态预览、技能、休整和跳过，情报与将领读板可继续向下查看，无明显重叠或裁切。
- `.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768`：通过，宽屏预览图生成成功；完整侧栏显示姿态预览、鹰旗被动、技能效果、战功和冷却状态。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -swift-version 5 -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk -target arm64-apple-ios17.0 -module-cache-path DerivedData/ManualModuleCache Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/RomeLegionsApp.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/RootView.swift RomeLegionsApp/Views/MainMenuView.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。

遗留事项：

- 本轮没有改变 `GameState` 核心数值、`TacticalOrder` / `GeneralTrait` 加成、AI 决策、敌军意图排序、战斗结算、Codable 存档字段或 Swift Testing 用例数量；Swift Testing 基线仍为 41 个用例，由 `main` push 后 GitHub Actions 重验证。
- 本轮没有默认本机跑完整 SwiftPM `swift test`、Gameplay Smoke 或 `xcodebuild build`；按项目规则交给 `origin/main` 最新 commit 的 GitHub Actions 结果包验收。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.11 run id、run attempt 和 artifact；不能使用 v0.10 旧结果包。

### v0.10 / 敌军意图路线与目标地图叠层

日期：2026-07-04

核心变更：

- `GameViewModel` 新增敌军意图 UI 派生模型，把 `AIIntent`、来源单位、目标单位和目标城市转成起点、目的地、目标格、路线段、目标文案、预计伤害/效果文案和无障碍说明。
- `BattleView` 新增敌军意图路线层，使用 `HexMetrics.center(for:)` 绘制 `origin -> destination -> target` 可视线段，并增加目的地虚线叠层和目标格准星叠层；叠层不拦截地图点击，不改变 AI 行为。
- 敌情侧栏行从单行摘要扩展为可换行摘要，能显示来源、路线、目标和预计伤害或效果；单位头顶意图徽标保留并补充更完整的 VoiceOver 文案。
- Swift Testing 扩展既有 AI 意图测试，锁定直接攻击、移动后攻击和夺城意图继续提供 UI 叠层所需的 `destination`、`targetUnitID` / `targetCityID` 和 `projectedDamage` 字段，并保持预测只读。
- Gameplay Smoke 增加直接攻击、移动后攻击和夺城意图字段轻量断言，确认 forecast 不移动原始单位、不改变状态。
- `Tools/RenderBattlePreview` 改为确定性移动后攻击场景，渲染前断言 `enemyIntentMapOverlays` 含起点、目的地、目标格、路线段和预计伤害文案；三尺寸截图用于检查路线、目标叠层和侧栏敌情可读性。
- README、flow、flowchart、test 文档同步敌军意图路线/目标叠层、ViewModel 派生边界和 v0.10 artifact 版本，并新增 v0.10 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（玩法推进）/v0.10（敌军意图路线与目标地图叠层）.md`
- `update_log.md`

验证结果：

- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test --scratch-path .build/swift-test-local --disable-sandbox`：通过，41 个 Swift Testing 用例通过；本机 SwiftPM cache 目录只读警告不影响测试结果。
- `swiftc -swift-version 5 -module-cache-path .build/module-cache Sources/RomeLegionsCore/GameState.swift Tools/GameplaySmoke/main.swift -o .build/gameplay-smoke`：通过，无错误输出。
- `.build/gameplay-smoke`：通过，输出 `Gameplay smoke test passed.`
- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430`：通过，短横屏预览图生成成功，敌军路线和目标叠层可辨认，右侧情报未被遮挡。
- `.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844`：通过，竖屏预览图生成成功，地图不横向裁切，路线和目标叠层位于地图内部，信息面板无重叠。
- `.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768`：通过，宽屏预览图生成成功，敌情面板显示接敌攻击、起点、目的地、目标和预计伤害，地图路线和目标叠层可读。
- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：通过，输出 `yaml ok`。
- `plutil -lint RomeLegionsApp.xcodeproj/project.pbxproj`：通过，输出 `RomeLegionsApp.xcodeproj/project.pbxproj: OK`。

遗留事项：

- 本轮没有改变 AI 评分、目标选择、真实移动路径、`performSimpleAI` 执行顺序或战斗结算；路线叠层只是 `AIIntent` 既有字段的直线可视化。
- 本轮没有默认本机跑完整 `xcodebuild build`；按项目规则交给 `main` push 后的 GitHub Actions 重验证。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.10 run id、run attempt 和 artifact；不能使用 v0.9 旧结果包。

### v0.9 / 将领技能冷却与战功状态可读化

日期：2026-07-04

核心变更：

- `ArmyUnit` 新增 `generalSkillCooldownRemaining`，并实现自定义 Codable，旧 `ArmyUnit` JSON 缺冷却字段时默认解码为 0。
- `GeneralTrait` 新增统一技能冷却回合数；`useGeneralSkill(unitID:)` 成功后写入冷却，核心层在冷却未归零时抛出 `generalSkillOnCooldown`。
- `GeneralSkillPreview` 新增冷却剩余和冷却文案；预览、释放和 AI 技能判断共享可执行状态，冷却时 `isExecutable == false`。
- 抽出所属阵营回合开始刷新 helper，让 `endTurn()` 和 `aiIntents(for:limit:)` 的 forecast copy 复用同一套行动重置、姿态清空和冷却递减逻辑；其他阵营回合不会递减冷却。
- 新增 `WarMeritStatus`，把经验转为军阶、战功进度和 `experience * 3` 伤害加成说明，不改变既有伤害公式。
- `GameViewModel` 暴露选中单位战功状态、技能冷却摘要和按钮 detail；`BattleView` 在完整/紧凑情报、将领卡、技能按钮和兵牌冷却徽标中展示冷却与战功。
- AI 主动技能判断补齐 `preview.isExecutable` 检查，避免治疗类技能在冷却中仍产生 `.useSkill` 意图或实际释放。
- Swift Testing 增加冷却写入、递减时机、核心阻止释放、预览只读、AI 遵守冷却、战功映射和旧 `ArmyUnit` JSON 兼容用例。
- Gameplay Smoke 增加技能冷却主链路和战功状态轻量断言。
- README、flow、flowchart、test 文档同步技能冷却、战功状态、AI 预测和 artifact 版本，并新增 v0.9 Agent A 提示词。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（玩法推进）/v0.9（将领技能冷却与战功状态可读化）.md`
- `update_log.md`

验证结果：

- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test --scratch-path .build/swift-test-local --disable-sandbox`：通过，41 个 Swift Testing 用例通过；本机 SwiftPM cache 目录只读警告不影响测试结果。
- `swiftc -swift-version 5 -module-cache-path .build/module-cache Sources/RomeLegionsCore/GameState.swift Tools/GameplaySmoke/main.swift -o .build/gameplay-smoke`：通过，无错误输出。
- `.build/gameplay-smoke`：通过，输出 `Gameplay smoke test passed.`
- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430`：通过，短横屏预览图生成成功，冷却和战功信息在侧栏可读，地图无明显遮挡。
- `.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844`：通过，竖屏预览图生成成功，紧凑情报面板新增战功/冷却信息后未出现明显裁切。
- `.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768`：通过，宽屏预览图生成成功，将领卡展示军阶进度条、冷却状态和技能摘要，无明显重叠。
- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：通过，输出 `yaml ok`。
- `plutil -lint RomeLegionsApp.xcodeproj/project.pbxproj`：通过，输出 `RomeLegionsApp.xcodeproj/project.pbxproj: OK`。

遗留事项：

- 本轮没有新增将领、技能种类、升级树或手动点选技能目标；后续仍可继续扩展将领成长线和更细的战略技能。
- 本轮没有默认本机跑完整 `xcodebuild build`；按项目规则交给 `main` push 后的 GitHub Actions 重验证。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.9 run id、run attempt 和 artifact；不能使用 v0.8 旧结果包。

### v0.8 / 将领技能范围与目标预览体验

日期：2026-07-04

核心变更：

- 新增 `GeneralSkillPreview` 只读模型，统一描述将领主动技能的范围格、受影响友军/敌城、预计恢复量、预计城防削弱、可执行状态、不可用原因和 UI 摘要。
- `useGeneralSkill(unitID:)` 改为先生成技能预览，再复用预览中的目标 ID 执行治疗或削城防，避免预览和结算使用两套目标筛选逻辑。
- AI 主动技能判断和 `.useSkill` 意图复用技能预览；攻城技能继续填目标城市，治疗类技能填主要受益友军。
- `GameViewModel` 新增选中将领技能预览、范围格、目标格、目标单位/城市集合和技能按钮摘要等 UI 派生数据。
- `BattleView` 新增技能范围青色虚线叠层、技能目标金色叠层，并在将领卡、紧凑情报面板和军令按钮展示范围、目标数、预计效果或不可用原因。
- Swift Testing 增加将领技能预览相关基线，覆盖预览只读、鹰旗/军需/盾墙恢复预览与释放一致、攻城预览与释放一致、攻城无目标不可执行、AI 技能意图目标来自预览。
- Gameplay Smoke 增加将领技能预览不改状态、恢复预览和攻城预览与释放结果一致的轻量断言。
- README、flow、flowchart、test 文档同步将领技能预览链路，并将 CI artifact 版本同步到 v0.8。
- 新增 v0.8 Agent A 提示词，明确本轮技能预览目标、UI 边界、测试和 Agent C 云端复判要求。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（玩法推进）/v0.8（将领技能范围与目标预览体验）.md`
- `update_log.md`

验证结果：

- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test --scratch-path .build/swift-test-local --disable-sandbox`：通过，35 个 Swift Testing 用例通过；本机 SwiftPM cache 目录只读警告不影响测试结果。
- `swiftc -swift-version 5 -module-cache-path .build/module-cache Sources/RomeLegionsCore/GameState.swift Tools/GameplaySmoke/main.swift -o .build/gameplay-smoke`：通过，无错误输出。
- `.build/gameplay-smoke`：通过，输出 `Gameplay smoke test passed.`
- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430`：通过，短横屏预览图生成成功，地图完整可见，技能范围/目标叠层和侧栏摘要可读。
- `.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844`：通过，竖屏预览图生成成功，地图不横向裁切，技能叠层不遮断主要操作。
- `.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768`：通过，宽屏预览图生成成功，将领卡展示范围、友军目标数和技能状态。
- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：通过，输出 `yaml ok`。
- `plutil -lint RomeLegionsApp.xcodeproj/project.pbxproj`：通过，输出 `RomeLegionsApp.xcodeproj/project.pbxproj: OK`。

遗留事项：

- 本轮没有新增将领、技能冷却、升级树或手动点选技能目标；后续仍可继续扩展将领详情和成长系统。
- 本轮没有默认本机跑完整 `xcodebuild build`；按项目规则交给 `main` push 后的 GitHub Actions 重验证。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.8 run id、run attempt 和 artifact；不能使用 v0.7 旧结果包。

### v0.7 / AI 意图与移动后攻击预览一致性

日期：2026-07-04

核心变更：

- 新增 AI 规划态战斗预览 helper，让 AI 攻击评分、直接攻击意图和移动后攻击意图优先使用 `attackPreview` 的同一套伤害来源。
- 修正同一移动目的地既可占城又可攻击时的意图优先级：真实 AI 会移动后继续攻击，因此敌军意图优先显示 `.advanceAttack` 和预计伤害，无法攻击时才显示 `.captureCity`。
- 直接攻击和移动后攻击意图的 `projectedDamage` 与规划态 `attackPreview.damage` 对齐，保持 `aiIntents(for:limit:)` 只读不改原始状态。
- 新增 Swift Testing 用例，锁定移动后攻击意图、规划态预览和 `performSimpleAI` 真实伤害一致。
- Gameplay Smoke 增加直接攻击和移动后攻击 projectedDamage / preview 一致性断言。
- README、flow、flowchart、test 文档同步 AI 意图预计伤害来源，并将 CI artifact 版本同步到 v0.7。
- 新增 v0.7 Agent A 提示词，明确本轮 AI 一致性目标、核心边界、测试和 Agent C 云端复判要求。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（玩法推进）/v0.7（AI意图与移动后攻击预览一致性）.md`
- `update_log.md`

验证结果：

- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test --scratch-path .build/swift-test-local --disable-sandbox`：通过，32 个 Swift Testing 用例通过；本机 SwiftPM cache 目录只读警告不影响测试结果。
- `swiftc -swift-version 5 -module-cache-path .build/module-cache Sources/RomeLegionsCore/GameState.swift Tools/GameplaySmoke/main.swift -o .build/gameplay-smoke`：通过，无错误输出。
- `.build/gameplay-smoke`：通过，输出 `Gameplay smoke test passed.`
- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：通过，输出 `yaml ok`。

遗留事项：

- 本轮未修改 SwiftUI 呈现层、`GameViewModel`、存档结构或 Xcode project。
- 本轮没有默认本机跑完整 `xcodebuild build`；按项目规则交给 `main` push 后的 GitHub Actions 重验证。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.7 run id、run attempt 和 artifact；不能使用 v0.6 旧结果包。

### v0.6 / 战斗地图可读性与窄屏完整显示

日期：2026-07-04

核心变更：

- 修正非竖屏战斗区高度约束，让 `WarMapView` 使用顶栏后的真实可见高度，避免短横屏地图按过高容器放大后被裁切。
- 调整 `HexMetrics`，移除固定 44pt 地块下限，按地图安全边距和可用宽高自适应 tile 尺寸，并输出用于地图内容缩放的 `tileScale`。
- 强化地图视觉层级：可移动格改为黄色半透明六边形和虚线边框，选中格增加白金双层描边，攻击目标增加红色半透明覆盖层。
- 增加原创地形纹理：道路路线、水域波纹、城市据点横纹、森林/丘陵/平原低调纹理，使战略通道和海陆分界更清楚。
- 强化单位兵牌：加入单位类型底纹图标和阵营描边，保持将领星标、战术姿态和生命条显示。
- 为地图格和攻击徽标补充 VoiceOver 按钮语义，避免仅靠 `onTapGesture` 暴露交互。
- README 补齐 1024x768 宽屏战斗页预览命令。
- 新增 v0.6 Agent A 提示词，明确本轮 UI 边界、三尺寸预览验收和 Agent C 云端复判要求。

关键文件：

- `RomeLegionsApp/Views/BattleView.swift`
- `README.md`
- `md/prompt/v0（玩法推进）/v0.6（战斗地图可读性与窄屏完整显示）.md`
- `update_log.md`

验证结果：

- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430`：通过，短横屏预览图生成成功，12x8 棋盘完整可见。
- `.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844`：通过，竖屏预览图生成成功，地图不横向裁切。
- `.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768`：通过，宽屏预览图生成成功，地图与完整侧栏不重叠。
- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`

遗留事项：

- 本轮只改 SwiftUI 呈现层、README 和提示词/日志，未修改 `GameState`、`GameViewModel` 玩法语义或核心测试。
- 本轮没有默认本机跑完整 `swift test`、Gameplay Smoke 或 `xcodebuild build`；按项目规则交给 `main` push 后的 GitHub Actions 重验证。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.6 run id、run attempt 和 artifact；不能使用 v0.5 旧结果包。
- `.github/workflows/ci-results.yml` 未同步 CI_VERSION，artifact 名称可能仍含 v0.4，验收以 manifest 的 commit、run id 和 run attempt 为准。

### v0.5 / 引入 Agent X 循环迭代文档基线

日期：2026-07-04

核心变更：

- 新增 Agent X 召唤、职责、循环判断和停止条件。
- 将现有 Agent A/B/C 云端验证流程扩展为可被 Agent X 多轮调度。
- 更新 flow、flowchart、test、prompt README 和 README 中的协作说明。
- 明确本轮只做文档准备，不启动真实自动循环。
- 补充小数据量验证、必要 artifact 下载和下载目录容量检查规则。

关键文件：

- `AGENTS.md`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（协作自动化）/v0.5（引入AgentX循环迭代）.md`
- `update_log.md`

验证结果：

- `git diff --check`：通过。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`

遗留事项：

- 后续人工可用 `agentx:` 提供总目标 X，启动 Agent X 主控循环。
- Agent X 真正执行循环时，仍必须经过 Agent A 提示词、Agent B 实现 push、Agent C 云端 artifact 验收。
- 本轮未修改 `.github/workflows/ci-results.yml`，CI artifact 命名版本仍以当前 workflow 的 `CI_VERSION` 为准。

### v0.4 / 战役目标与胜负结算

日期：2026-07-04

核心变更：

- 在 `RomeLegionsCore` 中新增 `MissionRequirement`、`CampaignStatusKind`、`CampaignStatus` 和 `GameState.campaignStatus`，让核心层判断战役进行中、罗马胜利和罗马失败。
- 三项核心任务改为带 requirement 的可判断目标：占领叙拉古、拥有 5 支罗马部队、占领迦太基；旧 mission id 只作为缺 requirement 的兼容兜底。
- `evaluateMissions()` 保持任务奖励只发一次；触发全部核心目标后输出罗马胜利，罗马失去所有城市后输出罗马失败。
- `moveUnit`、`attack`、`recruit`、`research`、`developCity`、`trainUnit`、`appointGeneral`、`useGeneralSkill`、`restUnit`、`skipUnit`、`setTacticalOrder`、`sendEnvoy`、`endTurn` 和 `performSimpleAI` 接入战役结束保护。
- `GameViewModel` 暴露战役状态派生值，结束后停止 AI while loop，并让命令可用性跟随 `isCampaignOver`。
- `BattleView` 在顶部、战术状态条和元老院任务面板展示战役状态；结束回合、军令、科技和外交入口在战役结束后禁用。
- 更新 Gameplay Smoke、结构检查、CI artifact 版本、README、flow、flowchart、test 和 Agent 入口文档。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `Tools/verify_project.mjs`
- `.github/workflows/ci-results.yml`
- `AGENTS.md`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（玩法推进）/v0.4（战役目标与胜负结算）.md`
- `update_log.md`

验证结果：

- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test --scratch-path .build/swift-test-local --disable-sandbox`：通过，31 个 Swift Testing 用例通过。
- `swiftc -swift-version 5 -module-cache-path .build/module-cache Sources/RomeLegionsCore/GameState.swift Tools/GameplaySmoke/main.swift -o .build/gameplay-smoke`：通过，无错误输出。
- `.build/gameplay-smoke`：通过，输出 `Gameplay smoke test passed.`
- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430`：通过，生成横屏预览图。
- `.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844`：通过，生成竖屏预览图。
- `.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768`：通过，生成宽屏预览图。
- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：通过，输出 `yaml ok`。
- `plutil -lint RomeLegionsApp.xcodeproj/project.pbxproj`：通过，输出 `RomeLegionsApp.xcodeproj/project.pbxproj: OK`。
- `git status --short`：已确认只包含本轮 v0.4 相关源码、测试、工具、CI、文档和 Agent A 提示词。
- GitHub Actions 云端结果包需要本轮 commit push 到 `origin/main` 后由 Agent C 下载复判。

遗留事项：

- 本轮没有默认本机跑完整 `xcodebuild build`，按项目规则交给 `main` push 后的 GitHub Actions 重验证。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.4 artifact，不能使用 v0.3 旧结果包。

### v0.3 / 升级 main 直推云端验证流程

日期：2026-07-03

核心变更：

- 精简并强化 `AGENTS.md`，加入 `agenta` / `a:`、`agentb` / `b:`、`agentc` / `c:` 角色召唤、身份标识、`main` 直推和 Agent C 结果包验收规则。
- 更新 `md/test/test.md`，把默认策略改为本地轻量检查 + GitHub Actions 云端重验证，保留人工明确要求时的本机完整测试命令。
- 更新 `md/flow/flow.md` 和 `md/flow/flowchart.md`，加入 Agent A/B/C、`main` commit/push、GitHub Actions、未加密结果包、Agent C 下载复判和追加修复 commit 闭环。
- 新增 `md/prompt/README.md`，记录提示词目录、角色召唤和 Agent A 必须写入的 CI / main push / artifact 要求。
- 新增 `.github/workflows/ci-results.yml`，在 `main` push 或手动触发时生成 `ci-artifact-manifest.json`、`ci-failure-summary.md`、`junit.xml`、日志和 `.xcresult` 结果包。
- 更新 `README.md` 和 `Tools/verify_project.mjs`，让快速入口和结构检查覆盖新的云端协作制度。
- 本轮是协作流程制度变更，不是业务功能或玩法质量提升；未修改 Swift 玩法源码。

关键文件：

- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/README.md`
- `.github/workflows/ci-results.yml`
- `Tools/verify_project.mjs`
- `update_log.md`

验证结果：

- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- `plutil -lint RomeLegionsApp.xcodeproj/project.pbxproj`：通过，输出 `RomeLegionsApp.xcodeproj/project.pbxproj: OK`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：通过，输出 `yaml ok`

遗留事项：

- 当前本地仓库未配置 `origin`，`git remote -v` 无输出，因此本轮无法真实 `git push origin main`、等待 GitHub Actions、下载 artifact 或核对 run id。配置远端后必须按 `md/test/test.md` 的 Agent C 结果包下载与核对流程补跑。
- 本轮未跑完整 Swift Testing、Gameplay Smoke 或 Xcode build；原因是本轮仅改协作文档、结构检查和 GitHub Actions workflow，且新制度默认由云端重验证承担完整测试。

### v0.2 / 规范 Agent C 版本提交

日期：2026-06-29

核心变更：

- 将入口文档统一为 `AGENTS.md`。
- 更新 Agent C 工作流：验收不通过时退回 Agent B；验收通过后按版本号自动 git commit。
- 规定提交说明格式：标题包含版本号，正文简要概括本版本工作内容和验证结果。
- 同步 README、测试规范、流程图和结构检查脚本。

关键文件：

- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flowchart.md`
- `Tools/verify_project.mjs`
- `update_log.md`

验证结果：

- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- 本轮只修改协作文档和结构检查脚本，未修改 Swift 源码和核心规则，未运行 Swift Testing、Gameplay Smoke、SwiftUI typecheck 或 Xcode build。

遗留事项：

- 后续 Agent C 执行提交前仍需确认 `git status --short`，避免纳入无关文件。

### v0.1 / 建立多 Agent 协作系统

日期：2026-06-28

核心变更：

- 建立标准入口 `AGENT.md`，定义项目规则、架构边界、Agent A/B/C 工作流、测试规则、文档规则、交付格式和禁止项。
- 建立 `update_log.md`，记录项目当前状态、历史决策和遗留事项。
- 建立 `md/test/test.md`，按 Probe/Fast、Smoke、Stage Regression、Full 分层管理测试命令和触发条件。
- 建立 `md/flow/flow.md`，总结当前真实数据流、执行流、核心状态对象、边界、入口和扩展点。
- 建立 `md/flow/flowchart.md`，用 Mermaid 图展示核心数据流、回合执行流、Agent 迭代流和测试选择流。
- 建立 `md/prompt/v0（协作系统）/v0.1（建立多Agent协作文档）.md`，作为 Agent A 提示词版本管理的首个基线。
- 更新 `README.md`，把协作规范入口改为标准 `AGENT.md` 和新增文档目录。
- 更新 `Tools/verify_project.mjs`，让结构检查覆盖核心协作文档。

关键文件：

- `AGENT.md`
- `update_log.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（协作系统）/v0.1（建立多Agent协作文档）.md`
- `README.md`
- `Tools/verify_project.mjs`

验证结果：

- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- 本轮只建立文档和更新结构检查脚本，未修改 Swift 源码和核心规则，未运行 Swift Testing、Gameplay Smoke、SwiftUI typecheck 或 Xcode build。

遗留事项：

- 后续功能迭代应从 Agent A 提示词开始，不直接跳到实现。
- 若 `BattleView.swift` 继续膨胀，应在后续版本拆分稳定子视图文件。
- 存档链路已有 `SaveStore`，但 UI 入口和测试覆盖仍可继续完善。

## 历史维护记录

### 2026-06-27 / 初始 Codex 规范文档

核心变更：曾新增小写 `agent.md` 并在 `README.md` 中记录 Codex 后续协作规范。

后续处理：2026-06-28 按标准命名和多 Agent 工作流要求，统一升级为大写 `AGENT.md`，并补齐 `update_log.md`、`md/test`、`md/flow`、`md/prompt` 目录。2026-06-29 入口再统一为复数 `AGENTS.md`，匹配用户对 agents 工作流的命名。
