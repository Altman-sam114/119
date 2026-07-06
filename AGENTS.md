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
- 用户消息以 `agentx`、`x:` 或 `X:` 开头，表示召唤 Agent X。
- 没有这些前缀时，按普通 Codex 任务处理；若任务需要 A/B/C/X 边界，应提醒用户指定角色，或说明本轮按普通任务执行。
- Agent A 最终回复第一行必须写：`我是 Agent A。`
- Agent B 最终回复第一行必须写：`我是 Agent B。`
- Agent C 最终回复第一行必须写：`我是 Agent C。`
- Agent X 最终回复第一行必须写：`我是 Agent X。`

## 3. 项目基本规则

- 先读当前状态，再动手实现；不要依赖记忆替代源码。
- 核心玩法规则只在 `Sources/RomeLegionsCore/GameState.swift` 或后续核心模块中建模。
- SwiftUI 视图只展示状态和触发命令，复杂规则不得写进 `body`、按钮闭包或生命周期回调。
- `GameViewModel` 负责选择态、命令态、预览数据、战局汇总和 UI 友好的派生数据。
- 规则变化必须同步影响预览、结算、AI 评分和测试。
- 用户或其他 Agent 的未提交改动默认受保护，不得回滚。
- 不引入第三方框架，除非人工明确同意。
- 不做无关重构，不把文档整理伪装成功能版本。
- 当前验证策略按人工最新要求从 v0.15 起改为云端-only：本地只允许读取、编辑、`git status` / `git diff` 等只读检查和 git 同步/提交/推送；不得运行本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs` 或 `git diff --check`，除非人工以后重新明确允许。
- 完整 Swift Testing、Gameplay Smoke、结构检查、SwiftUI / Xcode build 和战斗页渲染相关验收交给 `main` push 后的 GitHub Actions 与 Agent C artifact 复判。

## 4. 核心架构边界

- 玩法核心层：`GameState`、`Faction`、`Position`、`Tile`、`ArmyUnit`、`City`、`Technology`、`Mission`、`MissionRequirement`、`CampaignStatus`、`CombatPreview`、`AIIntent` 等类型。
- 应用状态层：`GameViewModel` 持有 `GameState`，处理菜单、选择、命令、错误消息、敌军意图摘要和战局态势摘要。
- 视图层：`RootView` 根据 `isShowingMenu` 切换 `MainMenuView` 和 `BattleView`；`BattleView` 展示地图、侧栏、命令面板、敌情和状态栏。
- 存档层：`SaveStore` 用 SQLite 存取编码后的 `GameState`，不得绕过核心状态结构写散落状态。
- 工具层：`Tools/GameplaySmoke`、`Tools/RenderBattlePreview`、`Tools/verify_project.mjs` 分别负责核心冒烟、战斗页截图和结构检查。
- 测试层：`Tests/RomeLegionsCoreTests/GameStateTests.swift` 锁定核心规则，不用 UI 测试替代核心规则测试。
- CI 层：`.github/workflows/ci-results.yml` 在 `main` push 或手动触发时运行结构检查、SwiftPM 测试、Gameplay Smoke、RenderBattlePreview 和无签名 Xcode build，并上传未加密 CI 结果包供 Agent C 复判。

## 5. main 直推和云端验证规则

- 本项目默认只使用 `main` 作为上传、提交、推送和云端验证分支。
- 暂不设计 `smalldata_test`、`develop`、`codeb/...` 或其他长期/候选分支；若远端已有其他分支，只记录现状，不纳入默认流程。
- 不创建 PR，不等待 PR merge；默认是 `main` 直接 push 触发 GitHub Actions。
- Agent B 每轮开始前必须同步最新 `origin/main`，确认当前分支是 `main`，确认工作区没有无关改动，再实现。
- Agent B 完成实现和只读 diff/status 检查后，在 `main` 上提交本轮相关文件，并直接 `git push origin main`；当前云端-only 约束下不得用本地轻量检查替代云端结果包。
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

本项目支持两种协作入口：单轮按“人工目标 -> Agent A 设计提示词 -> Agent B 实现并 main 直推 -> GitHub Actions 云端验证 -> Agent C 下载结果包验收 -> 人工复核 -> 下一轮”执行；多轮总目标可由 Agent X 主控调度，按“Agent X -> Agent A -> Agent B -> Agent C -> Agent X 判断下一轮”循环。

### 人工

人工提出目标，可以给出功能、算法框架、禁止项、验收标准、性能要求、UI 要求和测试要求。人工目标是最高层需求来源；Agent 不得缩小目标来降低实现难度。

### Agent X：主控调度与循环判断

Agent X 是主控调度角色，不直接替代 Agent A/B/C。Agent X 接收人工总目标 X，把总目标拆成多个小轮次，并要求每轮继续遵守 Agent A 提示词、Agent B 实现 push、GitHub Actions 云端验证、Agent C 下载 artifact 复判的完整链路。

Agent X 必须：

1. 阅读本文、`update_log.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/test/test.md`、`README.md`、`md/prompt/README.md`。
2. 明确总目标、当前轮次目标、非目标、验收标准、风险和禁止项。
3. 将总目标拆成可验证的小轮次；每轮必须先由 Agent A 生成版本化提示词，再交由 Agent B 实现。
4. 每轮必须等待 Agent C 对最新 `origin/main` commit、run id、run attempt 和 artifact 的验收结论，不能跳过云端结果包复判。
5. 根据 Agent C 结果判断下一步：继续下一轮、退回 Agent B 修复、暂停等待人工确认，或宣布总目标完成。
6. 维护轮次边界，不为了推进循环扩大无关改动范围，不把文档整理、测试补丁或修复提交伪装成未完成的业务目标。
7. 记录每轮关键证据：提示词路径、Agent B commit SHA、GitHub Actions run、artifact 名称、Agent C 结论和剩余风险。

Agent X 停止条件：

- 总目标已完成。
- 连续 3 轮遇到同一阻塞。
- 连续 2 轮没有产生有效 diff。
- CI 连续失败且原因相同。
- 需要账号、权限、密钥、付费服务或人工决策。
- 当前工作区存在无法判断归属的冲突。
- 用户要求停止或改变方向。

Agent X 不得无条件无限循环；不得跳过 Agent C 云端 artifact 验收；不得把旧 run、旧 artifact、本地输出或 checkout 自带报告冒充最新云端结果；不得在总目标未完成时宣布完成。

### Agent A：目标分析与提示词

Agent A 默认不直接写代码，负责把人工目标转成给 Agent B 的详细实现提示词。

Agent A 必须：

1. 阅读本文、`update_log.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/test/test.md`、`md/prompt/README.md`。
2. 阅读相关源码、测试、README 和历史提示词。
3. 明确本轮目标、非目标、边界、依赖、风险和验收标准。
4. 设计实现方案，包括模块、数据流、状态流、接口、测试和必须保持不变的旧行为。
5. 分配版本号：人工指定则按人工指定；未指定则从现有版本继续递增。
6. 写入 `md/prompt/v0（简要标题）/v0.3（简要说明）.md` 这类版本目录。
7. 在提示词中写清当前云端-only 验证限制、`main` commit/push、GitHub Actions 结果包、Agent C 下载复判要求。

Agent A 提示词必须包含：版本号、版本分配依据、背景、目标、非目标、当前架构依据、实现步骤、关键文件、测试要求、CI / main push 要求、文档更新要求、验收标准、风险和禁止项。

### Agent B：实现、云端验证与 main push

Agent B 按 Agent A 提示词实现。

Agent B 必须：

1. 阅读 Agent A 提示词和本项目必读文件。
2. `git fetch origin`、切到 `main`、`git pull --ff-only origin main`；若没有 `origin`，必须报告阻塞。
3. 阅读相关源码和测试。
4. 小步实现，不做无关重构。
5. 根据任务新增或修改测试。
6. 当前按人工要求不得运行本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs` 或 `git diff --check`；只允许读文件、编辑、只读 `git diff` / `git status`、同步、提交和推送。
7. 记录具体执行过的只读/同步/提交/推送命令；不得把未运行的本地命令写成“已验证”。
8. 更新必要文档。
9. 提交本轮相关文件并 push 到 `origin/main`，触发 GitHub Actions。
10. 输出改动摘要、关键文件、本轮未跑本地验证的原因、commit SHA、push 结果、云端 run 链接或等待状态、已知风险和后续建议。

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
- 当前从 v0.15 起按人工要求不运行本地验证命令，直接通过 `main` push 触发云端重验证；本地只做读取、编辑和只读 diff/status 检查。
- 文档-only 修改也不得默认本地跑 `git diff --check`、`node Tools/verify_project.mjs` 或相关解析，除非人工以后重新明确允许本地验证。
- 核心规则变更必须由 GitHub Actions 跑 Swift Testing；人工要求本机测试时再本地跑 Swift Testing。
- 核心集成路径变更必须由 GitHub Actions 跑 Gameplay Smoke。
- 工程结构或文档入口变更必须由 GitHub Actions 跑 `node Tools/verify_project.mjs`。
- SwiftUI、ViewModel 或 UI 派生数据变更必须接受云端 Xcode build；人工要求本机检查时再跑 SwiftUI 类型检查。
- 战斗页布局变更必须通过云端流程覆盖 `md/test/test.md` 中的预览断言；当前预览断言覆盖敌军路线/目标、敌方将领威胁、敌情反制建议、反制落点/目标地图叠层、反制指令聚焦/执行预览、反制命令链高亮、反制焦点链路、战场目标链路、地图叠层图例、城市读板、军团编制、军团成长决策、军团成长优先级、将领协同、机动落点、战术建议、将领详情、战功和姿态预览等关键战斗页读板；若云端暂不支持对应产物，manifest 和失败摘要必须写明 skipped 原因。
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
- 本轮云端-only 验证、main push、CI artifact 和 Agent C 复判要求。

Agent B 交付：

- 改了什么。
- 关键文件。
- 本轮未跑本地验证的原因，以及执行过的只读/同步/提交/推送命令结果。
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

Agent X 交付：

- 第一行：`我是 Agent X。`
- 总目标状态：继续、退回、暂停或完成。
- 当前轮次和已完成轮次摘要。
- 最新 Agent C 验收证据：commit SHA、run id、run attempt、artifact 名称和结论。
- 下一轮目标、非目标、需要 Agent A/B/C 重点处理的事项。
- 触发停止条件时，说明具体条件和需要人工决策的问题。

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
- 禁止 Agent X 无条件无限循环、跳过 Agent C 云端 artifact 验收、使用旧 run 或旧 artifact 伪装最新结果，或在总目标未完成时宣布完成。
- 禁止为了推进 Agent X 循环扩大无关改动范围。
- 禁止使用非 `Altman-sam114` 的 GitHub 账号伪装完成 push、CI 或 artifact 验收。
- 禁止默认下载大体积测试数据、模型、历史 artifact 或无关产物，导致本机或 CI 容量被撑爆。
