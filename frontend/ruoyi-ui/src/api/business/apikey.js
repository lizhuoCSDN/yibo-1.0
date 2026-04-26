import request from '@/utils/request'

export function listApiKey(query) {
  return request({ url: '/business/apikey/list', method: 'get', params: query })
}

export function getApiKey(id) {
  return request({ url: '/business/apikey/' + id, method: 'get' })
}

export function addApiKey(data) {
  return request({ url: '/business/apikey', method: 'post', data })
}

export function updateApiKey(data) {
  return request({ url: '/business/apikey', method: 'put', data })
}

export function delApiKey(ids) {
  return request({ url: '/business/apikey/' + ids, method: 'delete' })
}
