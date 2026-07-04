# 项目核心流程文档

一句话总览：`RomeLegions` 当前是 SwiftUI App + 纯 Swift 核心规则的罗马题材战棋原型，用户在菜单选择模式后进入战场，SwiftUI 通过 `GameViewModel` 调用 `GameState` 完成移动、战斗、城市、科技、外交、战役胜负结算、AI 和敌军意图展示；协作层默认通过 `main` 直推触发 GitHub Actions，并由 Agent C 下载未加密结果包复判；未来可由 Agent X 围绕人工总目标调度 A/B/C 多轮迭代。

本文只记录当前真实链路，不写历史叙事。

## 当前核心数据流

1. `RomeLegionsApp` 创建 `GameViewModel`，并通过 `.environmentObject(viewModel)` 注入根视图。
2. `RootView` 根据 `viewModel.isShowingMenu` 展示 `MainMenuView` 或 `BattleView`。
3. `MainMenuView` 调用 `viewModel.start(mode:)`，创建 `GameState.newCampaign(mode:)` 并进入战斗。
4. `BattleView` 读取 `GameViewModel` 的派生数据：当前回合、资源、选中单位、选中城市、可移动格、攻击目标、战斗预览、将领技能预览、战功状态、任务目标、战役状态、敌军意图、战局态势。
5. 用户点击地图或命令按钮后，`GameViewModel` 调用 `GameState` 的 mutating 方法。
6. `GameState` 修改核心状态并返回中文消息数组。
7. `GameViewModel.apply` 捕获成功消息或 `GameRuleError`，更新 `bannerMessage`。
8. SwiftUI 根据 `@Published` 状态自动刷新地图、侧栏、命令面板和状态条。

## 当前核心执行流

### 启动与模式选择

- App 入口：`RomeLegionsApp/App/RomeLegionsApp.swift`。
- 根视图：`RomeLegionsApp/Views/RootView.swift`。
- 菜单：`RomeLegionsApp/Views/MainMenuView.swift`。
- 模式：`GameMode.campaign`、`.conquest`、`.expedition`。
- 调试参数：
  - `--start-battle`：直接进入战斗。
  - `--attack-demo`：进入战斗并放置相邻敌军，便于复现攻击 UI。

### 地图选择与命令

- 用户点击单位：`GameViewModel.selectTile(_:)` 选中单位，并同步驻守城市和位置。
- 用户点击可移动格：`selectTile(_:)` 调用 `state.moveUnit(id:to:)`。
- 用户点击敌军攻击目标：`selectTile(_:)` 或按钮调用 `attack(_:)`，再进入 `state.attack(attackerID:defenderID:)`。
- 用户点击城市：选中 `selectedCityID`，命令面板可招募、扩建或查看资源。
- 用户点击空地：清除单位/城市选择，只显示地形信息。

### 战斗与预览

- `state.attackPreview(attackerID:defenderID:)` 生成 `CombatPreview`。
- 预览包含基础攻击、防御、地形、友军支援、包夹、将领指挥、守军支援、战术姿态、反击和剩余生命。
- `state.attack(attackerID:defenderID:)` 必须与预览使用同一套修正逻辑。
- `state.aiIntents(for:limit:)` 在只读规划态中为直接攻击和移动后攻击调用同一套预览逻辑，敌军意图的 `projectedDamage` 必须等于规划态 `attackPreview.damage`。
- UI 通过 `viewModel.attackPreview(for:)` 展示攻击风险和目标徽标。

### 战术、将领与技能

- `TacticalOrder` 决定移动、攻击、防御修正。
- `setTacticalOrder(unitID:order:)` 只能在单位移动或行动前执行。
- `GeneralTrait` 提供被动修正、主动技能参数和统一的技能冷却回合数。
- `generalSkillPreview(unitID:)` 只读计算技能范围、受影响友军/敌城、预计恢复量、预计城防削弱、冷却剩余、可执行状态和不可用原因，不改变原始 `GameState`。
- `useGeneralSkill(unitID:)` 处理鹰旗鼓舞、攻城布阵、战地补给、盾墙号令等技能，并复用技能预览的目标筛选逻辑；成功后消耗行动并写入技能冷却。
- `WarMeritStatus` 将单位经验转成军阶、战功进度和 `experience * 3` 伤害加成说明，不改变既有伤害公式。
- `GameViewModel.selectedGeneralSkillPreview` 和 `selectedWarMeritStatus` 将核心预览转为地图范围、目标集合、按钮摘要、冷却摘要和战功摘要；SwiftUI 只展示范围叠层、目标叠层、将领卡和命令 detail，不复制技能规则。

