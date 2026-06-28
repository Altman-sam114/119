# 测试规范

本文指导 Agent B 和 Agent C 根据改动范围选择测试层级。每次实现前必须先读本文件。

## 固定前缀 / 环境要求

项目是 SwiftPM + Xcode SwiftUI 工程组合：

- SwiftPM 核心包：`Package.swift`，核心 target 为 `RomeLegionsCore`。
- iOS App 工程：`RomeLegionsApp.xcodeproj`。
- 最低平台：iOS 17、macOS 14。
- Swift 工具链：优先使用 `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift` 或同目录 `swiftc`。
- 部分命令需要设置 `HOME=$PWD/.home` 和本地 module cache，避免污染用户环境。
- 当前没有必须启动的后端服务、数据库容器或网络依赖。
- `SaveStore` 使用 SQLite，功能测试若覆盖真实存档，应使用临时数据库路径，避免污染用户实际存档。

常用环境前缀：

```sh
env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

## 测试分层

### 1. Probe / Fast

最快发现主链路断点。

触发条件：

- 文档、目录、工程结构、资源清单或工具入口变化。
- 小范围核心规则改动前后的快速检查。
- Agent C 验收时先确认结构未破。

命令：

```sh
node Tools/verify_project.mjs
```

当前基线：

- 应输出 `Project structure verification passed.`
- 结构检查必须覆盖 `AGENT.md`、`update_log.md`、`md/test/test.md`、`md/flow/flow.md`、`md/flow/flowchart.md` 和至少一个版本化 prompt。

### 2. Smoke

验证主要集成路径，不依赖 SwiftPM 测试发现。

触发条件：

- `GameState` 核心主链路变化。
- 移动、占城、招募、科技、训练、将领、战术姿态、战斗预览、AI 意图、技能、外交、回合推进等行为变化。
- SwiftPM 测试运行受限时，至少跑此层。

命令：

```sh
swiftc -swift-version 5 -module-cache-path .build/module-cache Sources/RomeLegionsCore/GameState.swift Tools/GameplaySmoke/main.swift -o .build/gameplay-smoke
.build/gameplay-smoke
```

当前基线：

- 应输出 `Gameplay smoke test passed.`
- 覆盖占城、招募、科技、训练、将领、战术姿态、战斗修正、AI 意图、主动技能、外交和回合推进。

### 3. Stage Regression

覆盖当前阶段核心模块。

触发条件：

- 任何核心规则变化。
- AI、战斗、外交、资源、将领、任务、城市、存档数据结构变化。
- Agent B 实现功能后进入验收前。

命令：

```sh
env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test --scratch-path .build/swift-test-local --disable-sandbox
```

当前基线：

- `Tests/RomeLegionsCoreTests/GameStateTests.swift` 当前包含 24 个 Swift Testing 用例。
- 基线覆盖地形移动、占城、攻击、预览结算一致性、招募、科技重复保护、城市扩建、训练、将领、战术姿态、支援/包夹/指挥/守军支援、主动技能、外交保护、回合收入、跳过单位、AI 攻击、AI 意图、AI 招募。

### 4. Full

全量验证，适合阶段交付、重大重构或发布前。

触发条件：

- 影响核心、ViewModel、SwiftUI 和工程文件的综合改动。
- 修改 Xcode project、资源、App target、Info.plist、存档结构或入口流程。
- 重要里程碑版本。

命令：

```sh
node Tools/verify_project.mjs
```

```sh
env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test --scratch-path .build/swift-test-local --disable-sandbox
```

```sh
swiftc -swift-version 5 -module-cache-path .build/module-cache Sources/RomeLegionsCore/GameState.swift Tools/GameplaySmoke/main.swift -o .build/gameplay-smoke
.build/gameplay-smoke
```

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -swift-version 5 -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk -target arm64-apple-ios17.0 -module-cache-path DerivedData/ManualModuleCache Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/RomeLegionsApp.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/RootView.swift RomeLegionsApp/Views/MainMenuView.swift RomeLegionsApp/Views/BattleView.swift
```

```sh
env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift
.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430
.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844
.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768
```

可选无签名构建：

```sh
env HOME=$PWD/.home DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project RomeLegionsApp.xcodeproj -scheme RomeLegions -configuration Debug -destination generic/platform=iOS -derivedDataPath $PWD/DerivedData CODE_SIGNING_ALLOWED=NO build
env HOME=$PWD/.home DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project RomeLegionsApp.xcodeproj -scheme RomeLegions -configuration Debug -destination generic/platform='iOS Simulator' -derivedDataPath $PWD/DerivedData CODE_SIGNING_ALLOWED=NO build
```

当前基线：

- Full 应同时证明结构、核心规则、核心冒烟、SwiftUI 类型检查和战斗页预览图链路可用。
- 若因本地 Xcode SDK 版本不同导致命令路径或 SDK 路径变化，应先核对本机 `/Applications/Xcode.app`，再更新本文件和 README。

## 静态检查

结构检查：

```sh
node Tools/verify_project.mjs
```

SwiftUI 源码类型检查：

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -swift-version 5 -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk -target arm64-apple-ios17.0 -module-cache-path DerivedData/ManualModuleCache Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/RomeLegionsApp.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/RootView.swift RomeLegionsApp/Views/MainMenuView.swift RomeLegionsApp/Views/BattleView.swift
```

README/文档检查：

```sh
grep -n "AGENT.md\|md/test/test.md\|md/flow/flow.md\|update_log.md" README.md AGENT.md update_log.md md/test/test.md md/flow/flow.md md/flow/flowchart.md
```

## 规则

- 每次实现前先读本文件。
- 默认从最小测试开始，根据改动范围扩大测试。
- 测试命令必须原样记录到最终回复或 Agent B 输出。
- 不得伪造测试结果。
- 失败测试要记录失败摘要和下一步处理，不得只写“失败”。
- 文档-only 修改可只跑结构检查和文档内容检查，但必须说明未跑完整 Swift 测试的原因。
- 修改测试命令、触发条件或当前基线后，必须同步更新 `README.md`、`AGENT.md` 和 `update_log.md`。
