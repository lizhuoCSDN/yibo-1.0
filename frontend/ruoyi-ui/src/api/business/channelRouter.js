import request from '@/utils/request'

/**
 * 按分组维护通道国家/地区：新增/编辑传 country，删除分组传 clear: true
 */
/** 使用 POST：部分环境对 PUT 返回 405；后端对 /groupCountry 同时接受 PUT/POST */
export function updateChannelGroupCountry(data) {
  return request({ url: '/business/channel/groupCountry', method: 'post', data })
}
