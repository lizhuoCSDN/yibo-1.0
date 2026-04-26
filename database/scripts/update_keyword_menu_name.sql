-- 将「敏感词的管理」等旧名称统一为「敏感词管理页」（侧栏与权限菜单展示名）
-- 可重复执行。

UPDATE sys_menu
SET menu_name = '敏感词管理页'
WHERE menu_type = 'C'
  AND (component = 'business/keyword/index' OR path = 'keywordManage');
