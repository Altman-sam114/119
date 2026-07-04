# 项目核心流程图

本文是 `md/flow/flow.md` 的可视化版本。每张图前都有中文读图说明，方便人工快速理解当前真实逻辑。

## 1. 核心数据流

读图说明：这张图展示从 App 启动到用户操作再到核心规则更新的主数据流。SwiftUI 不直接改规则状态，所有命令都先进入 `GameViewModel`，再调用 `GameState`。

```mermaid
flowchart TD
    A["App 启动<br/>RomeLegionsApp 创建 GameViewModel"] --> B["RootView<br/>判断是否显示菜单"]
    B -->|isShowingMenu = true| C["MainMenuView<br/>人工选择战役/征服/远征"]
    C --> D["GameViewModel.start(mode:)<br/>创建 GameState.newCampaign"]
    B -->|isShowingMenu = false| E["BattleView<br/>展示地图、城市读板、侧栏、命令面板"]
    D --> E
    E --> F["用户点击地图或命令<br/>选择单位/城市/地块/目标"]
    F --> G["GameViewModel 命令方法<br/>selectTile / attack / recruit / develop / endTurn"]
    G --> H["GameState 核心规则<br/>移动、攻击、城市预览、招募、科技、外交、AI"]
    H --> I["返回中文消息或 GameRuleError<br/>说明命令结果"]
    I --> J["GameViewModel 更新 @Published 状态<br/>banner、选择态、派生数据"]
    J --> E
```

## 2. 回合执行流

读图说明：这张图展示玩家回合结束后，系统如何依次执行非罗马势力 AI，直到重新回到罗马玩家回合。

```mermaid
flowchart TD
    A["玩家点击结束回合"] --> B["GameViewModel.endTurn()"]
    B --> C["GameState.endTurn()<br/>结算收入、推进 activeFaction<br/>刷新新势力行动并递减其技能冷却"]
    C --> D{"当前 activeFaction 是罗马？"}
    D -->|是| E["清空选择态<br/>banner 显示新罗马回合"]
    D -->|否| F["GameState.performSimpleAI(for:)<br/>AI 招募、移动、攻击、技能、休整"]
    F --> G["GameState.endTurn()<br/>AI 势力结束回合<br/>刷新下一势力并递减其冷却"]
    G --> D
    E --> H["BattleView 刷新<br/>玩家继续下令"]
```

## 3. 战斗与敌军意图流

读图说明：这张图展示战斗预览、实际攻击、敌军意图和战线压力之间的关系。关键铁律是预览与结算必须一致，敌军意图和战线压力只能读取和预测，地图路线只是 `AIIntent` 既有字段的可视化，不能改变状态或 AI 决策。

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
    K --> L["GameState.aiIntents(for:limit:)<br/>只读预测攻击、接敌、夺城、固守、整备、技能<br/>forecast copy 刷新行动并递减该势力冷却<br/>攻击类预计伤害来自规划态 attackPreview"]
    K --> M["GameViewModel.enemyIntentMapOverlays<br/>派生起点、六边形邻接路径、目的地、目标格、伤害/效果文案"]
    L --> K
    M --> W["BattleView 地图折线路径、目的地叠层、目标格叠层<br/>侧栏显示来源、去向、目标和预计伤害"]
    L --> AB["GameState.frontlinePressureReports<br/>按罗马单位或城市聚合多路意图<br/>来源、预计伤害、夺城风险、压力等级"]
    AB --> AC["GameViewModel.frontlinePressureSummaries<br/>目标、来源、压力标签、影响文案、无障碍说明"]
    AC --> AD["BattleView 战线 chip 与战局面板<br/>展示高压目标和防守优先级"]

    N["选中有将领单位"] --> O["GameViewModel.selectedGeneralSkillPreview"]
    O --> P["GameState.generalSkillPreview<br/>只读计算范围、目标、预计恢复或削城防"]
    P --> Q["GameViewModel.selectedCommanderBrief<br/>整合将领名、被动贡献、技能状态、冷却原因和战功摘要"]
    Q --> X["BattleView 将领读板<br/>完整/紧凑情报展示被动、技能效果和战功"]
    X --> R["玩家发动技能"]
    R --> S["GameState.useGeneralSkill<br/>复用预览目标筛选<br/>消耗行动并写入冷却"]

    T["选中单位经验"] --> U["GameState.warMeritStatus<br/>经验转军阶、伤害加成、进度"]
    U --> Q

    Y["选中单位当前姿态"] --> Z["GameViewModel.selectedTacticalOrderPreviews<br/>局部复制单位替换姿态<br/>调用 effectiveAttack/Defense/Movement 计算攻防移预览"]
    Z --> AA["BattleView 姿态预览与按钮<br/>展示攻防移、变化值、当前标记和不可切换原因"]
```

## 4. 城市经营与招募预览流

读图说明：这张图展示城市读板如何从核心只读预览派生到 UI。扩建和招募按钮展示的是预览状态，但真实执行仍回到 `GameState`，并复用同一成本、收益和部署来源。

```mermaid
flowchart TD
    A["选中城市或驻城单位"] --> B["GameViewModel.commandCity / selectedCity"]
    B --> C["GameState.cityDevelopmentPreview(id:)<br/>成本、产出增量、城防增量、阻塞原因"]
    B --> D["GameState.recruitmentPreview(_:at:)<br/>兵种成本、预计部署位置、阻塞原因"]
    C --> E["GameViewModel.selectedCityBrief / commandCityBrief<br/>收入、库存、扩建收益、部署摘要"]
    D --> E
    E --> F["BattleView 情报栏和军令面板<br/>展示城市读板、扩建按钮、招募按钮"]
    F --> G["玩家点击扩建或招募"]
    G --> H["GameState.developCity / recruit<br/>复用同一预览来源后修改城市或创建单位"]
    H --> I["GameViewModel.apply<br/>展示中文结果或 GameRuleError"]
