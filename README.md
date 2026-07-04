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
- 战役目标与胜负结算：任务目标可由核心规则判断，罗马完成核心目标后胜利，失去全部城市后失败
- 战役结束保护：胜负已定后移动、攻击、招募、科技、外交、AI 推进等写状态命令不再改变战局
- 城市扩建、军团训练、将领任命和外交派使
- 将领特性与主动技能：鹰旗鼓舞、攻城布阵、战地补给、盾墙号令
- 手机横屏紧凑战斗栏、可攻击目标头顶徽标、选中单位待机/跳过
- AI 招募、休整、战术姿态、将领技能、移动后攻击和目标优先级评估
- 敌军意图预判：地图徽标、顶部敌情芯片和侧栏敌情面板展示攻击、接敌、夺城、固守等倾向，预计伤害与规划态战斗预览一致
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

默认协作流固定为 `main` 直推：Agent B 本地跑轻量检查后提交并 push 到 `origin/main`，GitHub Actions 运行 SwiftPM 测试、Gameplay Smoke 和无签名 Xcode build，并上传未加密结果包。Agent C 使用 `gh auth login` 后下载最新 run artifact，核对 manifest、JUnit、日志和 `origin/main` 最新 commit；失败时退回 Agent B 在 `main` 上追加修复 commit。

`agentx:` 用于未来启动主控循环。Agent X 接收人工总目标后拆分轮次，并调度 Agent A 写提示词、Agent B 实现 push、Agent C 下载 artifact 验收；Agent X 不直接替代 A/B/C，也不能跳过 Agent C 的最新云端结果包复判。

## 本地验证

默认完整验证在云端运行；以下本机命令用于人工明确要求本地验证、定位失败或快速检查。

不依赖 SwiftPM 的核心玩法冒烟测试：

```sh
swiftc -swift-version 5 -module-cache-path .build/module-cache Sources/RomeLegionsCore/GameState.swift Tools/GameplaySmoke/main.swift -o .build/gameplay-smoke
.build/gameplay-smoke
```

工程结构检查：

```sh
node Tools/verify_project.mjs
```

战斗页三尺寸预览图：

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
