-- Rename menu path/component from typo statistcis -> statistics (Vue: business/statistics/index)
-- Run against the same DB as the app (default schema yibo).
SET NAMES utf8mb4;

UPDATE sys_menu
SET path = 'statistics'
WHERE path = 'statistcis';

UPDATE sys_menu
SET component = REPLACE(component, 'statistcis', 'statistics')
WHERE component LIKE '%statistcis%';
