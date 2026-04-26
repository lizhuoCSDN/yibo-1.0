-- 已上线库可选执行：卸掉自助充值 / 财务充值审核（与代码移除配套）
-- 会删除两菜单的授权、菜单行，并删除表 wallet_recharge_request（有数据时请先备份）

DELETE FROM sys_role_menu
WHERE menu_id IN (SELECT m.menu_id FROM (SELECT menu_id FROM sys_menu WHERE path IN ('walletRecharge', 'walletRechargeApprove')) AS m);

DELETE FROM sys_menu WHERE path IN ('walletRecharge', 'walletRechargeApprove');

DROP TABLE IF EXISTS wallet_recharge_request;

SELECT 'remove_wallet_recharge_feature: done' AS result;
