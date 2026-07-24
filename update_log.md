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
- 当前玩法：六边形地图、地形、城市、阵营、军团、移动、攻击、反击、占城、招募、科技、任务 requirement、战役目标、胜负结算、结束保护、外交、城市扩建、城市经营与招募读板、军团训练、将领任命、军团成长决策读板、军团成长优先级读板、主动技能、技能冷却、将领详情读板、将领指挥链读板、将领战机威胁桥接读板、将令技能入口链路、将领技能目标与收益读板、被动贡献、战功状态、军团编制与成长读板、选中军团处境命令入口读板、选中军团军令窗口读板、战役推进线 HUD、地图侦察视角 HUD、战术命令建议与补线路径读板、本方将领协同与战术连携读板、将领协同步骤读板、机动落点与地图风险读板、战场焦点与将领机会读板、战场目标链路、战场态势交汇链路、敌情交战闭环 HUD、目标线地图叠层、阶段聚焦、阶段命令预览与联动高亮、地图控制与威胁热区读板、主动地图叠层图例、AI 作战计划与时间线读板、敌方将领协同读板、敌方将领威胁读板、敌情反制建议读板、反制落点/目标地图叠层、反制指令聚焦、反制命令链高亮与反制焦点链路、战术姿态与姿态预览、AI 回合、AI 主攻优先执行、敌军意图预判、敌军意图六边形路径/目标叠层、战线压力读板、战局态势面板。
- 当前测试入口：Swift Testing、Gameplay Smoke、项目结构检查、SwiftUI 类型检查、战斗页预览图渲染、无签名 Xcode 构建。
- 当前协作系统：已建立 `AGENTS.md`、`update_log.md`、`md/prompt/`、`md/test/test.md`、`md/flow/flow.md`、`md/flow/flowchart.md`，默认按 `main` 直推、GitHub Actions 云端重验证、Agent C 下载未加密结果包复判，并具备未来由 Agent X 主控调度 Agent A/B/C 多轮循环的文档基线。
- 当前 CI 入口：`.github/workflows/ci-results.yml`，在 `main` push 和手动触发时运行结构检查、SwiftPM 测试、Gameplay Smoke、RenderBattlePreview 和无签名 Xcode build，并上传 CI 结果包。

## 历史记录

### v0.53 / 地图层级与战场可读性重构

日期：2026-07-24

核心变更：

- `MapOverlayPresentation` 复用 `GameViewModel.selectedMapReconPerspective`，把敌路、反制、目标线、热区四种侦察视角映射为 route layer、tile overlay 和图例的显示优先级；攻击、技能、可达、选中与当前军议命令预览不受过滤影响。
- 地图底部原侦察 HUD、敌情闭环 HUD 和独立图例收敛为 `MapIntelligenceDockView`：横屏/宽屏单行、窄屏最多两行，四个 44pt 视角按钮、当前状态、闭环风险摘要和按视角排序的完整横向图例仍可达。
- `HexMetrics` 缩小地图上下保留区并按容器比例使用稳定垂直偏置，竖屏宽度受限时战区上移；窄屏顶部带改用同源短标题/战役进度，避免 390pt 标题硬截断。
- `UnitTokenView` 将单一将领星标升级为原创姓名首字圆形徽章，保留兵种、姿态、经验、冷却、行动状态和生命条。
- RenderBattlePreview 保留 v0.52 全部门禁，新增 `missingMapOverlayFocusStrategy` 与 `missingMapIntelligenceDock`，核对四视角显示映射和三尺寸六图的红/青/金视角按钮情报坞。
- 首次 v0.53 云端六图复判发现紧凑图例在 AppKit 离屏快照中没有物化横向滚动内容；后续修复让紧凑坞直接绘制按当前视角排序的前三个图例与剩余数量，完整图例继续保留在 accessibility 描述，非紧凑场景才使用横向滚动。同时把情报坞像素门禁拆分为按钮区与图例区，防止空白图例误通过。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.53；README、flow、flowchart、test 和 prompt README 同步真实 UI 数据流与云端验收要求。

关键文件：

- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.53（地图层级与战场可读性重构）.md`
- `update_log.md`

验证结果：

- 按人工要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- 初始实现 commit `4a4f2409869ba9ab8df7d87ba858ee83b1a99395` 的 run `30067466031` 虽然 CI 成功，但 Agent C 六图复判发现紧凑图例空白，因此未通过人工验收；修复 commit `e968ba7724bd728766bc660aed9db910c9be730a` 的 run `30068603870` 被新增图例像素门禁正确拦截。
- 最终修复 commit `af1bfd2af1e25b3c2030fbb73f77b6aa55a5febc` 对应 GitHub Actions run `30069308442`、attempt `1`、artifact `RomeLegions-ci-v0.53-main-af1bfd2-run30069308442-attempt1`；manifest 的结构检查、Swift Testing、Gameplay Smoke、RenderBattlePreview、Xcode build 和总体结果均为 `success`，JUnit 为 5 项、0 失败，Swift Testing 为 88 项通过。
- Agent C 已复判六张 PNG：横屏/宽屏单行情报坞与 390pt 两行情报坞均显示按当前视角排序的紧凑图例和剩余数量，窄屏标题、将领首字徽章、地图、右侧工具和底部命令坞无不合理遮挡。v0.53 正式验收通过。

遗留事项：

- 本轮没有修改 `GameState`、`GameViewModel` 派生规则、AI 评分/执行、敌军意图、战斗/任务/城市/成长/外交规则或存档结构；侦察视角只改变 SwiftUI 显示优先级。
- 地图材质、正式人物资产、将领池、AI 多步规划和动画系统仍留待后续独立版本。

### v0.52 / 地图主导战斗壳层 UI 重构

日期：2026-07-13

核心变更：

- `BattleView` 默认改为薄顶部资源带、全宽主地图、五类边缘工具、可关闭覆盖式抽屉和选择驱动底部命令坞，不再常驻完整/紧凑右侧栏或把竖屏地图固定为 45%。
- 情报军令、战场、敌情、元老院和战报抽屉复用原选择、军令、战场焦点、战局、敌情、科技、外交、任务与日志 panel；抽屉分类只保存在 SwiftUI 本地 `@State`，不改变 `GameViewModel` 或 `GameState`。
- 军团命令坞直接展示阵营/兵种、生命、姿态、将领和攻击、技能、军令、休整、跳过入口；城市命令坞展示归属、城防、产出、部署以及扩建/招募入口；地块选择保留身份和完整情报入口。
- 紧凑顶部资源读板继续展示金币、粮草、铁、科学和威望五项资源；地图单位兵牌生命条新增数值，城市名和城防就地读板保持不变。
- `Tools/RenderBattlePreview/main.swift` 将紧凑命令区与城市读板采样迁移到底部命令坞，并新增 `missingMapDominantBattleShell`，检查三尺寸六张图的中央地图、边缘工具和底部命令坞。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.52；README、flow、flowchart、test 和 prompt README 同步新壳层与云端验收。

关键文件：

- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.52（地图主导战斗壳层UI重构）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- Agent B 首次实现提交 `779ed2dacfdc0345bb56eb5e00c8fa5899038a35` 已直推 `origin/main`；GitHub Actions run `29219592639` attempt `1` 与 artifact `RomeLegions-ci-v0.52-main-779ed2d-run29219592639-attempt1` 的结构检查、SwiftPM、Gameplay Smoke、RenderBattlePreview 和 Xcode build 虽全部为 success，但 Agent C 逐图发现六张 PNG 的底部命令坞操作区均为空、右侧工具轨遮挡顶部 HUD，且原上下对称采样会误把顶部内容算作底部命令坞，因此正式判定不通过。
- 修复提交 `413e1218bd10db927f09eecec26adc9d8cccfc8e` 将命令区改为明确尺寸的专用按钮、为状态条预留工具轨安全区，并把 Render 门禁迁移到真实底部坞；GitHub Actions run `29221031604` attempt `1` 的结构检查、88 项 Swift Testing、Gameplay Smoke 和 Xcode build 成功，但 RenderBattlePreview 在首张 932×430 单位图抛出 `missingMapDominantBattleShell`。artifact `RomeLegions-ci-v0.52-main-413e121-run29221031604-attempt1` 只包含该单位图，显示命令按钮与 HUD 已恢复，失败来自比例工具轨采样未匹配真实顶部锚定布局；同时固定单位场景没有攻击目标，却被门禁要求必须出现红色攻击按钮。
- 修复提交 `4a97a39c04936c105e2e6e0e54fea1665ddb5707` 将窄屏单位命令坞固定为两行并保留攻击、技能、姿态、休整、跳过，增加专用相邻攻击夹具，并按真实顶部锚点采样五个工具按钮。GitHub Actions run `29596794324` attempt `1` 的结构检查、88 项 Swift Testing、Gameplay Smoke、地图/工具轨像素门禁和 Xcode build 成功，但随后单位命令坞色彩门禁抛出 `missingCompactCommandRender`；artifact 中的 932×430 单位图已清楚显示五个命令按钮，证明失败仍来自把 `NSBitmapImageRep.colorAt` 错当成底部原点，命令坞采样实际落在顶栏。
- 修复提交 `1c3a5877a17a4b72a8075cedb815dad81fde79e1` 统一像素坐标为顶部原点。GitHub Actions run `29603952017` attempt `1` 的结构检查、88 项 Swift Testing、Gameplay Smoke、地图/工具轨像素门禁和 Xcode build 成功，但单位命令坞色彩门禁仍抛出 `missingCompactCommandRender`；artifact PNG 继续清楚显示全部五个命令按钮。对该云端 PNG 只读复算得到底部区域旧阈值信号 `bright=147`、`red=241`、`cyan=313`，说明 UI 与采样区域正确，剩余差异来自 AppKit 设备色彩空间转换下的绝对分量比较。
- 修复提交 `54ca77ecfdd0ed6afb2487f8ce1866bbf3a893e2` 将命令色识别改为通道相对优势并提高有效像素与场景差异门槛，同时把地图、工具、单位和城市签名写入 stderr。GitHub Actions run `29606848751` attempt `1` 的结构检查、SwiftPM、Gameplay Smoke、Render 步骤后的 Xcode build 与 artifact 上传均完成，但聚合结果记录 `renderPreviewOutcome=failure`，Render 以 exit `133` 结束，正式结论仍为不通过；artifact `RomeLegions-ci-v0.52-main-54ca77e-run29606848751-attempt1`（ID `8417416663`）仅生成横屏单位/城市两张 PNG 后抛出 `missingDistinctCommandDockRender`。日志显示单位签名 `red=445, orange=180`、城市签名 `red=1015, orange=1243`，两图目视均无空坞、按钮缺失或工具轨遮挡，证明失败来自色彩分类而非 UI 缺失。
- 修复提交 `1a65e28857f0946462a7746f9e3aa91300ec7f41` 收紧红色通道优势，使红/橙分类互斥，并为单位/城市差异 guard 增加 stderr 签名。GitHub Actions run `29884652850` attempt `1` 与 artifact `RomeLegions-ci-v0.52-main-1a65e28-run29884652850-attempt1` 的 manifest 精确匹配 `main` 与该 commit，结构检查、88 项 Swift Testing、Gameplay Smoke、RenderBattlePreview、无签名 Xcode build 和聚合测试均为 success，JUnit 为 5/0。六张 PNG 尺寸、中央地图、五按钮工具轨、单位/城市就地标记、横竖屏命令坞及攻击、技能、姿态、休整、跳过、扩建、招募入口均完成目视复判，无空坞、裁切或 HUD/工具重叠；v0.52 正式验收通过。

遗留事项：

- 本轮没有修改 `GameState`、`GameViewModel`、AI 评分/执行、敌军意图、战斗/任务/城市/成长/外交规则或存档结构。
- 本轮只完成地图主导战斗壳层、按需抽屉、底部命令坞和现有代码绘制兵牌的信息层级重排；地图材质、正式人物资产、将领池、AI 多步规划和动画系统留待后续独立版本。

### v0.51 / HUD 信号胶囊 UI 重构

日期：2026-07-11

核心变更：

- `BattleView` 新增通用 `ReadoutSignalPill`，统一地图 HUD / 战役读板信号胶囊的图标、标题、tint、透明度、padding、高度和圆角。
- `MapReconPerspectiveSignalPill` 改为复用 `ReadoutSignalPill`，保留原 wrapper 名称和调用语义。
- `EnemyEngagementLoopHUDView.signalStrip(limit:)` 和 `CampaignAdvanceReadoutView.signalStrip(limit:)` 改为复用 `ReadoutSignalPill`，symbol 与 tint 映射仍留在各自 view 内。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.51。
- README、flow、test 和 prompt README 同步 HUD 信号胶囊共享组件和 v0.51 Agent A 提示词。

关键文件：

- `RomeLegionsApp/Views/BattleView.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.51（HUD信号胶囊UI重构）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- Agent B 已将实现提交 `4d8f621da3502a40ad2f879def8911870c0e206e` 直推 `origin/main`。
- Agent C 下载并复判 GitHub Actions 结果包 `RomeLegions-ci-v0.51-main-4d8f621-run29144693002-attempt1`，run id `29144693002`，run attempt `1`，manifest 对应 `main` / `4d8f621da3502a40ad2f879def8911870c0e206e` / `v0.51`。
- manifest 显示 `staticChecksOutcome`、`swiftTestsOutcome`、`gameplaySmokeOutcome`、`renderPreviewOutcome`、`buildOutcome`、`testOutcome` 均为 `success`；JUnit 记录 `tests="5"`、`failures="0"`；Swift Testing 日志记录 `88 tests` passed；Gameplay Smoke 输出 `Gameplay smoke test passed.`；RenderBattlePreview 生成 6 张非空 PNG；Xcode build 日志记录 `** BUILD SUCCEEDED **`。
- Agent C 核对 `BattleView` 已存在 `ReadoutSignalPill`，且 `MapReconPerspectiveSignalPill`、敌情交战闭环与战役推进线 signal strip 复用该组件；symbol/tint 映射仍留在各自 view。
- Agent C 复看宽屏、横屏和竖屏单位场景 PNG，地图侦察视角、敌情交战闭环和战役推进线信号胶囊仍可读，未见本轮重构引入的明显遮挡、挤压或异常换行。

遗留事项：

- 本轮没有修改 `GameState`、`GameViewModel` 派生字段、AI 评分、AI 作战计划、敌军意图、地图 overlay、战役任务、移动、攻击、技能、姿态、城市、训练、任命、外交、存档或胜负结算。
- 本轮只处理地图侦察视角 HUD、敌情交战闭环 HUD 和战役推进线读板的信号胶囊 UI 结构复用，不新增读板信息、按钮、命令队列或自动执行行为。

### v0.50 / 战斗读板标签行 UI 重构

日期：2026-07-11

核心变更：

- `BattleView` 新增通用 `ReadoutLabelRow`，统一短读板标签行的图标、标题、值、标题宽度、透明度和缩放参数。
- `BattlefieldConvergenceLabelRow`、`SelectedUnitSituationLabelRow` 和 `SelectedUnitOrderWindowLabelRow` 改为复用 `ReadoutLabelRow`，保留原 wrapper 名称和调用语义，避免扩大调用点变更。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.50。
- README、flow、flowchart、test 和 prompt README 同步战斗读板共享标签行组件、云端 artifact 版本和 v0.50 Agent A 提示词。

关键文件：

