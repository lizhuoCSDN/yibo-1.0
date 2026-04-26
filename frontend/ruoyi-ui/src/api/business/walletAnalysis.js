import request from '@/utils/request'

export function listWalletBind(params) {
  return request({
    url: '/business/wallet/bind/list',
    method: 'post',
    data: params || {}
  })
}

export function listWalletBindOptions() {
  return request({
    url: '/business/wallet/bind/options',
    method: 'get'
  })
}

export function addWalletBind(data) {
  return request({
    url: '/business/wallet/bind',
    method: 'post',
    data
  })
}

export function updateWalletBind(data) {
  return request({
    url: '/business/wallet/bind',
    method: 'put',
    data
  })
}

export function delWalletBind(ids) {
  return request({
    url: '/business/wallet/bind/' + ids,
    method: 'delete'
  })
}

export function analyzeWallet(usdtAddress) {
  return request({
    url: '/business/wallet/analyze',
    method: 'get',
    params: { usdtAddress }
  })
}
