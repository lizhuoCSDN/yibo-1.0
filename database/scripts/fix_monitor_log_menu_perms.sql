-- Fix monitor log menus: perms must be monitor:* (matches Controller @PreAuthorize).
-- Component must be views/monitor/... (system/operlog does not exist -> blank page).

UPDATE sys_menu SET component = 'monitor/operlog/index' WHERE menu_id = 500;
UPDATE sys_menu SET component = 'monitor/logininfor/index' WHERE menu_id = 501;

UPDATE sys_menu SET perms = 'monitor:operlog:list' WHERE menu_id = 500 AND perms LIKE 'system:operlog:list';
UPDATE sys_menu SET perms = 'monitor:logininfor:list' WHERE menu_id = 501 AND perms LIKE 'system:logininfor:list';

UPDATE sys_menu SET perms = 'monitor:operlog:query' WHERE menu_id = 1039 AND perms LIKE 'system:operlog:query';
UPDATE sys_menu SET perms = 'monitor:operlog:remove' WHERE menu_id IN (1040, 1042) AND perms LIKE 'system:operlog:remove';
UPDATE sys_menu SET perms = 'monitor:operlog:detail' WHERE menu_id = 1041 AND perms LIKE 'system:operlog:detail';

UPDATE sys_menu SET perms = 'monitor:logininfor:query' WHERE menu_id = 1043 AND perms LIKE 'system:logininfor:query';
UPDATE sys_menu SET perms = 'monitor:logininfor:remove' WHERE menu_id IN (1044, 1045) AND perms LIKE 'system:logininfor:remove';
