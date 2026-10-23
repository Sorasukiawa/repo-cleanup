# 仓库整理技能开发约定

入口为 `SKILL.md`，按任务读取 `references/`；`scripts/survey.sh` 负责只读盘点，不添加自动删除或安装钩子。

- 元数据和链接检查用 `bash tests/check-skill.sh`；修改盘点逻辑时再运行隔离夹具 `bash tests/test-survey.sh`。
- `SKILL.md`、插件 manifest 和 CHANGELOG 的版本保持一致。Claude 插件封装与普通技能共享同一套行为。
- 工作区、忽略文件、唯一提交和个人配置分别核对；清理空间必须覆盖项目自己放在仓库外的产物，并说明大体积保留项。
- 文档变更保持中英及其他已有介绍的事实一致；维护报告、真实仓库快照、账号资料与密钥不提交。