- `RomeLegionsApp/Views/BattleView.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.50（战斗读板标签行UI重构）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- Agent B 已将实现提交 `8594c1c7ec394f2bdeb9c97297f71ca4b98cb1a1` 直推 `origin/main`。
- Agent C 下载并复判 GitHub Actions 结果包 `RomeLegions-ci-v0.50-main-8594c1c-run29134820234-attempt1`，run id `29134820234`，run attempt `1`，manifest 对应 `main` / `8594c1c7ec394f2bdeb9c97297f71ca4b98cb1a1` / `v0.50`。
- manifest 显示 `staticChecksOutcome`、`swiftTestsOutcome`、`gameplaySmokeOutcome`、`renderPreviewOutcome`、`buildOutcome`、`testOutcome` 均为 `success`；JUnit 记录 `tests="5"`、`failures="0"`；Swift Testing 日志记录 `88 tests` passed；Gameplay Smoke 输出 `Gameplay smoke test passed.`；RenderBattlePreview 生成 6 张非空 PNG；Xcode build 日志记录 `** BUILD SUCCEEDED **`。
- Agent C 复看宽屏、横屏和竖屏单位场景，战场态势交汇、选中军团处境和军令窗口短标签行可读，未见本轮重构引入的明显遮挡、挤压或异常换行。

遗留事项：

- 本轮没有修改 `GameState`、`GameViewModel` 派生字段、AI 评分、AI 作战计划、敌军意图、移动、攻击、技能、姿态、任务、城市、训练、任命、外交、存档或胜负结算。
- 本轮只处理战场态势交汇、选中军团处境和选中军团军令窗口等短标签行的 UI 结构复用，不新增读板信息、按钮、命令队列或自动执行行为。

### v0.49 / AI 作战计划时间线读板

日期：2026-07-07

核心变更：

- `GameViewModel` 新增 `AIOperationalPlanTimelineStepReadout`，并在 `AIOperationalPlanSummary` 暴露 `timelineSteps`、`timelineLabel` 和 `timelineAccessibilityLabel`，把核心 `AIOperationalPlanReport.steps` 转成角色、军团、意图、起点、落点、目标、姿态、预计影响和详情可读的 UI 派生数据。
- `BattleView` 在敌情计划卡逐条展示 AI 作战计划行动队列，战局计划行显示压缩时间线；不新增按钮、命令队列或自动执行。
- `Tools/RenderBattlePreview/main.swift` 新增 `missingAIOperationalPlanTimelineReadout` 断言，覆盖时间线与核心 steps 的数量同源、关键字段可读、固定预览样本包含 `carthage-hunter` 主攻推进，以及读取时间线不改变核心状态。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.49。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步 AI 作战计划时间线读板和 v0.49 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.49（AI作战计划时间线读板）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- Agent B 已将实现提交 `cb0f74076fe94cab72017f4e2e2a4be6593d06f2`、编译收敛提交 `b37d49b91a5d4e1efece2f5cfd82256f67744e2c`、`05f84f629f8abd92293ffb832aa93d970726531f`、`753cc8d5f8717d0361dbadde6738c240058bfc3c` 和最终返回值修复提交 `da13a4a60bb70ede438866fec159e887cbed6d32` 直推 `origin/main`。
- Agent C 下载并复判最新 GitHub Actions 结果包 `RomeLegions-ci-v0.49-main-da13a4a-run28858374803-attempt1`，run id `28858374803`，run attempt `1`，manifest 对应 `main` / `da13a4a60bb70ede438866fec159e887cbed6d32` / `v0.49`。
- manifest 显示 `staticChecksOutcome`、`swiftTestsOutcome`、`gameplaySmokeOutcome`、`renderPreviewOutcome`、`buildOutcome`、`testOutcome` 均为 `success`；JUnit 记录 `tests="5"`、`failures="0"`；Swift Testing 日志记录 `88 tests` passed；Gameplay Smoke 输出 `Gameplay smoke test passed.`；RenderBattlePreview 生成 6 张非空 PNG 且未出现 `missingAIOperationalPlanTimelineReadout`；Xcode build 日志记录 `** BUILD SUCCEEDED **`。

遗留事项：

- 本轮没有改写 AI 评分、作战计划生成、真实 AI 执行顺序、移动、攻击、技能释放、姿态、战斗结算、任务、城市、装备、升级树、外交界面、存档 UI 或建筑树。
- AI 作战计划时间线读板只解释现有 `AIOperationalPlanReport.steps`，不自动下令，不反向影响敌军意图或 `GameState`。

### v0.48 / 将领协同步骤读板

日期：2026-07-07

核心变更：

- `GameViewModel` 新增 `CommanderSynergyStepReadout`，并在 `CommanderSynergySummary` 暴露 `stepReadouts`、`stepSequenceLabel` 和 `stepAccessibilityLabel`，把核心 `CommanderSynergyReport.steps` 转成角色、军团、姿态、位置、目标和详情可读的 UI 派生数据。
- `BattleView` 在将令卡展示将领协同步骤读板；完整卡逐条显示前几步，紧凑卡保留步骤序列，均不新增按钮或自动命令。
- `Tools/RenderBattlePreview/main.swift` 新增 `missingCommanderSynergyStepReadout` 断言，覆盖 `stepReadouts` 与核心 steps 的数量和字段同源、步骤序列/无障碍文案可读，以及读取不改变核心状态。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.48。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步将领协同步骤读板和 v0.48 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.48（将领协同步骤读板）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- Agent B 待将实现提交并直推 `origin/main`，由 GitHub Actions 产出 v0.48 结果包后交 Agent C 复判。

遗留事项：

- 本轮没有改写将领协同评分、步骤生成、目标选择、战斗结算、技能结算、AI 决策、自动命令、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 将领协同步骤读板只解释现有 `CommanderSynergyReport.steps`，不改变移动、攻击、技能、姿态、AI、任务或城市结算。

### v0.47 / 战役推进线 HUD

日期：2026-07-07

核心变更：

- `GameViewModel` 新增 `CampaignAdvanceSignalKind`、`CampaignAdvanceSignal`、`CampaignAdvanceReadout` 和 `primaryCampaignAdvanceReadout`，只读组合首要任务、`campaignStatus.progressText`、战线压力、战场目标线、活动目标线阶段命令预览、地图侦察视角和战场态势交汇。
- `BattleView` 在顶部状态条新增“推进” chip，并在元老院任务面板展示战役推进线读板，说明当前战役目标如何落到地图目标线、前线风险和下一步入口。
- `Tools/RenderBattlePreview/main.swift` 新增 `missingCampaignAdvanceReadout` 断言，覆盖首要任务、进度、战线、目标线、活动阶段、侦察视角、态势交汇同源关系和只读快照。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.47。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步战役推进线 HUD 和 v0.47 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.47（战役推进线HUD）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- Agent B 待将实现提交并直推 `origin/main`，由 GitHub Actions 产出 v0.47 结果包后交 Agent C 复判。

遗留事项：

- 本轮没有实现任务规则改写、自动推进、自动目标线聚焦、自动侦察视角切换、自动反制、自动技能、命令队列、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 战役推进线 HUD 只解释当前已有任务、进度、战线压力、目标线、侦察视角和态势交汇，不改变任何移动、攻击、技能、姿态、AI、任务或城市结算。

### v0.46 / 地图侦察视角 HUD

日期：2026-07-07

核心变更：

- `GameViewModel` 新增 `MapReconPerspectiveKind`、`MapReconPerspectiveSignalKind`、`MapReconPerspectiveSignal`、`MapReconPerspectiveHUDReadout`、`selectedMapReconPerspective` 和 `mapReconPerspectiveHUDReadout`，按敌路、反制、目标线、热区/控区四类视角只读组合既有 overlay、summary、preview 和战场态势交汇。
- `selectMapReconPerspective(_:)` 只改变侦察视角 UI 状态和 banner；不改变 `GameState`、单位/城市选择态、反制聚焦、目标线聚焦、移动、攻击、技能或姿态。
- `BattleView` 在地图底部新增可点击的地图侦察视角 HUD，并在顶部状态条新增“侦察” chip；HUD 不过滤现有叠层，不替代主动地图图例。
- `Tools/RenderBattlePreview/main.swift` 新增 `missingMapReconnaissanceViewHUD` 断言，覆盖敌路、反制、目标线、热区/控区四类视角、同源引用、字段可读和切换视角不改变核心状态。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.46。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步地图侦察视角 HUD 和 v0.46 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.46（地图侦察视角HUD）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- Agent B 已将实现提交 `3c6d66c8fbd45e4b9575ce26ab5529d44c5469b8` 和云端 RenderBattlePreview 编译收敛修复提交 `55c9cb817f0449ea933c2e1dd27f42b40500b4ce` 直推 `origin/main`。
- Agent C 下载并复判最新 GitHub Actions 结果包 `RomeLegions-ci-v0.46-main-55c9cb8-run28842857357-attempt1`，run id `28842857357`，run attempt `1`，manifest 对应 `main` / `55c9cb817f0449ea933c2e1dd27f42b40500b4ce` / `v0.46`。
- manifest 显示 `staticChecksOutcome`、`swiftTestsOutcome`、`gameplaySmokeOutcome`、`renderPreviewOutcome`、`buildOutcome`、`testOutcome` 均为 `success`；JUnit 记录 `tests="5"`、`failures="0"`；Swift Testing 日志记录 `88 tests passed`；Gameplay Smoke 输出 `Gameplay smoke test passed.`；RenderBattlePreview 生成 6 张非空 PNG 且未出现 `missingMapReconnaissanceViewHUD`；Xcode build 日志记录 `** BUILD SUCCEEDED **`。
- 云端 RenderBattlePreview 阶段用时较长但最终成功；地图侦察视角 HUD 的四类视角、同源引用、切换只读快照和顶部侦察 chip 已由云端断言覆盖。

遗留事项：

- 本轮没有实现叠层过滤、自动反制、自动技能、目标线自动执行、命令队列、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 地图侦察视角 HUD 只解释当前已有的敌路、反制、目标线、热区/控区和态势交汇，不改变任何移动、攻击、技能、姿态、AI 或城市结算。

### v0.45 / 选中军团军令窗口读板

日期：2026-07-07

核心变更：

- `GameViewModel` 新增 `SelectedUnitOrderWindowStepKind`、`SelectedUnitOrderWindowStep`、`SelectedUnitOrderWindowReadout` 和 `selectedUnitOrderWindowReadout`，只读聚合选中军团处境读板、反制指令、目标线阶段、将领战机桥接、将领指挥链、将令技能入口、军议、机动、推荐姿态、敌情闭环和战场态势交汇。
- `SelectedUnitOrderWindowReadout` 输出开局、姿态、机动、打击、将令、反制、下一步、风险、compact、steps、同源 references 和无障碍文案；不新增核心评分、命令队列、自动反制、自动技能、自动移动、自动攻击或存档字段。
- `BattleView` 在完整/紧凑选中单位情报面板的处境读板之后展示军令窗口；紧凑版显示一行动作窗口和短 step，完整版显示开局/姿态、机动/打击、入口和下一步，不新增按钮。
- `Tools/RenderBattlePreview/main.swift` 新增 `missingSelectedUnitOrderWindowReadout` 断言，覆盖固定预览样本 `rome-legion-1` 的处境读板、反制指令、目标线阶段、将领战机桥接、将领指挥链、军议、机动、敌情闭环、战场态势交汇和推荐姿态同源关系，并检查读取读板不改变核心状态。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.45。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步选中军团军令窗口读板和 v0.45 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.45（选中军团军令窗口读板）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- Agent B 已将实现提交 `bf102983d9fbb99c919c556377d0c7919086ab26` 直推 `origin/main`。
- Agent C 下载并复判最新 GitHub Actions 结果包 `RomeLegions-ci-v0.45-main-bf10298-run28840341318-attempt1`，run id `28840341318`，run attempt `1`，manifest 对应 `main` / `bf102983d9fbb99c919c556377d0c7919086ab26` / `v0.45`。
- manifest 显示 `staticChecksOutcome`、`swiftTestsOutcome`、`gameplaySmokeOutcome`、`renderPreviewOutcome`、`buildOutcome`、`testOutcome` 均为 `success`；JUnit 记录 `tests="5"`、`failures="0"`；Swift Testing 日志记录 `88 tests passed`；Gameplay Smoke 输出 `Gameplay smoke test passed.`；RenderBattlePreview 生成 6 张非空 PNG 且未出现 `missingSelectedUnitOrderWindowReadout`；Xcode build 日志记录 `** BUILD SUCCEEDED **`。
- 云端宽屏单位预览显示“军团军令窗口”可读，横屏和竖屏命令面板未见明显裁切或遮挡。

遗留事项：

- 本轮没有实现自动技能、自动反制、目标线自动执行、命令队列、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 选中军团军令窗口只解释当前军团已有的处境入口、反制指令、目标线阶段、将领战机、军议、机动、姿态、敌情闭环和战场态势交汇，不改变任何移动、攻击、技能、姿态、AI 或城市结算。

### v0.44 / 将领战机威胁桥接读板

日期：2026-07-06

核心变更：

- `GameViewModel` 新增 `CommanderOpportunityBridgeSignalKind`、`CommanderOpportunityBridgeSignal`、`SelectedCommanderOpportunityBridgeReadout` 和 `selectedCommanderOpportunityBridgeReadout`，只读聚合选中将领 brief、将领指挥链、技能目标读板、将令技能入口、本方将令协同、首要敌方将领威胁、反制建议/指令、目标线阶段和敌情交战闭环。
- `SelectedCommanderOpportunityBridgeReadout` 输出战机、技能窗口、敌将威胁、反制入口、下一步、风险、compact、signals、同源 references 和无障碍文案；无选中单位或选中单位无将领时返回 nil，不新增核心评分、命令队列、自动技能、自动反制、目标线执行或存档字段。
- `BattleView` 在完整/紧凑将领卡内部展示将领战机威胁桥接短读板；紧凑版一行展示战机/敌将/入口，完整版两行展示机会/威胁与入口/下一步，不新增按钮。
- `Tools/RenderBattlePreview/main.swift` 新增 `missingCommanderOpportunityBridgeReadout` 断言，覆盖固定预览样本 `rome-legion-1` 的将领 brief、指挥链、技能目标、本方将令协同、首要敌将威胁、反制建议/指令、目标线阶段和敌情闭环同源关系，并检查读取读板不改变核心状态。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.44。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步将领战机威胁桥接读板和 v0.44 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.44（将领战机威胁桥接读板）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- Agent B 已将实现提交 `fdb3fdc9405cc43e669d5c4ba00e6acf19a5b297` 直推 `origin/main`。
- Agent C 下载并复判最新 GitHub Actions 结果包 `RomeLegions-ci-v0.44-main-fdb3fdc-run28812253649-attempt1`，run id `28812253649`，run attempt `1`，manifest 对应 `main` / `fdb3fdc9405cc43e669d5c4ba00e6acf19a5b297` / `v0.44`。
- manifest 显示 `staticChecksOutcome`、`swiftTestsOutcome`、`gameplaySmokeOutcome`、`renderPreviewOutcome`、`buildOutcome`、`testOutcome` 均为 `success`；JUnit 记录 `tests="5"`、`failures="0"`；Swift Testing 日志记录 `88 tests passed`；Gameplay Smoke 输出 `Gameplay smoke test passed.`；RenderBattlePreview 生成 6 张非空 PNG 且未出现 `missingCommanderOpportunityBridgeReadout`；Xcode build 日志记录 `** BUILD SUCCEEDED **`。
- 云端宽屏和竖屏预览复判显示将领战机威胁桥接读板可读，未见明显裁切或遮挡命令侧栏。

遗留事项：

- 本轮没有实现自动技能、自动反制、目标线自动执行、命令队列、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 将领战机威胁桥接读板只解释当前选中将领已有的技能目标、将令机会、敌将威胁、反制入口、目标线阶段和敌情闭环，不改变任何移动、攻击、技能、姿态、AI 或城市结算。

### v0.43 / 敌情交战闭环 HUD

日期：2026-07-07

核心变更：

- `GameViewModel` 新增 `EnemyEngagementLoopSignalKind`、`EnemyEngagementLoopSignal`、`EnemyEngagementLoopReadout` 和 `primaryEnemyEngagementLoopReadout`，只读聚合敌军路线、战线压力、敌将威胁、反制建议、反制指令预览、回应军团将领指挥链和战场态势交汇读板。
- `EnemyEngagementLoopReadout` 输出敌路、压力、敌将、反制、回应、下一步、风险、compact、signals、同源 references 和无障碍文案；不新增核心评分、命令队列、自动反制、目标线执行或存档字段。
- `BattleView` 在地图内新增敌情交战闭环 HUD，用一条紧凑提示展示敌路、压力、敌将、反制和回应；HUD 不新增按钮，不拦截地图点击。
- `Tools/RenderBattlePreview/main.swift` 新增 `missingEnemyEngagementLoopReadout` 断言，覆盖固定预览样本的敌军路线、战线压力、敌将威胁、反制建议、反制指令预览、回应军团将领指挥链和战场态势交汇同源关系，并检查读取读板不改变核心状态。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.43。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步敌情交战闭环 HUD 和 v0.43 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.43（敌情交战闭环HUD）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- Agent B 已将实现提交 `9318c36051133d696167e397b6cafee3fcbad25a` 直推 `origin/main`。
- Agent C 下载并复判最新 GitHub Actions 结果包 `RomeLegions-ci-v0.43-main-9318c36-run28807604819-attempt1`，run id `28807604819`，run attempt `1`，manifest 对应 `main` / `9318c36051133d696167e397b6cafee3fcbad25a` / `v0.43`。
- manifest 显示 `staticChecksOutcome`、`swiftTestsOutcome`、`gameplaySmokeOutcome`、`renderPreviewOutcome`、`buildOutcome`、`testOutcome` 均为 `success`；JUnit 记录 `tests="5"`、`failures="0"`；Swift Testing 日志记录 `88 tests passed`；Gameplay Smoke 输出 `Gameplay smoke test passed.`；RenderBattlePreview 生成 6 张非空 PNG 且未出现 `missingEnemyEngagementLoopReadout`；Xcode build 日志记录 `** BUILD SUCCEEDED **`。
- 云端宽屏、横屏和竖屏预览复判显示敌情交战闭环 HUD 可见，未见明显裁切或遮挡命令侧栏。

遗留事项：

- 本轮没有实现自动反制、自动技能、目标线自动执行、命令队列、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 敌情交战闭环 HUD 只解释当前敌军路线、压力、敌将威胁、反制指令和回应将领链，不改变任何移动、攻击、技能、姿态、AI 或城市结算。

### v0.42 / 将领指挥链读板

日期：2026-07-06

核心变更：

- `GameViewModel` 新增 `SelectedCommanderChainSignalKind`、`SelectedCommanderChainSignal`、`SelectedCommanderChainReadout` 和 `selectedCommanderChainReadout`，只读聚合选中将领 brief、技能目标、战功、将令入口、将令协同、目标线阶段和处境入口。
- `SelectedCommanderChainReadout` 输出被动、技能目标、战功、入口、summary、signals、同源 references 和无障碍文案；不新增核心评分、命令队列、自动技能、目标线执行或存档字段。
- `BattleView` 在完整/紧凑将领卡内部展示指挥链短读板；紧凑版一行显示被动、技能目标和入口，完整版保持短读板，不新增按钮。
- `Tools/RenderBattlePreview/main.swift` 新增 `missingCommanderChainReadout` 断言，覆盖固定预览样本 `rome-legion-1` 的将领 brief、技能目标、战功、将令入口、将令协同、目标线阶段、处境入口同源关系，并检查读取读板不改变核心状态。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.42。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步将领指挥链读板和 v0.42 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.42（将领指挥链读板）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- Agent B 已将实现提交 `20ebca7a77c2e5999444e1277516f991c62ab320` 直推 `origin/main`。
- Agent C 下载并复判最新 GitHub Actions 结果包 `RomeLegions-ci-v0.42-main-20ebca7-run28804023219-attempt1`，run id `28804023219`，run attempt `1`，manifest 对应 `main` / `20ebca7a77c2e5999444e1277516f991c62ab320` / `v0.42`。
- manifest 显示 `staticChecksOutcome`、`swiftTestsOutcome`、`gameplaySmokeOutcome`、`renderPreviewOutcome`、`buildOutcome`、`testOutcome` 均为 `success`；JUnit 记录 `tests="5"`、`failures="0"`；Swift Testing 日志记录 `88 tests passed`；Render battle preview 生成 6 张非空 PNG；Xcode build 日志记录 `** BUILD SUCCEEDED **`。

遗留事项：

- 本轮没有实现自动技能、自动反制、目标线自动执行、命令队列、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 将领指挥链读板只解释当前选中将领既有被动、技能目标、战功、将令、目标线和处境入口，不改变任何移动、攻击、技能、姿态、AI 或城市结算。

### v0.41 / 处境命令入口联动

日期：2026-07-06

核心变更：

- `GameViewModel` 新增 `SelectedUnitSituationCommandEntryKind`、`SelectedUnitSituationCommandEntry`，并扩展 `SelectedUnitSituationReadout` 的 `commandEntries`、主入口文案、入口摘要、反制/目标线/将领/姿态同源引用方法。
- `selectedUnitSituationReadout` 继续只读聚合选中军团压力、热区、控区、编制、军议、机动和将令，同时按反制指令预览、目标线阶段命令预览、将领技能入口、机动、军议、姿态建议生成命令入口 cue；不新增 `@Published` 状态、命令队列、自动执行或存档字段。
- `BattleView` 的选中军团处境卡改为展示入口 cue：紧凑版保留下一步并新增一条短入口行，完整版保持三行布局并把原“下一步”行替换为“入口”行。
- `Tools/RenderBattlePreview/main.swift` 扩展 `missingSelectedUnitSituationReadout` 断言，覆盖 `commandEntries` 非空、主入口 cue、入口无障碍文案、选中反制/目标线阶段/将领技能/姿态同源引用，并继续检查读取读板不改变核心状态。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.41。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步处境命令入口联动和 v0.41 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.41（处境命令入口联动）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- 实现提交 `8cc794e41e0e5e737b4be1c785ef6e8e0e236fb3` 已 push 到 `origin/main`，GitHub Actions run `28801045450` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.41-main-8cc794e-run28801045450-attempt1`。
- Agent C 复判已核对 manifest `version=v0.41`、`branch=main`、`commitSha=8cc794e41e0e5e737b4be1c785ef6e8e0e236fb3`、`runId=28801045450`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success。
- Swift Testing 日志显示 88 tests 通过，Gameplay Smoke 输出 `Gameplay smoke test passed.`，RenderBattlePreview 产出 6 张非空 PNG 且未出现 `missingSelectedUnitSituationReadout`、`missingBattlefieldConvergenceSummary`、`missingGeneralSkillTargetReadout`、`missingCommanderActionGuidance`、`missingBattleObjectiveStageLinkedHighlight`、`missingBattleObjectiveStageCommandPreview`、`missingBattleObjectiveStageFocus`、`missingBattleObjectiveMapOverlay`、`missingBattleObjectiveChainSummary`、`missingMapOverlayLegend` 或 `missingCountermeasure...`，Xcode build 日志以 `** BUILD SUCCEEDED **` 结束。