### 城市、资源、科技、外交

- `income(for:)` 根据城市生产统计资源收入。
- `developCity(id:)` 消耗资源提升城市产出和防御。
- `recruit(_:at:)` 在城市或相邻可用格招募单位。
- `research(_:)` 消耗资源解锁科技，重复研究会抛出规则错误。
- `sendEnvoy(to:)` 改变罗马与目标势力外交状态；条约可阻止攻击。

### 任务、战役目标与胜负

- `MissionRequirement` 描述任务判断条件，当前支持控制指定城市、指定阵营单位数量不少于目标值。
- `newCampaign(mode:)` 创建三项核心任务：占领叙拉古、拥有 5 支罗马部队、占领迦太基。
- `evaluateMissions()` 优先按 `Mission.requirement` 判断完成，缺 requirement 的旧任务才走 legacy id 兜底。
- 任务完成时只在 `isCompleted == false` 时发放一次奖励，并写入中文完成消息。
- `campaignStatus` 是 `GameState` 的只读计算状态：进行中显示当前目标；罗马完成全部核心任务后胜利；罗马失去全部城市后失败。
- 会改变战局的核心命令在 `campaignStatus.isGameOver == true` 时抛出或返回 `campaignAlreadyEnded`，不再移动、攻击、招募、研发、外交或推进回合。
- 导致胜负的命令先完成本次结算和任务奖励，再输出胜利或失败消息；后续命令才被结束保护拦截。

### 回合与 AI

- `GameViewModel.endTurn()` 调用 `state.endTurn()` 结束罗马回合。
- 当 `activeFaction` 不是罗马且战役未结束时，ViewModel 循环调用 `state.performSimpleAI(for:)` 和 `state.endTurn()`，直到回到罗马或出现胜负结果。
- `endTurn()` 推进到下一个势力后调用所属阵营回合开始刷新：重置移动/行动、清空战术姿态，并让该阵营单位的将领技能冷却递减 1；其他阵营冷却不递减。
- AI 当前支持招募、休整、战术姿态、主动技能、移动后攻击、目标优先级评估。
- `performSimpleAI(for:)` 在战役结束后直接返回空消息；AI 单位循环中若移动或攻击导致胜负，也会停止后续动作。
- `aiIntents(for:limit:)` 只预测敌军倾向，不改变状态；它在 forecast copy 上复用同一回合开始刷新 helper，攻击类意图的预计伤害来自规划态战斗预览。
- AI 主动技能判断和 `.useSkill` 意图复用将领技能预览并尊重冷却；攻城技能填入目标城市，治疗类技能填入主要受益友军。

### 存档链路

- `SaveStore` 用 SQLite 创建 `saves` 表。
- 存档内容是编码后的完整 `GameState` blob，同时保存模式、回合、当前势力、时间和摘要。
- 当前核心存档代码已存在，但 UI 中继续完善存档列表、继续游戏、删除存档和错误展示仍是扩展点。

## 云端协作执行流

1. 人工提出目标；若消息以 `agenta`、`a:` 或 `A:` 开头，召唤 Agent A。
2. Agent A 读取项目文档、相关源码和历史提示词，写入版本化提示词，明确本地轻量检查、`main` commit/push、CI artifact 和 Agent C 复判要求。
3. Agent B 读取提示词和项目文档，先同步最新 `origin/main`，确认当前分支是 `main` 且工作区无无关改动。
4. Agent B 小步实现并更新必要测试和文档，默认只跑本地轻量检查。
5. Agent B 在 `main` 上提交本轮相关文件并 push 到 `origin/main`。
6. GitHub Actions 的 `RomeLegions CI Results` workflow 在 `main` push 或手动触发时运行，产出未加密 CI 结果包。
7. Agent C 用 `gh auth login` 后下载最新 run 的 artifact 到 `/private/tmp/romelegions-c-review-<run_id>/`。
8. Agent C 核对 manifest、JUnit、主日志、失败摘要、run id、run attempt 和 `origin/main` 最新 commit。
9. 若云端失败或验收不通过，Agent C 退回 Agent B，Agent B 在 `main` 上追加修复 commit 并重新 push。
10. 若通过，Agent C 确认文档同步、记录版本事项和结果包证据；若 Agent C 产生新提交，也必须 push 并验收最新 run。

