import request from '@/utils/request'

export function listTemplate(query) {
  return request({
    url: '/business/template/list',
    method: 'get',
    params: query
  })
}

export function getTemplate(id) {
  return request({
    url: '/business/template/' + id,
    method: 'get'
  })
}

export function addTemplate(data) {
  return request({
    url: '/business/template',
    method: 'post',
    data
  })
}

export function updateTemplate(data) {
  return request({
    url: '/business/template',
    method: 'put',
    data
  })
}

export function delTemplate(id) {
  return request({
    url: '/business/template/' + id,
    method: 'delete'
  })
}

export function exportTemplate(query) {
  return request({
    url: '/business/template/export',
    method: 'post',
    params: query,
    responseType: 'blob'
  })
}

/** 与数据仓库「按任务导入」相同：按日期拉取可选任务编号（短链/用户链接任务 id） */
export function listTemplateTaskIdOptions(data) {
  return request({
    url: '/business/template/taskIdOptions',
    method: 'post',
    data: data || {}
  })
}

/** 按发送任务编号 task_no 取短信正文与 sms_send_task.id，用于预填「模板内容」并关联 refTaskId */
export function getSendTaskContentForTemplate(taskNo) {
  return request({
    url: '/business/template/sendTaskContent',
    method: 'get',
    params: { taskNo }
  })
}
