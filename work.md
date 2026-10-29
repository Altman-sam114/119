# 当前任务

<!-- 活跃任务恢复点；本轮遵循单模型、云端-only，不开启子智能体。 -->

## 目标与验收

- 目标：持续向成熟罗马题材战棋推进；当前小目标是以《大征服者：罗马》公开实机图为布局/材质参考，改进战斗 UI、地图质感和四兵种原创生成美术。
- 非目标：不复制商业游戏原素材，不更换引擎，不混入人工工程/Unity 分析改动；此视觉迭代不更改核心规则、AI 数值和存档。
- 验收标准：四类高品质透明兵模实际打包、地图不遮蔽单位/城市/命令；三尺寸五场景的云端 Render 与 Xcode 成功，manifest/JUnit/PNG 与最新实现 SHA 精确核对；保留 44pt 命令入口和所有原选择/预演链路。

## 计划与进度

1. [完成] 安全 fetch/pull 后 main 与 origin/main 同为 32fb4fe；核对改前云端 manifest/JUnit/日志及三类代表图，百度移动检索取得两张真实战斗参考。
2. [完成，待云端验收] 四兵种+五类材质地标、共享解码缓存、地图实体/情报条与命令钮已经接入；原15图门禁保留，加材质/地标门禁和第17张检视图。
3. [进行中] 精确提交 main/push，下载本轮结果包、逐图核对并修复；记录结论后继续下一小目标（将领/AI）。

## 本轮编辑记录与已有改动保护

- 起点：main `32fb4fe3e14cd3a99ebe0c698ab520eda98ea00e`，GitHub API 确认远端同 SHA；`gh auth status` active 为 Altman-sam114。
- 已有未提交：`RomeLegionsApp.xcodeproj/project.pbxproj`（人工签名/注释排序）、Xcode `UserInterfaceState.xcuserstate`、未跟踪 `md/unity分析/`；不覆盖、不暂存。
- 当前编辑：四兵种 PNG 已替换，五类新材质/地标已复制；BattleViewStyles 共享加载器/缓存与 chrome 尺寸，BattleMapView 材质/地标/实体层级/78pt 竖屏情报行，BattleShellControls 兵种招募图/金属命令钮；Render 新资源门禁/检视图/同源采样区域；verify/CI 范围测试/结果清单与必要 README、AGENTS、flow/flowchart/test、美术说明同步。
- 预计文件：BattleMapView.swift、BattleViewStyles.swift、BattleShellControls.swift、Resources/BattleUnitArt 四 PNG、Tools/RenderBattlePreview、必要结构/CI 与架构/美术说明；不为小改动重写全部入口。

## 关键决策与风险

- 用户明确持续迭代、不得多开子智能体：全程当前模型串行完成；目标未完成不清空恢复点。
- 百度桌面搜索/图片页返回安全验证，移动版成功。实际查看 Bilibili BV1xF1oBUEeQ（麦松战役）与 BV14o1dBDEYM 实机缩略图；只参考地图主导、材质、实体比例，不打包原图。
- 内置生图实际完成四兵种+五地表/地标；弓兵首稿右侧弓箭裁切，已单独编辑缩小构图修正。工具没有可核验模型 ID，不虚构底层模型名称；不使用 CLI/API fallback。
- Git 默认 DNS 指向不可连接地址，使用单条命令 `-c http.curloptResolve=github.com:443:140.82.112.3` 成功 fetch/pull；不改系统 DNS、不写永久 Git 配置。

## 验证选择与证据

