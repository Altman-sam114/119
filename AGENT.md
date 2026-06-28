# AGENT.md

本文是 `RomeLegions` 项目的入口记忆、项目总览、基本规则和多 Agent 迭代工作流。后续 Codex 接手本项目时，必须先读本文，再按任务读取相关文档和源码。

一句话总览：`RomeLegions` 是一个原创 SwiftUI iOS 罗马题材战棋原型，核心规则在纯 Swift `RomeLegionsCore` 中建模，SwiftUI 通过 `GameViewModel` 展示战场、命令、敌军意图和战局态势。

## 1. 必读文件

每轮任务开始前按顺序读取：

1. `AGENT.md`：入口规则和 Agent 工作流。
2. `update_log.md`：版本记录、历史决策、遗留问题。
3. `md/flow/flow.md`：当前真实架构和核心运行流程。
4. `md/flow/flowchart.md`：核心流程 Mermaid 图。
5. `md/test/test.md`：测试分层、触发条件、命令和当前基线。
6. `README.md`：项目运行、已实现能力和本地验证入口。
7. 当前任务相关源码、测试和提示词。

若任务由 Agent A 提示词驱动，还必须读取对应 `md/prompt/.../*.md`。

## 2. 项目基本规则

- 先读当前状态，再动手实现；不要依赖记忆替代源码。
- 核心玩法规则只在 `Sources/RomeLegionsCore/GameState.swift` 或后续核心模块中建模。
- SwiftUI 视图只展示状态和触发命令，复杂规则不得写进 `body`、按钮闭包或生命周期回调。
- `GameViewModel` 负责选择态、命令态、预览数据、战局汇总和 UI 友好的派生数据。
- 规则变化必须同步影响预览、结算、AI 评分和测试。
- 用户或其他 Agent 的未提交改动默认受保护，不得回滚。
- 不引入第三方框架，除非人工明确同意。
- 不做无关重构，不把文档整理伪装成功能版本。

## 3. 核心架构边界

- 玩法核心层：`GameState`、`Faction`、`Position`、`Tile`、`ArmyUnit`、`City`、`Technology`、`Mission`、`CombatPreview`、`AIIntent` 等类型。
- 应用状态层：`GameViewModel` 持有 `GameState`，处理菜单、选择、命令、错误消息、敌军意图摘要和战局态势摘要。
- 视图层：`RootView` 根据 `isShowingMenu` 切换 `MainMenuView` 和 `BattleView`；`BattleView` 展示地图、侧栏、命令面板、敌情和状态栏。
- 存档层：`SaveStore` 用 SQLite 存取编码后的 `GameState`，不得绕过核心状态结构写散落状态。
- 工具层：`Tools/GameplaySmoke`、`Tools/RenderBattlePreview`、`Tools/verify_project.mjs` 分别负责核心冒烟、战斗页截图和结构检查。
- 测试层：`Tests/RomeLegionsCoreTests/GameStateTests.swift` 锁定核心规则，不用 UI 测试替代核心规则测试。

## 4. 标准迭代工作流

本项目按“人工目标 -> Agent A 设计提示词 -> Agent B 实现测试 -> Agent C 验收并更新核心逻辑文档 -> 人工复核 -> 下一轮”循环。

### 人工

人工提出目标，可以给出功能、算法框架、禁止项、验收标准、性能要求、UI 要求和测试要求。人工目标是最高层需求来源；Agent 不得缩小目标来降低实现难度。

### Agent A：目标分析与提示词

Agent A 默认不直接写代码，负责把人工目标转成给 Agent B 的详细实现提示词。

Agent A 必须：

1. 阅读本文、`update_log.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/test/test.md`。
2. 阅读相关源码、测试、README 和历史提示词。
3. 明确本轮目标、非目标、边界、依赖、风险和验收标准。
4. 设计实现方案，包括模块、数据流、状态流、接口、测试和必须保持不变的旧行为。
5. 分配版本号：人工指定则按人工指定；未指定则从 `v0.1` 起递增。小任务用 `v0.2`、`v0.3`；重要里程碑可用 `v1.0`。
6. 写入 `md/prompt/v0（简要标题）/v0.1（简要说明）.md` 这种版本目录。

