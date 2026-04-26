/**
 * 与「通道管理」列表的对接方式、API/线路 列一致，供 SMPP 外放、API 外放、线路分配等复用。
 */
export function inferConnectorLabelFromMeta(row) {
  const code = String(row.channelCode || '').toLowerCase()
  const name = String(row.channelName || '').toLowerCase()
  if (code.includes('smpp') || name.includes('smpp')) {
    return 'SMPP'
  }
  if (code.includes('api') || name.includes('http') || name.includes('v3') || name.includes('api')) {
    return 'API'
  }
  if (code.startsWith('laaffic') && !code.includes('smpp')) {
    return 'API'
  }
  return 'API'
}

/** 只展示 SMPP / API。优先用后端列表/详情中的 dockingType。 */
export function connectorLabel(row) {
  if (row && row.dockingType) {
    return row.dockingType
  }
  if (!row) {
    return 'API'
  }
  const raw = row.config
  if (raw != null && String(raw).trim() !== '') {
    try {
      const o = JSON.parse(raw)
      if (o && (o.connectorType === 'smpp' || o.protocol === 'smpp')) {
        return 'SMPP'
      }
      return 'API'
    } catch (e) {
      return inferConnectorLabelFromMeta(row)
    }
  }
  return inferConnectorLabelFromMeta(row)
}

/** 对接为 API 时区分云发、Laaffic、国际短信等。row 可含 { config, channelName, channelCode, dockingType }。 */
export function lineProtocolLabel(row) {
  if (!row) {
    return '—'
  }
  if (connectorLabel(row) === 'SMPP') {
    let smppP = '通用'
    const raw = row.config
    if (raw != null && String(raw).trim() !== '') {
      try {
        const o = JSON.parse(raw)
        if (o && o.smppProvider === 'laaffic') {
          smppP = 'Laaffic'
        }
      } catch (e) {
        return 'SMPP'
      }
    }
    return 'SMPP · ' + smppP
  }
  const raw = row.config
  if (raw == null || String(raw).trim() === '') {
    return '—'
  }
  try {
    const o = JSON.parse(raw)
    if (!o) {
      return '云发(通用)'
    }
    if (
      o.apiProvider === 'ta_sms_openapi' ||
      o.httpAdapter === 'ta_sms_openapi_v2' ||
      (o.taBaseUrl && o.username && o.apiKey)
    ) {
      return '国际短信 (ta-sms v2)'
    }
    if (o.apiProvider === 'laaffic') {
      return 'Laaffic v3'
    }
    if (o.sendUrl && o.appKey && o.appSecret) {
      return '云发(通用 JSON)'
    }
    return '云发(通用)'
  } catch (e) {
    return '—'
  }
}

/** 外放下拉：通道名 + 与通道管理一致的线路说明 */
export function formatChannelSelectLabel(ch) {
  if (!ch || ch.id == null) {
    return '—'
  }
  const name = ch.channelName || '#' + ch.id
  const line = lineProtocolLabel(ch)
  if (!line || line === '—') {
    return name
  }
  return name + ' · ' + line
}
