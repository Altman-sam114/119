# RomeLegions

这是一个受《帝国军团罗马：大征服者》公开 App Store 页面启发的原创 SwiftUI iOS 战棋原型。当前美术使用色块和基础形状占位，没有复用商店截图或原游戏素材。

## 已实现

- iPhone/iPad SwiftUI App 工程：`RomeLegionsApp.xcodeproj`
- 纯 Swift 玩法核心：`Sources/RomeLegionsCore/GameState.swift`
- 战役/征服/远征入口
- 六边形战役地图、地形、城市、阵营、军团
- 回合制移动、攻击、反击、城市占领
- 战术姿态：均衡、突击、坚守、行军，影响移动、伤害和防御
- 战斗修正：友军支援、包夹、将领指挥和守军支援会进入预览与结算
- 城市收入、资源池、招募、科技、任务和简单 AI 回合
- 城市经营与招募读板：城市情报展示本城产出、势力收入、库存、扩建收益、部署摘要和四类兵种招募成本/阻塞原因
- 战役目标与胜负结算：任务目标可由核心规则判断，罗马完成核心目标后胜利，失去全部城市后失败
- 战役结束保护：胜负已定后移动、攻击、招募、科技、外交、AI 推进等写状态命令不再改变战局
- 城市扩建、军团训练、将领任命和外交派使
- 军团成长决策读板：训练/任命有核心只读预览，展示成本、预计经验/军阶/伤害、恢复、候选将领/特性和阻塞原因，并复用到军令按钮
- 军团成长优先级读板：核心层只读汇总训练/任命推荐，按生命损失、升阶收益、缺将领、近敌和战备排序，顶部态势与战局面板显示首要成长建议
- 将领特性与主动技能：鹰旗鼓舞、攻城布阵、战地补给、盾墙号令
- 将领技能范围、目标与冷却预览：地图叠层、将领卡和军令按钮展示预计恢复、削城防、冷却和不可用原因
- 将领详情读板：选中单位展示将领名、特性、被动贡献、技能状态、预计效果和战功摘要；无将领单位显示“无被动贡献”
- 战功状态：经验转为军阶、伤害加成和下一军阶进度，在兵牌、情报面板和将领卡中可读
- 战术姿态预览：均衡、突击、坚守、行军会展示切换后的攻、防、移、变化值、当前标记和不可切换原因
- 军团编制与成长读板：核心层只读派生军团职责、战备等级、相邻/两格友军、近敌、有效攻防移、建议姿态和命令建议，顶部态势、战局面板和选中单位情报均可读
- 战术命令建议与补线路径读板：核心层只读派生选中单位的攻击、补线、推进、坚守或整备建议，地图显示本方建议路径/目标，情报面板显示推荐姿态、风险和命令理由
- 本方将领协同与战术连携读板：核心层只读整合将领技能、合击修正、补线、推进和整备机会，顶部将令 chip、战局面板和选中单位情报展示预计伤害/恢复、支援、包夹、指挥、阻塞原因和协同步骤
- 机动落点与地图风险读板：核心层只读评估选中单位真实可达格，输出打击、夺城、补线、推进或稳固落点，地图叠层、顶部机动 chip、战局面板和选中单位情报展示落点路径、热区风险、控区影响、预计伤害和推荐姿态
- 手机横屏紧凑战斗栏、可攻击目标头顶徽标、选中单位待机/跳过
- AI 招募、休整、战术姿态、将领技能冷却判断、移动后攻击和目标优先级评估；真实 AI 回合会按当前意图威胁分优先执行主攻单位
- 敌军意图预判：地图徽标、贴合六边形邻接的路径线段、目的地/目标格叠层、顶部敌情芯片和侧栏敌情面板展示攻击、接敌、夺城、固守等倾向，预计伤害与规划态战斗预览一致
- 敌军作战计划读板：核心层只读聚合敌军意图、战线压力、威胁热区和敌方将领技能机会，展示集火、夺城、推进、固守、整备或将领协同计划，不改变真实 AI 决策
- 敌方将领威胁读板：核心层只读聚合敌将 trait、技能窗口、AI 意图、作战计划、战线压力和热区，顶部敌将 chip、敌情卡和战局行展示首要敌将威胁
- 敌情反制建议读板、地图叠层与焦点链路：核心层只读聚合敌将威胁、AI 作战计划、战线压力、热区、本方战术建议、机动落点和将领协同，顶部反制 chip、敌情卡和战局行展示建议回应单位、命令、收益和风险，地图用“1 回应、2 落点、3 目标”阶段标记、反制线和目标标记展示回应空间关系；敌情卡和军令面板还可定位回应军团并显示同一链路摘要、推荐姿态、落点、目标、下一步和阻塞原因，推荐姿态按钮与当前可攻击反制目标会显示反制提示但不自动执行
- 战线压力读板：核心层聚合敌军意图，展示罗马单位或城市被多路攻击、夺城或推进的压力等级、来源和预计伤害
- 战场焦点与将领机会读板：核心层综合战线压力、战术建议、军团编制和将领技能状态，提示救线、打击、补线、推进、整编或将领技能机会
- 战场目标链路：ViewModel 只读组合战场焦点、将领协同、机动落点和本方军议，战场面板用“1 焦点、2 将令、3 机动、4 军议”串联当前目标线，各卡片显示同一链路 cue，不自动执行命令
- 地图控制与威胁热区读板：核心层只读派生每格友军/敌军影响、控制状态和威胁热度，地图低透明叠层、顶部热区 chip、战场卡和战局行均可读
- 主动地图叠层图例：战斗地图底部按当前可见叠层解释敌军路线/目标、热区、控区、军议路径、机动落点、反制落点/目标、可移动/可攻击和技能范围，同时保留阵营色说明
- Codex 后续协作规范：`AGENTS.md`、`update_log.md`、`md/test/test.md`、`md/flow/flow.md`、`md/flow/flowchart.md` 和 `md/prompt/` 组成长期多 Agent 迭代文档系统，支持未来用 `agentx:` 主控调度 A/B/C 多轮循环
- GitHub Actions 云端验证：`.github/workflows/ci-results.yml` 在 `main` push 时生成未加密 CI 结果包
- 核心规则测试：`Tests/RomeLegionsCoreTests/GameStateTests.swift`

