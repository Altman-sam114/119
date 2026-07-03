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

## 4. 多 Agent 云端迭代流

读图说明：这张图展示人工、Agent A、Agent B、GitHub Actions 和 Agent C 的职责边界。当前默认不是 PR 流，而是 `main` 直推、云端结果包、Agent C 下载复判；失败时在 `main` 上追加修复 commit。

```mermaid
flowchart TD
    A["人工提出目标<br/>功能、禁止项、验收标准、测试要求"] --> B["Agent A<br/>读取文档和源码，设计实现提示词"]
    B --> C["写入 md/prompt/vX/...md<br/>版本、目标、非目标、步骤、CI 要求"]
    C --> D["Agent B<br/>同步 origin/main，在 main 小步实现"]
    D --> E["本地轻量检查<br/>git diff --check / verify_project / YAML / Plist"]
    E --> F["main commit/push<br/>git push origin main"]
    F --> G["GitHub Actions<br/>RomeLegions CI Results"]
    G --> H["未加密 CI 结果包<br/>manifest / junit / logs / xcresult"]
    H --> I["Agent C<br/>gh auth login 后下载 artifact"]
    I --> J["核对 origin/main 最新 commit<br/>run id / run attempt / manifest / 日志"]
    J --> K{"是否满足目标？"}
    K -->|通过| L["确认文档和版本记录<br/>输出云端验收证据"]
    K -->|不通过| M["退回问题清单<br/>Agent B 追加修复 commit"]
    M --> D
    L --> N["人工复核<br/>决定下一轮目标"]
    N --> A
```

## 5. 测试选择流

读图说明：这张图帮助 Agent B/C 判断默认验证路径。默认先跑本地轻量检查，再 push 到 `main` 触发云端重验证；只有人工明确要求时才把本机完整 Swift / Xcode 测试作为默认路径。

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
