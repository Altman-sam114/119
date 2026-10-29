# RomeLegions

受罗马题材战棋公开截图启发的原创 SwiftUI iOS 原型。战场采用原创地表材质、立体城镇/树林/山脊与四兵种透明 PNG，代码负责真实地形裁剪、道路和战术叠层；不复用原游戏素材，不依赖第三方框架。

## 主要能力

- 战役、征服、远征入口；六边形地图、地形、城市、阵营与军团。
- 回合制移动、攻击、反击、占城、招募、科技、外交、城市扩建、军团训练与将领任命；任务、胜负结算和结束保护。
- 战斗目标锁定、身份链与攻击预演；确认才结算，取消只清理选择。预览、真实结算与 AI 评分共用核心规则。
- 战术姿态、将领特性/主动技能、范围/目标/冷却、经验/战功与成长建议；选中单位的处境、军令窗口与指挥链读板。
- AI 招募、休整、移动后攻击、集火、立即击杀优先、移动后施令，以及姿态与行动联合候选；意图、计划、威胁与地图读板同源，只读预测不改变战局。
- 敌路、敌将威胁、反制、目标线、热区与控区叠层；敌将聚焦、反制姿态/移动/锁敌为独立入口，不自动串联命令。
- 地图主导的响应式战斗壳层、固定 HUD、分类抽屉、选择驱动命令坞；独立战区画布在 1x 也可平移，竖屏不强求把整张横向地图压进窄屏，缩放/聚焦/复位不进入玩法或存档。
- 同源自然海岸、岛/湖/陆桥、连续草地/水面材质与相邻道路；城镇/树林/山脊采用原创预渲染地标，四兵种配合真实阵营军旗/地环及原生命、经验、将领、姿态、冷却与行动标记。
- 凯撒、汉尼拔、维钦托利、拉比埃努斯拥有独立原创肖像；地图将领标记、选中身份与敌将卡精确按姓名读取，未知将领使用中性图标，不按阵营猜配。

## 架构与资源

| 层 | 入口 |
| --- | --- |
| 核心规则 | `Sources/RomeLegionsCore/GameState.swift`，纯 Swift `RomeLegionsCore` |
| 状态与派生 | `RomeLegionsApp/App/GameViewModel.swift` 与 Map/Strategy/Selection readout 文件 |
| 展示 | Root/MainMenu/BattleView；BattleShellControls、BattleMapView、BattlePanels、BattleViewStyles |
| 存档 | `SaveStore`，SQLite 中保存完整 `GameState` |
| 验证 | Swift Testing、GameplaySmoke、RenderBattlePreview、结构检查与云端 Xcode build |

最低平台为 iOS 17 / macOS 14，工程为 `RomeLegionsApp.xcodeproj`，scheme 为 `RomeLegions`。

原创资源在 `RomeLegionsApp/Resources/BattleUnitArt/`，以普通 folder resource 随 App 打包，不依赖 asset catalog 或网络。共享 ImageIO 加载器将兵模/地标限制到最长边 384px、地表材质限制到 768px、将领肖像限制到 256px，再由各目录一次缓存；旧 Canvas/中性图标仅作缺失时降级。资源说明见 [兵模美术](md/art/battle-unit-art.md)、[战场材质](md/art/battle-scenery-art.md) 和 [将领肖像](md/art/battle-commander-art.md)。独立 macOS 云端 Render 通过显式 `ROMELEGIONS_ART_ROOT` 读取同一资源，iOS 仅从 bundle 读取。

## 开发流程

用户给目标后，由同一个模型按“读取现状 → work.md 计划 → 小步实现 → main 提交/push → 相关云端验证 → 核对结果/修复 → 清空计划”自主完成，不需要角色召唤或提示词交接，默认不开子智能体。

- [AGENTS.md](AGENTS.md)：稳定事实、硬规则与迭代入口。
- [work.md](work.md)：当前任务的计划、进度、编辑记录与恢复点；上下文压缩后先读，任务完成后清空内容、保留空模板。
- [核心流程](md/flow/flow.md) 与 [流程图](md/flow/flowchart.md)：当前真实架构和执行流。
- [测试规范](md/test/test.md)：`baseline + direct + optional` 选择及云端结果核对。
- [更新日志](update_log.md)：版本、维护、决策与真实验证证据；[旧设计归档](md/prompt/README.md) 不作为当前执行规则。

普通任务不必改遍全部文档；架构/职责改变才更新 flow，验证制度改变才更新 test，长期事实改变才更新入口。

## 云端编译与测试

默认只走 `main` 直推和 GitHub Actions；[CI workflow](.github/workflows/ci-results.yml) 按改动范围选检查并上传未加密结果包。同一个模型核对最新 commit、run/attempt、manifest、JUnit、日志和必要产物，失败后追加修复提交。

- 纯文档或 CI 路由修改只做相关结构/路由检查，不编译游戏、不渲染战斗图。
- 核心公共规则修改覆盖受影响的预览、结算、AI 与 App；战斗 UI/读板修改选择云端 Render 和 Xcode，不默认陪跑无关核心测试。
- 只有发布、明确共享依赖、失败调查或用户要求才扩大回归；主动跳过的无关项明确记录，不冒充通过。

除非用户明确要求，本地不运行测试、build、typecheck、Render、结构/解析/语法校验或 `git diff --check`。本地允许读取、编辑、只读 Git 检查、同步/提交/推送及云端结果查询下载。用户明确授权本机编译或运行时，只能使用已有 UDID 以 `FAC4325D` 开头的唯一 iOS 模拟器，不创建或选择其他设备；云端不受此设备限制。
