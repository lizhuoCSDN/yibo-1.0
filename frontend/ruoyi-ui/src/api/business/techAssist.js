import request from '@/utils/request'

export function listTechAssist(query) {
  return request({
    url: '/business/techAssist/list',
    method: 'get',
    params: query
  })
}

export function getTechAssist(id) {
  return request({
    url: '/business/techAssist/' + id,
    method: 'get'
  })
}

export function addTechAssist(data) {
  return request({
    url: '/business/techAssist',
    method: 'post',
    data: data
  })
}

export function passTechAssist(id, lastActionRemark) {
  return request({
    url: '/business/techAssist/pass/' + id,
    method: 'put',
    data: { lastActionRemark: lastActionRemark || null }
  })
}

export function escalateTechAssist(id, lastActionRemark) {
  return request({
    url: '/business/techAssist/escalate/' + id,
    method: 'put',
    data: { lastActionRemark: lastActionRemark || null }
  })
}
