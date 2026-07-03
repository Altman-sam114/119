# Agent A 提示词目录说明

`md/prompt/` 存放 Agent A 为每轮迭代写给 Agent B 的版本化实现提示词。提示词是执行依据，不是版本日志；正式版本和重要维护事项写入 `update_log.md`。

## 角色召唤

- `agenta`、`a:` 或 `A:`：召唤 Agent A。
- `agentb`、`b:` 或 `B:`：召唤 Agent B。
- `agentc`、`c:` 或 `C:`：召唤 Agent C。
- 没有前缀时，按普通 Codex 任务处理；若任务需要 A/B/C 边界，应提醒用户指定角色，或说明本轮按普通任务执行。

Agent A、B、C 的最终回复第一行分别必须是：

```text
我是 Agent A。
我是 Agent B。
我是 Agent C。
```

## 目录和命名

目录按版本主题管理：

```text
md/prompt/v0（协作系统）/v0.1（建立多Agent协作文档）.md
md/prompt/v0（某主题）/v0.3（某任务）.md
```

人工指定版本号时按人工要求；未指定时从 `update_log.md` 现有版本继续递增。

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

## 云端阶段要求

Agent A 写提示词时必须明确：

- 本轮固定使用 `main` 作为唯一上传、提交、推送和云端验证分支。
- Agent B 开始前同步最新 `origin/main`，完成后在 `main` 上 commit 并 `git push origin main`。
- 默认本地只跑轻量检查；完整 SwiftPM、Gameplay Smoke 和 Xcode build 由 GitHub Actions 重验证。
- `.github/workflows/ci-results.yml` 的结果包必须可供 Agent C 下载，且不得加密。
- Agent C 必须用 `gh auth login` 后下载最新 run artifact 到 `/private/tmp/romelegions-c-review-<run_id>/`。
- Agent C 必须核对 manifest 的 `branch=main`、`commitSha`、`runId`、`runAttempt` 与 `origin/main` 最新状态一致。
- 云端失败时，不回滚 main；退回 Agent B 在 `main` 上追加修复 commit 并重新 push。
- 本轮不设计 PR、`develop`、`smalldata_test`、`codeb/...` 或其他候选分支流，除非人工另行明确要求。

## 禁止项

- 禁止把业务实现写进提示词后由 Agent A 直接完成，除非人工明确要求 Agent A 也实现。
- 禁止把 AITRANS、MD Journal 或其他项目的业务探针、模型、截图、数据文件硬复制到本项目。
- 禁止把旧 artifact、旧 output 或 checkout 自带报告写成新一轮云端验证结果。
- 禁止让 Agent C 只看 Agent B 文字汇报。
