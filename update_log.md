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
- 当前玩法：六边形地图、地形、城市、阵营、军团、移动、攻击、反击、占城、招募、科技、任务 requirement、战役目标、胜负结算、结束保护、外交、城市扩建、军团训练、将领任命、主动技能、战术姿态、AI 回合、敌军意图预判、战局态势面板。
- 当前测试入口：Swift Testing、Gameplay Smoke、项目结构检查、SwiftUI 类型检查、战斗页预览图渲染、无签名 Xcode 构建。
- 当前协作系统：已建立 `AGENTS.md`、`update_log.md`、`md/prompt/`、`md/test/test.md`、`md/flow/flow.md`、`md/flow/flowchart.md`，默认按 `main` 直推、GitHub Actions 云端重验证、Agent C 下载未加密结果包复判，并具备未来由 Agent X 主控调度 Agent A/B/C 多轮循环的文档基线。
- 当前 CI 入口：`.github/workflows/ci-results.yml`，在 `main` push 和手动触发时运行结构检查、SwiftPM 测试、Gameplay Smoke 和无签名 Xcode build，并上传 CI 结果包。

## 历史记录

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
