-- 财务统计(path=analysis) 下增加子菜单：钱包分析
SET NAMES utf8mb4;

SET @analysis_id := (
  SELECT menu_id FROM sys_menu WHERE path = 'analysis' AND menu_type = 'M' LIMIT 1
);

INSERT INTO sys_menu (
  menu_name, parent_id, order_num, path, component, is_frame, menu_type,
  visible, status, perms, icon, create_by, create_time, remark
)
SELECT
  CONVERT(UNHEX('E992B1E58C85E58886E69E90') USING utf8mb4),
  @analysis_id,
  3,
  'walletAnalysis',
  'business/finance/walletAnalysis',
  1,
  'C',
  '0',
  '0',
  'business:wallet:list',
  'money',
  'admin',
  NOW(),
  CONVERT(UNHEX('55534454E59CB0E59D80E6B581E6B0B4E4B88EE5AFB9E6898BE696B9E58886E69E90') USING utf8mb4)
FROM DUAL
WHERE @analysis_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM sys_menu WHERE parent_id = @analysis_id AND path = 'walletAnalysis'
  );

SET @wallet_menu_id := (
  SELECT menu_id FROM sys_menu
  WHERE parent_id = @analysis_id AND path = 'walletAnalysis' AND menu_type = 'C'
  LIMIT 1
);

SET @profit_id := (
  SELECT menu_id FROM sys_menu
  WHERE parent_id = @analysis_id AND path = 'financeProfit' AND menu_type = 'C'
  LIMIT 1
);

INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT r.role_id, @wallet_menu_id
FROM sys_role_menu r
WHERE @wallet_menu_id IS NOT NULL
  AND @profit_id IS NOT NULL
  AND r.menu_id = @profit_id;
