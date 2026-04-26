-- 与 yibo_init_baseline 中「一级菜单 4」对齐：若库中仍是从旧基线或备份带来的「若依官网/ruoyi.vip」入口，可执行本脚本一次。
-- 在目标库中执行: mysql yibo < replace_ry_portal_menu_placeholder.sql
UPDATE sys_menu
SET
  menu_name = '帮助',
  path = '#',
  remark = '占位，可改为你自己的帮助/文档外链'
WHERE menu_id = 4
  AND (path LIKE '%ruoyi%' OR menu_name LIKE '%若依%');

SELECT ROW_COUNT() AS updated_rows;