遗留事项：

- 本轮没有实现自动反制、目标线自动执行、命令队列、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 处境命令入口只解释当前选中军团应查看的既有反制、目标线、将领技能、机动、军议和姿态入口，不改变任何移动、攻击、技能、姿态、AI 或城市结算。

### v0.40 / 选中军团处境读板

日期：2026-07-06

核心变更：

- `GameViewModel` 新增 `SelectedUnitSituationSignalKind`、`SelectedUnitSituationSignal`、`SelectedUnitSituationReadout` 和 `selectedUnitSituationReadout`，只读聚合当前选中军团的战线压力、覆盖选中位置的威胁热区、脚下地图控区、军团编制、选中军议、首要机动落点和选中将令协同。
- `SelectedUnitSituationReadout` 输出压力、空间、机会、下一步、风险、signal 列表、同源 references 和无障碍文案；不新增核心评分、命令队列、地图叠层、自动执行或存档字段。
- `BattleView` 在完整/紧凑选中单位情报面板的基础属性后展示处境读板；紧凑版只显示状态和下一步，完整版显示压力、机会和下一步。
- `Tools/RenderBattlePreview/main.swift` 新增 `missingSelectedUnitSituationReadout` 断言，覆盖固定预览样本 `rome-legion-1` 在 `(3,3)` 的压力、热区、控区、编制、军议、机动、将令同源关系，并检查读取读板不改变核心状态。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.40。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步选中军团处境读板和 v0.40 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.40（选中军团处境读板）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- 实现提交 `bb605851c3fd093a0cc6932174043f37f23b38a6` 已 push 到 `origin/main`，GitHub Actions run `28796743246` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.40-main-bb60585-run28796743246-attempt1`。
- Agent C 复判已核对 manifest `version=v0.40`、`branch=main`、`commitSha=bb605851c3fd093a0cc6932174043f37f23b38a6`、`runId=28796743246`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success。
- Swift Testing 日志显示 88 tests 通过，Gameplay Smoke 输出 `Gameplay smoke test passed.`，RenderBattlePreview 产出 6 张非空 PNG 且未出现 `missingSelectedUnitSituationReadout`、`missingBattlefieldConvergenceSummary`、`missingGeneralSkillTargetReadout`、`missingCommanderActionGuidance`、`missingBattleObjectiveStageLinkedHighlight`、`missingBattleObjectiveStageCommandPreview`、`missingBattleObjectiveStageFocus`、`missingBattleObjectiveMapOverlay`、`missingBattleObjectiveChainSummary`、`missingMapOverlayLegend` 或 `missingCountermeasure...`，Xcode build 日志以 `** BUILD SUCCEEDED **` 结束。
- Agent C 目视核对宽屏单位场景 PNG，情报面板新增“处境”卡显示压力、机会和下一步，未见明显裁切、重叠或遮挡。

遗留事项：

- 本轮没有实现自动反制、目标线自动执行、命令队列、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 选中军团处境读板只解释当前选中军团已存在的压力、热区、控区、编制、军议、机动和将令信号，不改变任何移动、攻击、技能、姿态、AI 或城市结算。

### v0.39 / 战场态势交汇链路

日期：2026-07-06

核心变更：

- `GameViewModel` 新增 `BattlefieldConvergenceRole`、`BattlefieldConvergenceSignal`、`BattlefieldConvergenceSummary` 和 `primaryBattlefieldConvergenceSummary`，只读聚合首要目标线、首要反制建议、首要反制指令预览、活动目标线阶段、将领协同、机动落点、威胁热区和地图控区。
- `BattlefieldConvergenceSummary` 输出主线、回应、空间、下一步、风险、signal 列表、同源 references 和无障碍文案；不新增核心评分、命令队列、地图叠层或存档字段。
- `BattleView` 新增完整/紧凑战场态势交汇读板，并在战局面板顶部显示一条紧凑摘要；SwiftUI 只展示 ViewModel 派生字段，不重新计算热区、控区、路径、反制收益或目标线阶段。
- `Tools/RenderBattlePreview/main.swift` 新增 `missingBattlefieldConvergenceSummary` 断言，覆盖交汇读板与目标线、反制、反制指令预览、活动阶段、将令、机动、热区和控区的同源关系，并检查读取读板不改变核心状态。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.39。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步战场态势交汇链路和 v0.39 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.39（战场态势交汇链路）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- 实现提交 `66966e5db622f28ebcf2392ecd177e8954dcc087` 已 push 到 `origin/main`，GitHub Actions run `28793510015` attempt `1` 中 static checks、Swift Testing、Gameplay Smoke 和 Xcode build 为 success，但 RenderBattlePreview 因 v0.39 新增断言错误地要求交汇读板引用包含 `(3,3)` 的热区而失败，日志抛出 `missingBattlefieldConvergenceSummary`。
- 修复提交 `858893eee0207d7029da9b77073d5551d14666d5` 改为核对 `primaryThreatHeatZoneSummary` 同源后已 push 到 `origin/main`，GitHub Actions run `28793999969` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.39-main-858893e-run28793999969-attempt1`。
- Agent C 复判已核对 manifest `version=v0.39`、`branch=main`、`commitSha=858893eee0207d7029da9b77073d5551d14666d5`、`runId=28793999969`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success。
- Swift Testing 日志显示 88 tests 通过，Gameplay Smoke 输出 `Gameplay smoke test passed.`，RenderBattlePreview 产出 6 张非空 PNG 且未出现 `missingBattlefieldConvergenceSummary`、`missingGeneralSkillTargetReadout`、`missingCommanderActionGuidance`、`missingBattleObjectiveStageLinkedHighlight`、`missingBattleObjectiveStageCommandPreview`、`missingBattleObjectiveStageFocus`、`missingBattleObjectiveMapOverlay`、`missingBattleObjectiveChainSummary`、`missingMapOverlayLegend` 或 `missingCountermeasure...`，Xcode build 日志以 `** BUILD SUCCEEDED **` 结束。

遗留事项：

- 本轮没有实现自动反制、目标线自动执行、命令队列、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 战场态势交汇链路只解释既有目标线、反制、阶段预览、将令、机动、热区和控区之间的关系，不改变任何移动、攻击、技能、姿态、AI 或城市结算。

### v0.38 / 将领技能目标与收益读板

日期：2026-07-06

核心变更：

- `GameViewModel` 新增 `GeneralSkillTargetReadoutTarget`、`SelectedGeneralSkillTargetReadout` 和 `selectedGeneralSkillTargetReadout`，把选中单位主动技能预览中的受影响单位/城市转成目标数、目标类型、收益、地图标记数量、目标短列表和无障碍文案。
- `BattleView` 的完整/紧凑将领卡新增目标收益读板，展示当前技能目标、预计恢复或削城防、地图紫标数量和前几个目标名称；技能按钮 action、`.disabled(...)`、核心技能筛选、冷却、结算和 AI 行为保持不变。
- `Tools/RenderBattlePreview/main.swift` 新增 `missingGeneralSkillTargetReadout` 断言，覆盖目标数量、目标坐标、收益文案、地图标记提示、状态和无障碍文案与 `selectedGeneralSkillPreview` 同源。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.38。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步将领技能目标与收益读板和 v0.38 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.38（将领技能目标与收益读板）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、YAML/JSON/Plist 解析或脚本语法检查。说明：暂存前曾误执行一次空暂存区的 `git diff --check --cached`，没有检查本轮工作区 diff，也未作为验收依据；本轮正式验收只采用云端结果包。
- 实现提交 `296866def4df472686e8cf7506c92d3ea0e5756f` 已 push 到 `origin/main`，GitHub Actions run `28790625708` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.38-main-296866d-run28790625708-attempt1`。
- Agent C 复判已核对 manifest `version=v0.38`、`branch=main`、`commitSha=296866def4df472686e8cf7506c92d3ea0e5756f`、`runId=28790625708`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success。
- Swift Testing 日志显示 88 tests 通过，Gameplay Smoke 输出 `Gameplay smoke test passed.`，RenderBattlePreview 产出 6 张非空 PNG 且未出现 `missingGeneralSkillTargetReadout`、`missingCommanderActionGuidance`、`missingBattleObjectiveStageLinkedHighlight`、`missingBattleObjectiveStageCommandPreview`、`missingBattleObjectiveStageFocus`、`missingBattleObjectiveMapOverlay`、`missingBattleObjectiveChainSummary`、`missingMapOverlayLegend` 或 `missingCountermeasure...`，Xcode build 日志以 `** BUILD SUCCEEDED **` 结束。

遗留事项：

- 本轮没有实现一键发动技能、目标线自动执行、命令队列、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 将领技能目标与收益读板只解释当前技能预览已有目标和预计收益，不改变技能目标筛选、可用性、冷却、结算、移动、攻击、姿态或 AI 行为。

### v0.37 / 将令技能入口链路提示

日期：2026-07-06

核心变更：

- `GameViewModel` 新增 `CommanderActionGuidance`、`selectedCommanderActionGuidance` 和 `selectedGeneralSkillCommandButtonDetail`，把选中单位将领简报、主动技能预览、当前将令协同和目标线“2 将令”阶段 cue 串成同源技能入口提示。
- `BattleView` 的完整/紧凑将领卡状态行与技能按钮 detail 改为读取同一 ViewModel 引导；按钮 action、`.disabled(...)`、目标线聚焦、技能释放、核心规则和 AI 决策保持不变。
- `Tools/RenderBattlePreview/main.swift` 新增 `missingCommanderActionGuidance` 断言，覆盖将领简报、技能预览、将令协同、目标线 `.synergy` 阶段 cue、按钮 detail 和只读联动关系。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.37。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步将令技能入口链路和 v0.37 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.37（将令技能入口链路提示）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- 实现提交 `69258f6ed1b4e0eb41bdda515c1178a8f5529937` 已 push 到 `origin/main`，GitHub Actions run `28788827475` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.37-main-69258f6-run28788827475-attempt1`。
- Agent C 复判已核对 manifest `version=v0.37`、`branch=main`、`commitSha=69258f6ed1b4e0eb41bdda515c1178a8f5529937`、`runId=28788827475`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success。
- Swift Testing 日志显示 88 tests 通过，Gameplay Smoke 输出 `Gameplay smoke test passed.`，RenderBattlePreview 产出 6 张非空 PNG 且未出现 `missingCommanderActionGuidance`、`missingBattleObjectiveStageLinkedHighlight`、`missingBattleObjectiveStageCommandPreview`、`missingBattleObjectiveStageFocus`、`missingBattleObjectiveMapOverlay`、`missingBattleObjectiveChainSummary`、`missingMapOverlayLegend` 或 `missingCountermeasure...`，Xcode build 日志以 `** BUILD SUCCEEDED **` 结束。

遗留事项：

- 本轮没有实现一键发动技能、目标线自动执行、命令队列、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 将令技能入口链路只解释当前将领技能入口与既有“2 将令”阶段之间的关系，不改变技能可用性、结算、冷却、移动、攻击、姿态或 AI 行为。

### v0.36 / 目标线阶段联动高亮

日期：2026-07-06

核心变更：

