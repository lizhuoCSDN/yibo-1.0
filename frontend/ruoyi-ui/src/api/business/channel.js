import request from '@/utils/request'

// 查询短信通道管理列表
export function listChannel(query) {
  return request({
    url: '/business/channel/list',
    method: 'get',
    params: query
  })
}

// 查询短信通道管理列表
export function channelList(query) {
  return request({
    url: '/business/channel/list/list',
    method: 'get',
    params: query
  })
}

// 查询短信通道管理详细
export function getChannel(id) {
  return request({
    url: '/business/channel/' + id,
    method: 'get'
  })
}

/** 供应商标准详情：通道 + 路由健康/统计（404 时由调用方回退 getChannel，故 silent 避免无接口时全屏报错） */
export function getChannelDetail(id) {
  return request({
    url: '/business/channel/detail/' + id,
    method: 'get',
    silent: true
  })
}

// 新增短信通道管理
export function addChannel(data) {
  return request({
    url: '/business/channel',
    method: 'post',
    data: data
  })
}

// 修改短信通道管理
export function updateChannel(data) {
  return request({
    url: '/business/channel',
    method: 'put',
    data: data
  })
}

// 删除短信通道管理
export function delChannel(id) {
  return request({
    url: '/business/channel/' + id,
    method: 'delete'
  })
}

export function getChannelBalance(channelId) {
  return request({
    url: '/business/channel/balance/'+channelId,
    method: 'get',
  })
}
