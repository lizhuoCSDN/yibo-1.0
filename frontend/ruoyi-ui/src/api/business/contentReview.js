import request from '@/utils/request'

export function listReview(query) {
  return request({
    url: '/business/sendTask/review/list',
    method: 'get',
    params: query
  })
}

export function approveReview(id) {
  return request({
    url: '/business/sendTask/review/approve/' + id,
    method: 'put'
  })
}

export function rejectReview(id) {
  return request({
    url: '/business/sendTask/review/reject/' + id,
    method: 'put'
  })
}

export function escalateReview(id) {
  return request({
    url: '/business/sendTask/review/escalate/' + id,
    method: 'put'
  })
}
