<template>
  <el-alert
    :closable="false"
    type="info"
    show-icon
    class="sms-ops-flow"
  >
    <div class="sms-ops-flow__steps">
      <router-link
        to="/smsOps/channel"
        :class="['sms-ops-flow__link', { 'is-current': current === 'channel' }]"
      >① 通道</router-link>
      <span class="sms-ops-flow__sep">→</span>
      <router-link
        to="/smsOps/channelRouter"
        :class="['sms-ops-flow__link', { 'is-current': current === 'router' }]"
      >② 智能路由</router-link>
      <span class="sms-ops-flow__sep">→</span>
      <router-link
        :to="{ path: '/accountMgmt/newUser', query: { tab: 'channelAssign' } }"
        :class="['sms-ops-flow__link', { 'is-current': current === 'line' }]"
      >③ 线路分配</router-link>
      <span class="sms-ops-flow__sep">→</span>
      <span class="sms-ops-flow__out">
        ④ 外放
        <router-link
          to="/smsOps/apikey"
          :class="['sms-ops-flow__link', { 'is-current': current === 'apikey' }]"
        >HTTP</router-link>
        <span class="sms-ops-flow__dot">·</span>
        <router-link
          to="/smsOps/smppAccount"
          :class="['sms-ops-flow__link', { 'is-current': current === 'smpp' }]"
        >SMPP</router-link>
      </span>
    </div>
    <p class="sms-ops-flow__txt">
      接上游通道 → 平台侧权重/健康与熔断 → 给子户分配可用线路（<strong>新户-线路分配</strong>，表 <code>sms_user_channel</code>）→ HTTP / SMPP 凭据；发信时仅允许走子户被分配且已启用的通道。
    </p>
  </el-alert>
</template>

<script>
/**
 * 通道路由菜单下各页的「同一条业务链」说明（非向导，仅说明与互链）。
 * current: channel | router | line | apikey | smpp
 */
export default {
  name: 'SmsOpsFlowContext',
  props: {
    current: {
      type: String,
      default: 'channel'
    }
  }
}
</script>

<style scoped>
.sms-ops-flow {
  margin-bottom: 12px;
}
.sms-ops-flow__steps {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 4px 6px;
  line-height: 1.5;
  font-size: 13px;
}
.sms-ops-flow__sep {
  color: #c0c4cc;
  user-select: none;
}
.sms-ops-flow__out {
  display: inline-flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 4px;
}
.sms-ops-flow__dot {
  color: #909399;
  user-select: none;
}
.sms-ops-flow__link {
  color: #409eff;
  text-decoration: none;
  padding: 0 2px;
  border-bottom: 1px solid transparent;
}
.sms-ops-flow__link:hover {
  border-bottom-color: #409eff;
}
.sms-ops-flow__link.is-current {
  color: #303133;
  font-weight: 600;
  border-bottom-color: #303133;
  cursor: default;
  pointer-events: none;
}
.sms-ops-flow__txt {
  margin: 8px 0 0;
  font-size: 12px;
  line-height: 1.6;
  color: #606266;
}
.sms-ops-flow__txt code {
  font-size: 11px;
  background: #f4f4f5;
  padding: 0 4px;
  border-radius: 2px;
}
</style>