```

## 5. 任务与胜负结算流

读图说明：这张图展示 v0.4 后任务 requirement、任务奖励、战役胜负和结束保护的关系。胜负只由 `GameState` 判断，SwiftUI 只读取结果和禁用入口。

```mermaid
flowchart TD
    A["写状态命令<br/>移动、攻击、招募、科技、外交、AI"] --> B{"campaignStatus 已结束？"}
    B -->|是| C["GameRuleError.campaignAlreadyEnded<br/>不改变战局"]
    B -->|否| D["执行本次核心结算<br/>移动/伤害/占城/招募等"]
    D --> E["evaluateMissions()<br/>按 MissionRequirement 判断任务"]
    E --> F{"任务首次完成？"}
    F -->|是| G["标记 isCompleted<br/>发放一次奖励并写中文消息"]
    F -->|否| H["不重复发放奖励"]
    G --> I["重新读取 campaignStatus"]
    H --> I
    I --> J{"是否满足胜负？"}
    J -->|全部核心任务完成| K["罗马胜利<br/>输出战役胜利消息"]
    J -->|罗马失去全部城市| L["罗马失败<br/>输出战役失败消息"]
    J -->|仍在进行| M["返回任务/战斗消息<br/>继续玩家回合"]
    K --> N["后续写命令被结束保护拦截"]
    L --> N
    N --> O["只读展示仍可查看<br/>状态、预览、敌军意图"]
```

## 6. 多 Agent 云端迭代流

读图说明：这张图展示人工、Agent X、Agent A、Agent B、GitHub Actions 和 Agent C 的职责边界。Agent X 只做主控调度和轮次判断，不替代 A/B/C；当前默认不是 PR 流，而是 `main` 直推、云端结果包、Agent C 下载复判；失败时在 `main` 上追加修复 commit。

```mermaid
flowchart TD
    A["人工用 agentx: 提供总目标 X<br/>功能、禁止项、验收标准、测试要求"] --> B["Agent X<br/>读取入口文档，拆分当前轮次目标"]
    B --> C["Agent A<br/>读取文档和源码，设计本轮提示词"]
    C --> D["写入 md/prompt/vX/...md<br/>目标、非目标、步骤、CI、artifact、Agent C 要求"]
    D --> E["Agent B<br/>同步 origin/main，在 main 小步实现"]
    E --> F["本地轻量检查<br/>git diff --check / verify_project / YAML / Plist"]
    F --> G["main commit/push<br/>git push origin main"]
    G --> H["GitHub Actions<br/>RomeLegions CI Results"]
    H --> I["未加密必要 CI 结果包<br/>manifest / junit / logs / xcresult"]
    I --> J["Agent C<br/>gh auth login 后下载最新 artifact"]
    J --> K["核对 origin/main 最新 commit<br/>run id / run attempt / manifest / 日志"]
    K --> L["Agent C 输出验收结论<br/>通过或不通过"]
    L --> M{"Agent X 判断下一步"}
    M -->|退回修复| N["退回问题清单<br/>Agent B 追加修复 commit"]
    N --> E
    M -->|继续下一轮| C
    M -->|暂停等待人工| O["人工确认方向、权限或取舍"]
    O --> B
    M -->|总目标完成| P["Agent X 输出最终结论<br/>列出 run、artifact 和剩余风险"]
```

## 7. 测试选择流

读图说明：这张图帮助 Agent B/C/X 判断默认验证路径。默认先跑本地轻量检查，再 push 到 `main` 触发云端重验证；只有人工明确要求时才把本机完整 Swift / Xcode 测试作为默认路径。

```mermaid
flowchart TD
    A["本轮改动完成"] --> B["本地轻量检查<br/>git diff --check / verify_project"]
    B --> C{"是否修改 workflow / project / 文档入口？"}
    C -->|是| D["本地解析<br/>plutil / YAML / JSON"]
    C -->|否| E["记录轻量检查结果"]
    D --> E
    E --> F{"是否可推送 origin/main？"}
    F -->|否| G["报告阻塞<br/>缺 origin、权限或网络"]
    F -->|是| H["main commit/push<br/>触发 GitHub Actions"]
    H --> I["云端重验证<br/>Swift Testing / Smoke / Xcode build"]
    I --> J["上传结果包<br/>manifest / junit / logs / xcresult"]
    J --> K["Agent C 下载并核对<br/>/private/tmp/romelegions-c-review-run_id"]
    K --> L{"云端是否通过？"}
    L -->|是| M["验收通过<br/>记录 run 和 artifact"]
    L -->|否| N["退回 Agent B<br/>main 追加修复 commit"]
    N --> H
    G --> O{"人工是否明确要求本机完整测试？"}
    O -->|是| P["运行本机 Swift / Xcode / 预览命令"]
    O -->|否| Q["说明未跑完整测试原因"]
```
