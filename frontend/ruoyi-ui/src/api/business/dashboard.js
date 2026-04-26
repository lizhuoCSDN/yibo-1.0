import request from '@/utils/request'

export function getOverview() {
  return request({
    url: '/business/dashboard/overview',
    method: 'get'
  })
}

export function getDailyStats(days) {
  return request({
    url: '/business/dashboard/daily',
    method: 'get',
    params: { days }
  })
}
