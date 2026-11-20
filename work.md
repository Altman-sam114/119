# 当前任务

## 2026-11-20 继续改善战场视觉

- 目标：推进未完成的疆域、地图和战斗壳层改造，并改善移动、攻击提示及将领呈现；制作并筛选原创地图素材。保持真实规则、选择与存档不变。
- 验收：云端结构合同、完整 Render 与 Xcode/资源打包通过；检查三种尺寸的实图及攻击、移动、肖像的可辨识性；不把截图通过等同触控或最终美术验收。
- 计划：核对未提交 v0.84 工作和受影响显示链路；增补移动/攻击视觉层级、将领框和地图素材；同步必要文档；精确提交 push，下载最新结果包，失败按日志修复。Swift Testing/Smoke 因核心不变主动跳过。
- 保护：main 与 origin/main 起点为 `db207bc`，既有 v0.84 源码及测试工作与本次目标一致，继续完成；pbxproj、xcuserstate 和 `md/unity分析/` 不纳入。保留下方历史恢复记录，绝不覆盖其他会话改动。
- 当前：已复核并继续 v0.84 地图疆域与壳层工作；调整移动提示、攻击目标样式与将领肖像框，接入新生成 `water.png`。树林、山地生成稿带背景，未采用。已同步 README、flow、flowchart、test。下一步精确暂存本轮相关源码、素材、验证及文档，push 后等待云端。所有测试仅云端，不开子智能体。

## 2026-11-20 美术迭代补充（进行中）

- 目标：根据《大征服者：罗马》战场截图方向，优先制作并接入原创高品质兵种与地图素材；只做必要接线，不改规则、AI 或存档。本地不运行编译、测试或自动校验，不启用子智能体。
- 验收：素材在真实战场与资源证明图中可辨识、透明与地表约束保持，云端结构检查、Render 和 Xcode 构建通过；逐图核对云端证据。素材质量或生成服务不可用时如实记录，不能宣称全面完成。
- 计划：核对已有资源与远端；调用内置生图并目检；小步接入可用素材；按需云端验证并记录结果。主动跳过核心 Swift 测试和 Gameplay Smoke（规则未变）。
- 保护：下方 v0.84 未完成记录和未提交改动继续保留；不纳入本次美术提交，也不覆盖 pbxproj、xcuserstate 和未跟踪目录。main 与 origin/main 均为 a80cde4；GitHub 活跃账号 Altman-sam114。
- 当前：内置生图成功；替换 `legion.png`、`cavalry.png`、`ground.png`（提交 `4c2330b`）和 `archer.png`（提交 `a98df53`），均已推送 main；最新 run `44698425722` attempt 1 的结构、Render、Xcode/十三资源比对通过，JUnit 0 失败、Swift Testing/Smoke 主动跳过。部分截图目检发现密集战区标记重叠；18 图尚未逐一目检。舰船多次生成仍带背景，暂保留旧素材。百度搜索页工具无法访问，已检索到百度经验与发行方截图页面。下方未提交界面工作仍受保护。
- 下一步：完成全部截图目检并继续原创海军、地图地标及阵营兵种素材的质量迭代；界面重叠需要后续单独处理。持续目标未完成，不清除既有 v0.84 恢复点。

<!-- 活跃任务恢复点；本轮遵循单模型、云端-only，不开启子智能体。 -->

## 目标与验收

- 目标（2026-10-31 用户）：参照 EasyTech《大征服者：罗马》优化战斗页画风、界面与排版。本轮 v0.84：阵营疆域着色/边界、去除调试感制图网格、淡六边形网格，以及顶栏 SPQR 徽章/资源账条/结束回合、石质青铜方钮、深红抽屉标题、城名牌。
- 非目标：不复制或打包商业素材；不改核心规则、AI、ViewModel 状态、存档或人工工程配置；本轮不改主菜单（CI 无菜单截图证据）、不改兵模/肖像资源。
- 验收：疆域只按真实城市归属与核心 `hexDistance` 派生，平局/中立不着色，占城后重算，不写 GameState；新增 Render 数据门禁与实际像素证明（有/无疆域同图对比，边界两侧阵营色偏移、内陆不变）；原 18 图与全部既有门禁不削弱；Xcode 构建通过；云端 manifest/JUnit/PNG 与最新 SHA 精确核对后逐图目检。

## 计划与进度