- `BattleObjectiveStageCommandPreview` 新增命令入口、推荐姿态、攻击和技能阶段 cue，并提供当前阶段执行单位判断；`GameViewModel` 新增 `activeBattleObjectiveStageCommandPreview` 与 `activeBattleObjectiveStageRole`，统一地图徽标和目标线阶段读板的高亮来源。
- `BattleView` 将目标线地图阶段徽标、目标线卡片阶段按钮、姿态推荐按钮、攻击按钮和将领技能入口接到同一阶段 cue；反制目标和反制推荐姿态仍保持最高优先级。
- 目标线阶段联动高亮只读取现有 ViewModel 派生数据，不改变 `Button` action、`.disabled(...)`、`GameState`、AI 决策、攻击/移动/技能/姿态结算或核心规则。
- `Tools/RenderBattlePreview/main.swift` 新增 `missingBattleObjectiveStageLinkedHighlight` 断言，覆盖 active/focused/selected 阶段预览、地图 overlay、推荐姿态 cue、攻击 cue、技能 cue 与只读快照。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.36。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步目标线阶段联动高亮和 v0.36 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.36（目标线阶段联动高亮）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- 实现提交 `57ddaa6e9a68b102d2bb421dd8543acf08445ab7` 已 push 到 `origin/main`，GitHub Actions run `28787049108` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.36-main-57ddaa6-run28787049108-attempt1`。
- Agent C 复判已核对 manifest `version=v0.36`、`branch=main`、`commitSha=57ddaa6e9a68b102d2bb421dd8543acf08445ab7`、`runId=28787049108`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success。
- Swift Testing 日志显示 88 tests 通过，Gameplay Smoke 输出 `Gameplay smoke test passed.`，RenderBattlePreview 产出 6 张非空 PNG 且未出现 `missingBattleObjectiveStageLinkedHighlight`、`missingBattleObjectiveStageCommandPreview`、`missingBattleObjectiveStageFocus`、`missingBattleObjectiveMapOverlay`、`missingBattleObjectiveChainSummary`、`missingMapOverlayLegend` 或 `missingCountermeasure...`，Xcode build 日志以 `** BUILD SUCCEEDED **` 结束。

遗留事项：

- 本轮没有实现目标线自动执行、一键移动、一键攻击、一键技能、一键切姿态、命令队列、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 阶段联动高亮只解释当前目标线与既有命令入口的关系，不声明为真实命令队列，也不改变既有 AI、技能、攻击、移动、城市、外交或胜负规则。

### v0.35 / 目标线阶段命令预览

日期：2026-07-06

核心变更：

- `GameViewModel` 新增 `BattleObjectiveStageCommandStep`、`BattleObjectiveStageCommandPreview` 和目标线阶段命令预览派生属性，把焦点、将令、机动和军议阶段映射到既有命令入口、推荐姿态、落点、目标、技能状态、下一步和阻塞原因。
- 阶段命令预览与 `BattleObjectiveChainSummary`、`BattleObjectiveMapOverlay` 同源，只读取现有 summary、overlay 和 `GameState` 只读查询；不会移动、攻击、发动技能、切换姿态或修改核心规则。
- `BattleObjectiveChainCardView` 在阶段定位按钮下展示当前聚焦阶段或主阶段命令预览；完整/紧凑军令面板会展示选中罗马单位关联的目标线阶段命令预览。
- 攻击按钮可在非反制优先场景追加目标线目标提示，但不改变 action 或 disabled 规则。
- `Tools/RenderBattlePreview/main.swift` 新增 `missingBattleObjectiveStageCommandPreview` 断言，覆盖阶段预览同源字段、按钮文案、步骤、聚焦切换和核心状态不变，并把技能冷却纳入只读快照。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.35。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步目标线阶段命令预览和 v0.35 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.35（目标线阶段命令预览）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- 实现提交 `257df755e1bdae22aed99f706bf71bafd084337a` 已 push 到 `origin/main`，GitHub Actions run `28782710719` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.35-main-257df75-run28782710719-attempt1`。
- Agent C 复判已核对 manifest `version=v0.35`、`branch=main`、`commitSha=257df755e1bdae22aed99f706bf71bafd084337a`、`runId=28782710719`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success。
- Swift Testing 日志显示 88 tests 通过，Gameplay Smoke 输出 `Gameplay smoke test passed.`，RenderBattlePreview 产出 6 张非空 PNG 且未出现 `missingBattleObjectiveStageCommandPreview`、`missingBattleObjectiveStageFocus`、`missingBattleObjectiveMapOverlay`、`missingBattleObjectiveChainSummary`、`missingMapOverlayLegend` 或 `missingCountermeasure...`，Xcode build 日志以 `** BUILD SUCCEEDED **` 结束。

遗留事项：

- 本轮没有实现目标线自动执行、一键移动、一键攻击、一键技能、一键切姿态、命令队列、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 阶段命令预览只解释当前已有命令入口，不声明为真实命令队列，也不改变既有 AI、技能、攻击、移动、城市、外交或胜负规则。

### v0.34 / 战场目标线阶段聚焦

日期：2026-07-06

核心变更：

- `GameViewModel` 新增 `focusedBattleObjectiveRole`、`focusedBattleObjectiveOverlay` 和 `focusPrimaryBattleObjectiveStage(_:)`，把 v0.33 目标线阶段变成只读定位入口。
- 目标线阶段聚焦只更新 `selectedPosition`、可执行罗马单位选择、`selectedCityID`、聚焦 role 和 banner；不会调用 `GameState` 写命令，不移动、不攻击、不发动技能、不切换姿态。
- `BattleObjectiveChainCardView` 新增阶段定位按钮，可定位“1 焦点、2 将令、3 机动、4 军议”；按钮文案保持短小并提供无障碍标签。
- 地图目标线阶段徽标会对当前聚焦阶段显示轻量外圈高亮，仍保持 `allowsHitTesting(false)`，不接管地图点击。
- `Tools/RenderBattlePreview/main.swift` 新增 `missingBattleObjectiveStageFocus` 断言，覆盖机动、军议、焦点阶段聚焦、banner、聚焦 role、聚焦位置，以及单位、城市、资源、回合和当前势力核心状态不变。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.34。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步目标线阶段聚焦和 v0.34 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.34（战场目标线阶段聚焦）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- 实现提交 `eecd6bee617bac9f18a6c63e9b961c05c99423f9` 已 push 到 `origin/main`，GitHub Actions run `28780471889` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.34-main-eecd6be-run28780471889-attempt1`。
- Agent C 复判已核对 manifest `version=v0.34`、`branch=main`、`commitSha=eecd6bee617bac9f18a6c63e9b961c05c99423f9`、`runId=28780471889`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success。
- Swift Testing 日志显示 88 tests 通过，Gameplay Smoke 输出 `Gameplay smoke test passed.`，RenderBattlePreview 产出 6 张非空 PNG 且未出现 `missingBattleObjectiveStageFocus`、`missingBattleObjectiveMapOverlay`、`missingBattleObjectiveChainSummary`、`missingMapOverlayLegend` 或 `missingCountermeasure...`，Xcode build 日志以 `** BUILD SUCCEEDED **` 结束。

遗留事项：

- 本轮没有实现目标线自动执行、一键移动、一键攻击、一键技能、一键切姿态、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 目标线阶段聚焦只帮助玩家定位已有焦点、将令、机动和军议阶段，不声明为真实移动路径，也不改变既有 AI、技能、攻击、移动、城市、外交或胜负规则。

### v0.33 / 战场目标线地图叠层

日期：2026-07-06

核心变更：

- `BattleObjectiveChainSummary` 增加同源地图叠层派生：`BattleObjectiveMapOverlay`、`BattleObjectivePositionOverlay`、`BattleObjectiveRouteSegment` 与 `BattleObjectiveMapRole`，把“1 焦点、2 将令、3 机动、4 军议”目标线转成只读阶段位置和路线线段。
- `GameViewModel` 新增 `primaryBattleObjectiveMapOverlay`、`battleObjectiveRouteSegments`、`battleObjectiveOverlaysByPosition` 和 `battleObjectiveOverlayPositions`，按位置保留多个阶段，避免同格阶段互相覆盖。
- `BattleView` 在地图上展示战场目标线金色连线和阶段徽标，并将 tile accessibility 同步读出阶段、坐标和链路摘要；叠层不接管点击，不改变按钮 action 或 disabled 规则。
- 主动地图叠层图例新增“目标线”，只在目标线 overlay 存在时显示。
- `Tools/RenderBattlePreview/main.swift` 新增 `missingBattleObjectiveMapOverlay` 断言，覆盖目标线 overlay、route segments、按位置索引、阶段位置、链路引用一致性和图例。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.33。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步战场目标线地图叠层和 v0.33 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.33（战场目标线地图叠层）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- 实现提交 `2db8463fa97fb1245295975dcd410d6992f5f157` 已 push 到 `origin/main`，GitHub Actions run `28778604793` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.33-main-2db8463-run28778604793-attempt1`。
- Agent C 复判已核对 manifest `version=v0.33`、`branch=main`、`commitSha=2db8463fa97fb1245295975dcd410d6992f5f157`、`runId=28778604793`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success。
- Swift Testing 日志显示 88 tests 通过，Gameplay Smoke 输出 `Gameplay smoke test passed.`，RenderBattlePreview 产出 6 张非空 PNG 且未出现 `missingBattleObjectiveMapOverlay`、`missingBattleObjectiveChainSummary`、`missingBattlefieldFocus`、`missingCommanderSynergySummary`、`missingManeuverOptionSummary`、`missingTacticalRecommendationSummary`、`missingMapOverlayLegend` 或 `missingCountermeasure...`，Xcode build 日志以 `** BUILD SUCCEEDED **` 结束。

遗留事项：

- 本轮没有实现目标线自动执行、一键移动、一键攻击、一键技能、一键切姿态、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 战场目标线地图叠层只解释已有焦点、将令、机动和军议的空间关系，不声明为真实移动路径，也不改变既有 AI、技能、攻击、移动、城市、外交或胜负规则。

### v0.32 / 战场目标链路

日期：2026-07-06

核心变更：

- `BattlefieldFocusSummary`、`CommanderSynergySummary`、`ManeuverOptionSummary` 和 `TacticalRecommendationSummary` 新增目标链路 cue 与无障碍文案补充。
- `GameViewModel` 新增 `BattleObjectiveChainSummary` 和 `primaryBattleObjectiveChainSummary`，只读组合首要战场焦点、当前将令、首要机动落点和选中单位军议，输出“1 焦点、2 将令、3 机动、4 军议”的战场目标线。
- `BattleView` 的战场面板新增目标链路卡，紧凑布局显示目标线摘要；焦点、将令、机动和军议卡片展示各自阶段 cue。
- `Tools/RenderBattlePreview/main.swift` 新增 `missingBattleObjectiveChainSummary` 断言，覆盖目标链路字段非空、四类摘要引用一致性和四类 cue 可读。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.32。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步战场目标链路和 v0.32 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.32（战场目标链路）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- 实现提交 `0970e230579f8c3c8e75575a2f335a33c27acd00` 已 push 到 `origin/main`，GitHub Actions run `28776700641` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.32-main-0970e23-run28776700641-attempt1`。
- Agent C 复判已核对 manifest `version=v0.32`、`branch=main`、`commitSha=0970e230579f8c3c8e75575a2f335a33c27acd00`、`runId=28776700641`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success。
- Swift Testing 日志显示 88 tests 通过，Gameplay Smoke 输出 `Gameplay smoke test passed.`，RenderBattlePreview 产出 6 张非空 PNG 且未出现 `missingBattleObjectiveChainSummary`、`missingBattlefieldFocus`、`missingCommanderSynergySummary`、`missingManeuverOptionSummary` 或 `missingTacticalRecommendationSummary`，Xcode build 日志以 `** BUILD SUCCEEDED **` 结束。

遗留事项：

- 本轮没有实现自动执行目标线、一键移动、一键攻击、一键技能、一键切姿态、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 战场目标链路只用于把焦点、将令、机动和军议读板串成同一条只读提示线，不改变既有 AI、技能、攻击、移动、城市、外交或胜负规则。

### v0.31 / 反制焦点链路

日期：2026-07-06

核心变更：

- `CountermeasureMapRole` 新增 1/2/3 阶段序号与阶段标签，`CountermeasurePositionOverlay` 和 `CountermeasureMapOverlay` 暴露焦点文案、链路摘要和包含链路的无障碍文案。
- `CountermeasureSummary` 新增“1 回应 -> 2 落点 -> 3 目标”链路摘要；`CountermeasureCommandPreview` 复用同一链路摘要，新增目标阶段 cue 和地图目标 overlay 判断 helper。
- `BattleView` 的反制地图标记在圆形徽标中显示阶段序号；当反制目标格同时是普通攻击目标时，仍会在攻击框之上补画“3 目标”标记。
- 完整和紧凑军令面板的反制指令预览显示同一焦点链路，反制攻击按钮 detail 和无障碍文案引用“3 目标”cue；按钮 action 和 disabled 规则保持不变。
- `Tools/RenderBattlePreview/main.swift` 扩展云端预览断言，覆盖反制地图阶段标签、焦点文案、链路摘要、无障碍文案、指令链路摘要、目标阶段 cue、地图目标 overlay 与攻击目标一致性。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.31。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步反制焦点链路和 v0.31 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.31（反制焦点链路）.md`
- `AGENTS.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- 实现提交 `1f0398d9873955c485d3f435a7521112081c153c` 已 push 到 `origin/main`，GitHub Actions run `28773744753` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.31-main-1f0398d-run28773744753-attempt1`。
- Agent C 复判已核对 manifest `version=v0.31`、`branch=main`、`commitSha=1f0398d9873955c485d3f435a7521112081c153c`、`runId=28773744753`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success。
- Swift Testing 日志显示 88 tests 通过，Gameplay Smoke 输出 `Gameplay smoke test passed.`，RenderBattlePreview 产出 6 张非空 PNG 且未出现 `missingCountermeasureCommandPreview`、`missingCountermeasureOverlay` 或 `missingCountermeasureSummary`，Xcode build 日志以 `** BUILD SUCCEEDED **` 结束。

遗留事项：

- 本轮没有实现自动执行反制、一键移动、一键攻击、一键切姿态、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 反制焦点链路只用于把地图阶段标记、反制卡、军令面板和攻击按钮 cue 串成同一条只读提示链，不改变既有 AI、技能、攻击、移动、城市、外交或胜负规则。

### v0.30 / 反制命令链高亮

日期：2026-07-06

核心变更：

- `CountermeasureCommandPreview` 新增命令链短标签、推荐姿态 cue、移动 cue、攻击 cue，并提供推荐姿态和反制攻击目标判断 helper，继续保持只读 UI 派生。
- `BattleView` 在 `CountermeasureCommandPreviewView` 展示命令链提示，并在 `TacticalOrderPreviewButtonContent` 标记反制推荐姿态按钮。
- 完整和紧凑军令面板的攻击按钮会在目标匹配当前反制建议时显示“反制攻击”与反制目标 cue；按钮 action 和 disabled 规则仍沿用原有 `viewModel.attack(target.id)` 和现有规则。
- `Tools/RenderBattlePreview/main.swift` 扩展反制指令断言，覆盖命令链短标签、姿态 cue、移动 cue、攻击 cue、推荐姿态 helper 和当前可攻击反制目标 helper。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.30。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步反制命令链高亮和 v0.30 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.30（反制命令链高亮）.md`
- `AGENTS.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- 实现提交 `04d705687989094ad6765a7921e0e76eac47001e` 已 push 到 `origin/main`，GitHub Actions run `28771178563` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.30-main-04d7056-run28771178563-attempt1`。
- Agent C 复判已核对 manifest `version=v0.30`、`branch=main`、`commitSha=04d705687989094ad6765a7921e0e76eac47001e`、`runId=28771178563`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success。
- Swift Testing 日志显示 88 tests 通过，Gameplay Smoke 输出 `Gameplay smoke test passed.`，RenderBattlePreview 产出 6 张非空 PNG 且未出现 `missingCountermeasureCommandPreview`、`missingCountermeasureOverlay` 或 `missingCountermeasureSummary`，Xcode build 日志以 `** BUILD SUCCEEDED **` 结束。

遗留事项：

- 本轮没有实现自动执行反制、一键移动、一键攻击、一键切姿态、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 反制命令链高亮只用于标出现有姿态/攻击命令入口，不改变既有 AI、技能、攻击、移动、城市、外交或胜负规则。

### v0.29 / 反制指令聚焦与执行预览

日期：2026-07-06

核心变更：

- `GameViewModel` 新增 `CountermeasureCommandStep`、`CountermeasureCommandPreview`、`countermeasureCommandPreviews`、`primaryCountermeasureCommandPreview`、`selectedCountermeasureCommandPreview` 和 `focusedCountermeasureID`，把 v0.27/v0.28 的反制建议转成推荐姿态、落点可达性、目标窗口、下一步和阻塞原因等只读指令预览。
- `GameViewModel.focusCountermeasure(_:)` 与 `focusPrimaryCountermeasure()` 只改变 ViewModel 选择态、位置、聚焦 ID 和 banner，使现有可达格、攻击目标和姿态预览自然刷新；它们不移动单位、不攻击、不切换姿态，也不改变 `GameState`。
- `BattleView` 在敌情反制卡展示指令预览和“定位回应”按钮，在战局反制行展示下一步并支持定位，在完整/紧凑军令面板中为选中的回应军团展示反制执行预览。
- `Tools/RenderBattlePreview/main.swift` 增加 `primaryCountermeasureCommandPreview`、步骤文案、按钮文案和 `focusCountermeasure(_:)` 行为断言；失败抛出 `missingCountermeasureCommandPreview`。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.29。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步反制指令聚焦与执行预览和 v0.29 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.29（反制指令聚焦与执行预览）.md`
- `AGENTS.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- 实现提交 `2916691d0fa77452a815907e789a5d76293a3650` 已 push 到 `origin/main`，GitHub Actions run `28769598754` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.29-main-2916691-run28769598754-attempt1`。
- Agent C 复判已核对 manifest `version=v0.29`、`branch=main`、`commitSha=2916691d0fa77452a815907e789a5d76293a3650`、`runId=28769598754`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success。
- Swift Testing 日志显示 88 tests 通过，Gameplay Smoke 输出 `Gameplay smoke test passed.`，RenderBattlePreview 产出 6 张非空 PNG 且未出现 `missingCountermeasureCommandPreview`、`missingCountermeasureOverlay` 或 `missingCountermeasureSummary`，Xcode build 日志以 `** BUILD SUCCEEDED **` 结束。

