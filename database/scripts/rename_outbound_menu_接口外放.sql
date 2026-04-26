-- 将侧栏中 path=outbound 的目录名统一为「接口外放」（原英文 Outbound 或「外放接口」）
SET NAMES utf8mb4;
UPDATE sys_menu
SET menu_name = '接口外放', remark = '接口外放目录'
WHERE path = 'outbound' AND menu_type = 'M'
LIMIT 1;
