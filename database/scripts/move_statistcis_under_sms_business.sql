-- 将「统计分析」(path=statistics，旧库可能仍为 statistcis) 挂到「短信业务」(path=core, 一级目录) 下
-- 若仍使用旧 path，请先执行 rename_menu_statistcis_to_statistics.sql，或把下面 WHERE 改为 path = 'statistics'
-- 执行后请重新登录以刷新侧栏路由
SET NAMES utf8mb4;

SET @sms := (
  SELECT menu_id FROM sys_menu
  WHERE path = 'core' AND menu_type = 'M' AND parent_id = 0
  LIMIT 1
);

SET @max_ord := (
  SELECT IFNULL(MAX(m.order_num), 0)
  FROM sys_menu m
  WHERE m.parent_id = @sms
);

UPDATE sys_menu
SET parent_id = @sms,
    order_num = @max_ord + 1
WHERE path IN ('statistcis', 'statistics')
  AND menu_type = 'C'
  AND @sms IS NOT NULL;
