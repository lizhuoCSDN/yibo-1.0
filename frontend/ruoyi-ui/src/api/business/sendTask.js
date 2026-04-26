import request from '@/utils/request'

export function listSendTask(query) {
  return request({
    url: '/business/sendTask/list',
    method: 'get',
    params: query
  })
}

export function listSendRecord(query) {
  return request({
    url: '/business/sendTask/records',
    method: 'get',
    params: query
  })
}

export function getSendTask(id) {
  return request({
    url: '/business/sendTask/' + id,
    method: 'get'
  })
}

export function submitSendTask(data) {
  return request({
    url: '/business/sendTask/submit',
    method: 'post',
    data: data,
    headers: { repeatSubmit: false }
  })
}

export function cancelSendTask(id) {
  return request({
    url: '/business/sendTask/cancel/' + id,
    method: 'put'
  })
}

export function deleteSendTask(id) {
  return request({
    url: '/business/sendTask/' + id,
    method: 'delete'
  })
}