- baseline：云端 diff/结构合同；如改 CI/结构工具，加现有 CI 范围 Node 测试。
- direct：Battle UI/共享样式/兵模 -> Render 全部既有门禁、16 PNG 与 Xcode App/bundle；新增材质必须做资源/解码/视觉直接证据。
- optional：当前无；后续规则/AI 迭代独立选择核心真实行为验证。
- skipped 及原因：本地所有编译/测试/自动校验禁止；本轮视觉阶段不改核心，云端 Swift Testing/Gameplay Smoke 不选。
- 改前证据：v0.81 da244ab / run 40630157134 attempt1 的既有缓存 manifest/JUnit 5/0、107 Swift Testing、Smoke、Render 和 Xcode 日志一致；最新 32fb4fe / run 40689576052 文档检查成功、四项主动 skipped。新目录下载首包偏慢，未以其空目录冒充新结果；旧实现证据只作为改前对照。
- 首轮 `c4c0418b0c1ae621e34e450938fa1b89ee09ba4b` 已 push；run `40699499521` attempt1 结果下载至 `/private/tmp/romelegions-review-40699499521/`，manifest 精确匹配 task-scoped static/Render/Xcode，JUnit5/3/2skipped。Static 13/14 Node合同通过，失败为17图清单仍断言16；Render/Xcode 同因旧 Panels 内 private legendTint 跨文件不可见失败，未产 PNG。
- 追加修复：Tools/ci_scope.test.mjs 将清单断言改17并要求新地标图缺失进入失败；将 legendTint 从 Panels 私有扩展移到共享 BattleViewStyles，不改变颜色或放宽检查。
- 修复提交 `36c3a39089c24fd5fc310c5674340c4017562480` 已 push main；最新 run `40702065272` 已排队，等待本 SHA 云端结果。此前失败不是重复重试，已针对两条具体诊断修复。
- run40702065272已结束：云端日志确认14项Node合同、App build及九资源cmp通过；四兵种alpha/五材质解码与明暗门禁通过，Render在 `missingContinuousTerrainSurface` 停止。读源码发现仍有旧“portrait地图顶端<160pt”构图断言，与本轮明确的0.38居中策略不符；保留真实地形中心/道路检查，改为精确预期居中位置+上下HUD安全区，并给失败分支添加坐标诊断。不是放宽为更大上限。
- 结果包9MB下载较慢，另用授权API取得签名URL进行有界curl下载；未将缺少PNG的本地目录称为已完成验收。下一目标准备了凯撒/汉尼拔肖像原稿，仍在生成目录、尚未接入或提交，须先完成本轮验收。
- 下载通路：gh单连接超时、curl单连接约30KB/s；改为同一签名artifact URL按1MB HTTP Range分段下载，仅拼接/解包云端结果，不运行项目验证。构图修正只改Render工具，下轮direct为Render，App bundle继续引用36c3a39的真实通过证据。
- 2026-10-29恢复核对：实际 main 为 `e495ad8f3ef656c899fb089aaa561e492dc2863f`，仅比远端领先该构图修复；已重新读取计划/源码/提交、确认 Altman-sam114，fetch后安全push。最新 run `40799212655` 正在运行，选择static+Render；本机临时结果缓存已不存在，重新下载40702065272的必要结果包，不把旧文字记录当成本轮已下载证据。
- 再次通过百度移动图片检索实际查看麦松战役原图（hdslb `9a5e06e62aaaccd9977802a5a34e6287e0c9b089.jpg`），确认地图主导、写实低饱和地表、地面阵营环、独立圆形将领肖像的关系。已目检生成目录内凯撒/汉尼拔原稿，尚未接入；后续将领表现应按真实名字映射，不能给其它将领冒用这两人的肖像。
- 重新下载后更正旧记录：40702065272的Static实际在BattlePanels EOF新增空行处失败，未执行结构/Node合同；不能采用此前“14项Node通过”的描述。App BUILD SUCCEEDED/九资源cmp及资源解码日志确实存在。当前去掉EOF多余空行，补充混合视觉修复路由案例，让最新云端真实运行Node合同。
- run40799212655 / e495ad8 attempt1已下载，manifest/JUnit5项1失败3主动skipped一致；Static通过，Render编译约2分半、通过精确地图构图/海岸和7张实图后在`missingDistinctCommandDockRender`失败。unit.red=70、city.red=73，城市招募红衣兵模削弱了确认攻击的独立红色信号；不放宽原断言，给真实确认/选敌按钮增加主操作渐变与象牙图标，待新云端Render+Xcode。
- 图像目检：写实兵模/地表确实接入；焦点态仍把可玩地图压成中间窄带、军团底栏长提示溢出，不能把技术通过当成商业美术完成。下一小目标优先优化地图工作区与身份卡布局，将领肖像原稿（新增维钦托利/拉比埃努斯）先保留生成目录、不混入本次修复。

## 当前步骤、阻塞与下一步

- 当前：修复真实命令主操作区分/清除上一EOF问题，等待精确提交并云端重验；人工工程/xcuserstate/Unity分析仍保护，不暂存。
- 下一步：核对新SHA的完整17图、Node合同和App构建；后续重做地图工作区与将领身份，不以步骤continue-on-error显示结论代替实际outcome。
