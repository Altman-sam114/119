# Agent A 提示词目录说明

`md/prompt/` 存放 Agent A 为每轮迭代写给 Agent B 的版本化实现提示词。提示词是执行依据，不是版本日志；正式版本和重要维护事项写入 `update_log.md`。

## 角色召唤

- `agenta`、`a:` 或 `A:`：召唤 Agent A。
- `agentb`、`b:` 或 `B:`：召唤 Agent B。
- `agentc`、`c:` 或 `C:`：召唤 Agent C。
- `agentx`、`x:` 或 `X:`：召唤 Agent X。
- 没有前缀时，按普通 Codex 任务处理；若任务需要 A/B/C/X 边界，应提醒用户指定角色，或说明本轮按普通任务执行。

Agent A、B、C、X 的最终回复第一行分别必须是：

```text
我是 Agent A。
我是 Agent B。
我是 Agent C。
我是 Agent X。
```

## 目录和命名

目录按版本主题管理：

```text
md/prompt/v0（协作系统）/v0.1（建立多Agent协作文档）.md
md/prompt/v0（某主题）/v0.3（某任务）.md
```

人工指定版本号时按人工要求；未指定时从 `update_log.md` 现有版本继续递增。

当前最新玩法推进提示词：

- `md/prompt/v0（玩法推进）/v0.40（选中军团处境读板）.md`
- `md/prompt/v0（玩法推进）/v0.39（战场态势交汇链路）.md`

## Agent A 提示词必含内容

每个 Agent A 提示词必须包含：

- 版本号。
- 版本分配依据。
- 背景。
- 目标。
- 非目标。
- 当前架构依据。
- 实现步骤。
- 关键文件。
- 测试要求。
- CI / main push 要求。
- 文档更新要求。
- 验收标准。
- 风险和禁止项。

## Agent X 与每轮提示词管理

Agent X 可以围绕人工总目标 X 要求 Agent A 为每个小轮次生成版本化提示词。Agent X 不直接替代 Agent A 写实现提示词，也不直接替代 Agent B 实现或 Agent C 验收。

Agent X 要求 Agent A 生成每轮提示词时，必须明确：

- 本轮目标和它对应总目标 X 的哪一部分。
- 本轮非目标和不得扩大的范围。
- 需要读取的源码、测试、文档和历史提示词。
- 本轮实现步骤、关键文件和必须保持不变的旧行为。
- 本轮云端-only 验证限制；当前不得要求 Agent B 运行本地测试、build、typecheck、RenderBattlePreview、`verify_project` 或 `git diff --check`。
- `main` commit/push 要求。
- GitHub Actions artifact 要求。
- Agent C 下载、核对和复判要求。
- Agent X 在 Agent C 结论后如何判断继续、退回、暂停或完成。

每轮提示词必须按版本目录保存，不覆盖旧提示词；若人工指定版本号，以人工指定为准，否则从 `update_log.md` 现有版本继续递增。

## 云端阶段要求

Agent A 写提示词时必须明确：

- 本轮固定使用 `main` 作为唯一上传、提交、推送和云端验证分支。
- Agent B 开始前同步最新 `origin/main`，完成后在 `main` 上 commit 并 `git push origin main`。
- 当前按人工要求默认不跑本地验证命令；完整结构检查、SwiftPM、Gameplay Smoke 和 Xcode build 由 GitHub Actions 重验证。
- `.github/workflows/ci-results.yml` 的结果包必须可供 Agent C 下载，且不得加密。
- Agent C 必须用 `gh auth login` 后下载最新 run artifact 到 `/private/tmp/romelegions-c-review-<run_id>/`。
- Agent C 必须核对 manifest 的 `branch=main`、`commitSha`、`runId`、`runAttempt` 与 `origin/main` 最新状态一致。
- 云端失败时，不回滚 main；退回 Agent B 在 `main` 上追加修复 commit 并重新 push。
- Agent X 主控循环时，不得跳过 Agent C 最新 artifact 验收，也不得在云端失败时进入下一轮伪装成功。
- 本轮不设计 PR、`develop`、`smalldata_test`、`codeb/...` 或其他候选分支流，除非人工另行明确要求。

## 禁止项

- 禁止把业务实现写进提示词后由 Agent A 直接完成，除非人工明确要求 Agent A 也实现。
- 禁止把 AITRANS、MD Journal 或其他项目的业务探针、模型、截图、数据文件硬复制到本项目。
- 禁止把旧 artifact、旧 output 或 checkout 自带报告写成新一轮云端验证结果。
- 禁止让 Agent C 只看 Agent B 文字汇报。
- 禁止让 Agent X 用旧 run、旧 artifact、本地输出或未验收结果推进循环。
