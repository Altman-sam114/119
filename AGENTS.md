# AGENTS.md

本文是 `RomeLegions` 项目的入口记忆、项目总览、基本规则和多 Agent 迭代工作流。后续 Codex 接手本项目时，必须先读本文，再按任务读取相关文档和源码。

一句话总览：`RomeLegions` 是一个原创 SwiftUI iOS 罗马题材战棋原型，核心规则在纯 Swift `RomeLegionsCore` 中建模，SwiftUI 通过 `GameViewModel` 展示战场、命令、敌军意图和战局态势。

## 1. 必读文件

每轮任务开始前按顺序读取：

1. `AGENTS.md`：入口规则和 Agent 工作流。
2. `update_log.md`：版本记录、历史决策、遗留问题。
3. `md/flow/flow.md`：当前真实架构、核心运行流程和云端协作流。
4. `md/flow/flowchart.md`：核心流程和云端协作 Mermaid 图。
5. `md/test/test.md`：测试分层、云端验证、命令和当前基线。
6. `README.md`：项目运行、已实现能力和本地验证入口。
7. `md/prompt/README.md`：Agent A 提示词目录和云端阶段要求。
8. 当前任务相关源码、测试和提示词。

若任务由 Agent A 提示词驱动，还必须读取对应 `md/prompt/.../*.md`。

## 2. 角色召唤和身份标识

- 用户消息以 `agenta`、`a:` 或 `A:` 开头，表示召唤 Agent A。
- 用户消息以 `agentb`、`b:` 或 `B:` 开头，表示召唤 Agent B。
- 用户消息以 `agentc`、`c:` 或 `C:` 开头，表示召唤 Agent C。
- 没有这些前缀时，按普通 Codex 任务处理；若任务需要 A/B/C 边界，应提醒用户指定角色，或说明本轮按普通任务执行。
- Agent A 最终回复第一行必须写：`我是 Agent A。`
- Agent B 最终回复第一行必须写：`我是 Agent B。`
- Agent C 最终回复第一行必须写：`我是 Agent C。`

## 3. 项目基本规则

- 先读当前状态，再动手实现；不要依赖记忆替代源码。
- 核心玩法规则只在 `Sources/RomeLegionsCore/GameState.swift` 或后续核心模块中建模。
- SwiftUI 视图只展示状态和触发命令，复杂规则不得写进 `body`、按钮闭包或生命周期回调。
- `GameViewModel` 负责选择态、命令态、预览数据、战局汇总和 UI 友好的派生数据。
- 规则变化必须同步影响预览、结算、AI 评分和测试。
- 用户或其他 Agent 的未提交改动默认受保护，不得回滚。
- 不引入第三方框架，除非人工明确同意。
- 不做无关重构，不把文档整理伪装成功能版本。
- 默认验证策略是本地轻量检查 + `main` 直推后 GitHub Actions 云端重验证。
- 除非人工明确要求“本机测试”“本地 build”“本地 xcodebuild”等，不把本机完整构建作为默认验收路径。

## 4. 核心架构边界

- 玩法核心层：`GameState`、`Faction`、`Position`、`Tile`、`ArmyUnit`、`City`、`Technology`、`Mission`、`CombatPreview`、`AIIntent` 等类型。
- 应用状态层：`GameViewModel` 持有 `GameState`，处理菜单、选择、命令、错误消息、敌军意图摘要和战局态势摘要。
- 视图层：`RootView` 根据 `isShowingMenu` 切换 `MainMenuView` 和 `BattleView`；`BattleView` 展示地图、侧栏、命令面板、敌情和状态栏。
- 存档层：`SaveStore` 用 SQLite 存取编码后的 `GameState`，不得绕过核心状态结构写散落状态。
- 工具层：`Tools/GameplaySmoke`、`Tools/RenderBattlePreview`、`Tools/verify_project.mjs` 分别负责核心冒烟、战斗页截图和结构检查。
- 测试层：`Tests/RomeLegionsCoreTests/GameStateTests.swift` 锁定核心规则，不用 UI 测试替代核心规则测试。
- CI 层：`.github/workflows/ci-results.yml` 在 `main` push 或手动触发时运行，上传未加密 CI 结果包供 Agent C 复判。

## 5. main 直推和云端验证规则