Agent A 提示词必须包含：版本号、版本分配依据、背景、目标、非目标、当前架构依据、实现步骤、关键文件、测试要求、文档更新要求、验收标准、风险和禁止项。

### Agent B：实现与测试

Agent B 按 Agent A 提示词实现。

Agent B 必须：

1. 阅读 Agent A 提示词和本项目必读文件。
2. 阅读相关源码和测试。
3. 小步实现，不做无关重构。
4. 根据任务新增或修改测试。
5. 按 `md/test/test.md` 选择测试层级并运行测试。
6. 记录具体命令和结果，不得用“已验证”代替测试输出。
7. 更新必要文档。
8. 输出改动摘要、关键文件、测试命令和结果、未跑测试原因、已知风险和后续建议。

Agent B 不得绕过核心规则直接改 UI 状态，不得擅自扩大范围，不得删除旧实现，不得伪造测试通过，不得回滚用户或其他 Agent 改动。

### Agent C：验收与核心逻辑更新

Agent C 负责验收 Agent B 的结果，并更新核心逻辑文档。

Agent C 必须：

1. 阅读 Agent B 输出和实际 diff。
2. 核对测试结果是否覆盖 Agent A 提示词和人工目标。
3. 阅读本项目必读文件。
4. 检查架构边界、测试充分性、文档同步和未说明风险。
5. 基于新实现更新 `md/flow/flow.md`。
6. 更新 `md/flow/flowchart.md` 的 Mermaid 图。
7. 如形成正式版本或重要历史事项，更新 `update_log.md`。
8. 输出通过/不通过、问题清单、已更新文档和下一步建议。

## 5. 测试规则

- 每次实现前先读 `md/test/test.md`。
- 默认从最小测试开始，根据改动范围扩大测试。
- 核心规则变更必须跑 Swift Testing。
- 核心集成路径变更必须跑 Gameplay Smoke。
- 工程结构或文档入口变更必须跑 `node Tools/verify_project.mjs`。
- SwiftUI、ViewModel 或 UI 派生数据变更必须跑 SwiftUI 类型检查。
- 战斗页布局变更必须渲染预览图并检查竖屏、短横屏、宽屏。
- 文档-only 修改可只跑结构检查和文档内容检查，但最终回复必须说明未跑完整 Swift 测试的原因。
- 不得伪造、概括或美化测试结果。

## 6. 文档规则

- `README.md` 面向人工快速了解、运行和验证项目。
- `AGENT.md` 面向后续 Agent，是入口规则和协作流程。
- `update_log.md` 记录正式版本、重要维护事项、关键决策和遗留问题，不写无意义流水账。
- `md/test/test.md` 是测试选择依据；测试命令变化必须更新它。
- `md/flow/flow.md` 只写当前真实架构和运行流程，不写历史废话。
- `md/flow/flowchart.md` 必须与 `flow.md` 同步，Mermaid 图前要有中文读图说明。
- `md/prompt/` 存放 Agent A 每轮输出的详细实现提示词，按版本目录管理。
- 若核心逻辑、测试规范、入口文档或协作流程变化，必须同步更新相关文档。

## 7. 交付格式

Agent A 交付：

- 提示词文件路径。
- 版本号和版本分配依据。
- 本轮目标、非目标、验收标准摘要。
- 需要 Agent B 重点读取的文件。

Agent B 交付：

- 改了什么。
- 关键文件。
- 测试命令和结果。
- 未跑测试及原因。
- 已知风险。
- 后续建议。

Agent C 交付：

- 验收结论：通过或不通过。
- 问题清单，按严重程度排序。
- 已更新文档。
- 验证证据。
- 建议下一步。

## 8. 禁止项

- 禁止不读当前源码就按记忆修改。
- 禁止把核心规则写入 SwiftUI 视图。
- 禁止让战斗预览和实际结算使用两套不一致逻辑。
- 禁止让 AI 意图预测改变 `GameState`。
- 禁止用 UI 测试代替核心规则测试。
- 禁止无理由删除测试、工具、文档入口或历史记录。
- 禁止把构建缓存、DerivedData 临时产物或无关截图加入版本管理。
- 禁止伪造测试通过或隐瞒未跑测试。
- 禁止在未获人工同意时引入第三方框架或改项目技术栈。
