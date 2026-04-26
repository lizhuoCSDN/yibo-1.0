import request from '@/utils/request'

// 获取财务利润统计（可选 beginTime/endTime：按消费日志时间段汇总；不传则累计口径）
export function getFinanceList(params) {
  return request({
    url: '/business/finance/list',
    method: 'get',
    params: params || {}
  })
}

// 获取消费明细
export function getBalanceLogList(params) {
  return request({
    url: '/business/finance/balanceLog',
    method: 'post',
    data: params
  })
}