遗留事项：

- 本轮没有实现自动执行反制、一键移动、一键攻击、一键切姿态、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 反制指令预览只用于把建议转成玩家可读、可聚焦的下一步操作提示，不改变既有 AI、技能、攻击、移动、城市、外交或胜负规则。

### v0.28 / 反制落点地图叠层

日期：2026-07-06

核心变更：

- `GameViewModel` 新增 `CountermeasureRouteSegment`、`CountermeasureMapRole`、`CountermeasurePositionOverlay`、`CountermeasureMapOverlay`、`primaryCountermeasureMapOverlay`、`countermeasureRouteSegments`、`countermeasureOverlaysByPosition` 和 `countermeasureOverlayPositions`，把首要反制建议的回应位置、推荐落点和威胁目标转成只读地图叠层数据。
- `CountermeasureSummary` 暴露 `responsePosition` 和 `routeSegments`，反制引导线表达“回应位置 -> 推荐落点 -> 威胁目标”的空间关系；它只读取 v0.27 核心报告，不改变 `GameState`、AI、移动、攻击、技能或姿态结算。
- `MapOverlayLegendKind` 增加 `.countermeasure`，`activeMapOverlayLegendItems` 在反制叠层存在时加入“反制”图例。
- `BattleView` 在战斗地图上渲染反制引导线、推荐落点和威胁目标 hex 标记，并将 tile accessibility 同步读出反制类型、回应、目标和风险；SwiftUI 只展示 ViewModel 派生数据，不重新匹配目标或评分。
- `Tools/RenderBattlePreview/main.swift` 增加反制地图叠层断言，要求 `primaryCountermeasureMapOverlay`、反制路线线段、按位置索引 overlay 和 overlay positions 非空，并包含首要反制建议的推荐落点和威胁目标；失败抛出 `missingCountermeasureOverlay`。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.28。
- README、flow、flowchart、test、prompt README、AGENTS 文档同步反制落点/目标地图叠层和 v0.28 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.28（反制落点地图叠层）.md`
- `AGENTS.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- 实现提交 `fe10045f92af1008dedc8dbbb1c593184513c3bd` 已 push 到 `origin/main`，GitHub Actions run `28768182174` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.28-main-fe10045-run28768182174-attempt1`。
- Agent C 复判已核对 manifest `version=v0.28`、`branch=main`、`commitSha=fe10045f92af1008dedc8dbbb1c593184513c3bd`、`runId=28768182174`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success。
- Swift Testing 日志显示 88 tests 通过，Gameplay Smoke 输出 `Gameplay smoke test passed.`，RenderBattlePreview 产出 6 张非空 PNG 且未出现 `missingCountermeasureOverlay` 或 `missingCountermeasureSummary`，Xcode build 日志以 `** BUILD SUCCEEDED **` 结束。

遗留事项：

- 本轮没有实现自动执行反制、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 反制地图叠层只解释首要反制建议的回应空间关系，不声明为真实移动路径，也不改变既有 AI、技能、攻击、移动、城市、外交或胜负规则。

### v0.27 / 敌情反制建议读板

日期：2026-07-06

核心变更：

- `GameState` 新增 `CountermeasureKind`、`CountermeasurePriority` 和 `CountermeasureReport`，通过 `countermeasureReports(for:limit:)` 与 `countermeasureReport(for:)` 只读汇总敌情反制建议。
- 反制建议复用敌方将领威胁、AI 作战计划、战线压力、威胁热区、本方战术建议、机动落点和将领协同报告，输出打断敌将、稳住战线、补防城市、打击威胁、将令反制或机动换位建议。
- `GameViewModel` 新增 `CountermeasureSummary`、`countermeasureSummaries` 和 `primaryCountermeasureSummary`，把核心报告转成反制 chip、敌情卡、战局行、收益、风险、命令和无障碍文案。
- `BattleView` 在顶部态势加入“反制”chip，在敌情面板展示首要反制建议卡，并在完整战局面板展示前两条反制建议行；SwiftUI 只展示 ViewModel 摘要，不重新计算反制评分、目标或回应单位。
- Swift Testing 增加反制建议只读、敌将/AI 计划链接、战线压力补线、回应单位归属罗马和条约保护过滤断言。
- Gameplay Smoke 增加敌方将领威胁到反制建议的主链路断言；RenderBattlePreview 增加 `primaryCountermeasureSummary` / `countermeasureSummaries` 断言，失败抛出 `missingCountermeasureSummary`。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.27。
- README、flow、flowchart、test、prompt README 文档同步敌情反制建议读板和 v0.27 Agent A 提示词。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.27（敌情反制建议读板）.md`
- `update_log.md`
- `AGENTS.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- 实现提交 `6ab318e0d381fea8507b77c04c77ecdc8e86d388` 已 push 到 `origin/main`，GitHub Actions run `28767348619` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.27-main-6ab318e-run28767348619-attempt1`。
- Agent C 复判已核对 manifest `version=v0.27`、`branch=main`、`commitSha=6ab318e0d381fea8507b77c04c77ecdc8e86d388`、`runId=28767348619`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success。
- Swift Testing 日志显示 88 tests 通过，Gameplay Smoke 输出 `Gameplay smoke test passed.`，RenderBattlePreview 产出 6 张非空 PNG 且未出现 `missingCountermeasureSummary`，Xcode build 日志以 `** BUILD SUCCEEDED **` 结束。

遗留事项：

- 本轮没有实现自动执行反制、多回合搜索、AI 权重重写、装备、升级树、将领池 UI、外交界面、存档 UI 或建筑树。
- 敌情反制建议读板只用于解释“敌方威胁 -> 本方回应”的只读建议，不改变既有 AI、技能、攻击、移动、城市、外交或胜负规则。

### v0.26 / 敌方将领威胁读板

日期：2026-07-06

核心变更：

- `GameState` 新增 `EnemyCommanderThreatLevel` 和 `EnemyCommanderThreatReport`，通过 `enemyCommanderThreatReports(against:limit:)` 与 `enemyCommanderThreatReport(unitID:against:)` 只读汇总敌方将领威胁。
- 敌将威胁报告复用敌方 forecast 下的 `GeneralSkillPreview`、`AIIntent`、`AIOperationalPlanReport`、`FrontlinePressureReport` 和 `ThreatHeatZoneReport`，按技能窗口、预计伤害/恢复/削城防、战线压力、热区和 trait 被动价值生成等级、评分、理由和影响。
- `GameViewModel` 新增 `EnemyCommanderThreatSummary`、`enemyCommanderThreatSummaries` 和 `primaryEnemyCommanderThreatSummary`，把核心报告转成敌将 chip、敌情卡、战局敌将行、状态和无障碍文案。
- `BattleView` 在顶部态势加入“敌将”chip，在敌情面板展示首要敌将威胁卡，并在完整战局面板展示敌将威胁行；SwiftUI 只展示 ViewModel 摘要，不重新计算威胁分。
- Swift Testing 增加敌方 forecast 技能威胁只读、技能就绪优先级、攻城削城防、攻击伤害复用 AIIntent 和条约保护过滤断言。
- Gameplay Smoke 增加敌方将领威胁主链路断言；RenderBattlePreview 增加 `primaryEnemyCommanderThreatSummary` / `enemyCommanderThreatSummaries` 断言，失败抛出 `missingEnemyCommanderThreatSummary`。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.26。
- README、flow、flowchart、test、prompt README 文档同步敌方将领威胁读板和 v0.26 Agent A 提示词。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.26（敌方将领威胁读板）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- 初始提交 `aedcfe52ba929f2cfc083e415a8a86ee284b0a0e` 触发 GitHub Actions run `28766199521` attempt `1`，static checks、RenderBattlePreview、Xcode build 成功，但 Swift Testing 与 Gameplay Smoke 失败；失败原因为冷却敌将评分高于技能就绪敌将的测试期望、敌方攻城威胁 fixture 同时贴近罗马和那不勒斯导致目标城市期望不稳。
- 修复提交 `a73921048ef640e10ea7df1d1f90f295710b0782` 已 push 到 `origin/main`，GitHub Actions run `28766410731` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.26-main-a739210-run28766410731-attempt1`。
- Agent C 复判已核对 manifest `version=v0.26`、`branch=main`、`commitSha=a73921048ef640e10ea7df1d1f90f295710b0782`、`runId=28766410731`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success；Swift Testing 日志显示 84 tests 通过，Gameplay Smoke 输出 `Gameplay smoke test passed.`，RenderBattlePreview 产出 6 张非空 PNG，Xcode build 日志以 `** BUILD SUCCEEDED **` 结束。
- 后续文档验收记录提交 `609e63203df8a3a426f6e9ef99344eb55db191f9` 已 push 到 `origin/main`，GitHub Actions run `28766551449` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.26-main-609e632-run28766551449-attempt1`；这是 v0.26 最新已验收云端证据。

遗留事项：

- 本轮没有实现 AI 权重重写、多回合搜索、自动反制建议、敌将装备、升级树、将领池 UI、将领改名、技能选择、真实补给线、建筑树、人口、外交界面或存档 UI。
- 敌方将领威胁读板只用于解释和排序敌将威胁，不改变既有 AI、技能、攻击、移动、城市、外交或胜负规则。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.26 run id、run attempt 和 artifact；不能使用 v0.25 旧结果包。

### v0.25 / 军团成长优先级读板

日期：2026-07-05

核心变更：

- `GameState` 新增 `UnitDevelopmentRecommendationKind`、`UnitDevelopmentRecommendationPriority` 和 `UnitDevelopmentRecommendationReport`，通过 `unitDevelopmentRecommendationReports(for:limit:)` 与 `unitDevelopmentRecommendationReport(unitID:)` 只读汇总训练/任命成长推荐。
- 成长推荐复用 `TrainingPreview`、`GeneralAppointmentPreview` 和 `LegionFormationReport`，按生命损失、训练恢复、升阶/伤害收益、缺将领、近敌、战备、候选 trait 和阻塞状态生成优先级、评分、理由和影响。
- `GameViewModel` 新增 `UnitDevelopmentRecommendationSummary`、`unitDevelopmentRecommendationSummaries` 和 `primaryUnitDevelopmentRecommendationSummary`，把核心推荐转成全局成长 chip、战局成长行、状态和无障碍文案。
- `BattleView` 在顶部态势加入“成长”chip，并在完整战局面板展示前三条成长推荐；SwiftUI 只展示 ViewModel 摘要，不重新计算推荐分。
- Swift Testing 增加成长推荐只读、训练/任命预览复用、已有将领阻塞和资源不足可读断言。
- Gameplay Smoke 增加成长推荐主链路断言；RenderBattlePreview 增加 `primaryUnitDevelopmentRecommendationSummary` / `unitDevelopmentRecommendationSummaries` 断言，失败抛出 `missingUnitDevelopmentRecommendationSummary`。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.25。
- README、flow、flowchart、test、prompt README 文档同步军团成长优先级读板和 v0.25 Agent A 提示词。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.25（军团成长优先级读板）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- GitHub Actions run `28741952637` attempt `1` 曾失败，失败范围为 RenderBattlePreview 和 Xcode build 编译 `GameViewModel.swift` 时发现 `unitDevelopmentRecommendationSummary(for:)` 缺少 `return`。
- 修复提交 `07f217f2fa6719b776aa51737c8c2f8a2b94c6ff` 已 push 到 `origin/main`，GitHub Actions run `28743500256` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.25-main-07f217f-run28743500256-attempt1`。
- Agent C 复判已核对 manifest `version=v0.25`、`branch=main`、`commitSha=07f217f2fa6719b776aa51737c8c2f8a2b94c6ff`、`runId=28743500256`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success；Swift Testing 日志显示 79 tests 通过，RenderBattlePreview 产出 6 张非空 PNG，Xcode build 日志以 `** BUILD SUCCEEDED **` 结束。

遗留事项：

- 本轮没有实现自动训练、自动任命、升级树、装备、兵种转职、将领池 UI、将领改名、技能选择、真实补给线、建筑树、人口、外交界面或存档 UI。
- 军团成长优先级读板只用于解释和排序训练/任命建议，不改变既有训练/任命结算、AI、移动、攻击、技能、城市或胜负规则。
- 下一轮 Agent X 可继续拆分地图、AI、将领或战斗 UI 目标，但仍必须验收最新 `origin/main` commit 对应的 run id、run attempt 和 artifact。

### v0.24 / 军团成长决策读板

日期：2026-07-05

核心变更：

- `GameState` 新增 `TrainingPreview` 和 `GeneralAppointmentPreview`，通过 `trainingPreview(unitID:)` 与 `generalAppointmentPreview(unitID:)` 只读展示训练/任命成本、预计经验/军阶/伤害、恢复、候选将领/特性和阻塞原因。
- `trainUnit(id:)` 与 `appointGeneral(unitID:)` 改为复用同一预览的成本、预计收益和候选将领，避免成长读板与真实结算分叉。
- `GameViewModel` 新增 `UnitDevelopmentDecisionSummary` 与训练/任命按钮 detail/can 执行派生字段，把核心预览转成成本、收益、状态和无障碍文案。
- `BattleView` 在完整与紧凑选中单位情报中新增“成长”卡，展示训练和任命两项决策；完整军令面板训练/任命按钮使用预览摘要和可执行状态。
- Swift Testing 增强训练/任命测试，覆盖预览只读、成本复用、执行结果匹配预览、资源不足和已任命阻塞。
- Gameplay Smoke 增加训练/任命预览主链路断言；RenderBattlePreview 增加 `selectedUnitDevelopmentDecisionSummary` 断言，失败抛出 `missingUnitDevelopmentDecisionSummary`。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.24。
- README、flow、flowchart、test、prompt README 文档同步军团成长决策读板和 v0.24 Agent A 提示词。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.24（军团成长决策读板）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- GitHub Actions run `28740275512` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.24-main-85db5c6-run28740275512-attempt1`。
- Agent C 复判已核对 manifest `version=v0.24`、`branch=main`、`commitSha=85db5c621e615e03dd63400792b128361babb460`、`runId=28740275512`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success。

遗留事项：

- 本轮没有实现升级树、装备、兵种转职、将领池 UI、将领改名、技能选择、自动训练、真实补给线、建筑树、人口、外交界面或存档 UI。
- 军团成长决策读板只解释训练/任命成本、收益和阻塞，不改变既有训练/任命数值、候选顺序、trait 映射、AI、移动、攻击、技能、城市或胜负结算。

### v0.23 / 主动地图叠层图例

日期：2026-07-05

核心变更：

