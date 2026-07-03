# 项目核心流程文档

一句话总览：`RomeLegions` 当前是 SwiftUI App + 纯 Swift 核心规则的罗马题材战棋原型，用户在菜单选择模式后进入战场，SwiftUI 通过 `GameViewModel` 调用 `GameState` 完成移动、战斗、城市、科技、外交、AI 和敌军意图展示；协作层默认通过 `main` 直推触发 GitHub Actions，并由 Agent C 下载未加密结果包复判。

本文只记录当前真实链路，不写历史叙事。

## 当前核心数据流

1. `RomeLegionsApp` 创建 `GameViewModel`，并通过 `.environmentObject(viewModel)` 注入根视图。
2. `RootView` 根据 `viewModel.isShowingMenu` 展示 `MainMenuView` 或 `BattleView`。
3. `MainMenuView` 调用 `viewModel.start(mode:)`，创建 `GameState.newCampaign(mode:)` 并进入战斗。
4. `BattleView` 读取 `GameViewModel` 的派生数据：当前回合、资源、选中单位、选中城市、可移动格、攻击目标、战斗预览、敌军意图、战局态势。
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
- UI 通过 `viewModel.attackPreview(for:)` 展示攻击风险和目标徽标。

### 战术、将领与技能

- `TacticalOrder` 决定移动、攻击、防御修正。
- `setTacticalOrder(unitID:order:)` 只能在单位移动或行动前执行。
- `GeneralTrait` 提供被动修正和主动技能。
- `useGeneralSkill(unitID:)` 处理鹰旗鼓舞、攻城布阵、战地补给、盾墙号令等技能，并消耗行动。

### 城市、资源、科技、外交

- `income(for:)` 根据城市生产统计资源收入。
- `developCity(id:)` 消耗资源提升城市产出和防御。
- `recruit(_:at:)` 在城市或相邻可用格招募单位。
- `research(_:)` 消耗资源解锁科技，重复研究会抛出规则错误。
- `sendEnvoy(to:)` 改变罗马与目标势力外交状态；条约可阻止攻击。

### 回合与 AI

- `GameViewModel.endTurn()` 调用 `state.endTurn()` 结束罗马回合。
- 当 `activeFaction` 不是罗马时，ViewModel 循环调用 `state.performSimpleAI(for:)` 和 `state.endTurn()`，直到回到罗马。
- AI 当前支持招募、休整、战术姿态、主动技能、移动后攻击、目标优先级评估。
- `aiIntents(for:limit:)` 只预测敌军倾向，不改变状态。

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

## 核心状态对象 / 模块

- `Faction`：罗马、迦太基、高卢、埃及、中立等势力及回合顺序。
- `GameMode`：战役、征服、远征。
- `DiplomaticStatus` / `DiplomaticRelation`：外交状态和势力关系。
- `TerrainType`、`Position`、`Tile`：六边形地图、地形成本和邻接。
- `EmpireResources`：金币、粮草、威望。
- `UnitKind`：军团、骑兵、弓兵、舰队等单位类型。
- `TacticalOrder`：均衡、突击、坚守、行军。
- `GeneralTrait`：将领特性、技能名、技能效果参数。
- `ArmyUnit`：单位状态、生命、经验、将领、姿态、行动标记。
- `City`：城市位置、所属、产出、防御。
- `Technology`：科技解锁。
- `Mission`：任务状态。
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
- 协作层：`AGENTS.md`、`update_log.md`、`md/test/test.md`、`md/flow/` 和 `md/prompt/` 约束 Agent 迭代；默认流程是本地轻量检查、`main` 直推、云端重验证和 Agent C 结果包复判。

## 已确认的铁律

- 核心规则先有测试，再扩 UI。
- 预览和结算必须一致。
- AI 意图不改状态。
- 回合推进必须回到罗马后才交还玩家控制。
- 外交条约必须能阻止被保护势力之间的攻击。
- 战术姿态只能在单位移动或行动前切换。
- 城市招募优先城市格，城市格被占用时使用相邻可用格。
- Agent C 不能只看 Agent B 文字汇报，必须核对最新云端结果包。

## 未来扩展点

- 更明确的战役目标、失败条件和胜利结算。
- 将领详情、技能范围预览、技能冷却和升级树。
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
- 派使停战后，被条约保护的攻击必须被阻止。
- 跳过单位必须消耗移动和行动。
- AI 能移动到攻击范围并攻击。
- AI 意图必须能预测直接攻击和夺城，且不改变状态。
