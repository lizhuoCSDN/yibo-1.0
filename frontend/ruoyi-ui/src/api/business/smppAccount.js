import request from '@/utils/request'

export function listSmppAccount(query) {
  return request({
    url: '/business/smppAccount/list',
    method: 'get',
    params: query
  })
}

export function getSmppAccount(id) {
  return request({
    url: '/business/smppAccount/' + id,
    method: 'get'
  })
}

export function addSmppAccount(data) {
  return request({
    url: '/business/smppAccount',
    method: 'post',
    data: data
  })
}

export function updateSmppAccount(data) {
  return request({
    url: '/business/smppAccount',
    method: 'put',
    data: data
  })
}

export function delSmppAccount(ids) {
  return request({
    url: '/business/smppAccount/' + ids,
    method: 'delete'
  })
}
