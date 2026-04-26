import request from '@/utils/request'

/**
 * Short-link click dashboard; backend returns overview + dailyTrend + hourlyDist from user_link_click_log.
 */
export function getStatsDashboard(params) {
  return request({
    url: '/business/userlink/statistics',
    method: 'get',
    params: {
      taskId: params.taskId,
      originalUrl: params.originalUrl,
      beginTime: params.beginTime,
      endTime: params.endTime
    }
  })
}
