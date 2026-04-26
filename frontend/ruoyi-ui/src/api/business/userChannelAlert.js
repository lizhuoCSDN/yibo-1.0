import request from '@/utils/request'

// 与 /business/channelAssign/list 同级，单层路径
const BASE = '/business/channelAssign/alert'

export function listUserChannelAlert(userId) {
  return request({
    url: '/business/channelAssign/lineAlertList',
    method: 'get',
    params: { userId }
  })
}

export function addUserChannelAlert(data) {
  return request({
    url: BASE,
    method: 'post',
    data
  })
}

export function updateUserChannelAlert(data) {
  return request({
    url: BASE,
    method: 'put',
    data
  })
}

export function delUserChannelAlert(ids) {
  return request({
    url: `${BASE}/` + ids,
    method: 'delete'
  })
}
