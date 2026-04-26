import request from '@/utils/request'

export function listContactGroup(query) {
  return request({
    url: '/business/contact/group/list',
    method: 'get',
    params: query
  })
}

export function addContactGroup(data) {
  return request({
    url: '/business/contact/group',
    method: 'post',
    data
  })
}

export function updateContactGroup(data) {
  return request({
    url: '/business/contact/group',
    method: 'put',
    data
  })
}

export function delContactGroup(ids) {
  return request({
    url: '/business/contact/group/' + ids,
    method: 'delete'
  })
}

export function listContact(query) {
  return request({
    url: '/business/contact/list',
    method: 'get',
    params: query
  })
}

export function addContact(data) {
  return request({
    url: '/business/contact',
    method: 'post',
    data
  })
}

export function updateContact(data) {
  return request({
    url: '/business/contact',
    method: 'put',
    data
  })
}

export function delContact(ids) {
  return request({
    url: '/business/contact/' + ids,
    method: 'delete'
  })
}

export function clearContactsByGroup(groupId) {
  return request({
    url: '/business/contact/group/' + groupId + '/contacts',
    method: 'delete'
  })
}

export function importContact(groupId, file) {
  const data = new FormData()
  data.append('groupId', groupId)
  data.append('file', file)
  return request({
    url: '/business/contact/import',
    method: 'post',
    data
  })
}

/** 按短链/用户链接任务编号与点击条件导入 */
export function importContactFromTask(data) {
  return request({
    url: '/business/contact/importFromTask',
    method: 'post',
    data
  })
}

/** 按日期联动：可选任务编号（用户链接 + 短信发送任务）；使用 POST 避免与 /import 等仅 POST 接口在部分环境下误配 405 */
export function listImportTaskIdOptions(data) {
  return request({
    url: '/business/contact/importTaskIdOptions',
    method: 'post',
    data: data || {}
  })
}
