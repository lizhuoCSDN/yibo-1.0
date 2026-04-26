import request from '@/utils/request'

export function listKeyword(query) {
  return request({
    url: '/business/keyword/list',
    method: 'get',
    params: query
  })
}

export function getKeyword(id) {
  return request({
    url: '/business/keyword/' + id,
    method: 'get'
  })
}

export function addKeyword(data) {
  return request({
    url: '/business/keyword',
    method: 'post',
    data
  })
}

export function updateKeyword(data) {
  return request({
    url: '/business/keyword',
    method: 'put',
    data
  })
}

export function delKeyword(ids) {
  return request({
    url: '/business/keyword/' + ids,
    method: 'delete'
  })
}

export function refreshKeywordCache() {
  return request({
    url: '/business/keyword/refreshCache',
    method: 'post'
  })
}