1. [完成] 读取 AGENTS/work/日志/test，fetch 后 main=origin/main=`a80cde4`；下载 run `40822702860` attempt1，manifest/JUnit（static+Render 成功，3 主动 skipped）与 18 PNG 一致；Xcode 证据引用 `51f5a0c` / run `40820258972` 的 Xcode build 成功步骤。
2. [完成] 参考：根目录 `截屏2026-06-07 上午2.20.27.png` 与 App Store 15 张截图（临时目录 `/private/tmp/romelegions-ref/`，不入库）。差距：阵营疆域色块+粗边界、深色石质方钮、徽章资源条、深红弹窗标题、城名暗牌+阵营圆章；我方为单一橄榄地表、圆形象牙钮、长文字顶栏、调试感坐标网格。
3. [完成，未提交] 实现：BattleMapView（`regionContours` 共享轮廓追踪、`MapTerritoryOwnership` 疆域派生、`MapTerritoryLayerView` 淡网格+阵营边界、移除 `MapCartographyGridView`、城名暗牌+阵营圆章）、BattleViewStyles（石质青铜方钮、深红主按钮、`RomanStandardEmblemView`、新增 crimsonDeep/stone*/ink 色）、BattleShellControls（SPQR 菜单入口、`battleLedgerStrip` 资源账条、沙漏“结束回合”、深红抽屉标题）。
4. [部分完成，未提交] Render 新增 `verifyMapTerritoryLayer()`（归属/平局/中立/占城/只读/邻接边界/像素）；verify_project 新令牌并禁止网格回归；CI_VERSION v0.84。**未做**：flow/flowchart/test/README 文档同步。
5. [未开始] 精确暂存 push，下载最新结果包复判；通过后写 update_log 并清空本文件。

## 本轮编辑记录与已有改动保护

- 起点：main `a80cde4611c26a2e5141803aec40623fe29aa6f3`，与 origin/main 一致；`gh auth status` active=Altman-sam114。
- 已有未提交（不属于本轮，不暂存）：`RomeLegionsApp.xcodeproj/project.pbxproj`、Xcode `UserInterfaceState.xcuserstate`、未跟踪 `md/unity分析/`。
- 预计文件：`RomeLegionsApp/Views/BattleMapView.swift`、`BattleViewStyles.swift`、`BattleShellControls.swift`、`Tools/RenderBattlePreview/main.swift`、`Tools/verify_project.mjs`、`.github/workflows/ci-results.yml`（仅版本号）、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/test/test.md`、`README.md`、`update_log.md`、`work.md`。

## 关键决策与风险

- 疆域采用“最近城市归属，异主平局不着色”的纯展示派生，复用海岸同一整数顶点轮廓；画布外延景观格按与海岸相同的钳制规则继承边缘格归属。
- 只画边界内侧渐变带与实线，不做整片填色：既有材质门禁要求绿/土色像素，整片阵营色会掩盖地貌；内陆保留真实材质。
- 用户中途要求“不要本地编译”：本地只读/编辑/Git，所有编译、测试、Render 交给云端。

## 验证选择与证据

- baseline：云端 diff/结构合同；改 verify/workflow 版本号，附带 CI 范围 Node 合同。
- direct：Render（全部既有门禁+疆域新门禁，18 PNG）+ Xcode（App 编译与十三资源 cmp）。
- skipped：Swift Testing、Gameplay Smoke（核心未改）。
- 改前证据：`a80cde4` / run `40822702860` attempt1 已下载至 `/private/tmp/romelegions-review-40822702860/`。

## 当前步骤、阻塞与下一步

- 当前（2026-11-01 用户要求暂停并交接）：代码已改完但**从未编译**（遵守云端-only），未提交、未 push、无云端证据。不能视为完成或验收。
- 本轮未提交文件（只暂存这 7 个）：`.github/workflows/ci-results.yml`、`RomeLegionsApp/Views/BattleMapView.swift`、`BattleShellControls.swift`、`BattleViewStyles.swift`、`Tools/RenderBattlePreview/main.swift`、`Tools/verify_project.mjs`、`work.md`。仍不得暂存 pbxproj / xcuserstate / `md/unity分析/`。
- 待复核风险：
  - `Path.intersection(_:)`（iOS 17/macOS 14 API）首次使用；若云端编译报错，改为只 `clip(to: land)` 再描边。
  - 新像素门禁阈值为推算值（罗马红 r>0.55，迦太基紫 b>0.55 且 b>r+0.08，内陆灰偏差<0.10）；失败时先读日志 `Territory pixels:` 实测值再调整，不放宽到无意义。
  - 方钮 ivory 图标、顶栏/城名牌变化可能影响既有像素门禁：`Battle shell pixels` 的 tools>10 亮像素、`hasFixedReconSelector`（未改）、`commandDockSignature`（未改）；失败按日志诊断。
  - 竖屏顶栏加宽资源条后是否挤压标题，需在 390x844 图目检。
- 下一步：① 补 flow.md/flowchart.md（疆域链路、移除网格、v0.84 HUD）、test.md（Render 新增疆域门禁一句）、README 能力行；② 再次 `git fetch` 确认 origin/main 仍为 `a80cde4`；③ 精确 `git add` 上述文件，提交 `v0.84: campaign territory borders and stone-bronze HUD`，push；④ 下载 run 结果包至 `/private/tmp/romelegions-review-<run_id>/`，核对 manifest/JUnit/18 PNG/Xcode，逐图对照参考图目检；⑤ 通过后写 update_log、清空本文件。