- `GameViewModel` 新增 `MapOverlayLegendKind`、`MapOverlayLegendItem` 和 `activeMapOverlayLegendItems`，根据当前实际存在的地图叠层派生图例项。
- 主动图例覆盖敌军路线、敌军目标/目的地、威胁热区、地图控区、军议路径/目标、机动落点、可移动、可攻击和将领技能范围/目标；每项包含 symbol、title、detail 和无障碍文案。
- `BattleView` 将地图底部阵营色小图例升级为 `MapOverlayLegendView`，显示当前动态叠层图例并保留阵营色说明；图例横向滚动，避免紧凑视口文本溢出。
- SwiftUI 只展示 ViewModel 派生结果，不重新计算核心规则、路径、热区、控区、目标或机动评分。
- RenderBattlePreview 增加 `activeMapOverlayLegendItems` 断言，单位场景必须覆盖敌军路线、敌军目标、热区、控区、军议和机动图例；失败抛出 `missingMapOverlayLegend`。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.23。
- README、flow、flowchart、test、prompt README 文档同步主动地图叠层图例和 v0.23 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.23（主动地图叠层图例）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- GitHub Actions run `28738374857` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.23-main-dc05817-run28738374857-attempt1`。
- Agent C 复判已核对 manifest `version=v0.23`、`branch=main`、`commitSha=dc058178b33bfe25cb15bb3b44c62a1e9c6dd05f`、`runId=28738374857`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success。

遗留事项：

- 本轮没有实现图层开关、教程系统、地图缩放、地图 UI 大重构、军团成长预览、真实补给线、建筑树、装备、人口、外交界面或存档 UI。
- 主动地图叠层图例只用于解释当前可见叠层，不改变真实移动、攻击、占城、姿态、AI 决策、热区、控区、机动评分或战斗结算。

### v0.22 / AI 主攻优先执行

日期：2026-07-05

核心变更：

- `performSimpleAI(for:)` 改为通过当前状态下的单体 `AIIntent.threatScore` 排序尚未行动的 AI 单位，高威胁主攻单位优先执行；同分按 `unitID` 稳定排序。
- 新增私有 `aiActingUnitIDs(for:)` helper，不调用公开 `aiIntents(for:)` 驱动真实回合，避免 forecast 刷新语义污染当前行动状态。
- 单位内部既有休整、战术姿态、将领技能、站位攻击、移动和移动后攻击分支保持不变；本轮不调整 AI 权重、攻击/移动/夺城/技能数值或存档结构。
- Swift Testing 增加低威胁单位数组靠前、高威胁移动后攻击单位数组靠后的核心测试，锁定真实 AI 先执行主攻骑兵且伤害继续匹配意图预览。
- Gameplay Smoke 在移动后攻击链路中加入低威胁弓兵，断言 AI 首条行动消息来自高威胁骑兵。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.22。
- README、flow、flowchart、test、prompt README 文档同步 AI 主攻优先执行和 v0.22 Agent A 提示词。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.22（AI主攻优先执行）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- GitHub Actions run `28737218655` attempt `1` 通过，artifact 为 `RomeLegions-ci-v0.22-main-4261521-run28737218655-attempt1`。
- Agent C 复判已核对 manifest `version=v0.22`、`branch=main`、`commitSha=4261521ae9eb122fe2ba834224f04eb0f2b0276e`、`runId=28737218655`、`runAttempt=1`，JUnit `failures=0`，static checks、Swift Testing、Gameplay Smoke、RenderBattlePreview 和 Xcode build 均为 success。

遗留事项：

- 本轮没有实现多回合 AI 搜索、全局作战计划自动执行器、AI 权重调参、地图叠层图例、军团成长预览、真实补给线、建筑树、装备、人口、外交界面或存档 UI。
- AI 作战计划读板仍是只读解释层；真实 AI 只复用当前单体意图威胁分决定执行顺序，不自动执行计划报告。

### v0.21 / 机动落点与地图风险读板

日期：2026-07-05

核心变更：

- `GameState` 新增 `ManeuverOptionKind` 和 `ManeuverOptionReport`，通过 `maneuverOptionReports(unitID:limit:)` 与 `maneuverOptionReport(unitID:)` 只读评估选中单位真实可达格。
- 机动落点报告在 projected state 中复用既有可达格、路径、地图控制、威胁热区、战线压力、占城目标、外交过滤和 `attackPreview`，输出打击、夺城、补线、推进或稳固落点。
- 报告包含起点、落点、路径、目标单位/城市、目标位置、推荐姿态、控区状态、热区等级、友敌影响、预计伤害、反击、支援/包夹/指挥修正、补线/目标距离、风险、评分、标题、摘要和详情；不新增 Codable 存档字段。
- `GameViewModel` 新增 `ManeuverOptionSummary`、`selectedManeuverOptionSummaries`、`primaryManeuverOptionSummary`、`maneuverOptionOverlaysByPosition` 和 `maneuverOptionOverlayPositions`，把核心报告转成中文摘要、地图 overlay 和无障碍文案。
- `BattleView` 新增地图机动落点叠层、顶部“机动” chip、完整/紧凑选中单位机动卡和完整战局面板机动行；SwiftUI 只展示核心报告，不重新计算落点评分、热区、攻击目标或路径。
- Swift Testing 增加机动落点打击、夺城、条约保护、风险排序和已移动单位只读五类核心测试；Gameplay Smoke 增加机动打击主链路断言；RenderBattlePreview 增加机动落点 ViewModel 字段和 overlay 断言。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.21。
- README、flow、flowchart、test、prompt README 文档同步机动落点读板、云端 RenderBattlePreview 断言和 v0.21 Agent A 提示词。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.21（机动落点与地图风险读板）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法检查。
- 本轮完整验证必须在 push 到 `origin/main` 后由 GitHub Actions 执行，并由 Agent C 下载最新 v0.21 artifact 复判 manifest、JUnit、主日志、render 日志、预览 PNG 和失败摘要。

遗留事项：

- 本轮没有实现自动移动、自动攻击、一键执行机动、自动规避热区、多回合路径规划、真实补给线、建筑树、装备、人口、外交界面或存档 UI。
- 机动落点只用于读板和 UI 解释，不自动执行命令，也不改变真实移动、攻击、占城、姿态、AI 决策或战斗结算。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.21 run id、run attempt 和 artifact；不能使用 v0.20 旧结果包。

### v0.20 / 本方将领协同与战术连携读板

日期：2026-07-05

核心变更：

- `GameState` 新增 `CommanderSynergyKind`、`CommanderSynergyRole`、`CommanderSynergyStepReport` 和 `CommanderSynergyReport`，通过 `commanderSynergyReport(unitID:)` 与 `commanderSynergyReports(for:limit:)` 只读整合将领技能、合击攻击、补线、推进和整备机会。
- 本方将令报告复用 `GeneralSkillPreview`、`LegionFormationReport`、`TacticalRecommendationReport` 和 `CombatPreview`，输出协同步骤、执行单位、将领单位、目标单位/城市、支援单位、受益单位、推荐姿态、风险、预计伤害、支援/包夹/指挥修正、预计恢复/削城防、可执行状态和阻塞原因；不新增 Codable 存档字段。
- 合击报告的预计伤害、支援、包夹和指挥修正直接来自既有攻击预览；将领技能报告直接读取技能预览；补线、推进和整备报告复用战术建议，不改变真实移动、攻击、技能、姿态、AI、招募、城市或胜负结算。
- `GameViewModel` 新增 `CommanderSynergySummary`、`commanderSynergySummaries`、`primaryCommanderSynergySummary` 和 `selectedCommanderSynergySummary`，把核心报告转成中文摘要、影响文案、支援/受益文案和无障碍文案。
- `BattleView` 新增顶部“将令” chip、完整战局面板将令行、完整/紧凑选中单位将令卡，并保持紧凑界面军令入口优先。
- Swift Testing 增加将领技能协同、技能目标位置一致性、合击修正解释、冷却阻塞、不可执行技能排序降级、条约过滤和全局排序七类核心只读测试；Gameplay Smoke 增加本方将领协同与合击主链路断言；RenderBattlePreview 增加本方将令 ViewModel 字段断言。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.20。
- README、flow、flowchart、test、prompt README 文档同步本方将领协同读板、云端 RenderBattlePreview 断言和 v0.20 Agent A 提示词。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.20（本方将领协同与战术连携读板）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/Plist 解析或脚本语法检查。
- 本轮完整验证必须在 push 到 `origin/main` 后由 GitHub Actions 执行，并由 Agent C 下载最新 v0.20 artifact 复判 manifest、JUnit、主日志、render 日志、预览 PNG 和失败摘要。

遗留事项：

- 本轮没有实现自动释放技能、一键合击、自动移动补线、多回合规划、真实补给线、建筑树、装备、人口、外交界面或存档 UI。
- 本方将领协同只用于读板和 UI 解释，不自动执行命令，也不改变战斗结算或 AI 决策。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.20 run id、run attempt 和 artifact；不能使用 v0.19 旧结果包。

### v0.19 / AI 作战计划与将领协同读板

日期：2026-07-05

核心变更：

- `GameState` 新增 `AIOperationalPlanKind`、`AIPlanCoordinationRole`、`AIPlanStepReport` 和 `AIOperationalPlanReport`，通过 `aiOperationalPlanReports(against:perFactionLimit:limit:)` 只读聚合敌军意图、战线压力、威胁热区和敌方将领技能机会。
- AI 作战计划覆盖集火、夺城、将领技能、推进、固守和整备，输出来源单位、指挥将领、目标单位/城市、协同角色、预计伤害、压力/热区等级、标题和详情；不新增 Codable 存档字段。
- `aiIntents(for:limit:)` 继续只读预测敌军倾向，并复用同一敌方 forecast copy；作战计划中的敌方将领技能机会在敌方规划态上读取，避免罗马回合误判敌方技能不可用。
- 作战计划读板不改变真实 AI 行为、AI 评分、移动、攻击、技能释放、战斗结算、招募、城市扩建或胜负结算。
- `GameViewModel` 新增 `AIOperationalPlanSummary`、`aiOperationalPlanSummaries` 和 `primaryAIOperationalPlanSummary`，把核心计划转成类型、来源、目标、影响、步骤和无障碍文案。
- `BattleView` 新增顶部“计划”chip、敌情计划卡和完整战局计划行，让战斗页能直接看到敌军下一步集火、夺城或将领协同意图。
- Swift Testing 增加集火计划、夺城计划、敌方将领技能计划、整备兜底和条约过滤五类核心只读测试；Gameplay Smoke 增加 AI 作战计划主链路和敌方将领技能协同断言；RenderBattlePreview 增加 AI 作战计划 ViewModel 字段断言。
- `.github/workflows/ci-results.yml` artifact 版本更新到 v0.19。
- README、flow、flowchart、test、prompt README 文档同步 AI 作战计划读板、云端 RenderBattlePreview 断言和 v0.19 Agent A 提示词。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.19（AI作战计划与将领协同读板）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/Plist 解析或脚本语法检查。
- 本轮完整验证必须在 push 到 `origin/main` 后由 GitHub Actions 执行，并由 Agent C 下载最新 v0.19 artifact 复判 manifest、JUnit、主日志、render 日志、预览 PNG 和失败摘要。

遗留事项：

- 本轮没有实现真实多回合 AI 搜索、改变 AI 权重、自动执行计划、自动规避热区、真实补给线、外交界面、建筑树、装备系统或友方将领协同系统。
- AI 作战计划只用于读板和 UI 解释，不自动执行命令，也不改变 AI 决策。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.19 run id、run attempt 和 artifact；不能使用 v0.18 旧结果包。

### v0.18 / 地图控制与威胁热区读板

日期：2026-07-05

核心变更：

- `GameState` 新增 `MapControlState`、`ThreatHeatLevel`、`MapControlReport` 和 `ThreatHeatZoneReport`，通过 `mapControlReport(at:for:)`、`mapControlReports(for:)` 和 `threatHeatZoneReports(for:limit:)` 只读派生每格控制状态、友敌影响和高风险热区。
- 地图控制与威胁热区读取地形、城市、单位、外交状态、敌军意图和战线压力，展示友方控制、敌方控制、争夺、中立以及安静、监视、争夺、危险、危急热度，不新增 Codable 存档字段。
- 控图/热区报告不改变真实移动、攻击、战术姿态、将领技能、AI 评分、AI 决策、招募、城市扩建或胜负结算。
- `GameViewModel` 新增 `MapControlSummary`、`ThreatHeatZoneSummary`、控图/热区摘要列表、首要摘要和 overlay position 集合，把核心报告转成 UI 文案和无障碍文案。
- `BattleView` 新增顶部“热区”chip、地图低透明热区/争夺叠层、战场面板热区/控区卡和完整战局面板热区行；紧凑界面仍保持军令入口优先。
- Swift Testing 增加地图控制聚合、控制状态/非危急热度档、直接/移动后攻击热区、城市夺取热区和条约过滤五类核心只读测试；Gameplay Smoke 增加地图控制/热区主链路断言；RenderBattlePreview 增加地图控制和威胁热区 ViewModel 字段断言。
- `.github/workflows/ci-results.yml` 将 RenderBattlePreview 编译与三尺寸运行纳入云端 CI，结果包包含 render 日志和小量预览 PNG，artifact 版本更新到 v0.18。
- README、flow、flowchart、test、prompt README 文档同步地图控制、威胁热区和云端 RenderBattlePreview 验收，并新增 v0.18 Agent A 提示词。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.18（地图控制与威胁热区读板）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/Plist 解析或脚本语法检查。
- 本轮完整验证必须在 push 到 `origin/main` 后由 GitHub Actions 执行，并由 Agent C 下载最新 v0.18 artifact 复判 manifest、JUnit、主日志、render 日志、预览 PNG 和失败摘要。

遗留事项：

- 本轮没有实现自动规避热区、自动路线规划、多回合 AI 搜索、真实补给线、外交界面、建筑树或装备系统。
- 地图控制与威胁热区只用于读板和 UI 解释，不自动执行命令，也不改变 AI 决策。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.18 run id、run attempt 和 artifact；不能使用 v0.17 旧结果包。

### v0.17 / 战场焦点与将领机会读板

日期：2026-07-05

核心变更：

- `GameState` 新增 `BattlefieldFocusKind`、`BattlefieldFocusSeverity` 和 `BattlefieldFocusReport`，通过 `battlefieldFocusReports(for:limit:)` 与 `battlefieldFocusReport(for:)` 只读综合战线压力、战术建议、军团编制和将领技能机会。
- 战场焦点覆盖救线、将领机会、打击、补线、推进和整编恢复，输出阵营、严重度、位置、执行单位、目标单位/城市、相关单位、建议姿态、评分、标题、摘要和详情。
- 焦点报告不新增 Codable 存档字段，不改变真实移动、攻击、姿态切换、将领技能、AI 评分、AI 决策、招募、城市扩建或胜负结算。
- `GameViewModel` 新增 `BattlefieldFocusSummary`、`battlefieldFocusSummaries` 和 `primaryBattlefieldFocusSummary`，把核心报告转成焦点 chip、战场卡、战局行和无障碍文案。
- `BattleView` 新增顶部“焦点”chip、战场面板焦点卡和完整战局面板前两条焦点行；紧凑界面只显示一行焦点摘要，继续保持军令入口优先。
- Swift Testing 增加压力驱动焦点和将领技能机会焦点两类核心只读测试；Gameplay Smoke 增加战场焦点主链路断言；RenderBattlePreview 增加首要战场焦点摘要断言。
- README、flow、flowchart、test、prompt README 文档同步战场焦点读板和 v0.17 artifact 版本，并新增 v0.17 Agent A 提示词。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.17（战场焦点与将领机会读板）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/Plist 解析或脚本语法检查。
- 本轮完整验证必须在 push 到 `origin/main` 后由 GitHub Actions 执行，并由 Agent C 下载最新 v0.17 artifact 复判 manifest、JUnit、主日志和失败摘要。

遗留事项：

- 本轮没有实现自动执行焦点命令、多回合规划、真实战略 AI 搜索、外交界面、建筑树或装备系统。
- 战场焦点只用于读板和 UI 解释，不自动执行命令，也不改变 AI 决策。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.17 run id、run attempt 和 artifact；不能使用 v0.16 旧结果包。

### v0.16 / 战术命令建议与补线路径读板

日期：2026-07-05

核心变更：

- `GameState` 新增 `TacticalRecommendationKind`、`TacticalRecommendationRisk` 和 `TacticalRecommendationReport`，通过 `tacticalRecommendation(unitID:)` 只读派生选中单位的攻击、补线、推进、坚守或整备建议。
- 战术建议报告读取现有单位、可达格、攻击预览、战线压力、城市目标和军团编制报告，输出目标位置、目的地、目标单位/城市、推荐姿态、路径、优先级、风险、预计伤害或补线距离、理由和命令文案。
- 战术建议不新增 Codable 存档字段，不改变真实移动、攻击、姿态切换、将领技能、AI 评分、AI 决策、招募、城市扩建或胜负结算。
- `GameViewModel` 新增 `TacticalRecommendationSummary`、`selectedTacticalRecommendationSummary`、`selectedTacticalRecommendationPathPositions` 和 `selectedTacticalRecommendationTargetPosition`，把核心报告转成军议 chip、建议卡、地图路径/目标和无障碍文案。
- `BattleView` 新增本方战术建议路线层、目标叠层、顶部“军议”chip 和完整/紧凑选中单位战术建议卡；紧凑界面仍保持军令面板优先。
- Swift Testing 增加攻击建议、补线支援和已行动整备三类核心只读测试；Gameplay Smoke 增加战术建议主链路断言；RenderBattlePreview 增加选中单位战术建议摘要、路径位置、目标位置和路线线段断言。
- README、flow、flowchart、test、prompt README 文档同步战术建议读板和 v0.16 artifact 版本，并新增 v0.16 Agent A 提示词。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.16（战术命令建议与补线路径读板）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/Plist 解析或脚本语法检查。
- 本轮完整验证必须在 push 到 `origin/main` 后由 GitHub Actions 执行，并由 Agent C 下载最新 v0.16 artifact 复判 manifest、JUnit、主日志和失败摘要。

遗留事项：

- 本轮没有实现自动执行推荐命令、多回合路径规划、真实战略 AI 搜索、外交界面、建筑树或装备系统。
- 战术建议只用于读板和地图提示，不自动执行命令，也不改变 AI 决策。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.16 run id、run attempt 和 artifact；不能使用 v0.15 旧结果包。

### v0.15 / 将领成长与军团编制可读化

日期：2026-07-05

核心变更：

- `GameState` 新增 `LegionFormationRole`、`LegionFormationReadiness` 和 `LegionFormationReport`，通过 `legionFormationReport(unitID:)` 与 `legionFormationReports(for:limit:)` 只读派生军团职责、战备、生命、军阶、将领、姿态、建议姿态、有效攻防移、相邻/两格友军、两格内敌军、技能状态、编制完整度和命令建议。
- 军团编制报告只读取现有 `ArmyUnit`、将领、战功、姿态、外交和技能预览数据，不新增 Codable 存档字段，不改变 `experience * 3` 伤害、训练/任命成本、技能冷却、AI 招募策略、AI 评分、真实移动或战斗结算。
- `GameViewModel` 新增 `LegionFormationSummary`、`legionFormationSummaries`、`primaryLegionFormationSummary` 和 `selectedLegionFormationSummary`，把核心报告转成顶部 chip、战局面板和选中单位情报可消费的中文摘要和无障碍文案。
- `BattleView` 新增“军团”顶部 chip、完整战局面板军团编制行、完整/紧凑选中单位编制卡；紧凑界面仍保持军令面板优先，新增读板不插到军令前。
- Swift Testing 增加指挥型军团报告和受损孤军危急报告两类核心只读测试；Gameplay Smoke 增加军团编制主链路断言；RenderBattlePreview 增加选中军团与首要军团编制摘要断言。
- README、AGENTS、flow、flowchart、test、prompt README 文档同步云端-only 验证约束、军团编制读板和 v0.15 artifact 版本，并新增 v0.15 Agent A 提示词。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `AGENTS.md`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（玩法推进）/v0.15（将领成长与军团编制可读化）.md`
- `update_log.md`

