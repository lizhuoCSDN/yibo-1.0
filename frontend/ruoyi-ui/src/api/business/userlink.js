import request from '@/utils/request'

// 查询用户链接列表
export function listUserlink(query) {
  return request({
    url: '/business/userlink/list',
    method: 'get',
    params: query
  })
}
/**
 * 用户链接统计
 * @param {Object} params 查询参数：taskId, beginTime, endTime
 */
export function getStatistics(params) {
  return request({
    url: '/business/userlink/statistics',
    method: 'get',
    params
  });
}

// 查询用户链接详细
export function getUserlink(id) {
  return request({
    url: '/business/userlink/' + id,
    method: 'get'
  })
}

// 新增用户链接
export function addUserlink(data) {
  return request({
    url: '/business/userlink',
    method: 'post',
    data: data
  })
}

// 修改用户链接
export function updateUserlink(data) {
  return request({
    url: '/business/userlink',
    method: 'put',
    data: data
  })
}

// 删除用户链接
export function delUserlink(id) {
  return request({
    url: '/business/userlink/' + id,
    method: 'delete'
  })
}