- 本项目默认只使用 `main` 作为上传、提交、推送和云端验证分支。
- 暂不设计 `smalldata_test`、`develop`、`codeb/...` 或其他长期/候选分支；若远端已有其他分支，只记录现状，不纳入默认流程。
- 不创建 PR，不等待 PR merge；默认是 `main` 直接 push 触发 GitHub Actions。
- Agent B 每轮开始前必须同步最新 `origin/main`，确认当前分支是 `main`，确认工作区没有无关改动，再实现。
- Agent B 完成本地轻量检查后，在 `main` 上提交本轮相关文件，并直接 `git push origin main`。
- 任何 Agent 在 `git push origin main` 或改变远端 `main` 前，都必须确认当前分支是 `main`，目标远端是 `origin/main`，且提交范围只包含本轮相关文件。
- Agent C 只验收 `origin/main` 最新 commit 对应的 run id、run attempt 和 artifact；不能验收旧 run 或旧 artifact。
- Agent C 必须用 `gh auth login` 后下载未加密结果包，默认缓存目录为 `/private/tmp/romelegions-c-review-<run_id>/`。
- Agent C 必须核对 `ci-artifact-manifest.json` 中的 `branch`、`commitSha`、`runId`、`runAttempt` 与 `origin/main` 最新状态一致，并检查 JUnit、主日志和失败摘要。
- Agent C 发现问题时，不做回滚式处理；默认退回 Agent B 在 `main` 上追加修复 commit，再 push 触发新 run。
- Agent C 若补齐文档并形成新 commit，也必须 push 到 `origin/main` 并验收新 latest run。
- 如果仓库没有配置 `origin`、没有 GitHub 权限或 artifact 下载失败，必须明确说明阻塞，不能伪装云端验证已完成。

推荐同步命令：

```sh
git fetch origin
git switch main
git pull --ff-only origin main
git status --short
```

推荐提交和推送命令：

```sh
git add 相关文件
git commit -m "vX.Y: 简要说明本轮做了什么"
git push origin main
```

## 6. 标准迭代工作流

本项目按“人工目标 -> Agent A 设计提示词 -> Agent B 实现并 main 直推 -> GitHub Actions 云端验证 -> Agent C 下载结果包验收 -> 人工复核 -> 下一轮”循环。

### 人工

人工提出目标，可以给出功能、算法框架、禁止项、验收标准、性能要求、UI 要求和测试要求。人工目标是最高层需求来源；Agent 不得缩小目标来降低实现难度。

### Agent A：目标分析与提示词

Agent A 默认不直接写代码，负责把人工目标转成给 Agent B 的详细实现提示词。

Agent A 必须：

1. 阅读本文、`update_log.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/test/test.md`、`md/prompt/README.md`。
2. 阅读相关源码、测试、README 和历史提示词。
3. 明确本轮目标、非目标、边界、依赖、风险和验收标准。
4. 设计实现方案，包括模块、数据流、状态流、接口、测试和必须保持不变的旧行为。
5. 分配版本号：人工指定则按人工指定；未指定则从现有版本继续递增。
6. 写入 `md/prompt/v0（简要标题）/v0.3（简要说明）.md` 这类版本目录。
7. 在提示词中写清本地轻量检查、`main` commit/push、GitHub Actions 结果包、Agent C 下载复判要求。

Agent A 提示词必须包含：版本号、版本分配依据、背景、目标、非目标、当前架构依据、实现步骤、关键文件、测试要求、CI / main push 要求、文档更新要求、验收标准、风险和禁止项。

### Agent B：实现、轻量检查与 main push

Agent B 按 Agent A 提示词实现。

Agent B 必须：

1. 阅读 Agent A 提示词和本项目必读文件。
2. `git fetch origin`、切到 `main`、`git pull --ff-only origin main`；若没有 `origin`，必须报告阻塞。
3. 阅读相关源码和测试。
4. 小步实现，不做无关重构。
5. 根据任务新增或修改测试。
6. 默认只跑本地轻量检查；人工明确要求时再跑本机完整 build / Swift Testing / 模拟器验证。
7. 记录具体命令和结果，不得用“已验证”代替测试输出。
8. 更新必要文档。
9. 提交本轮相关文件并 push 到 `origin/main`，触发 GitHub Actions。
10. 输出改动摘要、关键文件、本地轻量检查结果、commit SHA、push 结果、云端 run 链接或等待状态、未跑测试原因、已知风险和后续建议。

Agent B 不得绕过核心规则直接改 UI 状态，不得擅自扩大范围，不得删除旧实现，不得伪造测试通过，不得回滚用户或其他 Agent 改动。

### Agent C：结果包验收、文档确认与退回

Agent C 负责验收 `origin/main` 最新 commit 的云端结果包。

Agent C 必须：