验证结果：

- 按人工最新要求，本轮未运行任何本地测试、build、typecheck、RenderBattlePreview、`Tools/verify_project.mjs`、`git diff --check`、YAML/Plist 解析或脚本语法检查。
- 本轮完整验证必须在 push 到 `origin/main` 后由 GitHub Actions 执行，并由 Agent C 下载最新 v0.15 artifact 复判 manifest、JUnit、主日志和失败摘要。

遗留事项：

- 本轮没有实现真实编制槽位、装备、升级树、技能点、人口、建筑树、AI 多回合搜索或外交界面。
- 军团编制建议只用于读板，不自动执行命令，也不改变 AI 决策。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.15 run id、run attempt 和 artifact；不能使用 v0.14 旧结果包。

### v0.14 / 战线压力与 AI 战略意图读板

日期：2026-07-05

核心变更：

- `GameState` 新增 `FrontlinePressureLevel`、`FrontlinePressureTargetKind` 和 `FrontlinePressureReport`，通过 `frontlinePressureReports(against:perFactionLimit:limit:)` 只读聚合交战敌军 `AIIntent`，按罗马单位或城市展示来源单位、来源阵营、意图数量、攻击/夺城数量、预计伤害合计、最高威胁值、压力分和压力等级。
- 战线压力报告不新增 `AIIntent` 存储字段，不改变 `performSimpleAI(for:)`、AI 权重、真实移动、战斗结算或 Codable 存档结构；压力等级只用于 UI 读板。
- `GameViewModel` 新增 `FrontlinePressureSummary`、`frontlinePressureSummaries` 和 `primaryFrontlinePressureSummary`，把核心报告整理成目标、来源、压力标签、影响文案和无障碍说明。
- `BattleView` 在地图顶部状态条显示首要“战线”chip，在完整战局面板展示最多三条战线压力行，在紧凑战场面板只显示一条短摘要，避免挤占手机竖屏和短横屏军令入口。
- Swift Testing 增加多路敌军集火同一罗马单位、敌军夺取罗马城市、停战势力过滤和只读不变性覆盖；Gameplay Smoke 增加多路压力主链路断言。
- `Tools/RenderBattlePreview` 在既有敌军路径、将领、姿态和城市读板断言基础上，新增首要战线压力摘要断言，并继续输出城市场景 PNG 和 `*-unit.png` 单位场景 PNG。
- README、flow、flowchart、test 文档同步战线压力边界、UI 展示和 v0.14 artifact 版本，并新增 v0.14 Agent A 提示词。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（玩法推进）/v0.14（战线压力与AI战略意图读板）.md`
- `update_log.md`

验证结果：

- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test --scratch-path .build/swift-test-local --disable-sandbox`：通过，48 个 Swift Testing 用例通过；本机 SwiftPM cache 目录只读警告不影响测试结果。
- `swiftc -swift-version 5 -module-cache-path .build/module-cache Sources/RomeLegionsCore/GameState.swift Tools/GameplaySmoke/main.swift -o .build/gameplay-smoke`：通过，无错误输出。
- `.build/gameplay-smoke`：通过，输出 `Gameplay smoke test passed.`
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -swift-version 5 -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk -target arm64-apple-ios17.0 -module-cache-path DerivedData/ManualModuleCache Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/RomeLegionsApp.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/RootView.swift RomeLegionsApp/Views/MainMenuView.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430`：通过，短横屏城市场景和 `DerivedData/battle-landscape-preview-unit.png` 单位场景生成成功；单位场景顶部显示战线 chip，军令入口仍在首屏。
- `.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844`：通过，竖屏城市场景和 `DerivedData/battle-portrait-preview-unit.png` 单位场景生成成功；地图、战线 chip、军令和情报面板无明显裁切或重叠。
- `.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768`：通过，宽屏城市场景和 `DerivedData/battle-wide-preview-unit.png` 单位场景生成成功；单位场景显示战线压力、敌军路线、目标叠层、将领详情和姿态预览。
- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：通过，输出 `yaml ok`。
- `plutil -lint RomeLegionsApp.xcodeproj/project.pbxproj`：通过，输出 `RomeLegionsApp.xcodeproj/project.pbxproj: OK`。

遗留事项：

- 本轮没有实现多回合 AI 搜索、战略路线规划、AI 权重调整、建筑树、人口、军团编制、存档 UI 或外交界面。
- 完整战局面板里的压力列表只展示核心只读报告，不参与招募、扩建、攻击或 AI 决策。
- 本轮没有默认本机跑完整 `xcodebuild build`；按项目规则交给 `origin/main` 最新 commit 的 GitHub Actions 重验证。
- CI 仍只上传必要 manifest、JUnit、日志和 xcresult，不上传本地 PNG；三尺寸城市场景 PNG 与 `*-unit.png` 单位场景 PNG 只用于本地目视检查，不提交版本库。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.14 run id、run attempt 和 artifact；不能使用 v0.13 旧结果包。

### v0.13 / 城市经营与招募预览读板

日期：2026-07-05

核心变更：

- `GameState` 新增 `CityDevelopmentPreview` 和 `CityRecruitmentPreview`，公开城市扩建成本/收益、招募成本、预计部署位置、可执行状态和阻塞原因。
- `developCity(id:)` 和 `recruit(_:at:)` 改为复用核心预览中的成本、收益和部署位置，避免 UI 预览与真实结算分叉；本轮不改变既有数值、部署顺序、AI 招募策略或存档字段。
- `GameViewModel` 新增 `SelectedCityBrief` 和 `CityRecruitmentOptionPreview`，把核心城市预览整理为本城产出、所属势力收入、罗马库存、部署摘要、扩建收益和四类兵种招募文案。
- `BattleView` 的完整/紧凑情报栏展示城市经营读板；完整/紧凑军令面板的扩建和招募按钮改为消费 ViewModel 预览，资源不足、缺少港口或无部署格时禁用并显示原因。
- Swift Testing 增加城市扩建预览、招募部署预览、资源不足、舰队港口、舰队港口被占和预览只读覆盖；Gameplay Smoke 增加城市扩建和招募预览主链路断言。
- `Tools/RenderBattlePreview` 保留 v0.11/v0.12 单位、将领、姿态和敌军路径断言，并追加那不勒斯城市读板、扩建收益、四类招募选项和舰队港口部署断言；每次渲染同时输出请求路径的城市场景图和 `*-unit.png` 单位场景图，避免城市截图覆盖单位 UI 视觉回归。
- README、flow、flowchart、test 文档同步城市读板、核心预览边界和 v0.13 artifact 版本，并新增 v0.13 Agent A 提示词。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（玩法推进）/v0.13（城市经营与招募预览读板）.md`
- `update_log.md`

验证结果：

- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test --scratch-path .build/swift-test-local --disable-sandbox`：通过，45 个 Swift Testing 用例通过；本机 SwiftPM cache 目录只读警告不影响测试结果。
- `swiftc -swift-version 5 -module-cache-path .build/module-cache Sources/RomeLegionsCore/GameState.swift Tools/GameplaySmoke/main.swift -o .build/gameplay-smoke`：通过，无错误输出。
- `.build/gameplay-smoke`：通过，输出 `Gameplay smoke test passed.`
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -swift-version 5 -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk -target arm64-apple-ios17.0 -module-cache-path DerivedData/ManualModuleCache Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/RomeLegionsApp.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/RootView.swift RomeLegionsApp/Views/MainMenuView.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430`：通过，短横屏城市场景和 `DerivedData/battle-landscape-preview-unit.png` 单位场景生成成功；军令区显示扩建和四类招募按钮，单位场景保留将领、姿态和敌军路线视觉覆盖。
- `.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844`：通过，竖屏城市场景和 `DerivedData/battle-portrait-preview-unit.png` 单位场景生成成功；地图、军令、城市情报顺序清楚，招募按钮无明显裁切。
- `.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768`：通过，宽屏城市场景和 `DerivedData/battle-wide-preview-unit.png` 单位场景生成成功；完整侧栏显示城市经营、扩建预览、四类招募选项和舰队港口部署，单位场景保留将领和敌军路径视觉覆盖。
- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：通过，输出 `yaml ok`。
- `plutil -lint RomeLegionsApp.xcodeproj/project.pbxproj`：通过，输出 `RomeLegionsApp.xcodeproj/project.pbxproj: OK`。

遗留事项：

- 本轮没有新增建筑树、城市等级、人口、军团编制、外交界面或 AI 招募策略；城市读板只公开并复用已有核心规则。
- 本轮没有默认本机跑完整 `xcodebuild build`；按项目规则交给 `origin/main` 最新 commit 的 GitHub Actions 重验证。
- CI 仍只上传必要 manifest、JUnit、日志和 xcresult，不上传本地 PNG；三尺寸城市场景 PNG 与 `*-unit.png` 单位场景 PNG 只用于本地目视检查，不提交版本库。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.13 run id、run attempt 和 artifact；不能使用 v0.12 旧结果包。

### v0.12 / 敌军意图路径贴合六边形地图

日期：2026-07-04

核心变更：

- `GameViewModel.enemyIntentMapOverlays(for:)` 不再只透传 `EnemyIntentSummary` 的直线路线，而是为每条敌军意图只读派生地图路线段。
- 敌军移动路线现在按 `Position.neighbors(width:height:)`、地形进入能力、地形移动成本、单位占用和该意图战术姿态后的有效机动生成相邻六边形路径；找不到合法路径时保留旧直线兜底，避免叠层消失。
- 目标段继续显示为 `destination -> target` 的 target leg，不和移动路径混淆；`BattleView` 仍只消费 `EnemyIntentMapOverlay.routeSegments`，不参与路径算法。
- `Tools/RenderBattlePreview` 增加路径断言：移动后攻击路线必须包含多个非 targetLeg 段，每段 `from` / `to` 都必须是六边形邻居，最后一段到达 `AIIntent.destination`，target leg 从 destination 指向目标格；同时保留 v0.11 将领详情、姿态预览和紧凑命令区像素检查。
- README、flow、flowchart、test 文档同步敌军意图六边形路径、ViewModel 只读派生边界和 v0.12 artifact 版本，并新增 v0.12 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（玩法推进）/v0.12（敌军意图路径贴合六边形地图）.md`
- `update_log.md`

验证结果：

- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -swift-version 5 -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk -target arm64-apple-ios17.0 -module-cache-path DerivedData/ManualModuleCache Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/RomeLegionsApp.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/RootView.swift RomeLegionsApp/Views/MainMenuView.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430`：通过，短横屏预览图生成成功；敌军路线显示为相邻六边形折线，军令入口仍在首屏。
- `.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844`：通过，竖屏预览图生成成功；地图路线折线、目标线和地图叠层可读，命令入口无回归。
- `.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768`：通过，宽屏预览图生成成功；路线从敌军位置按格点折向目的地，再以目标段指向罗马单位。
- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：通过，输出 `yaml ok`。
- `plutil -lint RomeLegionsApp.xcodeproj/project.pbxproj`：通过，输出 `RomeLegionsApp.xcodeproj/project.pbxproj: OK`。

遗留事项：

- 本轮没有改变 `GameState` 核心 AI 决策、评分、真实移动、战斗结算、Codable 存档字段或 Swift Testing 用例数量；路径只是 `GameViewModel` 的 UI 派生。
- 本轮没有默认本机跑完整 SwiftPM `swift test`、Gameplay Smoke 或 `xcodebuild build`；按项目规则交给 `origin/main` 最新 commit 的 GitHub Actions 重验证。
- 路线按核心 `Position.neighbors` 计算；未来如果要进一步提升视觉贴合度，应单独审查核心邻接和 `HexMetrics.center(for:)` 的坐标系一致性，不能在本轮顺手大改地图坐标。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.12 run id、run attempt 和 artifact；不能使用 v0.11 旧结果包。

### v0.11 / 将领详情与战术指挥可读化

日期：2026-07-04

核心变更：

- `GameViewModel` 新增选中单位指挥派生模型：`SelectedCommanderBrief`、`GeneralPassiveContribution` 和 `SelectedTacticalOrderPreview`，集中提供将领名、特性、被动贡献、技能状态、预计效果、战功摘要、各姿态攻防移、变化值和阻塞原因。
- 战术姿态预览通过局部复制选中单位并替换 `tacticalOrder`，再调用 `GameState.effectiveAttack/Defense/Movement` 计算，不写回 `GameState`，不改变核心数值、AI、结算或存档字段。
- `BattleView` 在完整侧栏、紧凑情报栏和战术姿态按钮中展示将领被动贡献、技能可用/冷却/阻塞状态、战功信息、均衡/突击/坚守/行军的攻防移预览和不可切换原因。
- 无将领单位会明确显示“无将领 / 无被动贡献”，避免把空状态伪装成加成。
- 紧凑命令栈在 iOS 上改为可滚动，并将“军令”置于手机竖屏和短横屏首屏，避免新增将领读板后挤掉攻击、姿态、技能、休整和跳过入口；macOS 预览渲染路径继续使用固定栈，规避 `ImageRenderer` 对紧凑 `ScrollView` 的空白渲染问题。
- `Tools/RenderBattlePreview` 的确定性场景加入凯撒鹰旗和非零经验，渲染前断言敌军意图路线仍存在，同时断言将领详情、鹰旗攻击被动、技能状态、战功摘要和完整战术姿态预览存在；渲染后对紧凑视口命令区域做轻量像素检查，防止命令区空白仍误判通过。
- README、flow、flowchart、test 文档同步选中单位指挥读板、姿态预览数据流和 v0.11 artifact 版本，并新增 v0.11 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（玩法推进）/v0.11（将领详情与战术指挥可读化）.md`
- `update_log.md`

验证结果：

- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：通过，输出 `yaml ok`。
- `plutil -lint RomeLegionsApp.xcodeproj/project.pbxproj`：通过，输出 `RomeLegionsApp.xcodeproj/project.pbxproj: OK`。
- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430`：通过，短横屏预览图生成成功；右侧首屏显示军令、姿态预览、技能、休整和跳过，敌军路线可读，情报可继续向下查看。
- `.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844`：通过，竖屏预览图生成成功；地图下方首屏显示军令、姿态预览、技能、休整和跳过，情报与将领读板可继续向下查看，无明显重叠或裁切。
- `.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768`：通过，宽屏预览图生成成功；完整侧栏显示姿态预览、鹰旗被动、技能效果、战功和冷却状态。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -swift-version 5 -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk -target arm64-apple-ios17.0 -module-cache-path DerivedData/ManualModuleCache Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/RomeLegionsApp.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/RootView.swift RomeLegionsApp/Views/MainMenuView.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。

