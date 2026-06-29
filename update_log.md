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
- 当前玩法：六边形地图、地形、城市、阵营、军团、移动、攻击、反击、占城、招募、科技、任务、外交、城市扩建、军团训练、将领任命、主动技能、战术姿态、AI 回合、敌军意图预判、战局态势面板。
- 当前测试入口：Swift Testing、Gameplay Smoke、项目结构检查、SwiftUI 类型检查、战斗页预览图渲染、无签名 Xcode 构建。
- 当前协作系统：已建立 `AGENTS.md`、`update_log.md`、`md/prompt/`、`md/test/test.md`、`md/flow/flow.md`、`md/flow/flowchart.md`。

## 历史记录

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
