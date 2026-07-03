# 测试规范

本文指导 Agent B、Agent C 和未来的 Agent X 根据改动范围选择测试层级、云端重验证和结果包复判。每次实现前必须先读本文件。

## 固定前缀 / 环境要求

项目是 SwiftPM + Xcode SwiftUI 工程组合：

- SwiftPM 核心包：`Package.swift`，核心 target 为 `RomeLegionsCore`。
- iOS App 工程：`RomeLegionsApp.xcodeproj`。
- Xcode scheme：`RomeLegions`。
- 最低平台：iOS 17、macOS 14。
- Swift 工具链：优先使用 `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift` 或同目录 `swiftc`。
- 部分本机命令需要设置 `HOME=$PWD/.home` 和本地 module cache，避免污染用户环境。
- 当前没有必须启动的后端服务、数据库容器或网络依赖。
- `SaveStore` 使用 SQLite，功能测试若覆盖真实存档，应使用临时数据库路径，避免污染用户实际存档。

常用本机环境前缀：

```sh
env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

## 默认验证策略

- 默认云端重验证，本机只跑轻量检查。
- 只有人工明确说“本机测试”“本地 build”“本地跑探针”“本地 xcodebuild”等，Agent 才把本机完整构建或模拟器验证作为默认路径。
- 文档-only 修改仍可本地跑 `git diff --check`、`node Tools/verify_project.mjs`、YAML/JSON/Plist 解析和脚本语法检查。
- Swift / Xcode / ViewModel / 核心规则 / 工具相关改动完成后，默认 commit 并 push 到 `origin/main`，由 GitHub Actions 运行重验证。
- 云端失败时，Agent B 根据结果包中的失败摘要、日志路径和 manifest 修复后继续在 `main` 上追加 commit 并 push。
- 云端环境缺依赖时，必须说明哪个测试没跑、缺什么依赖、是否影响验收、需要人工提供什么。
- 仓库没有 `origin` 或没有 GitHub Actions 权限时，必须明确报告阻塞，不能声称云端已验证。
- Agent X 主控循环下，每一轮仍以 Agent B 本地轻量检查、GitHub Actions artifact 和 Agent C 下载复判为准。
- Agent X 不得跳过 Agent C artifact 验收，不得在云端失败或验收不通过时继续下一轮并伪装成功。

## 本地轻量检查

### 1. 文档 / 结构 / workflow

触发条件：

- 文档、目录、工程结构、资源清单、GitHub Actions 或工具入口变化。
- Agent C 验收前先确认结构未破。

命令：

```sh
git diff --check
```

```sh
node Tools/verify_project.mjs
```

```sh
plutil -lint RomeLegionsApp.xcodeproj/project.pbxproj
```

```sh
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'
```

当前基线：

- `node Tools/verify_project.mjs` 应输出 `Project structure verification passed.`
- `plutil` 应输出 `OK`。
- YAML 解析应输出 `yaml ok`。
- 结构检查必须覆盖 `AGENTS.md`、`update_log.md`、`md/test/test.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md`、至少一个版本化 prompt 和 `.github/workflows/ci-results.yml`。

### 2. Probe / Fast

最快发现主链路断点。

命令：

```sh
node Tools/verify_project.mjs
```

适用：

- 小范围核心规则改动前后的快速检查。
- 文档、目录、工程结构或工具入口变化。

## GitHub Actions 云端重验证

默认 workflow：`.github/workflows/ci-results.yml`

触发条件：

```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch:
```

云端至少运行：

- `git diff --check`
- `plutil -lint RomeLegionsApp.xcodeproj/project.pbxproj`
- `node Tools/verify_project.mjs`
- SwiftPM `swift test`
- `swiftc` 编译并运行 `Tools/GameplaySmoke`
- 无签名 `xcodebuild build`

结果包最低内容：

- `ci-artifact-manifest.json`
- `ci-failure-summary.md`
- `junit.xml`
- `static-checks.log`
- `swift-test.log`
- `gameplay-smoke.log`
- `xcodebuild.log`
- `RomeLegions.xcresult`，若 Xcode 成功产出

artifact 命名规则：

```text
RomeLegions-ci-v0.4-main-<short_sha>-run<run_id>-attempt<run_attempt>
```

`ci-artifact-manifest.json` 必须至少包含：

- `version`
- `branch`
- `commitSha`
- `shortSha`
- `runId`
- `runAttempt`
- `workflowName`
- `createdAt`
- `projectName`
- `scheme`
- `destination`
- `resultBundlePath`
- `junitPath`
- `buildLogPath`
- `failureSummaryPath`
- `staticChecksOutcome`
- `buildOutcome`
- `testOutcome`
- `projectSpecificReports`

## Agent C 结果包下载与核对

Agent C 必须先登录 GitHub CLI：

```sh
gh auth login
```

查看最新 main run：

```sh
gh run list --workflow "RomeLegions CI Results" --branch main --limit 5
```

下载缓存目录固定为：

```sh
/private/tmp/romelegions-c-review-<run_id>/
```

下载命令示例：

```sh
mkdir -p /private/tmp/romelegions-c-review-<run_id>
gh run download <run_id> --name <artifact_name> --dir /private/tmp/romelegions-c-review-<run_id>
```

Agent C 必须核对：

- `origin/main` 最新 commit SHA 等于 manifest 的 `commitSha`。
- manifest 的 `branch` 为 `main`。
- manifest 的 `runId` 和 `runAttempt` 等于本次下载的 run。
- workflow 结论、JUnit、主构建日志、失败摘要互相一致。
- 若 workflow 失败，失败摘要和日志路径足以退回 Agent B 修复。
- 若本地仓库没有 `origin` 或 `gh` 无权限，明确报告阻塞，不能伪造下载核对。
- 只能使用 `Altman-sam114` 对应 GitHub 权限完成 push、CI 或 artifact 验收；不得使用其他账号伪装完成。

## Agent X 循环验证规则

Agent X 只调度验证链路，不替代 Agent B 的本地轻量检查，也不替代 Agent C 的云端 artifact 验收。

- 每轮开始前，Agent X 必须确认本轮目标可被本地轻量检查、GitHub Actions 和 Agent C 结果包复判验证。
- 每轮 Agent A 提示词必须写清本轮验证命令、`main` push、CI artifact 和 Agent C 验收要求。
- Agent B 未完成本地轻量检查、未 push 到 `origin/main`，或 GitHub Actions 未产出最新 artifact 时，Agent X 不能宣布该轮完成。
- Agent C 未核对最新 run 的 manifest、JUnit、主日志、失败摘要、run id、run attempt 和 `origin/main` 最新 commit 时，Agent X 不能进入下一轮。
- 若 Agent C 验收不通过，Agent X 只能退回 Agent B 修复、暂停等待人工确认，或因停止条件结束；不能继续下一轮伪装成功。
- 若连续 3 轮遇到同一阻塞、连续 2 轮没有有效 diff、CI 连续失败且原因相同，Agent X 必须暂停并说明阻塞。

## 测试数据与下载容量限制

本项目默认采用小数据量验证策略，避免下载过大 artifact、模型、数据集、缓存或结果包，把本机、CI runner 或临时目录容量撑爆。

规则：

- 测试数据必须尽量小，只覆盖必要边界。
- CI artifact 只上传必要文件：manifest、JUnit 或测试摘要、关键日志、失败摘要、必要结果包。
- 不上传大体积 DerivedData、完整 build cache、无关截图、视频、模型文件、历史 artifact 或重复压缩包。
- Agent C 下载 artifact 前优先确认只下载最新 run 对应的必要结果包。
- 下载缓存默认放在 `/private/tmp/<project>-review-<run_id>/`；本项目具体目录为 `/private/tmp/romelegions-c-review-<run_id>/`。
- 下载后应检查目录大小：

```sh
du -sh /private/tmp/romelegions-c-review-<run_id>/
```

- 禁止默认下载大体积测试数据、模型、历史 artifact 或无关产物。

## 本机完整测试命令

以下命令仅在人工明确要求本机完整验证、定位云端失败，或本地环境本身就是任务目标时作为默认路径。

### Smoke

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
- 覆盖占城、招募、科技、训练、将领、战术姿态、战斗修正、AI 意图、主动技能、外交、回合推进、战役胜利、战役失败和结束后回合保护。

### Stage Regression

覆盖当前阶段核心模块。

触发条件：

- 人工要求本机测试。
- 任何核心规则变化。
- AI、战斗、外交、资源、将领、任务、城市、存档数据结构变化。

命令：

```sh
env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test --scratch-path .build/swift-test-local --disable-sandbox
```

当前基线：

- `Tests/RomeLegionsCoreTests/GameStateTests.swift` 当前包含 31 个 Swift Testing 用例。
- 基线覆盖地形移动、占城、攻击、预览结算一致性、招募、科技重复保护、城市扩建、训练、将领、战术姿态、支援/包夹/指挥/守军支援、主动技能、外交保护、回合收入、跳过单位、AI 攻击、AI 意图、AI 招募、任务 requirement、奖励幂等、战役胜利、战役失败、结束保护、AI 结束后停止和 Codable 兼容。

### Full

全量验证，适合阶段交付、重大重构或发布前，也适合人工明确要求本机完整 build 时使用。

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

## 规则

- 每次实现前先读本文件。
- 默认从本地轻量检查开始，然后通过 `main` push 触发云端重验证。
- 测试命令必须原样记录到最终回复或 Agent B 输出。
- 不得伪造测试结果。
- 失败测试要记录失败摘要和下一步处理，不得只写“失败”。
- 文档-only 修改可只跑本地轻量检查，但必须说明未跑完整 Swift 测试的原因。
- 修改测试命令、触发条件或当前基线后，必须同步更新 `README.md`、`AGENTS.md` 和 `update_log.md`。
- Agent C 验收通过必须基于最新 `origin/main` 的 run 和结果包；验收不通过时只输出退回 Agent B 的修正项。
