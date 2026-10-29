# 测试规范

本文只定义可复用的范围选择、云端执行和证据核对制度。版本、commit、run ID、单次结果和历史性能数据写入 `update_log.md`；不要求逐版累积历史合同或无关 CI 测试。

## 1. 默认云端-only

- 编译、测试和自动校验默认只在 GitHub Actions 执行；除非用户明确要求，本地不运行测试、build、typecheck、RenderBattlePreview、`node Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析或脚本语法校验。
- 本地允许读取、编辑、`rg`/`sed`、只读 diff/status、Git 同步/提交/推送、GitHub 身份/结果查询与必要 artifact 下载。
- 用户明确授权本机编译或运行 iOS 时，只能使用已有 UDID 以 `FAC4325D` 开头的唯一模拟器；不可用就报告，不创建、克隆或选择其他设备。云端不受此限制。
- 项目为 SwiftPM + SwiftUI Xcode 工程：核心 `RomeLegionsCore`，工程 `RomeLegionsApp.xcodeproj`，scheme `RomeLegions`，最低 iOS 17 / macOS 14；无必启后端或网络服务。存档验证使用隔离的临时 SQLite，不污染用户存档。

## 2. 按任务选择

先根据 `work.md` 的本轮编辑记录明确“修改文件/符号 → 受影响行为/调用方 → 验证入口”，再选择 `baseline + direct + optional`：

- `baseline`：云端 diff/结构合同检查，保护入口、资源登记与既有架构边界。
- `direct`：修改点和真实受影响调用方的行为、协议、状态与展示；共享核心规则可能影响全部消费者，不能省略真实关联。
- `optional`：发布、失败诊断、兼容性调查或用户明确要求的额外回归，记录原因后开启；没有依据不运行。
- `skipped + reason`：主动不选的无关项明确说明；必需项意外 skipped、超时或缺产物属于失败，不属于范围优化。

不因为历史版本相近、同属一个大文件、修改 workflow 或笼统“UI”标签就打开历史测试全集；不把其他会话的未提交改动或累计未推送提交当成本轮编辑记录。CI 仍必须覆盖本次 push 实际包含的全部提交，避免多提交 push 漏验。

| 改动范围 | Baseline | Direct（云端） | 默认跳过 |
| --- | --- | --- | --- |
| Markdown、日志、work.md、忽略规则 | diff、文档/结构合同 | 当前入口、计划生命周期与历史归档边界 | Swift Testing、Gameplay Smoke、Render、Xcode |
| CI workflow、范围/结果路由、结构工具 | diff、结构合同 | CI 范围选择与结果合同的 Node 测试；实际受影响的步骤需另选对应领域或有依据地手动 full | 未涉及的玩法/UI 编译与渲染 |
| `Tests/RomeLegionsCoreTests/` | diff、结构合同 | Swift Testing | Smoke、Render、Xcode（除非同时改其输入） |
| `Tools/GameplaySmoke/` | diff、结构合同 | Gameplay Smoke | 其它无关检查 |
| `Tools/RenderBattlePreview/` | diff、结构合同 | Render 与其真实夹具/PNG | Swift Testing、Smoke、Xcode（除非同时改 App 输入） |
| 核心规则或 `Package.swift` | diff、结构合同 | Swift Testing、Smoke、Render、Xcode；核心是预览/结算/AI/UI 的公共输入 | 无额外无关探针 |
| GameViewModel、战斗 View/共享样式、兵模资源 | diff、结构合同 | Render + Xcode；所选 Render 保留其现有完整门禁 | 核心测试/Smoke（未改核心时） |
| 菜单/根入口/存档等其它 App 源码、工程、其它资源 | diff、结构合同 | Xcode 与修改行为的定向证据；涉及战斗共享输入时加 Render | 无关战斗图与核心测试 |
| 未识别路径、缺少可靠 diff 基线 | diff、结构合同 | 保守 full 并在 scope 记录原因，先调查分类缺口 | 不默默漏验 |

自动路由以文件依赖为下限，不能识别文件内全部语义；模型仍需核对 direct 是否充分。CI 执行命令/编译清单/结果语义变化时，须补对应步骤验证或带理由手动 full，不把仅路由测试通过解释为所有分支执行通过。文档-only、scope/metadata 路由维护本身不要求游戏编译。

## 3. 云端入口与执行

`.github/workflows/ci-results.yml`（GitHub Actions，`RomeLegions CI Results`）支持 `main` push 和手动 `workflow_dispatch`：

- 默认 `auto`，`Tools/ci_scope.mjs` 根据本次 push 的 before..SHA 全部改动选择必要检查；重命名按删除/新增两端识别。
- 手动 `auto` 比较目标提交与父提交；手动 `full` 用于有依据的完整回归。无可靠基线时保守全量并写明原因。
- baseline 必跑；其它四项按直接输入选择。workflow/范围工具修改本身不把所有业务步骤标成 direct。
- `Tools/ci_scope.test.mjs` 仅在 CI 路由/工具变化时执行，覆盖文档、核心、测试、UI、资源、混合改动、未知路径、full、无基线与结果状态合同；不启动 Swift、Xcode 或模拟器。
- `git diff --check` 在云端覆盖完整比较区间，工程解析、`node Tools/verify_project.mjs` 检查既有结构；不要求历史 prompt 保持执行效力。

按 scope 选择的真实执行入口：

| 检查 ID | 入口 | 证明范围 |
| --- | --- | --- |
| `static-checks` | 云端 diff/工程解析、`node Tools/verify_project.mjs`，按需 Node CI 合同测试 | 结构/接线，不证明游戏运行或美术品质 |
| `swift-tests` | `swift test --scratch-path .build/swift-test-ci --disable-sandbox` | 核心规则行为，实际数量从日志读取 |
| `gameplay-smoke` | `swiftc` 编译并运行 `Tools/GameplaySmoke/main.swift` | 核心集成与 AI 执行/预演同源 |
| `render-battle-preview` | 云端编译并运行 `Tools/RenderBattlePreview/main.swift` | ViewModel 只读/命令链、几何/布局、图像资源与静态截图 |
| `xcode-build` | 无签名 `xcodebuild build`，`generic/platform=iOS` | App target 与 bundle；含四兵种、五类地表/地标及四将领肖像逐文件 cmp |

默认串行重步骤；Render 使用标准 `-O`，不使用移除安全检查的 `-Ounchecked`。编译/夹具/逐图进度写日志，任一尺寸失败立即传播。总 job 75 分钟、Render 50 分钟、Xcode 15 分钟上限保留；不得靠无限加时或弱化门禁处理性能回归。不会为纯文档任务启动这些重步骤。

## 4. Render 与关联回归

只有 scope 选中 Render 才要求下列产物；未选中时不把“没有截图”记为游戏回归失败。工具目前是聚合入口，选中后保留其完整已有断言，不能伪称只运行了某一条夹具。

- 三个布局尺寸：932x430、390x844、1024x768；每尺寸 default 城市、unit、focused、focused-enemy、focused-countermeasure 五场景，共 15 张战斗图；另有 1400x1000 的 `battle-unit-art-preview.png`、1400x880 的 `battle-scenery-art-preview.png` 和 1600x800 的 `battle-commander-art-preview.png`，共 18 PNG。
- 敌路/计划/威胁/反制/目标线、成长、将领、城市、处境、军令窗口、推进线与侦察 HUD 均来自真实核心/readout；读取/聚焦不改核心、AI intent 或存档编码。
- 攻击锁定/取消幂等，预演等于核心 `CombatPreview`；敌将 focused/primary fallback 同源且只读，失效焦点清理；反制姿态/移动/锁敌三个独立入口只产生各自允许的状态变化，不自动攻击或串联命令。
- AI 的 intent/plan/threat/map 复用同一个姿态/落点/目标预览，真实结算匹配；保留立即击杀、集火、冷却、已行动、合法落点、占城终局与旧优先级行为。预测不能反向写入核心。
- 五种显示上下文优先级、地图主/次/隐藏层、无锁定时无攻击来源描边、用户文案不泄露 raw source ID；portrait“仅侦察”文字、102pt 命令坞和独立 44pt 入口不得回归。
- 镜头首帧 1x 取景、1x...1.8x clamp、独立画布在 1x 的拖移边界、三尺寸普通/焦点工作区、角落/中心聚焦及 reset 后重新取景；实际地形中心仍正确，竖屏实体至少比适屏鸟瞰大 1.5 倍，短横屏棋盘覆盖实际视口宽度。地图空间层共用变换，固定 HUD/镜头工具不随图漂移。
- 六边形顶点与核心邻接共边、自然岸线/内湖/岛/陆桥、地表中心分类、真实相邻道路、顺序稳定性和地图安全区；不使用屏幕距离代替核心邻接。
- 四兵种路径/透明 alpha/实体材质像素/384px 解码约束、紧凑兵牌高度；五类地表/地标的独立路径、768/384px 有界解码、材质明暗、地表不透明与地标透明 alpha；四将领独立资源、256px 解码、明暗和姓名精确匹配，未知/相似姓名不得借用身份；真实 App 十三类资源逐字节一致。Canvas/中性图标 fallback 不算资源通过。
- focused-enemy 的无宿主 ImageRenderer 使用有限静态 drawerContent；真实 App 默认仍是可滚动抽屉，截图适配不能改变产品行为。

常见失败从日志定位 `missingAttackForecast`、`missingEnemyCommanderThreatFocusReadout`、`missingCountermeasure*RuntimeConfirmation`、`missingAIMoveSkillPreviewChain`、`missingAITacticalActionPreviewChain`、`missingMapViewportStrategy`、`missingHexTerrainContinuity`、`missingContinuousTerrainSurface`、`missingNaturalTerrainContours`、`missingBattleUnitArtwork` / `opaqueBattleUnitArtwork`；完整 token 和断言以工具源码为准，不在本文件逐版重复。

所选 Render 成功后，同一个模型逐图检查固定 HUD、地图/叠层对齐、可读性、无裁切/重叠/空白，确认命令和阵营状态不被新美术遮住。像素/静态截图通过不代表触控、极端 Dynamic Type、VoiceOver 全流程或商业美术目标完成；这些缺口如实列出，按任务需要补充，不默认启动无关 UI 测试。

## 5. 结果包与核对

每个 run 必须上传未加密结果包，至少包含 `ci-artifact-manifest.json`、`ci-failure-summary.md`、`junit.xml`、`validation-scope.json` 与已选检查的日志。Render 选中时列出预期 18 PNG；Xcode 选中时保留实际 xcresult。未运行项不伪造日志/结果文件。

manifest 必须包含：

- 身份：`version`、`branch`、`commitSha`、`shortSha`、`runId`、`runAttempt`、`workflowName`、时间与工程/scheme/destination。
- 范围：`validationProfile`、比较基线、changed files、baseline/direct/optional、`selectedChecks` 与 `skippedChecks` 的原因；每项实际 outcome。
- 证据路径：JUnit、失败摘要、scope、实际日志、预期 Render 路径及实际 result bundle。选中项缺失/失败要进入最终失败门禁。
- JUnit 保留五个检查身份，主动未选项写 `<skipped>`，不能计作失败或成功；选中却 skipped/cancelled/missing 必须失败。汇总测试状态只按已选测试计算；未选任何测试为 skipped，而非“全部游戏测试成功”。

artifact 格式：`RomeLegions-ci-<version>-main-<short_sha>-run<run_id>-attempt<run_attempt>`。

同一个模型核对：

1. `gh auth status` 确认使用 `Altman-sam114`；需要登录才执行 `gh auth login`。
2. 查询 `origin/main` 最新 SHA 和对应最新 run/attempt，不仅看列表第一行，不用过期 artifact 代替。
3. 只下载本轮结果包到 `/private/tmp/romelegions-review-<run_id>/`；核对 manifest branch/SHA/run/attempt 与 GitHub 状态精确一致。
4. 对照 `work.md` 与 scope，确认所选检查覆盖真实 direct、optional 有依据，主动 skipped 理由合理；核对 JUnit、主日志、失败摘要和必要 PNG/xcresult 相互一致。
5. 失败先读具体诊断，追加修复 commit 并重验；权限、网络、缺依赖或产物不足都明确“阻塞/未验证”，不能谎称通过。

```sh
gh run list --workflow "RomeLegions CI Results" --branch main --limit 5
gh run view <run_id>
gh run download <run_id> --name <artifact_name> --dir /private/tmp/romelegions-review-<run_id>
```

## 6. 收口与容量

- 将实际命令/检查、SHA、run/attempt/artifact、结果、skipped 原因和未验证风险写入日志；无需分角色汇报。
- 文档收口提交仍核对自己的最新文档检查；没有改变业务输入时引用业务检查的精确 SHA，不重复整套编译，也不把旧 SHA 结果写成最新 SHA 的运行结果。
- `work.md` 在必要验证和目标完成前保留恢复点，完成后只留空模板；不把未完成或阻塞的计划清掉。
- 小夹具、必要日志/结果优先；不上传 DerivedData、`.build`、模型、缓存或历史包全集，不默认下载无关 artifact。
- 失败、超时、缺少真实资源/设备或未运行项必须如实保留。提速只减少无关与重复执行，不减少直接关联的必要覆盖。
