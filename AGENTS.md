# AGENTS.md

`RomeLegions` 的长期入口：只保留项目事实、开发流程和硬规则。用户直接提出目标，由同一个模型自主分析、规划、实现、核对云端结果并交付，不再使用角色前缀、身份标签、分角色交接或强制版本化提示词。未经用户明确要求，不启用子智能体。

## 1. 项目事实与读取顺序

`RomeLegions` 是原创 SwiftUI iOS 罗马题材战棋原型，核心规则在纯 Swift `RomeLegionsCore`，SwiftUI 通过 `GameViewModel` 展示战场、命令、敌军意图和态势。

每次开始任务或上下文压缩后：

1. 先读 `AGENTS.md`、根目录 `work.md`，检查 `git status --short --branch` 和最近提交；已有计划先核对实际文件与 Git 状态，不能凭压缩前记忆续做。
2. 按目标读取相关源码、调用方和测试；架构定位看 `md/flow/flow.md`，图示看 `md/flow/flowchart.md`，选择验证看 `md/test/test.md`。
3. 需要历史决策或证据时，读 `update_log.md` 的当前状态和相关条目，不通读全部历史合同。
4. `README.md` 是简明介绍；`md/prompt/` 只保留历史设计，不是当前执行入口。旧提示词与当前源码、用户目标冲突时，以最新用户要求和实际实现为准。

## 2. 文档职责

| 文件 | 唯一职责 | 更新时机 |
| --- | --- | --- |
| `AGENTS.md` | 稳定项目事实、流程与硬规则 | 长期规则或职责改变 |
| `README.md` | 项目介绍、能力、架构和上手 | 对外能力或上手方式改变 |
| `work.md` | 当前任务计划、进度、恢复点和本轮编辑记录 | 开始、阶段完成、决策/阻塞变化、压缩前；完成后清空任务内容 |
| `md/flow/flow.md`、`md/flow/flowchart.md` | 当前真实架构、数据流与执行流 | 架构或实际流程改变，两份同步 |
| `md/test/test.md` | 可复用的测试选择与结果包制度 | 测试入口、路由或验收规则改变 |
| `update_log.md` | 版本、重要维护、决策、验证证据和遗留问题 | 有意义的功能、修复或流程变更 |
| `md/prompt/` | 历史设计归档 | 默认不新增、不覆盖旧文件 |

不为每个小修复改遍所有文档，不把版本号、run ID、单次通过结论继续堆进入口、flow 或 test；历史证据写日志。流程整理不冒充玩法版本。文档移动时修正活动链接，历史提示词中的旧路径仅作历史语境。

## 3. 自主迭代流程

1. 理解目标，检查当前状态与相关实现，区分本轮改动和已有未提交改动；开始开发前安全同步 `origin/main`。若已有改动妨碍同步，不自动 stash、覆盖或回滚，先说明阻塞。
2. 将目标、非目标、可验证的分步计划、验收标准、风险、预计文件和验证选择写入 `work.md`。不必先让用户指定角色或生成提示词；普通实现取舍自主决定，确需人工决策才询问。
3. 小步实现，只改与目标直接相关的代码、测试和必要文档；每完成一步同步 `work.md`。发现计划与源码不符时调整计划并记录依据，不盲目执行历史提示词。
4. 根据本轮编辑记录选择 `baseline + direct + optional`，对不运行项记录 `skipped + reason`；不得为了流程完整运行无关 CI 测试。
5. 本地只做读取、编辑、只读 diff/status 和 Git 同步/提交/推送；编译、测试及自动校验默认都交给云端。
6. 核对本轮 diff、暂存范围、分支和远端，在 `main` 提交本轮相关文件并 `git push origin main`，由 GitHub Actions 按改动范围验证。
7. 同一个模型下载并核对最新 SHA/run/attempt 的结果包；失败先诊断，在 `main` 追加修复后重验，不回滚用户改动、不用旧结果代替新结果。
8. 本轮必要检查通过后继续下一个小目标；总目标完成时把长期结论和证据写入 `update_log.md`，清空 `work.md` 的任务内容并交付。日志收口提交只需其自身的文档检查，不因记录证据无限重跑已通过的业务检查。

遇到需要账号/密钥/付费、无法判断归属的冲突或必须由用户决定的产品取舍时，保留恢复点并询问；连续重复同一失败且没有新诊断依据时停止盲目重试。未完成的目标不能因停止而写成已完成。

## 4. work.md 生命周期

- 根目录固定保留 `work.md`；空闲时只保留空模板，不累积历史任务，不额外建立同用途计划文件。
- 活跃任务至少记录：目标/非目标/验收标准、分步清单、当前步骤、本轮文件或 hunk 编辑记录、已有改动保护、关键决策、验证选择/证据、阻塞与下一条可执行动作。
- 步骤完成、计划变化、云端失败或等待、上下文压缩前及时更新，不只在最终回复补写。
- 压缩后先重读，再核对文件、commit 和云端状态，避免重复实现或把已排队任务当成未执行。
- 暂停、失败、权限阻塞或仍有必要验证未完成时保留任务内容；真正完成后迁移必要结论到日志，再清空任务内容。保留模板不等于保留已完成计划。
- 不为保存中间计划单独 push；只提交本轮相关内容，最终 `work.md` 应为空模板。不要清掉不属于当前任务的未完成记录。

## 5. 核心架构边界