## Agent X 主控循环

Agent X 是未来的主控调度角色。人工用 `agentx`、`x:` 或 `X:` 提供总目标 X 后，Agent X 不直接替代 Agent A/B/C，而是把总目标拆成多个可验证的小轮次，并让每轮继续走现有云端协作执行流。

Agent X 循环步骤：

1. Agent X 读取入口文档、当前状态和人工总目标，拆出当前轮次目标、非目标和验收标准。
2. Agent X 要求 Agent A 为当前轮次生成版本化提示词，提示词必须写清本轮目标、实现边界、本地轻量检查、`main` push、GitHub Actions artifact 和 Agent C 验收要求。
3. Agent B 按提示词实现，先同步 `origin/main`，在 `main` 上提交并 push 本轮相关 diff。
4. GitHub Actions 生成最新 run 的未加密 artifact，只上传必要 manifest、JUnit、关键日志、失败摘要和必要结果包。
5. Agent C 下载最新 artifact 到 `/private/tmp/romelegions-c-review-<run_id>/`，核对 manifest、JUnit、主日志、失败摘要、run id、run attempt 和 `origin/main` 最新 commit。
6. Agent X 根据 Agent C 结论判断：继续下一轮、退回 Agent B 追加修复、暂停等待人工确认，或宣布总目标完成。

Agent X 停止条件包括：总目标已完成；连续 3 轮遇到同一阻塞；连续 2 轮没有产生有效 diff；CI 连续失败且原因相同；需要账号、权限、密钥、付费服务或人工决策；当前工作区存在无法判断归属的冲突；用户要求停止或改变方向。

Agent X 不能跳过 Agent C artifact 验收，不能把旧 run、旧 artifact、本地输出或 checkout 自带报告冒充最新云端结果，不能为了循环推进扩大无关改动范围。

## 核心状态对象 / 模块

- `Faction`：罗马、迦太基、高卢、埃及、中立等势力及回合顺序。
- `GameMode`：战役、征服、远征。
- `DiplomaticStatus` / `DiplomaticRelation`：外交状态和势力关系。
- `TerrainType`、`Position`、`Tile`：六边形地图、地形成本和邻接。
- `EmpireResources`：金币、粮草、威望。
- `UnitKind`：军团、骑兵、弓兵、舰队等单位类型。
- `TacticalOrder`：均衡、突击、坚守、行军。
- `GeneralTrait`：将领特性、技能名、技能效果参数和冷却回合数。
- `GeneralSkillPreview`：将领主动技能只读预览，包含范围、目标、预计恢复、预计削城防、冷却、可执行状态和 UI 摘要。
- `WarMeritStatus`：经验到军阶、伤害加成和下一军阶进度的只读状态。
- `ArmyUnit`：单位状态、生命、经验、将领、技能冷却、姿态、行动标记。
- `City`：城市位置、所属、产出、防御。
- `Technology`：科技解锁。
- `MissionRequirement`：任务完成条件。
- `Mission`：任务状态、目标文本、奖励和可判断条件。
- `CampaignStatusKind` / `CampaignStatus`：战役进行中、罗马胜利、罗马失败及 UI 友好说明。
- `CombatPreview`：战斗预估。
- `AIIntentKind` / `AIIntent`：敌军意图预测。
- `GameRuleError`：规则错误和中文提示。
- `GameState`：核心世界状态和所有规则入口。
- `GameViewModel`：UI 状态和派生数据。
- `SaveStore`：SQLite 存档。

## 关键边界

- SwiftUI 视图不得直接改 `GameState` 内部数组，只能通过 `GameViewModel` 命令方法。
- `GameViewModel` 不得复制核心规则；它只做选择态、错误展示和 UI 派生数据。
- `GameState` 不依赖 SwiftUI、AppKit、UIKit 或文件系统。
- `SaveStore` 存取完整 `GameState`，不得维护另一套玩法状态。
- AI 意图预测不得改变 `GameState`。
- 战斗预览和实际战斗必须共享规则来源。
- 战役胜负只由 `GameState.campaignStatus` 判断，SwiftUI 不复制占城、部队数量或失败条件。
- 战役结束保护必须在核心 mutating 命令中生效，ViewModel / SwiftUI 的禁用状态只能作为用户体验层。
- 云端 CI 和协作文档不得改变玩法语义；流程升级不等于业务质量提升。