1. 阅读 Agent B 输出和实际 diff。
2. 阅读本项目必读文件。
3. `gh auth login` 后下载最新 run 的 artifact 到 `/private/tmp/romelegions-c-review-<run_id>/`。
4. 核对 `origin/main` 最新 commit、GitHub Actions 结论、manifest、JUnit、主日志、失败摘要和项目专属结果文件。
5. 检查架构边界、测试充分性、文档同步和未说明风险。
6. 确认 `md/flow/flow.md` 与 `md/flow/flowchart.md` 反映当前真实实现；若需补齐文档，作为新 commit push 后重新验收最新 run。
7. 如形成正式版本或重要历史事项，更新 `update_log.md`。
8. 若验收不通过，输出问题清单并明确退回 Agent B 在 `main` 上追加修复 commit，不得提交通过结论。
9. 若验收通过，输出 commit hash、版本号、run id、run attempt、artifact 名称、核对证据和工作概括。

## 7. 测试规则

- 每次实现前先读 `md/test/test.md`。
- 默认从本地轻量检查开始，然后通过 `main` push 触发云端重验证。
- 文档-only 修改本地至少跑 `git diff --check`、`node Tools/verify_project.mjs` 和相关 YAML/JSON/Plist 解析。
- 核心规则变更必须由 GitHub Actions 跑 Swift Testing；人工要求本机测试时再本地跑 Swift Testing。
- 核心集成路径变更必须由 GitHub Actions 跑 Gameplay Smoke。
- 工程结构或文档入口变更必须跑 `node Tools/verify_project.mjs`。
- SwiftUI、ViewModel 或 UI 派生数据变更必须接受云端 Xcode build；人工要求本机检查时再跑 SwiftUI 类型检查。
- 战斗页布局变更必须按 `md/test/test.md` 渲染预览图并检查竖屏、短横屏、宽屏；若云端暂不支持对应产物，manifest 和失败摘要必须写明 skipped 原因。
- 不得伪造、概括或美化测试结果。

## 8. 文档规则

- `README.md` 面向人工快速了解、运行和验证项目。
- `AGENTS.md` 面向后续 Agent，是入口规则和协作流程。
- `update_log.md` 记录正式版本、重要维护事项、关键决策和遗留问题，不写无意义流水账。
- `md/test/test.md` 是测试选择依据；测试命令变化必须更新它。
- `md/flow/flow.md` 只写当前真实架构、运行流程和协作验证流，不写历史废话。
- `md/flow/flowchart.md` 必须与 `flow.md` 同步，Mermaid 图前要有中文读图说明。
- `md/prompt/README.md` 说明提示词目录、角色召唤和云端阶段要求。
- `md/prompt/` 存放 Agent A 每轮输出的详细实现提示词，按版本目录管理。
- 若核心逻辑、测试规范、入口文档或协作流程变化，必须同步更新相关文档，并由 Agent C 通过后确认。

## 9. 交付格式

Agent A 交付：

- 提示词文件路径。
- 版本号和版本分配依据。
- 本轮目标、非目标、验收标准摘要。
- 需要 Agent B 重点读取的文件。
- 本轮本地轻量检查、main push、CI artifact 和 Agent C 复判要求。

Agent B 交付：

- 改了什么。
- 关键文件。
- 本地轻量检查命令和结果。
- commit SHA、是否已 push 到 `origin/main`、云端 run 状态或链接。
- 未跑本机完整测试及原因。
- 已知风险。
- 后续建议。

Agent C 交付：

- 验收结论：通过或不通过。
- 问题清单，按严重程度排序。
- 已核对文档。
- 验证证据：commit SHA、run id、run attempt、artifact 名称、manifest/JUnit/log 核对结果。
- 若不通过：明确退回 Agent B 的修正项。
- 若通过：版本号、工作内容概括、云端结果包结论。
- 建议下一步。

## 10. 禁止项

- 禁止不读当前源码就按记忆修改。
- 禁止把核心规则写入 SwiftUI 视图。
- 禁止让战斗预览和实际结算使用两套不一致逻辑。
- 禁止让 AI 意图预测改变 `GameState`。
- 禁止用 UI 测试代替核心规则测试。
- 禁止无理由删除测试、工具、文档入口或历史记录。
- 禁止把构建缓存、DerivedData 临时产物或无关截图加入版本管理。
- 禁止伪造测试通过或隐瞒未跑测试。
- 禁止在未获人工同意时引入第三方框架或改项目技术栈。
- 禁止本轮引入 `smalldata_test`、`develop`、`codeb/...` 或 PR 合并制度。
- 禁止把旧 artifact、旧 output 或 checkout 自带报告冒充本轮云端结果。
- 禁止 Agent C 在验收不通过时给出通过结论。
