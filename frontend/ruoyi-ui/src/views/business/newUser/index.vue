<template>
  <div class="app-container nu-page">
    <el-row :gutter="20" class="nu-row">
      <!-- 左侧：新户列表 -->
      <el-col :xs="24" :sm="24" :md="8" :lg="7" class="nu-col-left">
        <div class="nu-card nu-card-left">
          <header class="nu-left-head">
            <div class="nu-left-title-block">
              <div class="nu-left-title-wrap">
                <i class="el-icon-user-solid nu-head-ico" aria-hidden="true" />
                <div class="nu-left-title-text">
                  <span class="nu-left-title">新户列表</span>
                  <span class="nu-left-sub">账户名称筛选与快捷开户</span>
                </div>
              </div>
              <el-button type="primary" size="small" round icon="el-icon-plus" class="nu-btn-open" @click="handleAdd">开户</el-button>
            </div>
          </header>
          <div class="nu-left-filters">
            <el-input
              v-model="queryParams.userName"
              placeholder="搜索账户名称"
              clearable
              size="small"
              prefix-icon="el-icon-search"
              class="nu-filter-input"
              @keyup.enter.native="handleQuery"
              @clear="handleQuery"
            />
            <el-select
              v-model="queryParams.status"
              placeholder="状态"
              clearable
              size="small"
              class="nu-status-select"
              @change="handleQuery"
            >
              <el-option label="正常" value="0" />
              <el-option label="停用" value="1" />
            </el-select>
          </div>
          <div class="nu-list-scroller">
            <el-scrollbar class="nu-list-scroll">
              <div v-loading="loading" class="nu-list-inner">
                <div
                  v-for="u in userList"
                  :key="u.userId"
                  class="nu-list-item"
                  :class="{ active: selectedUserId === u.userId }"
                  @click="selectUser(u)"
                >
                  <div class="nu-item-avatar" aria-hidden="true">{{ accountInitial(u.userName) }}</div>
                  <div class="nu-item-body">
                    <div class="nu-nick">{{ u.userName }}</div>
                  </div>
                  <span
                    class="nu-badge"
                    :class="u.status === '0' ? 'nu-badge--ok' : 'nu-badge--off'"
                  >{{ u.status === '0' ? '正常' : '停用' }}</span>
                </div>
                <el-empty v-if="!loading && (!userList || !userList.length)" class="nu-list-empty" description="暂无用户" :image-size="80" />
              </div>
            </el-scrollbar>
          </div>
          <footer class="nu-left-pager">
            <el-pagination
              small
              layout="prev, pager, next"
              :total="total"
              :page-size="queryParams.pageSize"
              :current-page.sync="queryParams.pageNum"
              @current-change="getList"
            />
          </footer>
        </div>
      </el-col>

      <!-- 右侧：账户详情 -->
      <el-col :xs="24" :sm="24" :md="16" :lg="17" class="nu-col-right">
        <div v-if="!selectedUserId" class="nu-card nu-card--empty nu-placeholder">
          <el-empty class="nu-empty" description="请从左侧选择用户" :image-size="100" />
        </div>
        <div v-else class="nu-card nu-detail-card" v-loading="detailLoading">
          <div class="nu-detail-head">
            <h3 class="nu-detail-title">
              <i class="el-icon-document nu-detail-ico" aria-hidden="true" />
              账户详情 · {{ detailAccountName }}
            </h3>
            <div class="nu-detail-actions">
              <el-button type="primary" size="small" icon="el-icon-edit" @click="handleEdit">编辑</el-button>
              <el-button type="success" size="small" icon="el-icon-key" @click="handleResetPwd">重置密码</el-button>
              <el-button
                v-if="selectedUserId !== 1"
                type="danger"
                size="small"
                plain
                icon="el-icon-delete"
                @click="handleDelete"
              >删除</el-button>
            </div>
          </div>

          <el-descriptions :column="2" border size="small" class="nu-desc">
            <el-descriptions-item label="账户名称">{{ detailUser.userName || '—' }}</el-descriptions-item>
            <el-descriptions-item label="用户级别">{{ userLevelText }}</el-descriptions-item>
            <el-descriptions-item label="状态">
              <el-switch
                v-model="detailUser.status"
                active-value="0"
                inactive-value="1"
                @change="onDetailStatusChange"
              />
            </el-descriptions-item>
            <el-descriptions-item label="邮箱">{{ detailUser.email || '—' }}</el-descriptions-item>
            <el-descriptions-item label="创建时间" :span="2">{{ parseTime(detailUser.createTime) || '—' }}</el-descriptions-item>
            <el-descriptions-item label="备注" :span="2">{{ detailUser.remark || '—' }}</el-descriptions-item>
          </el-descriptions>

          <el-tabs v-model="activeTab" class="nu-tabs" @tab-click="onDetailTabClick">
            <el-tab-pane label="账户概览" name="overview">
              <div class="nu-stat-row">
                <div class="nu-stat-card nu-stat-blue">
                  <i class="el-icon-wallet nu-stat-ico" />
                  <div class="nu-stat-num">{{ overviewBalance }}</div>
                  <div class="nu-stat-label">当前余额(条)</div>
                </div>
                <div class="nu-stat-card nu-stat-green">
                  <i class="el-icon-data-line nu-stat-ico" />
                  <div class="nu-stat-num">{{ overviewUsed }}</div>
                  <div class="nu-stat-label">累计使用(条)</div>
                </div>
                <div class="nu-stat-card nu-stat-amber">
                  <i class="el-icon-connection nu-stat-ico" />
                  <div class="nu-stat-num">{{ overviewChannelCount }}</div>
                  <div class="nu-stat-label">已分配通道</div>
                </div>
              </div>

              <div class="nu-alert-panel">
                <div class="nu-alert-head">
                  <div class="nu-alert-title">
                    <i class="el-icon-bell" />
                    <span>预警设置</span>
                    <el-tooltip
                      class="item"
                      effect="dark"
                      placement="top"
                      content="以「线路分配」中可提交数=分配-已用为判断；在计划发送时刻前N小时内，若可提交数低于预警线，则自动在「通知公告」中发布/更新同一条目。"
                    >
                    <i class="el-icon-question nu-alert-hint" />
                    </el-tooltip>
                  </div>
                  <el-button
                    type="primary"
                    size="small"
                    plain
                    round
                    icon="el-icon-plus"
                    v-hasPermi="['business:channel:edit']"
                    :disabled="!userChannelList || !userChannelList.length"
                    @click="openAlertDialog"
                  >新增规则</el-button>
                </div>
                <el-table
                  v-loading="alertListLoading"
                  :data="userAlertList"
                  size="small"
                  border
                  class="nu-alert-table"
                  empty-text="未配置，请点击「新增规则」"
                >
                  <el-table-column label="通道" min-width="120" show-overflow-tooltip>
                    <template slot-scope="s">{{ s.row.channelName || ('#' + s.row.channelId) }}</template>
                  </el-table-column>
                  <el-table-column label="可提交须≥(条)" width="120" align="right">
                    <template slot-scope="s">{{ s.row.minThreshold | fmtNum }}</template>
                  </el-table-column>
                  <el-table-column label="计划发送(时)" width="100" align="center">
                    <template slot-scope="s">{{ s.row.plannedSendHour | fmtHour }}</template>
                  </el-table-column>
                  <el-table-column label="提前(小时)" width="96" align="center" prop="leadHours" />
                  <el-table-column label="启用" width="80" align="center">
                    <template slot-scope="s">
                      <el-tag :type="s.row.enabled === '1' ? 'success' : 'info'" size="mini">{{ s.row.enabled === '1' ? '是' : '否' }}</el-tag>
                    </template>
                  </el-table-column>
                  <el-table-column label="操作" width="120" align="center" v-hasPermi="['business:channel:edit']">
                    <template slot-scope="s">
                      <el-button type="text" size="small" @click="editAlertRow(s.row)">编辑</el-button>
                      <el-button type="text" size="small" class="nu-ch-link--danger" @click="removeAlertRow(s.row)">删除</el-button>
                    </template>
                  </el-table-column>
                </el-table>
              </div>
            </el-tab-pane>
            <el-tab-pane label="线路分配" name="channelAssign" lazy>
              <div class="nu-ch-panel nu-ch-panel--tab">
                <div class="nu-ch-panel__head">
                  <div class="nu-ch-panel__title-wrap">
                    <i class="el-icon-connection nu-ch-panel__icon" aria-hidden="true" />
                    <span class="nu-ch-panel__title">线路分配</span>
                  </div>
                  <div class="nu-ch-panel__actions">
                    <el-button class="nu-ch-btn-refresh" type="text" size="small" icon="el-icon-refresh" @click="refreshUserChannels">刷新</el-button>
                    <el-button
                      v-hasPermi="['business:channel:edit']"
                      type="primary"
                      size="small"
                      round
                      icon="el-icon-plus"
                      @click="openChAssignAdd"
                    >新增分配</el-button>
                  </div>
                </div>
                <el-table
                  v-loading="userChannelLoading"
                  :data="userChannelList"
                  stripe
                  border
                  size="small"
                  class="nu-ch-table"
                  max-height="420"
                  empty-text="暂无分配"
                  :header-cell-style="nuChTableHeaderStyle"
                >
                  <el-table-column label="通道" prop="channelName" min-width="108" show-overflow-tooltip class-name="nu-ch-col-name" />
                  <el-table-column label="单价" width="84" align="right" header-align="right">
                    <template slot-scope="s">
                      <span class="nu-ch-num">{{ s.row.price != null ? s.row.price : '—' }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="分配(条)" prop="allotCount" width="92" align="right" header-align="right">
                    <template slot-scope="s">
                      <span class="nu-ch-num">{{ s.row.allotCount != null ? s.row.allotCount : '—' }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="成功率" min-width="110" align="center" header-align="center">
                    <template slot-scope="s">
                      <span v-if="s.row.successRateMin != null && s.row.successRateMax != null" class="nu-ch-rate">{{ s.row.successRateMin }}~{{ s.row.successRateMax }}%</span>
                      <span v-else class="nu-ch-empty">—</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="已用" prop="usedCount" width="72" align="right" header-align="right">
                    <template slot-scope="s">
                      <span class="nu-ch-num">{{ s.row.usedCount != null ? s.row.usedCount : '0' }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="状态" width="76" align="center" header-align="center">
                    <template slot-scope="scope">
                      <el-tag :type="scope.row.enabled === '1' ? 'success' : 'info'" size="mini" effect="plain" class="nu-ch-tag">
                        {{ scope.row.enabled === '1' ? '启用' : '停用' }}
                      </el-tag>
                    </template>
                  </el-table-column>
                  <el-table-column label="操作" width="108" align="center" fixed="right">
                    <template slot-scope="scope">
                      <el-button
                        v-hasPermi="['business:channel:edit']"
                        class="nu-ch-link"
                        type="text"
                        size="small"
                        @click="openChAssignEdit(scope.row)"
                      >编辑</el-button>
                      <el-button
                        v-hasPermi="['business:channel:edit']"
                        class="nu-ch-link nu-ch-link--danger"
                        type="text"
                        size="small"
                        @click="removeChAssign(scope.row)"
                      >删除</el-button>
                    </template>
                  </el-table-column>
                </el-table>
              </div>
            </el-tab-pane>
            <el-tab-pane label="菜单权限" name="menu">
              <p v-if="!menuPermEditable" class="nu-menu-hint">
                由左侧账户已绑定的<strong>角色</strong>决定。仅超级管理员可在此直接改菜单；您可请超管操作，或通过「编辑」更换用户角色。
              </p>
              <p v-else class="nu-menu-hint">
                选择<strong>配置角色</strong>后勾选菜单，点「保存到角色」会写入该角色在系统中的菜单（所有持该角色用户同步生效）。若只需改一人，请为其单独建角色或仅改「编辑」中的角色绑定。
              </p>
              <div v-if="menuTreeData.length" class="nu-menu-toolbar">
                <div v-if="detailUser.roles && detailUser.roles.length" class="nu-menu-role-row">
                  <span class="nu-menu-role-label">配置角色</span>
                  <el-select
                    v-model="menuEditRoleId"
                    size="small"
                    class="nu-menu-role-select"
                    placeholder="选择角色"
                    @change="onMenuEditRoleChange"
                  >
                    <el-option
                      v-for="r in detailUser.roles"
                      :key="r.roleId"
                      :label="displayRoleLabel(r)"
                      :value="r.roleId"
                    />
                  </el-select>
                  <el-button
                    v-if="menuPermEditable"
                    type="primary"
                    size="small"
                    icon="el-icon-check"
                    :disabled="!menuEditRoleId"
                    @click="saveUserRoleMenus"
                  >保存到角色</el-button>
                </div>
                <div class="nu-menu-wrap" :class="{ 'nu-menu-wrap--editable': menuPermEditable }">
                  <el-tree
                    ref="menuTree"
                    :data="menuTreeData"
                    :props="menuTreeProps"
                    node-key="id"
                    show-checkbox
                    :check-strictly="!menuPermEditable"
                    default-expand-all
                  />
                </div>
              </div>
              <el-empty v-else description="暂无角色或菜单" :image-size="80" />
            </el-tab-pane>
          </el-tabs>
        </div>
      </el-col>
    </el-row>

    <!-- 开户 / 编辑 -->
    <el-dialog
      :title="dialogTitle"
      :visible.sync="dialogOpen"
      width="560px"
      custom-class="nu-user-dlg"
      append-to-body
      @close="cancelForm"
    >
      <el-form
        :key="userDialogFormKey"
        ref="form"
        :model="form"
        :rules="rules"
        label-width="88px"
      >
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="账户名称" prop="userName">
              <el-input v-model="form.userName" placeholder="登录账号" maxlength="30" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="邮箱" prop="email">
              <el-input v-model="form.email" placeholder="邮箱" maxlength="50" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row v-if="form.userId == null" :gutter="16">
          <el-col :span="12">
            <el-form-item label="用户密码" prop="password">
              <el-input v-model="form.password" type="password" placeholder="密码" maxlength="20" show-password />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="24">
            <el-form-item label="角色">
              <el-select v-model="form.roleIds" multiple placeholder="角色" style="width:100%">
                <el-option
                  v-for="item in roleOptionsForForm"
                  :key="item.roleId"
                  :label="item.displayName"
                  :value="item.roleId"
                  :disabled="item.status == 1"
                />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" placeholder="选填" />
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button type="primary" @click="submitForm">确 定</el-button>
        <el-button @click="dialogOpen = false">取 消</el-button>
      </div>
    </el-dialog>

    <!-- 线路分配：新户内「线路分配」标签与独立页同一接口 -->
    <el-dialog
      :title="chAssignTitle"
      :visible.sync="chAssignOpen"
      width="520px"
      custom-class="ch-assign-dlg"
      append-to-body
      @close="onChAssignClose"
    >
      <el-form ref="chAssignForm" :model="chAssignForm" :rules="chAssignRules" label-width="96px" size="small" class="ch-assign-form">
        <el-form-item label="通道" prop="channelId">
          <el-select
            v-model="chAssignForm.channelId"
            filterable
            placeholder="通道"
            style="width: 100%"
            :disabled="!!chAssignForm.id"
          >
            <el-option v-for="c in channelOptions" :key="c.id" :label="c.channelName" :value="c.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="单价" prop="price">
          <el-input-number
            v-model="chAssignForm.price"
            :min="0"
            :precision="4"
            :step="0.0001"
            style="width: 100%"
            controls-position="right"
          />
        </el-form-item>
        <el-form-item label="分配条数" prop="allotCount">
          <el-input-number v-model="chAssignForm.allotCount" :min="0" :step="1" style="width: 100%" controls-position="right" />
        </el-form-item>
        <el-form-item label="发送成功率">
          <div class="ch-rate-row">
            <el-input-number
              v-model="chAssignForm.successRateMin"
              :min="0"
              :max="100"
              :precision="1"
              :controls="true"
              controls-position="right"
              placeholder="低"
              class="ch-rate-input"
            />
            <span class="ch-rate-sep">~</span>
            <el-input-number
              v-model="chAssignForm.successRateMax"
              :min="0"
              :max="100"
              :precision="1"
              :controls="true"
              controls-position="right"
              placeholder="高"
              class="ch-rate-input"
            />
            <span class="ch-rate-unit">%</span>
          </div>
        </el-form-item>
        <el-form-item v-if="chAssignForm.id" label="已用条数">
          <span>{{ chAssignForm.usedCount != null ? chAssignForm.usedCount : 0 }}</span>
        </el-form-item>
        <el-form-item label="状态" prop="enabled">
          <el-radio-group v-model="chAssignForm.enabled">
            <el-radio label="1">启用</el-radio>
            <el-radio label="0">停用</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="chAssignForm.remark" type="textarea" :rows="2" placeholder="选填" maxlength="500" show-word-limit />
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button type="primary" @click="submitChAssignForm">确 定</el-button>
        <el-button @click="chAssignOpen = false">取 消</el-button>
      </div>
    </el-dialog>

    <el-dialog
      :title="alertFormDialogTitle"
      :visible.sync="alertFormOpen"
      width="500px"
      append-to-body
      @close="resetAlertForm"
    >
      <el-form ref="alertForm" :model="alertForm" :rules="alertFormRules" label-width="120px" size="small">
        <el-form-item label="通道" prop="channelId">
          <el-select v-model="alertForm.channelId" placeholder="请选择已分配通道" style="width: 100%;" :disabled="!!alertForm.id">
            <el-option
              v-for="c in userChannelList"
              :key="c.channelId"
              :label="(c.channelName || '') + (c.allotCount != null ? '（可提交约 ' + Math.max(0, (c.allotCount || 0) - (c.usedCount || 0)) + '）' : '')"
              :value="c.channelId"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="可提交须≥" prop="minThreshold">
          <el-input-number v-model="alertForm.minThreshold" :min="0" :max="999999999" :step="10000" style="width: 100%;" />
          <span class="nu-alert-form-tip"> 条，低于时触发</span>
        </el-form-item>
        <el-form-item label="计划发送(时)" prop="plannedSendHour">
          <el-input-number v-model="alertForm.plannedSendHour" :min="0" :max="23" :step="1" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="提前" prop="leadHours">
          <el-input-number v-model="alertForm.leadHours" :min="1" :max="168" :step="1" style="width: 100%;" />
          <span class="nu-alert-form-tip"> 小时 内开始检查并同步公告</span>
        </el-form-item>
        <el-form-item label="启用">
          <el-switch v-model="alertForm.enabled" active-value="1" inactive-value="0" />
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="alertFormOpen = false">取 消</el-button>
        <el-button type="primary" @click="submitAlertForm">保 存</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import {
  listUser,
  getUser,
  addUser,
  updateUser,
  updateUserRoleMenu,
  delUser,
  resetUserPwd,
  changeUserStatus,
} from '@/api/system/user'
import { roleMenuTreeselect } from '@/api/system/menu'
import {
  listUserChannel,
  getUserChannel,
  addUserChannel,
  updateUserChannel,
  delUserChannel
} from '@/api/business/channelAssign'
import { channelList } from '@/api/business/channel'
import {
  listUserChannelAlert,
  addUserChannelAlert,
  updateUserChannelAlert,
  delUserChannelAlert
} from '@/api/business/userChannelAlert'
export default {
  name: 'BusinessNewUser',
  data() {
    return {
      loading: false,
      userList: [],
      total: 0,
      queryParams: {
        pageNum: 1,
        pageSize: 10,
        userName: undefined,
        status: undefined
      },
      selectedUserId: null,
      detailLoading: false,
      detailUser: {},
      activeTab: 'overview',
      overviewBalance: 0,
      overviewUsed: 0,
      overviewChannelCount: 0,
      /** 账户概览右侧：该用户线路分配明细 */
      userChannelList: [],
      userChannelLoading: false,
      channelOptions: [],
      chAssignOpen: false,
      chAssignTitle: '',
      chAssignForm: {},
      chAssignRules: {
        channelId: [{ required: true, message: '请选择通道', trigger: 'change' }]
      },
      menuTreeData: [],
      /** 菜单权限 tab 当前正在配置/展示的角色（按角色保存，非按人直存） */
      menuEditRoleId: null,
      menuTreeProps: {
        children: 'children',
        label: 'label'
      },
      dialogOpen: false,
      dialogTitle: '',
      form: {},
      roleOptions: [],
      initPassword: '',
      userAlertList: [],
      alertListLoading: false,
      alertFormOpen: false,
      alertFormDialogTitle: '新增预警',
      alertForm: {},
      alertFormRules: {
        channelId: [{ required: true, message: '请选择通道', trigger: 'change' }],
        minThreshold: [{ required: true, type: 'number', message: '请填写预警条数', trigger: 'change' }],
        leadHours: [{ required: true, type: 'number', message: '请填写提前小时', trigger: 'change' }],
        plannedSendHour: [{ required: true, type: 'number', message: '请填写计划发送时', trigger: 'change' }]
      },
      rules: {
        userName: [
          { required: true, message: '账户名称不能为空', trigger: 'blur' },
          { min: 2, max: 20, message: '账户名称长度必须介于 2 和 20 之间', trigger: 'blur' }
        ],
        password: [
          { required: true, message: '用户密码不能为空', trigger: 'blur' },
          { min: 5, max: 20, message: '用户密码长度必须介于 5 和 20 之间', trigger: 'blur' },
          { pattern: /^[^<>"'|\\]+$/, message: '不能包含非法字符：< > \" \' \\\ |', trigger: 'blur' }
        ],
        email: [{ type: 'email', message: '请输入正确的邮箱地址', trigger: ['blur', 'change'] }]
      }
    }
  },
  computed: {
    /** 展示用账户名称（与登录名一致） */
    detailAccountName() {
      return this.detailUser.userName || ''
    },
    userLevelText() {
      const roles = this.detailUser.roles
      if (roles && roles.length) {
        const label = r => {
          const key = (r.roleKey || '').toLowerCase()
          if (key === 'admin') return '超级管理员'
          if (key === 'manager') return '普通管理员'
          if (key === 'common') return '普通用户'
          const n = (r.roleName || '').trim()
          return n === '普通角色' ? '普通用户' : n
        }
        return roles.map(label).join('、')
      }
      return '未设置'
    },
    /** 编辑与「开户」共用弹窗，切换时重建表单，避免从编辑带过去的校验/残留状态在开户时仍生效 */
    userDialogFormKey() {
      if (!this.dialogOpen) {
        return 'user-form-closed'
      }
      return this.form && this.form.userId != null ? 'user-edit-' + this.form.userId : 'user-add'
    },
    /**
     * 按当前登录用户可分配范围过滤：
     * - 超级管理员（role 含 admin 或 userId=1）：可选 超级管理员、普通管理员、普通用户
     * - 普通管理员（role 含 manager，且非超管）：仅可选 普通用户
     * - 其它：仅 普通用户
     * 已绑定角色始终显示，避免编辑时标签丢失。
     */
    roleOptionsForForm() {
      const order = ['超级管理员', '普通管理员', '普通用户']
      const myKeys = this.$store.getters.roles || []
      const myId = Number(this.$store.getters.id)
      const isSuperOperator = myKeys.includes('admin') || myId === 1
      const allowedSet = isSuperOperator
        ? new Set(['超级管理员', '普通管理员', '普通用户'])
        : new Set(['普通用户'])

      const selected = new Set(this.form && this.form.roleIds ? this.form.roleIds : [])
      const displayNameFor = r => {
        const key = (r.roleKey || '').toLowerCase()
        if (key === 'admin') return '超级管理员'
        if (key === 'manager') return '普通管理员'
        if (key === 'common') return '普通用户'
        const n = (r.roleName || '').trim()
        if (n === '普通角色') return '普通用户'
        return n
      }
      const list = (this.roleOptions || []).map(r => ({
        ...r,
        displayName: displayNameFor(r)
      }))
      const inThree = l => order.indexOf(l.displayName) >= 0
      const picked = new Map()
      list.forEach(r => {
        if (!(inThree(r) || selected.has(r.roleId))) {
          return
        }
        if (selected.has(r.roleId)) {
          picked.set(r.roleId, r)
          return
        }
        if (allowedSet.has(r.displayName)) {
          picked.set(r.roleId, r)
        }
      })
      return [...picked.values()].sort((a, b) => {
        const ia = order.indexOf(a.displayName)
        const ib = order.indexOf(b.displayName)
        if (ia >= 0 && ib >= 0) {
          return ia - ib
        }
        if (ia >= 0) {
          return -1
        }
        if (ib >= 0) {
          return 1
        }
        return (a.displayName || '').localeCompare(b.displayName || '')
      })
    },
    /** 与开户编辑弹窗一致：超管 (userId=1 或 role 含 admin) 可改「菜单权限」并保存到角色 */
    menuPermEditable() {
      const myKeys = this.$store.getters.roles || []
      const myId = Number(this.$store.getters.id)
      return myKeys.includes('admin') || myId === 1
    }
  },
  created() {
    this.getList()
    this.loadChannelOptions()
    this.getConfigKey('sys.user.initPassword').then(res => {
      this.initPassword = res.msg || '123456'
    })
    if (this.$route.query.tab === 'channelAssign') {
      this.$nextTick(() => { this.activeTab = 'channelAssign' })
    }
  },
  filters: {
    fmtNum(v) {
      if (v == null) return '—'
      return v
    },
    fmtHour(v) {
      if (v == null || v === '') return '—'
      return String(v).padStart(2, '0') + ':00'
    }
  },
  methods: {
    accountInitial(name) {
      if (!name || typeof name !== 'string') return '?'
      const s = name.trim()
      if (!s.length) return '?'
      const ch = s.charAt(0)
      return /[a-z]/i.test(ch) ? ch.toUpperCase() : ch
    },
    /** 线路分配表头 */
    nuChTableHeaderStyle() {
      return {
        background: '#f5f7fa',
        color: '#303133',
        fontWeight: '600',
        fontSize: '13px',
        padding: '10px 0'
      }
    },
    getList() {
      this.loading = true
      listUser(this.queryParams)
        .then(res => {
          this.userList = res.rows || []
          this.total = res.total || 0
          this.loading = false
          if (this.userList.length) {
            const exists = this.selectedUserId && this.userList.some(u => u.userId === this.selectedUserId)
            if (!exists) {
              this.selectUser(this.userList[0])
            }
          } else {
            this.selectedUserId = null
            this.detailUser = {}
            this.userChannelList = []
            this.overviewChannelCount = 0
            this.overviewBalance = 0
            this.overviewUsed = 0
            this.userAlertList = []
          }
        })
        .catch(() => {
          this.loading = false
        })
    },
    handleQuery() {
      this.queryParams.pageNum = 1
      this.getList()
    },
    selectUser(row) {
      if (!row || !row.userId) return
      this.selectedUserId = row.userId
      this.loadDetail(row.userId)
    },
    loadDetail(userId) {
      this.detailLoading = true
      this.menuTreeData = []
      this.menuEditRoleId = null
      getUser(userId)
        .then(res => {
          this.detailUser = res.data || {}
          this.loadChannelOverview(userId)
          this.loadMenuForUser(res.data, res.roleIds)
        })
        .finally(() => {
          this.detailLoading = false
        })
    },
    loadChannelOptions() {
      channelList({ pageNum: 1, pageSize: 500 })
        .then(res => {
          this.channelOptions = res.rows || []
        })
        .catch(() => {})
    },
    loadChannelOverview(userId) {
      this.userChannelLoading = true
      listUserChannel({ userId, pageNum: 1, pageSize: 999 })
        .then(res => {
          const rows = res.rows || []
          this.userChannelList = rows
          this.overviewChannelCount = rows.length
          let bal = 0
          let used = 0
          rows.forEach(r => {
            const allot = Number(r.allotCount) || 0
            const u = Number(r.usedCount) || 0
            used += u
            bal += Math.max(0, allot - u)
          })
          this.overviewBalance = bal
          this.overviewUsed = used
        })
        .catch(() => {
          this.overviewChannelCount = 0
          this.overviewBalance = 0
          this.overviewUsed = 0
          this.userChannelList = []
        })
        .finally(() => {
          this.userChannelLoading = false
        })
      this.loadUserAlerts(userId)
    },
    loadUserAlerts(userId) {
      if (!userId) {
        this.userAlertList = []
        return
      }
      this.alertListLoading = true
      listUserChannelAlert(userId)
        .then(res => {
          this.userAlertList = (res && res.data) || []
        })
        .catch(() => {
          this.userAlertList = []
        })
        .finally(() => {
          this.alertListLoading = false
        })
    },
    onDetailTabClick(tab) {
      if (tab && tab.name === 'channelAssign' && this.selectedUserId) {
        this.loadChannelOverview(this.selectedUserId)
      }
      if (tab && tab.name === 'overview' && this.selectedUserId) {
        this.loadUserAlerts(this.selectedUserId)
      }
    },
    refreshUserChannels() {
      if (this.selectedUserId) {
        this.loadChannelOverview(this.selectedUserId)
      }
    },
    openAlertDialog() {
      this.alertFormDialogTitle = '新增预警'
      this.resetAlertForm()
      this.alertFormOpen = true
    },
    resetAlertForm() {
      this.alertForm = {
        id: undefined,
        userId: this.selectedUserId,
        channelId: undefined,
        minThreshold: 100000,
        leadHours: 6,
        plannedSendHour: 22,
        enabled: '1'
      }
      this.$nextTick(() => {
        if (this.$refs.alertForm) {
          this.$refs.alertForm.clearValidate()
        }
      })
    },
    editAlertRow(row) {
      this.alertFormDialogTitle = '编辑预警'
      this.alertForm = {
        id: row.id,
        userId: row.userId,
        channelId: row.channelId,
        minThreshold: row.minThreshold,
        leadHours: row.leadHours,
        plannedSendHour: row.plannedSendHour,
        enabled: row.enabled
      }
      this.alertFormOpen = true
    },
    submitAlertForm() {
      this.$refs.alertForm.validate(valid => {
        if (!valid) return
        const payload = { ...this.alertForm, userId: this.selectedUserId }
        const req = payload.id != null && payload.id !== undefined
          ? updateUserChannelAlert(payload)
          : addUserChannelAlert(payload)
        req.then(() => {
          this.$modal.msgSuccess('已保存')
          this.alertFormOpen = false
          this.loadUserAlerts(this.selectedUserId)
        })
      })
    },
    removeAlertRow(row) {
      if (!row || !row.id) return
      this.$modal.confirm('确认删除该条预警？').then(() => {
        delUserChannelAlert(row.id).then(() => {
          this.$modal.msgSuccess('已删除')
          this.loadUserAlerts(this.selectedUserId)
        })
      }).catch(() => {})
    },
    resetChAssignForm() {
      this.chAssignForm = {
        id: undefined,
        userId: this.selectedUserId || undefined,
        channelId: undefined,
        price: undefined,
        allotCount: undefined,
        usedCount: 0,
        enabled: '1',
        remark: undefined,
        successRateMin: undefined,
        successRateMax: undefined
      }
    },
    onChAssignClose() {
      this.resetChAssignForm()
      this.$nextTick(() => {
        this.$refs.chAssignForm && this.$refs.chAssignForm.clearValidate()
      })
    },
    openChAssignAdd() {
      if (!this.selectedUserId) {
        this.$message.warning('请先选择用户')
        return
      }
      this.resetChAssignForm()
      this.chAssignForm.userId = this.selectedUserId
      this.chAssignTitle = '新增线路分配'
      this.chAssignOpen = true
      this.$nextTick(() => {
        this.$refs.chAssignForm && this.$refs.chAssignForm.clearValidate()
      })
    },
    openChAssignEdit(row) {
      this.resetChAssignForm()
      getUserChannel(row.id)
        .then(res => {
          const d = res.data || row
          this.chAssignForm = {
            id: d.id,
            userId: d.userId,
            channelId: d.channelId,
            price: d.price != null ? Number(d.price) : undefined,
            allotCount: d.allotCount != null ? Number(d.allotCount) : undefined,
            usedCount: d.usedCount != null ? Number(d.usedCount) : 0,
            enabled: d.enabled != null ? String(d.enabled) : '1',
            remark: d.remark,
            successRateMin: d.successRateMin != null ? Number(d.successRateMin) : undefined,
            successRateMax: d.successRateMax != null ? Number(d.successRateMax) : undefined
          }
          this.chAssignTitle = '修改线路分配'
          this.chAssignOpen = true
          this.$nextTick(() => {
            this.$refs.chAssignForm && this.$refs.chAssignForm.clearValidate()
          })
        })
        .catch(() => {})
    },
    submitChAssignForm() {
      this.$refs.chAssignForm.validate(valid => {
        if (!valid) return
        const f = this.chAssignForm
        const a = f.successRateMin
        const b = f.successRateMax
        if ((a == null) !== (b == null)) {
          this.$message.warning('发送成功率需同时留空，或同时填写下限与上限')
          return
        }
        if (a != null && b != null && a > b) {
          this.$message.warning('成功率下限不能大于上限')
          return
        }
        const payload = {
          id: f.id,
          userId: f.userId || this.selectedUserId,
          channelId: f.channelId,
          price: f.price,
          allotCount: f.allotCount,
          enabled: f.enabled,
          remark: f.remark,
          successRateMin: a,
          successRateMax: b
        }
        if (f.id) {
          updateUserChannel(payload).then(() => {
            this.$modal.msgSuccess('修改成功')
            this.chAssignOpen = false
            this.loadChannelOverview(this.selectedUserId)
          })
        } else {
          addUserChannel(payload).then(() => {
            this.$modal.msgSuccess('新增成功')
            this.chAssignOpen = false
            this.loadChannelOverview(this.selectedUserId)
          })
        }
      })
    },
    removeChAssign(row) {
      this.$modal
        .confirm('是否确认删除该线路分配？')
        .then(() => delUserChannel(row.id))
        .then(() => {
          this.$modal.msgSuccess('删除成功')
          this.loadChannelOverview(this.selectedUserId)
        })
        .catch(() => {})
    },
    displayRoleLabel(r) {
      if (!r) return ''
      const key = (r.roleKey || '').toLowerCase()
      if (key === 'admin') return '超级管理员'
      if (key === 'manager') return '普通管理员'
      if (key === 'common') return '普通用户'
      const n = (r.roleName || '').trim()
      if (n === '普通角色') return '普通用户'
      return n
    },
    /**
     * 按账户绑定的 roleIds 确定「配置角色」并加载单角色菜单树（保存时只写该 role_id 的 sys_role_menu）
     */
    loadMenuForUser(user, roleIds) {
      const ids = roleIds && roleIds.length
        ? roleIds
        : (user && user.roles ? user.roles.map(r => r.roleId) : [])
      if (!ids || !ids.length) {
        this.menuTreeData = []
        this.menuEditRoleId = null
        return
      }
      if (this.menuEditRoleId == null || !ids.includes(this.menuEditRoleId)) {
        this.menuEditRoleId = ids[0]
      }
      this.loadMenuForRole(this.menuEditRoleId)
    },
    onMenuEditRoleChange() {
      this.loadMenuForRole(this.menuEditRoleId)
    },
    loadMenuForRole(roleId) {
      if (!roleId) {
        this.menuTreeData = []
        return
      }
      roleMenuTreeselect(roleId)
        .then(res => {
          const checked = res.checkedKeys || []
          this.menuTreeData = this.applyMenuNodeDisabled(res.menus || [])
          this.$nextTick(() => {
            const tree = this.$refs.menuTree
            if (tree) {
              tree.setCheckedKeys([])
              checked.forEach(k => {
                tree.setChecked(k, true, false)
              })
            }
          })
        })
        .catch(() => {
          this.menuTreeData = []
        })
    },
    applyMenuNodeDisabled(nodes) {
      if (!nodes || !nodes.length) return []
      const dis = !this.menuPermEditable
      return nodes.map(n => ({
        ...n,
        disabled: dis,
        children: this.applyMenuNodeDisabled(n.children)
      }))
    },
    saveUserRoleMenus() {
      if (!this.menuPermEditable || !this.selectedUserId || !this.menuEditRoleId) {
        return
      }
      const tree = this.$refs.menuTree
      if (!tree) return
      const part = (tree.getCheckedKeys && tree.getCheckedKeys()) || []
      const half = (tree.getHalfCheckedKeys && tree.getHalfCheckedKeys()) || []
      const menuIds = [...new Set([].concat(part, half))].map(Number)
      updateUserRoleMenu(this.selectedUserId, { roleId: this.menuEditRoleId, menuIds })
        .then(() => {
          this.$modal.msgSuccess('已保存到该角色，相关用户将按新菜单生效（若需重登可提示用户刷新）')
          this.loadDetail(this.selectedUserId)
        })
    },
    onDetailStatusChange() {
      const row = { userId: this.detailUser.userId, userName: this.detailUser.userName, status: this.detailUser.status }
      const text = row.status === '0' ? '启用' : '停用'
      this.$modal
        .confirm(`确认要「${text}」用户「${row.userName}」吗？`)
        .then(() => changeUserStatus(row.userId, row.status))
        .then(() => {
          this.$modal.msgSuccess(text + '成功')
          this.getList()
        })
        .catch(() => {
          this.detailUser.status = this.detailUser.status === '0' ? '1' : '0'
        })
    },
    handleAdd() {
      this.resetFormModel()
      getUser().then(response => {
        this.roleOptions = response.roles
        this.$set(this.form, 'postIds', [])
        this.$set(this.form, 'deptId', null)
        this.form.password = this.initPassword
        this.dialogTitle = '开户'
        this.dialogOpen = true
      })
    },
    handleEdit() {
      this.resetFormModel()
      getUser(this.selectedUserId).then(response => {
        this.form = { ...response.data }
        this.roleOptions = response.roles
        this.$set(this.form, 'postIds', [])
        this.$set(this.form, 'roleIds', response.roleIds)
        this.$set(this.form, 'deptId', null)
        this.$set(this.form, 'phonenumber', '')
        this.form.password = ''
        this.dialogTitle = '编辑用户'
        this.dialogOpen = true
      })
    },
    resetFormModel() {
      this.form = {
        userId: undefined,
        deptId: null,
        userName: undefined,
        password: undefined,
        email: undefined,
        status: '0',
        remark: undefined,
        postIds: [],
        roleIds: []
      }
    },
    cancelForm() {
      this.resetFormModel()
    },
    submitForm() {
      this.$refs.form.validate(valid => {
        if (!valid) return
        const payload = { ...this.form, postIds: [], phonenumber: '' }
        if (!payload.deptId) {
          payload.deptId = null
        }
        const name = (payload.userName || '').trim()
        payload.userName = name
        payload.nickName = name
        const req = payload.userId ? updateUser(payload) : addUser(payload)
        req.then(() => {
          this.$modal.msgSuccess(this.form.userId ? '修改成功' : '新增成功')
          this.dialogOpen = false
          this.getList()
          if (this.form.userId && this.form.userId === this.selectedUserId) {
            this.loadDetail(this.selectedUserId)
          }
        })
      })
    },
    handleResetPwd() {
      const row = this.detailUser
      this.$prompt(`请输入「${row.userName}」的新密码`, '重置密码', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        closeOnClickModal: false,
        inputPattern: /^.{5,20}$/,
        inputErrorMessage: '用户密码长度必须介于 5 和 20 之间',
        inputValidator: value => {
          if (/<|>|"|'|\||\\/.test(value)) {
            return '不能包含非法字符：< > \" \' \\\ |'
          }
        }
      })
        .then(({ value }) => {
          return resetUserPwd(row.userId, value)
        })
        .then(() => {
          this.$modal.msgSuccess('密码已重置')
        })
        .catch(() => {})
    },
    handleDelete() {
      this.$modal
        .confirm(`是否确认删除用户「${this.detailUser.userName}」？`)
        .then(() => delUser(this.detailUser.userId))
        .then(() => {
          this.$modal.msgSuccess('删除成功')
          this.selectedUserId = null
          this.detailUser = {}
          this.getList()
        })
        .catch(() => {})
    }
  }
}
</script>

<style scoped>
.nu-page {
  min-height: calc(100vh - 100px);
  background: linear-gradient(165deg, #f0f4f8 0%, #e9eef4 45%, #f2f4f7 100%);
  padding: 20px;
  box-sizing: border-box;
}

.nu-row {
  align-items: stretch;
}

.nu-col-left,
.nu-col-right {
  display: flex;
  flex-direction: column;
}

.nu-card {
  background: #fff;
  border-radius: 10px;
  border: 1px solid rgba(0, 0, 0, 0.06);
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.05), 0 0 0 1px rgba(0, 0, 0, 0.02);
  padding: 18px;
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 520px;
  box-sizing: border-box;
}

.nu-col-left .nu-card {
  min-height: 0;
}

.nu-card--empty {
  min-height: 400px;
}

.nu-card-left {
  padding: 10px 12px 14px;
  min-height: 0;
  overflow: hidden;
}

.nu-left-head {
  padding: 8px 4px 0;
  margin: 0;
  border: none;
}

.nu-left-title-block {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.nu-left-title-wrap {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  min-width: 0;
}

.nu-head-ico {
  font-size: 22px;
  color: #1890ff;
  margin-top: 2px;
  flex-shrink: 0;
}

.nu-left-title-text {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}

.nu-left-title {
  font-size: 17px;
  font-weight: 700;
  color: #141414;
  letter-spacing: -0.02em;
  line-height: 1.25;
}

.nu-left-sub {
  font-size: 12px;
  color: #8c8c8c;
  font-weight: 400;
  line-height: 1.3;
}

.nu-btn-open {
  flex-shrink: 0;
  box-shadow: 0 2px 8px rgba(24, 144, 255, 0.35);
}

.nu-left-filters {
  display: flex;
  gap: 10px;
  margin: 12px 0 12px;
  padding: 12px;
  background: linear-gradient(145deg, #f8fafc 0%, #f1f5f9 100%);
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.8);
}

.nu-left-filters .el-input {
  flex: 1;
  min-width: 0;
}

.nu-filter-input >>> .el-input__inner {
  border-radius: 10px;
  border-color: #dce4ec;
  height: 34px;
  line-height: 34px;
}

.nu-status-select {
  width: 100px;
  flex-shrink: 0;
}

.nu-status-select >>> .el-input__inner {
  border-radius: 10px;
  border-color: #dce4ec;
  height: 34px;
  line-height: 34px;
}

/* 固定列表可视区域高度，避免 flex 把中间撑出大片空白；条目在区域内滚动 */
.nu-list-scroller {
  margin: 0;
  height: max(220px, min(42vh, 380px));
  border-radius: 12px;
  border: 1px solid #eef0f4;
  background: #fbfcfe;
  overflow: hidden;
}

@media (min-width: 992px) {
  .nu-list-scroller {
    height: calc(100vh - 272px);
    max-height: 640px;
  }
}

.nu-list-scroll {
  height: 100%;
}

.nu-list-scroll >>> .el-scrollbar__wrap {
  overflow-x: hidden;
  height: 100%;
}

.nu-list-inner {
  padding: 8px 8px 10px;
  min-height: 80px;
}

.nu-list-empty {
  padding: 24px 8px 32px;
}

.nu-list-empty >>> .el-empty__description {
  color: #909399;
}

.nu-list-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  margin-bottom: 6px;
  border-radius: 10px;
  border: 1px solid transparent;
  background: #fff;
  cursor: pointer;
  transition: transform 0.15s ease, box-shadow 0.2s ease, border-color 0.2s ease, background 0.2s ease;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.05);
}

.nu-list-item:last-child {
  margin-bottom: 0;
}

.nu-list-item:hover {
  transform: translateY(-1px);
  border-color: #bfdbfe;
  box-shadow: 0 6px 16px rgba(37, 99, 235, 0.1);
}

.nu-list-item.active {
  background: linear-gradient(105deg, #eff6ff 0%, #fff 55%);
  border-color: #93c5fd;
  box-shadow: 0 4px 14px rgba(37, 99, 235, 0.15);
  outline: 1px solid rgba(59, 130, 246, 0.25);
}

.nu-item-avatar {
  flex-shrink: 0;
  width: 40px;
  height: 40px;
  border-radius: 12px;
  background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
  color: #fff;
  font-size: 15px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  letter-spacing: 0.02em;
  box-shadow: 0 2px 8px rgba(37, 99, 235, 0.35);
}

.nu-list-item.active .nu-item-avatar {
  background: linear-gradient(135deg, #2563eb 0%, #1e40af 100%);
}

.nu-item-body {
  flex: 1;
  min-width: 0;
}

.nu-nick {
  font-size: 15px;
  font-weight: 600;
  color: #0f172a;
  line-height: 1.35;
  letter-spacing: -0.01em;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.nu-badge {
  flex-shrink: 0;
  font-size: 11px;
  font-weight: 600;
  padding: 3px 10px;
  border-radius: 999px;
  letter-spacing: 0.02em;
}

.nu-badge--ok {
  color: #15803d;
  background: rgba(34, 197, 94, 0.12);
  border: 1px solid rgba(34, 197, 94, 0.35);
}

.nu-badge--off {
  color: #b91c1c;
  background: rgba(248, 113, 113, 0.12);
  border: 1px solid rgba(248, 113, 113, 0.35);
}

.nu-left-pager {
  flex-shrink: 0;
  padding: 10px 4px 2px;
  margin-top: 6px;
  text-align: center;
  border-top: 1px solid #f1f5f9;
  background: linear-gradient(180deg, #fff 0%, #fafbfc 100%);
}

.nu-left-pager >>> .el-pagination {
  padding: 0;
  font-weight: 500;
}

.nu-left-pager >>> .el-pagination button,
.nu-left-pager >>> .el-pager li {
  border-radius: 8px;
}

.nu-placeholder {
  align-items: center;
  justify-content: center;
}

.nu-empty >>> .el-empty__description {
  margin-top: 8px;
  color: #909399;
  font-size: 14px;
}

.nu-detail-card {
  padding-top: 12px;
}

.nu-detail-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 16px;
}

.nu-detail-title {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #1f1f1f;
  letter-spacing: 0.2px;
}

.nu-detail-ico {
  color: #1890ff;
  font-size: 18px;
}

.nu-detail-actions .el-button + .el-button {
  margin-left: 8px;
}

.nu-desc {
  margin-bottom: 12px;
}
.nu-desc >>> .el-descriptions__header {
  display: none;
}
.nu-desc >>> .el-descriptions__body {
  background: #fafbfc;
  border-radius: 8px;
  overflow: hidden;
}
.nu-desc >>> .el-descriptions-item__label {
  width: 100px;
  color: #606266;
  font-weight: 500;
  background: #f5f7fa;
}
.nu-desc >>> .el-descriptions-item__content {
  color: #303133;
  font-weight: 500;
}

.nu-tabs >>> .el-tabs__header {
  margin-bottom: 16px;
}

.nu-tabs >>> .el-tabs__item.is-active {
  color: #1890ff;
  font-weight: 600;
}

.nu-tabs >>> .el-tabs__active-bar {
  background-color: #1890ff;
}

.nu-stat-row {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
  margin-bottom: 8px;
}

.nu-stat-card {
  flex: 1;
  min-width: 160px;
  border-radius: 4px;
  padding: 16px 18px;
  color: #fff;
  position: relative;
  overflow: hidden;
}

.nu-stat-blue {
  background: linear-gradient(135deg, #1890ff 0%, #096dd9 100%);
}

.nu-stat-green {
  background: linear-gradient(135deg, #52c41a 0%, #389e0d 100%);
}

.nu-stat-amber {
  background: linear-gradient(135deg, #faad14 0%, #d48806 100%);
}

.nu-stat-ico {
  position: absolute;
  right: 14px;
  top: 14px;
  font-size: 28px;
  opacity: 0.35;
}

.nu-stat-num {
  font-size: 26px;
  font-weight: 700;
  line-height: 1.2;
}

.nu-stat-label {
  margin-top: 8px;
  font-size: 13px;
  opacity: 0.95;
}

.nu-alert-panel {
  margin-top: 20px;
  border: 1px solid #ebeef5;
  border-radius: 8px;
  padding: 14px 16px 16px;
  background: #fafbfc;
}

.nu-alert-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
  flex-wrap: wrap;
  gap: 10px;
}

.nu-alert-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 15px;
  font-weight: 600;
  color: #303133;
}

.nu-alert-hint {
  color: #909399;
  cursor: help;
  font-size: 15px;
}

.nu-alert-table {
  background: #fff;
}

.nu-alert-form-tip {
  margin-left: 4px;
  color: #909399;
  font-size: 12px;
}

.nu-ch-panel {
  border: 1px solid #ebeef5;
  border-radius: 8px;
  padding: 0;
  background: #fff;
  min-height: 200px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.04);
  overflow: hidden;
}

.nu-ch-panel--tab {
  max-width: 100%;
}

.nu-ch-panel__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 16px;
  background: linear-gradient(180deg, #fafbfc 0%, #fff 100%);
  border-bottom: 1px solid #eef0f3;
  flex-wrap: wrap;
  gap: 10px;
}

.nu-ch-panel__title-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
}

.nu-ch-panel__icon {
  font-size: 18px;
  color: #409eff;
  opacity: 0.9;
}

.nu-ch-panel__title {
  font-size: 15px;
  font-weight: 600;
  color: #303133;
  letter-spacing: 0.2px;
}

.nu-ch-panel__actions {
  display: flex;
  align-items: center;
  flex-shrink: 0;
  gap: 8px;
}

.nu-ch-btn-refresh {
  color: #606266 !important;
  padding: 6px 10px !important;
  border-radius: 4px;
}
.nu-ch-btn-refresh:hover {
  color: #409eff !important;
  background: rgba(64, 158, 255, 0.08) !important;
}

.nu-ch-table {
  width: 100%;
  border-radius: 0 0 8px 8px;
}
.nu-ch-table >>> .el-table__body-wrapper {
  font-size: 13px;
}
.nu-ch-table >>> .el-table--border,
.nu-ch-table >>> .el-table--group {
  border-color: #ebeef5;
}
.nu-ch-table >>> .el-table--border th,
.nu-ch-table >>> .el-table--border td {
  border-color: #f0f2f5;
}
.nu-ch-table >>> .el-table__body tr:hover > td {
  background-color: #f8fafc !important;
}
.nu-ch-table >>> .el-table__empty-text {
  color: #909399;
  padding: 24px 0;
}
.nu-ch-table >>> td {
  padding: 10px 0;
}
.nu-ch-table >>> th.is-leaf {
  border-color: #ebeef5;
}
.nu-ch-table >>> .el-table__fixed-right::before,
.nu-ch-table >>> .el-table__fixed::before {
  display: none;
}

.nu-ch-num {
  font-variant-numeric: tabular-nums;
  color: #303133;
  font-weight: 500;
}
.nu-ch-rate {
  font-size: 12px;
  color: #606266;
  font-variant-numeric: tabular-nums;
}
.nu-ch-empty {
  color: #c0c4cc;
}
.nu-ch-tag {
  border-radius: 4px;
  font-weight: 500;
  padding: 0 8px;
}
.nu-ch-link {
  padding: 0 6px !important;
  font-weight: 500;
}
.nu-ch-link--danger {
  color: #f56c6c !important;
}
.nu-ch-link--danger:hover {
  color: #f78989 !important;
}
.nu-ch-col-name .cell {
  color: #303133;
  font-weight: 500;
}

@media (min-width: 1200px) {
  .nu-stat-row {
    margin-bottom: 0;
  }
}

.nu-menu-hint {
  margin: 0 0 12px;
  padding: 10px 12px;
  font-size: 13px;
  line-height: 1.5;
  color: #606266;
  background: #f4f6f9;
  border: 1px solid #ebeef5;
  border-radius: 6px;
}

.nu-menu-wrap {
  max-height: 420px;
  overflow: auto;
  padding: 8px 0;
  border: 1px solid #f0f0f0;
  border-radius: 4px;
}

.nu-menu-toolbar {
  width: 100%;
}

.nu-menu-role-row {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
  flex-wrap: wrap;
}

.nu-menu-role-label {
  font-size: 13px;
  color: #606266;
  font-weight: 500;
}

.nu-menu-role-select {
  min-width: 200px;
}

.nu-menu-wrap >>> .el-tree-node__content {
  cursor: default;
}

.nu-menu-wrap--editable >>> .el-tree-node__content {
  cursor: pointer;
}

.ch-rate-row {
  display: flex;
  align-items: center;
  width: 100%;
  gap: 8px;
}

.ch-rate-input {
  flex: 1;
  min-width: 0;
}

.ch-rate-sep {
  flex: 0 0 18px;
  text-align: center;
  color: #c0c4cc;
  font-size: 15px;
  font-weight: 500;
  line-height: 32px;
}

.ch-rate-unit {
  flex: 0 0 auto;
  color: #909399;
  font-size: 13px;
}

.ch-assign-form >>> .ch-rate-input {
  width: 100%;
}

.ch-assign-form >>> .ch-rate-input .el-input__inner {
  text-align: left;
}
</style>

<style>
/* el-dialog 挂到 body，需非 scoped 才能命中 custom-class */
.ch-assign-dlg .el-dialog__header {
  padding: 16px 20px 8px;
  border-bottom: 1px solid #f0f0f0;
}
.ch-assign-dlg .el-dialog__title {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}
.ch-assign-dlg .el-dialog__body {
  padding: 12px 20px 0;
}
.ch-assign-dlg .el-dialog__footer {
  padding: 12px 20px 16px;
  border-top: 1px solid #f0f0f0;
}
.nu-user-dlg .el-dialog__header {
  padding: 16px 20px 10px;
  border-bottom: 1px solid #f0f2f5;
  background: linear-gradient(180deg, #fafbfc 0%, #fff 100%);
}
.nu-user-dlg .el-dialog__title {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
  letter-spacing: 0.3px;
}
.nu-user-dlg .el-dialog__body {
  padding: 20px 24px 8px;
}
.nu-user-dlg .el-dialog__footer {
  padding: 12px 20px 16px;
  border-top: 1px solid #f0f2f5;
  background: #fafbfc;
}
</style>
