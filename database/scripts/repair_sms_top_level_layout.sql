-- 修复：顶级 M 目录误写为 ParentView 时整页无 Layout（无侧栏、无 Tags 多页签）
-- 含：短信营销/通道路由、财务统计(analysis) 等。
-- 若依设计：仅「非一级的 M 目录」用 ParentView；与「系统管理」同级的根目录应使用 Layout。
-- 可重复执行。执行后请重新登录或强刷前端，使 getRouters 重新拉取。

SET NAMES utf8mb4;

UPDATE sys_menu SET component = 'Layout'
WHERE path IN ('smsMk', 'smsOps', 'analysis') AND menu_type = 'M' AND parent_id = 0
  AND component = 'ParentView';

SELECT 'repair_sms_top_level_layout: done' AS result;