## 用户入口

- 普通运行：打开 `RomeLegionsApp.xcodeproj`，选择 iPhone 或 iPad Simulator，运行 `RomeLegions` target。
- 命令行 UI 复现：`xcrun simctl launch booted com.codex.RomeLegions --attack-demo`。
- 预览渲染：`Tools/RenderBattlePreview/main.swift` 生成战斗页 PNG。
- 核心测试：Swift Testing 和 Gameplay Smoke。
- 云端验证：push 到 `origin/main` 后由 `.github/workflows/ci-results.yml` 上传 CI 结果包。

## 前端 / 数据层 / 模型层 / 测试层关系

- 前端：SwiftUI views，读取 `GameViewModel`。
- 应用状态层：`GameViewModel`，持有 `GameState`。
- 模型层：`RomeLegionsCore`，纯 Swift 可测试规则。
- 数据层：`SaveStore`，持久化 `GameState`。
- 测试层：`GameStateTests` 直接验证核心模型；工具脚本验证结构、冒烟和 UI 渲染。
- CI 层：`.github/workflows/ci-results.yml` 运行结构检查、SwiftPM 测试、Gameplay Smoke 和无签名 Xcode build，并上传未加密结果包。
- 协作层：`AGENTS.md`、`update_log.md`、`md/test/test.md`、`md/flow/` 和 `md/prompt/` 约束 Agent 迭代；默认流程是本地轻量检查、`main` 直推、云端重验证和 Agent C 结果包复判；Agent X 可在未来作为主控调度多轮 A/B/C 循环。

## 已确认的铁律

- 核心规则先有测试，再扩 UI。
- 预览和结算必须一致。
- AI 意图不改状态。
- 回合推进必须回到罗马后才交还玩家控制。
- 外交条约必须能阻止被保护势力之间的攻击。
- 战术姿态只能在单位移动或行动前切换。
- 城市招募优先城市格，城市格被占用时使用相邻可用格。
- Agent C 不能只看 Agent B 文字汇报，必须核对最新云端结果包。
- Agent X 不能越过 Agent C 的最新 artifact 验收来推进下一轮。

## 未来扩展点

- 将领详情、更多技能和升级树。
- 存档列表、继续游戏、删除存档和存档错误 UI。
- 城市生产、军团编制和外交界面的战略桌体验。
- AI 多步规划，使敌军意图和实际行为共享更多评分逻辑。
- 移动、攻击、反击、占城和回合切换动画。
- 拆分 `BattleView.swift` 中稳定的大型子视图。
- 将战斗页预览图渲染稳定纳入云端结果包。

## 不允许破坏的行为

- `reachablePositions` 必须尊重地形、边界和占用。
- 移动进中立城市会占领城市。
- 攻击会消耗攻击者行动并造成伤害。
- `CombatPreview` 的剩余生命必须匹配实际攻击结果。
- 重复研究同一科技必须报错。
- 城市扩建必须提高产出和防御并消耗资源。
- 将领特性必须影响有效移动、攻击或防御。
- 主动技能必须消耗行动。
- 主动技能释放成功后必须进入冷却，冷却只在所属阵营开始行动回合递减。
- 主动技能预览必须只读，且技能释放必须复用预览目标筛选逻辑。
- AI 主动技能判断必须复用预览并尊重冷却。
- 派使停战后，被条约保护的攻击必须被阻止。
- 跳过单位必须消耗移动和行动。
- AI 能移动到攻击范围并攻击。
- AI 意图必须能预测直接攻击、移动后攻击和夺城，攻击类预计伤害必须与规划态战斗预览一致，且不改变状态。
- 任务 requirement 必须继续作为任务完成判断的主路径，legacy mission id 只能兜底旧数据。
- 任务奖励不得重复发放。
- 罗马完成全部核心任务必须进入胜利；罗马失去全部城市必须进入失败。
- 战役结束后，移动、攻击、招募、科技、外交、AI 推进和结束回合不得继续改变战局。
