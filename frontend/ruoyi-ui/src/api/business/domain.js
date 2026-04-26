import request from '@/utils/request'

// 查询域名分页信息列表
export function listDomain(query) {
  return request({
    url: '/business/domain/list',
    method: 'get',
    params: query
  })
}

// 查询域名信息列表
export function list(query) {
  return request({
    url: '/business/domain/list/list',
    method: 'get',
    params: query
  })
}

// 查询域名信息详细
export function getDomain(id) {
  return request({
    url: '/business/domain/' + id,
    method: 'get'
  })
}

// 新增域名信息
export function addDomain(data) {
  return request({
    url: '/business/domain',
    method: 'post',
    data: data
  })
}

// 修改域名信息
export function updateDomain(data) {
  return request({
    url: '/business/domain',
    method: 'put',
    data: data
  })
}

// 删除域名信息
export function delDomain(id) {
  return request({
    url: '/business/domain/' + id,
    method: 'delete'
  })
}

export function checkDomain(data) {
  return request({
    url: '/business/domain/check',
    method: 'post',
    data: data
  })
}

export function checkOriginal(url) {
  return request({
    url: '/business/domain/checkOriginal',
    method: 'get',
    params: { url }
  })
}

/**
 * 后端遍历所有域名并检测（不需要传参）
 */
export function checkAllDomains() {
  return request({
    url: '/business/domain/checkAll',
    method: 'post'
  })
}

/** 将域名分配给指定用户（下级） */
export function assignDomain(data) {
  return request({
    url: '/business/domain/assign',
    method: 'post',
    data
  })
}

/** 回收单条分配 */
export function revokeDomainGrant(data) {
  return request({
    url: '/business/domain/revokeGrant',
    method: 'post',
    data
  })
}

/** 回收该域名对全部下级的分配 */
export function revokeAllDomainGrants(data) {
  return request({
    url: '/business/domain/revokeAllGrants',
    method: 'post',
    data
  })
}

/** 当前域名已分配列表（有效） */
export function listDomainGrants(domainId) {
  return request({
    url: '/business/domain/grants',
    method: 'get',
    params: { domainId }
  })
}

