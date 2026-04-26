-- 对「已下线/不应再出现」的侧栏与外链做只读健康检查。单行结果：PASS 或 FAIL。
-- 使用：mysql yibo -N -B < verify_yibo_menu_sanity.sql
SET NAMES utf8mb4;
SELECT
  CASE
    WHEN (
      (SELECT COUNT(*) FROM sys_menu WHERE menu_id IN (100, 101, 102, 103, 104))
      + (SELECT COUNT(*) FROM sys_menu WHERE menu_id = 2)
      + (SELECT COUNT(*) FROM sys_menu WHERE path LIKE '%ruoyi.vip%')
      + (SELECT COUNT(*) FROM sys_menu WHERE parent_id = 0 AND menu_type = 'M' AND path IN ('monitor', 'tool'))
      + (SELECT COUNT(*) FROM sys_menu WHERE parent_id = 0 AND menu_type = 'M' AND path = 'business')
    ) = 0
    THEN 'PASS'
    ELSE 'FAIL'
  END AS yibo_menu_sanity;
