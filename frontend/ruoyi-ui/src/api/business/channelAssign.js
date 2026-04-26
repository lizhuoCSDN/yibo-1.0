import request from '@/utils/request'

export function listUserChannel(query) {
  return request({ url: '/business/channelAssign/list', method: 'get', params: query })
}

/** 子户在「线路分配」中已启用、且平台通道为启用态的通道（与 SMPP/业务下拉与发信一致） */
export function channelsForUser(userId) {
  return request({ url: '/business/channelAssign/channelsForUser', method: 'get', params: { userId } })
}

export function getUserChannel(id) {
  return request({ url: '/business/channelAssign/' + id, method: 'get' })
}

export function addUserChannel(data) {
  return request({ url: '/business/channelAssign', method: 'post', data: data })
}

export function updateUserChannel(data) {
  return request({ url: '/business/channelAssign', method: 'put', data: data })
}

export function delUserChannel(ids) {
  return request({ url: '/business/channelAssign/' + ids, method: 'delete' })
}