遗留事项：

- 本轮没有改变 `GameState` 核心数值、`TacticalOrder` / `GeneralTrait` 加成、AI 决策、敌军意图排序、战斗结算、Codable 存档字段或 Swift Testing 用例数量；Swift Testing 基线仍为 41 个用例，由 `main` push 后 GitHub Actions 重验证。
- 本轮没有默认本机跑完整 SwiftPM `swift test`、Gameplay Smoke 或 `xcodebuild build`；按项目规则交给 `origin/main` 最新 commit 的 GitHub Actions 结果包验收。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.11 run id、run attempt 和 artifact；不能使用 v0.10 旧结果包。

### v0.10 / 敌军意图路线与目标地图叠层

日期：2026-07-04

核心变更：

- `GameViewModel` 新增敌军意图 UI 派生模型，把 `AIIntent`、来源单位、目标单位和目标城市转成起点、目的地、目标格、路线段、目标文案、预计伤害/效果文案和无障碍说明。
- `BattleView` 新增敌军意图路线层，使用 `HexMetrics.center(for:)` 绘制 `origin -> destination -> target` 可视线段，并增加目的地虚线叠层和目标格准星叠层；叠层不拦截地图点击，不改变 AI 行为。
- 敌情侧栏行从单行摘要扩展为可换行摘要，能显示来源、路线、目标和预计伤害或效果；单位头顶意图徽标保留并补充更完整的 VoiceOver 文案。
- Swift Testing 扩展既有 AI 意图测试，锁定直接攻击、移动后攻击和夺城意图继续提供 UI 叠层所需的 `destination`、`targetUnitID` / `targetCityID` 和 `projectedDamage` 字段，并保持预测只读。
- Gameplay Smoke 增加直接攻击、移动后攻击和夺城意图字段轻量断言，确认 forecast 不移动原始单位、不改变状态。
- `Tools/RenderBattlePreview` 改为确定性移动后攻击场景，渲染前断言 `enemyIntentMapOverlays` 含起点、目的地、目标格、路线段和预计伤害文案；三尺寸截图用于检查路线、目标叠层和侧栏敌情可读性。
- README、flow、flowchart、test 文档同步敌军意图路线/目标叠层、ViewModel 派生边界和 v0.10 artifact 版本，并新增 v0.10 Agent A 提示词。

关键文件：

- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `Tools/RenderBattlePreview/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（玩法推进）/v0.10（敌军意图路线与目标地图叠层）.md`
- `update_log.md`

验证结果：

- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test --scratch-path .build/swift-test-local --disable-sandbox`：通过，41 个 Swift Testing 用例通过；本机 SwiftPM cache 目录只读警告不影响测试结果。
- `swiftc -swift-version 5 -module-cache-path .build/module-cache Sources/RomeLegionsCore/GameState.swift Tools/GameplaySmoke/main.swift -o .build/gameplay-smoke`：通过，无错误输出。
- `.build/gameplay-smoke`：通过，输出 `Gameplay smoke test passed.`
- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430`：通过，短横屏预览图生成成功，敌军路线和目标叠层可辨认，右侧情报未被遮挡。
- `.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844`：通过，竖屏预览图生成成功，地图不横向裁切，路线和目标叠层位于地图内部，信息面板无重叠。
- `.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768`：通过，宽屏预览图生成成功，敌情面板显示接敌攻击、起点、目的地、目标和预计伤害，地图路线和目标叠层可读。
- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：通过，输出 `yaml ok`。
- `plutil -lint RomeLegionsApp.xcodeproj/project.pbxproj`：通过，输出 `RomeLegionsApp.xcodeproj/project.pbxproj: OK`。

遗留事项：

- 本轮没有改变 AI 评分、目标选择、真实移动路径、`performSimpleAI` 执行顺序或战斗结算；路线叠层只是 `AIIntent` 既有字段的直线可视化。
- 本轮没有默认本机跑完整 `xcodebuild build`；按项目规则交给 `main` push 后的 GitHub Actions 重验证。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.10 run id、run attempt 和 artifact；不能使用 v0.9 旧结果包。

### v0.9 / 将领技能冷却与战功状态可读化

日期：2026-07-04

核心变更：

- `ArmyUnit` 新增 `generalSkillCooldownRemaining`，并实现自定义 Codable，旧 `ArmyUnit` JSON 缺冷却字段时默认解码为 0。
- `GeneralTrait` 新增统一技能冷却回合数；`useGeneralSkill(unitID:)` 成功后写入冷却，核心层在冷却未归零时抛出 `generalSkillOnCooldown`。
- `GeneralSkillPreview` 新增冷却剩余和冷却文案；预览、释放和 AI 技能判断共享可执行状态，冷却时 `isExecutable == false`。
- 抽出所属阵营回合开始刷新 helper，让 `endTurn()` 和 `aiIntents(for:limit:)` 的 forecast copy 复用同一套行动重置、姿态清空和冷却递减逻辑；其他阵营回合不会递减冷却。
- 新增 `WarMeritStatus`，把经验转为军阶、战功进度和 `experience * 3` 伤害加成说明，不改变既有伤害公式。
- `GameViewModel` 暴露选中单位战功状态、技能冷却摘要和按钮 detail；`BattleView` 在完整/紧凑情报、将领卡、技能按钮和兵牌冷却徽标中展示冷却与战功。
- AI 主动技能判断补齐 `preview.isExecutable` 检查，避免治疗类技能在冷却中仍产生 `.useSkill` 意图或实际释放。
- Swift Testing 增加冷却写入、递减时机、核心阻止释放、预览只读、AI 遵守冷却、战功映射和旧 `ArmyUnit` JSON 兼容用例。
- Gameplay Smoke 增加技能冷却主链路和战功状态轻量断言。
- README、flow、flowchart、test 文档同步技能冷却、战功状态、AI 预测和 artifact 版本，并新增 v0.9 Agent A 提示词。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（玩法推进）/v0.9（将领技能冷却与战功状态可读化）.md`
- `update_log.md`

验证结果：

- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test --scratch-path .build/swift-test-local --disable-sandbox`：通过，41 个 Swift Testing 用例通过；本机 SwiftPM cache 目录只读警告不影响测试结果。
- `swiftc -swift-version 5 -module-cache-path .build/module-cache Sources/RomeLegionsCore/GameState.swift Tools/GameplaySmoke/main.swift -o .build/gameplay-smoke`：通过，无错误输出。
- `.build/gameplay-smoke`：通过，输出 `Gameplay smoke test passed.`
- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430`：通过，短横屏预览图生成成功，冷却和战功信息在侧栏可读，地图无明显遮挡。
- `.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844`：通过，竖屏预览图生成成功，紧凑情报面板新增战功/冷却信息后未出现明显裁切。
- `.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768`：通过，宽屏预览图生成成功，将领卡展示军阶进度条、冷却状态和技能摘要，无明显重叠。
- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：通过，输出 `yaml ok`。
- `plutil -lint RomeLegionsApp.xcodeproj/project.pbxproj`：通过，输出 `RomeLegionsApp.xcodeproj/project.pbxproj: OK`。

遗留事项：

- 本轮没有新增将领、技能种类、升级树或手动点选技能目标；后续仍可继续扩展将领成长线和更细的战略技能。
- 本轮没有默认本机跑完整 `xcodebuild build`；按项目规则交给 `main` push 后的 GitHub Actions 重验证。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.9 run id、run attempt 和 artifact；不能使用 v0.8 旧结果包。

### v0.8 / 将领技能范围与目标预览体验

日期：2026-07-04

核心变更：

- 新增 `GeneralSkillPreview` 只读模型，统一描述将领主动技能的范围格、受影响友军/敌城、预计恢复量、预计城防削弱、可执行状态、不可用原因和 UI 摘要。
- `useGeneralSkill(unitID:)` 改为先生成技能预览，再复用预览中的目标 ID 执行治疗或削城防，避免预览和结算使用两套目标筛选逻辑。
- AI 主动技能判断和 `.useSkill` 意图复用技能预览；攻城技能继续填目标城市，治疗类技能填主要受益友军。
- `GameViewModel` 新增选中将领技能预览、范围格、目标格、目标单位/城市集合和技能按钮摘要等 UI 派生数据。
- `BattleView` 新增技能范围青色虚线叠层、技能目标金色叠层，并在将领卡、紧凑情报面板和军令按钮展示范围、目标数、预计效果或不可用原因。
- Swift Testing 增加将领技能预览相关基线，覆盖预览只读、鹰旗/军需/盾墙恢复预览与释放一致、攻城预览与释放一致、攻城无目标不可执行、AI 技能意图目标来自预览。
- Gameplay Smoke 增加将领技能预览不改状态、恢复预览和攻城预览与释放结果一致的轻量断言。
- README、flow、flowchart、test 文档同步将领技能预览链路，并将 CI artifact 版本同步到 v0.8。
- 新增 v0.8 Agent A 提示词，明确本轮技能预览目标、UI 边界、测试和 Agent C 云端复判要求。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `RomeLegionsApp/App/GameViewModel.swift`
- `RomeLegionsApp/Views/BattleView.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（玩法推进）/v0.8（将领技能范围与目标预览体验）.md`
- `update_log.md`

验证结果：

- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test --scratch-path .build/swift-test-local --disable-sandbox`：通过，35 个 Swift Testing 用例通过；本机 SwiftPM cache 目录只读警告不影响测试结果。
- `swiftc -swift-version 5 -module-cache-path .build/module-cache Sources/RomeLegionsCore/GameState.swift Tools/GameplaySmoke/main.swift -o .build/gameplay-smoke`：通过，无错误输出。
- `.build/gameplay-smoke`：通过，输出 `Gameplay smoke test passed.`
- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430`：通过，短横屏预览图生成成功，地图完整可见，技能范围/目标叠层和侧栏摘要可读。
- `.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844`：通过，竖屏预览图生成成功，地图不横向裁切，技能叠层不遮断主要操作。
- `.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768`：通过，宽屏预览图生成成功，将领卡展示范围、友军目标数和技能状态。
- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：通过，输出 `yaml ok`。
- `plutil -lint RomeLegionsApp.xcodeproj/project.pbxproj`：通过，输出 `RomeLegionsApp.xcodeproj/project.pbxproj: OK`。

遗留事项：

- 本轮没有新增将领、技能冷却、升级树或手动点选技能目标；后续仍可继续扩展将领详情和成长系统。
- 本轮没有默认本机跑完整 `xcodebuild build`；按项目规则交给 `main` push 后的 GitHub Actions 重验证。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.8 run id、run attempt 和 artifact；不能使用 v0.7 旧结果包。

### v0.7 / AI 意图与移动后攻击预览一致性

日期：2026-07-04

核心变更：

- 新增 AI 规划态战斗预览 helper，让 AI 攻击评分、直接攻击意图和移动后攻击意图优先使用 `attackPreview` 的同一套伤害来源。
- 修正同一移动目的地既可占城又可攻击时的意图优先级：真实 AI 会移动后继续攻击，因此敌军意图优先显示 `.advanceAttack` 和预计伤害，无法攻击时才显示 `.captureCity`。
- 直接攻击和移动后攻击意图的 `projectedDamage` 与规划态 `attackPreview.damage` 对齐，保持 `aiIntents(for:limit:)` 只读不改原始状态。
- 新增 Swift Testing 用例，锁定移动后攻击意图、规划态预览和 `performSimpleAI` 真实伤害一致。
- Gameplay Smoke 增加直接攻击和移动后攻击 projectedDamage / preview 一致性断言。
- README、flow、flowchart、test 文档同步 AI 意图预计伤害来源，并将 CI artifact 版本同步到 v0.7。
- 新增 v0.7 Agent A 提示词，明确本轮 AI 一致性目标、核心边界、测试和 Agent C 云端复判要求。

关键文件：

- `Sources/RomeLegionsCore/GameState.swift`
- `Tests/RomeLegionsCoreTests/GameStateTests.swift`
- `Tools/GameplaySmoke/main.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（玩法推进）/v0.7（AI意图与移动后攻击预览一致性）.md`
- `update_log.md`

验证结果：

- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test --scratch-path .build/swift-test-local --disable-sandbox`：通过，32 个 Swift Testing 用例通过；本机 SwiftPM cache 目录只读警告不影响测试结果。
- `swiftc -swift-version 5 -module-cache-path .build/module-cache Sources/RomeLegionsCore/GameState.swift Tools/GameplaySmoke/main.swift -o .build/gameplay-smoke`：通过，无错误输出。
- `.build/gameplay-smoke`：通过，输出 `Gameplay smoke test passed.`
- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：通过，输出 `yaml ok`。

遗留事项：

- 本轮未修改 SwiftUI 呈现层、`GameViewModel`、存档结构或 Xcode project。
- 本轮没有默认本机跑完整 `xcodebuild build`；按项目规则交给 `main` push 后的 GitHub Actions 重验证。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.7 run id、run attempt 和 artifact；不能使用 v0.6 旧结果包。

### v0.6 / 战斗地图可读性与窄屏完整显示

日期：2026-07-04

核心变更：

- 修正非竖屏战斗区高度约束，让 `WarMapView` 使用顶栏后的真实可见高度，避免短横屏地图按过高容器放大后被裁切。
- 调整 `HexMetrics`，移除固定 44pt 地块下限，按地图安全边距和可用宽高自适应 tile 尺寸，并输出用于地图内容缩放的 `tileScale`。
- 强化地图视觉层级：可移动格改为黄色半透明六边形和虚线边框，选中格增加白金双层描边，攻击目标增加红色半透明覆盖层。
- 增加原创地形纹理：道路路线、水域波纹、城市据点横纹、森林/丘陵/平原低调纹理，使战略通道和海陆分界更清楚。
- 强化单位兵牌：加入单位类型底纹图标和阵营描边，保持将领星标、战术姿态和生命条显示。
- 为地图格和攻击徽标补充 VoiceOver 按钮语义，避免仅靠 `onTapGesture` 暴露交互。
- README 补齐 1024x768 宽屏战斗页预览命令。
- 新增 v0.6 Agent A 提示词，明确本轮 UI 边界、三尺寸预览验收和 Agent C 云端复判要求。

关键文件：

- `RomeLegionsApp/Views/BattleView.swift`
- `README.md`
- `md/prompt/v0（玩法推进）/v0.6（战斗地图可读性与窄屏完整显示）.md`
- `update_log.md`

验证结果：

- `env HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macosx14.0 -o .build/render-battle-preview Tools/RenderBattlePreview/main.swift Sources/RomeLegionsCore/GameState.swift RomeLegionsApp/App/GameViewModel.swift RomeLegionsApp/Views/BattleView.swift`：通过，无错误输出。
- `.build/render-battle-preview DerivedData/battle-landscape-preview.png 932 430`：通过，短横屏预览图生成成功，12x8 棋盘完整可见。
- `.build/render-battle-preview DerivedData/battle-portrait-preview.png 390 844`：通过，竖屏预览图生成成功，地图不横向裁切。
- `.build/render-battle-preview DerivedData/battle-wide-preview.png 1024 768`：通过，宽屏预览图生成成功，地图与完整侧栏不重叠。
- `git diff --check`：通过，无输出。
- `node Tools/verify_project.mjs`：通过，输出 `Project structure verification passed.`

遗留事项：

- 本轮只改 SwiftUI 呈现层、README 和提示词/日志，未修改 `GameState`、`GameViewModel` 玩法语义或核心测试。
- 本轮没有默认本机跑完整 `swift test`、Gameplay Smoke 或 `xcodebuild build`；按项目规则交给 `main` push 后的 GitHub Actions 重验证。
- Agent C 必须核对最新 `origin/main` commit 对应的 v0.6 run id、run attempt 和 artifact；不能使用 v0.5 旧结果包。
- `.github/workflows/ci-results.yml` 未同步 CI_VERSION，artifact 名称可能仍含 v0.4，验收以 manifest 的 commit、run id 和 run attempt 为准。

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