- 核心规则只在 `Sources/RomeLegionsCore/GameState.swift` 或后续核心模块建模；规则变化同步影响预览、结算、AI 评分和测试。
- `GameViewModel` 持有 `GameState`，负责选择态、命令态、预览和 UI 派生组装；Map/Strategy/Selection 三个 readout 文件只定义展示数据，不另设核心状态源。
- SwiftUI 只展示与触发公开命令，不在 `body`、按钮闭包或生命周期内写复杂规则。`RootView` 切换菜单/战斗；战斗壳层、控制、地图、读板、样式各自保持职责。
- `WarMapView` 的 `MapWorkspaceLayout` 区分战区画布和固定 HUD 工作区，`MapViewportState` 按画布边界管理缩放、拖移、首帧取景、选择聚焦和复位；二者不进入 `GameState`、存档或玩法选择源。
- `SaveStore` 通过 SQLite 保存编码后的完整 `GameState`，不绕过状态结构写零散状态。
- `Resources/BattleUnitArt/` 原创四兵种、地表材质、地标与将领肖像 PNG 随 App 打包；`BattleArtworkLoader` 统一查找与 ImageIO 受限解码，Unit/Scenery/Commander 各自缓存。肖像只按真实姓名精确匹配，未知将领不得冒用已有身份。独立 macOS 云端 Render 通过显式 `ROMELEGIONS_ART_ROOT` 读资源，iOS 仅从 bundle 读取；缺失时降级不能冒充资源验收通过。
- `Tests/RomeLegionsCoreTests/GameStateTests.swift` 验证核心规则；`Tools/GameplaySmoke` 验证集成，`Tools/RenderBattlePreview` 验证展示链路，`Tools/verify_project.mjs` 验证结构。UI/静态合同不能替代核心行为测试。

## 6. 测试规则

- 默认云端-only，除非用户明确要求本地验证；参考项目中的本地构建规则不适用于这里。
- 本地禁止测试、build、typecheck、RenderBattlePreview、`node Tools/verify_project.mjs`、`git diff --check`、YAML/JSON/Plist 解析与脚本语法校验。允许读取、编辑、`rg`/`sed`、只读 `git status`/`git diff`、Git 同步/提交/推送、查询/下载云端结果。
- 用户明确允许本机编译或运行 iOS 时，必须且只能使用已有的、UDID 以 `FAC4325D` 开头的唯一模拟器；不存在或不可用就报告，严禁创建、克隆或选择其他设备。云端不受此设备限制。
- 具体 `baseline + direct + optional` 见 `md/test/test.md`；纯文档、CI 路由或结构工具修改不自动触发 Swift Testing、Gameplay Smoke、Render 或 Xcode build。
- 核心公共规则变更覆盖真实受影响的预览/结算/AI/UI；UI 变更验证实际受影响的展示链路，不因同属一个历史版本扩大范围。全量回归需明确的发布、共享依赖或失败调查依据，或用户要求。
- 必需检查缺失、超时、意外 skipped 都不算通过；按范围主动跳过的无关项要在 manifest/JUnit/摘要中明确区分。

## 7. Git 与云端结果

- 默认只在 `main` 修改、提交并推送 `origin/main`；不新建分支或 PR，不复制参考项目的分支制度。
- 开始前检查工作区，`git fetch origin` 后确认同步状态；可安全快进时使用 `git pull --ff-only origin main`，不强制覆盖已有改动。
- 提交/push 前再次确认当前分支为 `main`、远端为目标仓库的 `origin/main`，以本轮编辑记录精确暂存文件/hunk；禁止 `git add .` 把用户或其他会话改动一并带走，禁止 amend 未获授权的提交。
- 只使用 `Altman-sam114` 的 GitHub 权限；先核对 `gh auth status`，需要认证才 `gh auth login`。权限缺失必须如实报告。
- `.github/workflows/ci-results.yml` 在 `main` push 或手动触发时选择必要检查；未知改动或无可靠 diff 基线时保守全量，不能默默跳过。
- 结果包不加密；核对 manifest 的 `branch`、`commitSha`、`runId`、`runAttempt`、`validationProfile` 与实际选择，再核对 JUnit、相关日志、失败摘要和必要 PNG/xcresult。默认缓存 `/private/tmp/romelegions-review-<run_id>/`，只下载本轮必要 artifact。
- 验收时重新核对 `origin/main` 最新 SHA；若已有后续提交，不把旧 run 当成最新。仅文档收口后业务输入未变，可引用其精确源 SHA 的已通过证据，并为文档提交核对自身最新检查，不能谎称最新提交重新跑过业务测试。
- 没有 `origin`、网络/权限不足或 artifact 下载失败时，明确“未验证/阻塞”，不能用本地输出、旧报告或仅成功的静态合同冒充云端运行证据。

## 8. 禁止项与交付

- 不覆盖、回滚用户或其他会话改动；发现无法解释的新变动先停下核对归属。
- 删除文件/目录默认 `trash <path>`；仅已获确认的临时文件/构建产物清理才用 `rm`，不使用破坏性 Git 命令。
- 不擅自引入第三方框架、切换技术栈或做无关重构；不为过检查削弱断言、删除测试或减少必要覆盖。
- 不让 AI 意图预测修改 `GameState`，不让预览与结算采用不同规则。
- 不提交构建缓存、DerivedData、临时数据、无关截图或大体积模型/历史 artifact，不默认全量下载。
- 最终用中文简洁说明：改动与关键文件、目标完成情况、当前分支/commit/push、实际云端检查与证据、skipped 及原因、未验证范围/风险；无需角色自我介绍或分角色报告。