## 运行

1. 打开 `RomeLegionsApp.xcodeproj`
2. 选择 iPhone 或 iPad Simulator
3. 运行 `RomeLegions` target

当前工程用代码绘制占位美术，`Assets.xcassets` 暂时只保留在项目中，不参与 target 的资源编译。这样可以避免受限环境里 `actool` 访问 CoreSimulatorService 失败；后续替换正式图标或图片资源时，再把资产目录加入 Resources build phase。

## 协作规范

后续使用 Codex 继续迭代时，先读取 `AGENTS.md`。该文件是本项目的入口记忆、项目总览、基本规则和多 Agent 工作流。

协作文档分工：

- `AGENTS.md`：入口规则、架构边界、Agent A/B/C/X 工作流、交付格式和禁止项
- `update_log.md`：版本更新记录、历史决策、完成事项和遗留问题
- `md/prompt/`：Agent A 每轮输出详细实现提示词的位置，按版本号管理
- `md/prompt/README.md`：角色召唤、提示词格式和云端阶段要求
- `md/test/test.md`：测试规范、测试分层、命令、触发条件和当前基线
- `md/flow/flow.md`：当前真实架构和核心运行流程
- `md/flow/flowchart.md`：与 `flow.md` 同步的 Mermaid 可视化流程图

每次功能完成后必须同步更新测试说明和 `README.md` 完成情况；若测试流程、架构边界、核心流程或协作规则变化，也要同步更新 `AGENTS.md`、`update_log.md`、`md/test/test.md` 或 `md/flow/` 对应文档。

## 协作与云端验证

默认协作流固定为 `main` 直推。当前按人工要求从 v0.15 起不在本地运行测试、build、typecheck、RenderBattlePreview 或结构验证；Agent B 只做读取、编辑、只读 diff/status 检查、提交并 push 到 `origin/main`。GitHub Actions 运行结构检查、SwiftPM 测试、Gameplay Smoke、RenderBattlePreview 和无签名 Xcode build，并上传未加密结果包。Agent C 使用 `gh auth login` 后下载最新 run artifact，核对 manifest、JUnit、日志、预览产物和 `origin/main` 最新 commit；失败时退回 Agent B 在 `main` 上追加修复 commit。

`agentx:` 用于未来启动主控循环。Agent X 接收人工总目标后拆分轮次，并调度 Agent A 写提示词、Agent B 实现 push、Agent C 下载 artifact 验收；Agent X 不直接替代 A/B/C，也不能跳过 Agent C 的最新云端结果包复判。

## 本地验证

默认完整验证在云端运行。当前人工已明确要求不做本地测试；以下本机命令只在人工以后重新明确允许本地验证、定位失败或快速检查时使用。

不依赖 SwiftPM 的核心玩法冒烟测试：

```sh
swiftc -swift-version 5 -module-cache-path .build/module-cache Sources/RomeLegionsCore/GameState.swift Tools/GameplaySmoke/main.swift -o .build/gameplay-smoke
.build/gameplay-smoke
```

工程结构检查：

```sh
node Tools/verify_project.mjs
```

战斗页三尺寸预览图；渲染前会断言敌军意图 ViewModel 叠层包含移动后攻击六边形邻接路径、目标格和预计伤害文案，并断言主动地图叠层图例、AI 作战计划读板、敌方将领威胁读板、敌情反制建议读板、反制落点/目标地图 overlay、反制指令聚焦与焦点链路、战线压力读板、战场焦点摘要、战场目标链路、地图控制摘要、威胁热区摘要、选中单位的军团编制摘要、军团成长决策摘要、军团成长优先级摘要、本方将领协同摘要、机动落点摘要/地图 overlay、战术建议摘要/路径/目标、将领详情、被动贡献、战功摘要、战术姿态预览和城市经营/招募读板存在。每个命令会写出请求的城市场景 PNG，并额外写出同尺寸 `*-unit.png` 单位场景 PNG：

```sh
env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift
.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430
.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844
.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768
```

模拟器攻击 UI 复现入口：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /usr/bin/xcrun simctl launch booted com.codex.RomeLegions --attack-demo
```

SwiftUI 源码类型检查：

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -swift-version 5 -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk -target arm64-apple-ios17.0 -module-cache-path DerivedData/ManualModuleCache Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/RomeLegionsApp.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/RootView.swift RomeLegionsApp/Views/MainMenuView.swift RomeLegionsApp/Views/BattleView.swift
```

无签名构建：

```sh
env HOME=$PWD/.home DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project RomeLegionsApp.xcodeproj -scheme RomeLegions -configuration Debug -destination generic/platform=iOS -derivedDataPath $PWD/DerivedData CODE_SIGNING_ALLOWED=NO build
env HOME=$PWD/.home DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project RomeLegionsApp.xcodeproj -scheme RomeLegions -configuration Debug -destination generic/platform='iOS Simulator' -derivedDataPath $PWD/DerivedData CODE_SIGNING_ALLOWED=NO build
```
