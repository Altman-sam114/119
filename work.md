# 当前任务

## 目标与边界

- 目标：移除活动文档中的分角色迭代制度，改为单模型自主规划、实现、云端验证；增加可恢复的临时计划机制。
- 非目标：不改玩法、UI、存档或已有美术；不复制参考项目的本地验证、分支与业务约束。
- 硬约束：默认不启用子智能体；禁止本地测试、构建、解析验证与 diff-check；只在 main 提交本轮文件并推送云端。
- 基线：main / da244ab，与 origin/main 一致。
- 保护已有改动：project.pbxproj、UserInterfaceState.xcuserstate、md/unity分析/；不暂存、不覆盖。

## 计划与进度

- [x] 阅读入口、现有流程/测试/历史、参考项目规范和 CI 关联代码。
- [x] 重写 AGENTS、测试规范与 prompt 归档入口，同步 README、flow/flowchart。
- [x] 移除结构检查的旧角色合同，CI 按直接受影响范围选择检查并明确 skipped 原因。
- [ ] 只读核对本轮 diff/status，提交并推送 main，核对最新云端结果包。
- [ ] 将长期结论记入 update_log.md，清空本文件中的任务内容。

## 本轮编辑记录

- 本轮修改：AGENTS.md、README.md、update_log.md、md/flow/flow.md、md/flow/flowchart.md、md/test/test.md、md/prompt/README.md、Tools/verify_project.mjs、.github/workflows/ci-results.yml。
- 本轮新增：work.md、Tools/ci_scope.mjs、Tools/ci_scope.test.mjs；无 Swift、资源或工程修改。

## 验证选择

- baseline：云端 diff/结构与文档合同检查。
- direct：云端 CI 范围选择、skipped/失败传播、结果包合同测试。
- optional：无；本轮不做全量游戏回归。
- skipped：Swift Testing、Gameplay Smoke、RenderBattlePreview、Xcode build；本轮未修改对应业务实现/资源/工程。
- 本地：只读文件、rg/sed、git status/diff、fetch 和 GitHub 身份查询；没有运行本地验证。

## 恢复点与下一步

- 决策：不迁移旧 prompt、不重写历史日志；删除的是活动角色合同，不删除历史或测试实现。CI auto 为下限，手动 full 需要理由，未知路径/无基线保守全量。
- 已只读检查本轮文件与关联接线；新增 Node 测试覆盖范围映射、skip/失败传播，并在云端隔离执行真实 metadata 脚本检查 JUnit 和缺产物失败。
- 下一步：核对最新 origin/main 与暂存范围，提交/push 并等待云端结果；当前没有阻塞。
- 完成条件：本轮文档/流程合同在最新 SHA 的云端通过，精确记录 run/attempt/artifact，work.md 恢复空模板。
