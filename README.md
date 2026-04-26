# Yibo 1.0 项目说明

本仓库为 **个人维护的「短信 CRM / Yibo」** 全栈项目：在 MIT 许可的开源基座上扩展了短信与业务模块；**对外产品名**为短信 CRM。第三方版权与基座说明见根目录 **NOTICE** 与 `backend/RuoYi-Vue/LICENSE`。

**仓库根目录名**建议使用 `yibo-1.0`（仅 ASCII、无空格），便于 shell 与 CI 引用；本地若已用其他名称，保持 `scripts/*.sh` 内以 `$ROOT` 推导路径即可。

## 目录结构（主工程）

| 路径 | 说明 |
|------|------|
| `backend/RuoYi-Vue/` | Java 后端（多模块：`ruoyi-admin`、`ruoyi-business`、`ruoyi-system` 等） |
| `frontend/ruoyi-ui/` | Vue2 + Element UI 前端工程 |
| `database/scripts/` | SQL 迁移、菜单与业务表增量脚本（按需执行） |
| `database/dumps/` | 本地/环境数据库导出备份（体积可能较大，按需保留） |
| `scripts/` | 启动脚本、E2E 测试、会话恢复等工具 |
| `docs/` | 说明文档目录 |

## 本地运行（概要）

- **后端**：在 `backend/RuoYi-Vue` 下执行 `mvn install` / `mvn -DskipTests compile`；主入口为 `ruoyi-admin`，端口见 `application.yml`（常见 `8080`）。
- **前端**：在 `frontend/ruoyi-ui` 执行 `npm install` 后 `npm run dev`。
- **脚本**：`scripts/run-backend.ps1`、`scripts/startup/` 下 bat 可按环境选用；数据库脚本见 `scripts/database/`。

## 构建注意

- 「统计分析」页面对应 **`frontend/ruoyi-ui/src/views/business/statistics`**；若数据库菜单仍指向旧路径 `statistcis`，可执行 `database/scripts/rename_menu_statistcis_to_statistics.sql`，或根目录运行 **`powershell -File scripts/database/run_rename_menu_statistics.ps1`**（读取 `db-password.local`），然后**重新登录**后台。
- 修改 `ruoyi-business` 等模块后，需 **`mvn install`** 再编译 `ruoyi-admin`，否则依赖可能未更新。
- 前端生产构建：`npm run build:prod`，产物在 `frontend/ruoyi-ui/dist/`（已在 `.gitignore` 中忽略）。

## 规范与忽略项

- 根目录 `.gitignore` 已忽略 Maven `target/`、前端 `dist/`、`node_modules/`、`db-password.local` 等。
- 建议使用根目录 `.editorconfig` 保持缩进与编码一致。
- 防止整库/菜单「回退到旧样」的操作约定与命令见 **`docs/数据与发版防回退.md`**。

---

以 `backend/`、`frontend/`、`database/` 为唯一源码与数据库脚本来源。默认开发库名为 **`yibo`**；基线建表见 `backend/RuoYi-Vue/sql/yibo_init_baseline.sql`（及同目录 `quartz.sql` 若启用调度器），大体积环境导出可自备放在 `database/dumps/` 且勿提交。
