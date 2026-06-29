# 项目核心流程图

本文是 `md/flow/flow.md` 的可视化版本。每张图前都有中文读图说明，方便人工快速理解当前真实逻辑。

## 1. 核心数据流

读图说明：这张图展示从 App 启动到用户操作再到核心规则更新的主数据流。SwiftUI 不直接改规则状态，所有命令都先进入 `GameViewModel`，再调用 `GameState`。

```mermaid
flowchart TD
    A["App 启动<br/>RomeLegionsApp 创建 GameViewModel"] --> B["RootView<br/>判断是否显示菜单"]
    B -->|isShowingMenu = true| C["MainMenuView<br/>人工选择战役/征服/远征"]
    C --> D["GameViewModel.start(mode:)<br/>创建 GameState.newCampaign"]
    B -->|isShowingMenu = false| E["BattleView<br/>展示地图、侧栏、命令面板"]
    D --> E
    E --> F["用户点击地图或命令<br/>选择单位/城市/地块/目标"]
    F --> G["GameViewModel 命令方法<br/>selectTile / attack / recruit / endTurn"]
    G --> H["GameState 核心规则<br/>移动、攻击、招募、科技、外交、AI"]
    H --> I["返回中文消息或 GameRuleError<br/>说明命令结果"]
    I --> J["GameViewModel 更新 @Published 状态<br/>banner、选择态、派生数据"]
    J --> E
```

## 2. 回合执行流

读图说明：这张图展示玩家回合结束后，系统如何依次执行非罗马势力 AI，直到重新回到罗马玩家回合。

```mermaid
flowchart TD
    A["玩家点击结束回合"] --> B["GameViewModel.endTurn()"]
    B --> C["GameState.endTurn()<br/>结算当前势力收入、重置行动、推进 activeFaction"]
    C --> D{"当前 activeFaction 是罗马？"}
    D -->|是| E["清空选择态<br/>banner 显示新罗马回合"]
    D -->|否| F["GameState.performSimpleAI(for:)<br/>AI 招募、移动、攻击、技能、休整"]
    F --> G["GameState.endTurn()<br/>AI 势力结束回合"]
    G --> D
    E --> H["BattleView 刷新<br/>玩家继续下令"]
```

## 3. 战斗与敌军意图流

读图说明：这张图展示战斗预览、实际攻击和敌军意图之间的关系。关键铁律是预览与结算必须一致，敌军意图只能读取和预测，不能改变状态。

```mermaid
flowchart TD
    A["选中罗马单位"] --> B["GameViewModel.attackTargets<br/>读取 GameState.attackTargets"]
    B --> C["BattleView 显示可攻击目标徽标"]
    C --> D["GameViewModel.attackPreview(for:)"]
    D --> E["GameState.attackPreview<br/>计算伤害、反击、地形、支援、包夹、指挥、姿态"]
    E --> F["UI 展示 CombatPreview"]
    C --> G["玩家确认攻击"]
    G --> H["GameState.attack<br/>使用同一套修正逻辑结算"]
    H --> I["更新单位生命、行动标记、经验和消息"]

    J["敌军意图面板"] --> K["GameViewModel.enemyIntentSummaries"]
    K --> L["GameState.aiIntents(for:limit:)<br/>只读预测攻击、接敌、夺城、固守、整备、技能"]
    L --> M["BattleView 显示地图徽标、顶部芯片、侧栏敌情"]
```

## 4. 多 Agent 迭代流

读图说明：这张图展示人工、Agent A、Agent B、Agent C 的职责边界。Agent A 写提示词，Agent B 实现测试，Agent C 验收并更新核心流程文档；通过后按版本号自动提交，不通过就退回 Agent B 修正。

```mermaid
flowchart TD
    A["人工提出目标<br/>功能、禁止项、验收标准、测试要求"] --> B["Agent A<br/>读取记忆文档和源码，设计实现提示词"]
    B --> C["写入 md/prompt/vX/...md<br/>版本号、目标、非目标、步骤、测试、验收"]
    C --> D["Agent B<br/>读取提示词和项目文档，小步实现"]
    D --> E["Agent B 运行测试<br/>按 md/test/test.md 选择层级"]
    E --> F["Agent B 更新 README / 测试说明 / 必要文档"]
    F --> G["Agent C<br/>查看 diff、核对测试、检查架构边界"]
    G --> H{"是否满足目标？"}
    H -->|通过| I["Agent C 更新 flow.md、flowchart.md、update_log.md"]
    I --> L["按版本号 git commit<br/>提交说明概括本版本工作和验证"]
    H -->|不通过| J["输出问题清单<br/>退回 Agent B 修正，不提交"]
    L --> K["人工复核<br/>决定下一轮目标"]
    J --> D
    K --> A
```

## 5. 测试选择流

读图说明：这张图帮助 Agent B/C 快速判断应该跑哪些测试。默认先跑最快的结构检查，再根据是否改核心、UI、工程或布局扩大验证范围。

```mermaid
flowchart TD
    A["本轮改动完成"] --> B["先跑 Probe / Fast<br/>node Tools/verify_project.mjs"]
    B --> C{"是否修改核心规则？"}
    C -->|是| D["跑 Stage Regression<br/>swift test"]
    C -->|否| E{"是否修改核心主链路或工具？"}
    E -->|是| F["跑 Smoke<br/>GameplaySmoke"]
    E -->|否| G{"是否修改 SwiftUI / ViewModel？"}
    G -->|是| H["跑 SwiftUI typecheck"]
    G -->|否| I{"是否修改战斗页布局？"}
    H --> I
    I -->|是| J["渲染预览图<br/>landscape / portrait / wide"]
    I -->|否| K["记录未跑更高层测试的原因"]
    D --> L{"是否重大版本或工程变更？"}
    F --> L
    J --> L
    L -->|是| M["跑 Full 或无签名构建"]
    L -->|否| K
    M --> K
```
