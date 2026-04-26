-- 【已废弃】侧栏已取消独立「线路分配」菜单；本脚本仅作历史参考
-- 原：智能路由 (channelRouter) 与 线路分配 (channelAssign) 交换 order_num
-- 仅作用于 menu_type='C' 的菜单项；两菜单须已存在。
-- 执行后若顺序未变，请重新登录或清前端缓存以刷新路由菜单。
SET NAMES utf8mb4;

SET @r := (SELECT order_num FROM sys_menu WHERE path = 'channelRouter' AND menu_type = 'C' LIMIT 1);
SET @a := (SELECT order_num FROM sys_menu WHERE path = 'channelAssign' AND menu_type = 'C' LIMIT 1);

UPDATE sys_menu SET order_num = @a WHERE path = 'channelRouter' AND menu_type = 'C' AND @r IS NOT NULL AND @a IS NOT NULL;
UPDATE sys_menu SET order_num = @r WHERE path = 'channelAssign' AND menu_type = 'C' AND @r IS NOT NULL AND @a IS NOT NULL;
