<template>
  <div class="app-container nu-page">
    <el-row :gutter="20" class="nu-row">
      <!-- 左侧：用户列表（与新户管理一致） -->
      <el-col :xs="24" :sm="24" :md="8" :lg="7" class="nu-col-left">
        <div class="nu-card nu-card-left">
          <div class="nu-left-head">
            <div class="nu-left-title-wrap">
              <i class="el-icon-s-operation ca-head-ico" aria-hidden="true" />
              <span class="nu-left-title">用户列表</span>
            </div>
            <el-button
              type="text"
              size="small"
              icon="el-icon-refresh"
              class="ca-left-refresh"
              @click="getUserList"
            >刷新</el-button>
          </div>
          <div class="nu-left-filters">
            <el-input
              v-model="userQueryParams.userName"
              placeholder="账户名称"
              clearable
              size="small"
              prefix-icon="el-icon-search"
              @keyup.enter.native="handleUserQuery"
              @clear="handleUserQuery"
            />
            <el-select
              v-model="userQueryParams.status"
              placeholder="状态"
              clearable
              size="small"
              class="nu-status-select"
              @change="handleUserQuery"
            >
              <el-option label="正常" value="0" />
              <el-option label="停用" value="1" />
            </el-select>
          </div>
          <el-scrollbar class="nu-list-scroll">
            <div v-loading="userLoading" class="nu-list-inner">
              <div
                v-for="u in userList"
                :key="u.userId"
                class="nu-list-item"
                :class="{ active: selectedUserId === u.userId }"
                @click="selectUser(u)"
              >
                <div class="nu-item-main">
                  <div class="nu-nick">{{ u.userName }}</div>
                </div>
                <div class="nu-item-meta">
                  <span class="nu-st" :class="u.status === '0' ? 'ok' : 'off'">{{ u.status === '0' ? '正常' : '停用' }}</span>
                </div>
              </div>
              <el-empty v-if="!userLoading && (!userList || !userList.length)" description="暂无用户" :image-size="72" />
            </div>
          </el-scrollbar>
          <div class="nu-left-pager">
            <el-pagination
              small
              layout="prev, pager, next"
              :total="userTotal"
              :page-size="userQueryParams.pageSize"
              :current-page.sync="userQueryParams.pageNum"
              @current-change="getUserList"
            />
          </div>
        </div>
      </el-col>

      <!-- 右侧：该用户的线路分配 -->
      <el-col :xs="24" :sm="24" :md="16" :lg="17" class="nu-col-right">
        <div v-if="!selectedUserId" class="nu-card nu-card--empty nu-placeholder">
          <el-empty class="ca-empty" description="请从左侧选择用户" :image-size="100" />
        </div>
        <div v-else class="nu-card nu-detail-card" v-loading="loading">
          <div class="nu-detail-head">
            <h3 class="nu-detail-title">
              <i class="el-icon-connection ca-detail-ico" aria-hidden="true" />
              线路分配 · {{ rightTitleName }}
            </h3>
            <div class="ca-toolbar">
              <el-select
                v-model="assignQueryParams.channelId"
                placeholder="通道"
                clearable
                filterable
                size="small"
                class="ca-filter-channel"
                @change="handleAssignQuery"
              >
                <el-option v-for="c in channelOptions" :key="c.id" :label="c.channelName" :value="c.id" />
              </el-select>
              <div class="nu-detail-actions">
                <el-button
                  v-hasPermi="['business:channel:edit']"
                  type="primary"
                  size="small"
                  round
                  icon="el-icon-plus"
                  @click="handleAdd"
                >新增分配</el-button>
                <el-button size="small" plain class="ca-btn-refresh" icon="el-icon-refresh" @click="getAssignList">刷新</el-button>
              </div>
            </div>
          </div>

          <el-table
            :data="list"
            border
            stripe
            size="small"
            class="ca-assign-table"
            :header-cell-style="caTableHeaderStyle"
          >
            <el-table-column label="ID" prop="id" width="72" align="center" />
            <el-table-column label="通道" prop="channelName" min-width="160" show-overflow-tooltip />
            <el-table-column label="单价" prop="price" width="100" align="right">
              <template slot-scope="scope">
                <span>{{ scope.row.price != null ? scope.row.price : '—' }}</span>
              </template>
            </el-table-column>
            <el-table-column label="分配条数" prop="allotCount" width="100" align="center" />
            <el-table-column label="成功率%" width="110" align="center">
              <template slot-scope="s">
                <span v-if="s.row.successRateMin != null && s.row.successRateMax != null">{{ s.row.successRateMin }}~{{ s.row.successRateMax }}</span>
                <span v-else>—</span>
              </template>
            </el-table-column>
            <el-table-column label="已用" prop="usedCount" width="80" align="center" />
            <el-table-column label="状态" prop="enabled" width="88" align="center">
              <template slot-scope="scope">
                <el-tag :type="scope.row.enabled === '1' ? 'success' : 'info'" size="mini">
                  {{ scope.row.enabled === '1' ? '启用' : '停用' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="备注" prop="remark" min-width="120" show-overflow-tooltip />
            <el-table-column label="操作" width="140" align="center" fixed="right" class-name="small-padding fixed-width">
              <template slot-scope="scope">
                <el-button
                  v-hasPermi="['business:channel:edit']"
                  size="mini"
                  type="text"
                  icon="el-icon-edit"
                  @click="handleUpdate(scope.row)"
                >修改</el-button>
                <el-button
                  v-hasPermi="['business:channel:edit']"
                  size="mini"
                  type="text"
                  icon="el-icon-delete"
                  @click="handleDelete(scope.row)"
                >删除</el-button>
              </template>
            </el-table-column>
          </el-table>

          <pagination
            v-show="total > 0"
            :total="total"
            :page.sync="assignQueryParams.pageNum"
            :limit.sync="assignQueryParams.pageSize"
            @pagination="getAssignList"
          />
        </div>
      </el-col>
    </el-row>

    <el-dialog
      :title="dialogTitle"
      :visible.sync="open"
      width="520px"
      custom-class="ch-assign-dlg"
      append-to-body
      @close="cancelForm"
    >
      <el-form ref="form" :model="form" :rules="rules" label-width="100px" size="small" class="ch-assign-form">
        <el-form-item label="用户" prop="userId">
          <el-select
            v-model="form.userId"
            filterable
            placeholder="用户"
            style="width: 100%"
            :disabled="isUserLockedInForm"
          >
            <el-option v-for="u in userOptions" :key="u.userId" :label="formatUserLabel(u)" :value="u.userId" />
          </el-select>
        </el-form-item>
        <el-form-item label="通道" prop="channelId">
          <el-select v-model="form.channelId" filterable placeholder="通道" style="width: 100%" :disabled="form.id != null">
            <el-option v-for="c in channelOptions" :key="c.id" :label="c.channelName" :value="c.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="单价" prop="price">
          <el-input-number v-model="form.price" :min="0" :precision="4" :step="0.0001" style="width: 100%" controls-position="right" />
        </el-form-item>
        <el-form-item label="分配条数" prop="allotCount">
          <el-input-number v-model="form.allotCount" :min="0" :step="1" style="width: 100%" controls-position="right" />
        </el-form-item>
        <el-form-item label="发送成功率">
          <div class="ch-rate-row">
            <el-input-number
              v-model="form.successRateMin"
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
              v-model="form.successRateMax"
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
        <el-form-item v-if="form.id" label="已用条数">
          <span>{{ form.usedCount != null ? form.usedCount : 0 }}</span>
        </el-form-item>
        <el-form-item label="状态" prop="enabled">
          <el-radio-group v-model="form.enabled">
            <el-radio label="1">启用</el-radio>
            <el-radio label="0">停用</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="form.remark" type="textarea" :rows="2" placeholder="选填" maxlength="500" show-word-limit />
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button type="primary" @click="submitForm">确 定</el-button>
        <el-button @click="open = false">取 消</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import {
  listUserChannel,
  getUserChannel,
  addUserChannel,
  updateUserChannel,
  delUserChannel
} from '@/api/business/channelAssign'
import { channelList } from '@/api/business/channel'
import { listUser, getUser } from '@/api/system/user'

export default {
  name: 'ChannelAssign',
  data() {
    return {
      userList: [],
      userTotal: 0,
      userLoading: false,
      userQueryParams: {
        pageNum: 1,
        pageSize: 10,
        userName: undefined,
        status: undefined
      },
      /** 从「新户-前往线路」等入口预选的 userId，首屏拉列表后高亮/补全 */
      pendingSelectUserId: null,

      selectedUserId: null,
      selectedUser: null,

      loading: false,
      list: [],
      total: 0,
      assignQueryParams: {
        pageNum: 1,
        pageSize: 10,
        userId: undefined,
        channelId: undefined
      },
      channelOptions: [],
      userOptions: [],
      open: false,
      dialogTitle: '',
      form: {},
      rules: {
        userId: [{ required: true, message: '请选择用户', trigger: 'change' }],
        channelId: [{ required: true, message: '请选择通道', trigger: 'change' }]
      }
    }
  },
  computed: {
    rightTitleName() {
      if (!this.selectedUser) return ''
      return this.selectedUser.userName || ''
    },
    isUserLockedInForm() {
      return this.form.id != null || (this.form.userId && !this.form.id)
    }
  },
  created() {
    const uid = this.$route.query.userId
    if (uid !== undefined && uid !== null && uid !== '') {
      this.pendingSelectUserId = Number(uid)
    }
    this.loadChannelOptions()
    this.loadUserOptions()
    this.getUserList()
  },
  methods: {
    caTableHeaderStyle() {
      return {
        background: '#f5f7fa',
        color: '#303133',
        fontWeight: '600',
        fontSize: '13px',
        padding: '10px 0',
        borderColor: '#ebeef5'
      }
    },
    formatUserLabel(u) {
      return u.userName || ''
    },
    loadChannelOptions() {
      channelList({ pageNum: 1, pageSize: 500 }).then(res => {
        this.channelOptions = res.rows || []
      }).catch(() => {})
    },
    loadUserOptions() {
      listUser({ pageNum: 1, pageSize: 500, status: '0' }).then(res => {
        this.userOptions = res.rows || []
      }).catch(() => {})
    },
    getUserList() {
      this.userLoading = true
      listUser(this.userQueryParams)
        .then(res => {
          this.userList = res.rows || []
          this.userTotal = res.total || 0
          this.userLoading = false
          this.finishPendingUserSelect()
        })
        .catch(() => {
          this.userLoading = false
        })
    },
    /** 路由带 userId 时：在列表中选中，若不在本页则拉详情补全 */
    finishPendingUserSelect() {
      if (this.pendingSelectUserId) {
        const id = this.pendingSelectUserId
        this.pendingSelectUserId = null
        const u = this.userList.find(x => x.userId === id)
        if (u) {
          this.selectUser(u)
        } else {
          getUser(id)
            .then(r => {
              const d = r.data
              if (d) {
                this.selectUser(d)
              }
            })
            .catch(() => {})
        }
        return
      }
      if (this.userList.length) {
        const exists = this.selectedUserId && this.userList.some(u => u.userId === this.selectedUserId)
        if (!exists && this.selectedUserId) {
          return
        }
        if (!this.selectedUserId) {
          this.selectUser(this.userList[0])
        }
      } else {
        this.selectedUserId = null
        this.selectedUser = null
        this.list = []
        this.total = 0
      }
    },
    handleUserQuery() {
      this.userQueryParams.pageNum = 1
      this.getUserList()
    },
    selectUser(row) {
      if (!row || !row.userId) return
      this.selectedUserId = row.userId
      this.selectedUser = { ...row }
      this.assignQueryParams.pageNum = 1
      this.getAssignList()
    },
    handleAssignQuery() {
      this.assignQueryParams.pageNum = 1
      this.getAssignList()
    },
    getAssignList() {
      if (!this.selectedUserId) {
        this.list = []
        this.total = 0
        return
      }
      this.loading = true
      const q = {
        ...this.assignQueryParams,
        userId: this.selectedUserId
      }
      if (q.channelId == null || q.channelId === '') {
        delete q.channelId
      }
      listUserChannel(q)
        .then(r => {
          this.list = r.rows || []
          this.total = r.total || 0
          this.loading = false
        })
        .catch(() => {
          this.loading = false
        })
    },
    handleAdd() {
      if (!this.selectedUserId) {
        this.$message.warning('请先在左侧选择用户')
        return
      }
      this.resetFormModel()
      this.form.userId = this.selectedUserId
      this.dialogTitle = '新增线路分配'
      this.open = true
      this.$nextTick(() => {
        this.$refs.form && this.$refs.form.clearValidate()
      })
    },
    resetFormModel() {
      this.form = {
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
    cancelForm() {
      this.resetFormModel()
    },
    handleUpdate(row) {
      this.resetFormModel()
      getUserChannel(row.id).then(res => {
        const d = res.data || row
        this.form = {
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
        this.dialogTitle = '修改线路分配'
        this.open = true
        this.$nextTick(() => {
          this.$refs.form && this.$refs.form.clearValidate()
        })
      }).catch(() => {})
    },
    submitForm() {
      this.$refs.form.validate(valid => {
        if (!valid) return
        const a = this.form.successRateMin
        const b = this.form.successRateMax
        if ((a == null) !== (b == null)) {
          this.$message.warning('发送成功率需同时留空，或同时填写下限与上限')
          return
        }
        if (a != null && b != null && a > b) {
          this.$message.warning('成功率下限不能大于上限')
          return
        }
        const payload = {
          id: this.form.id,
          userId: this.form.userId,
          channelId: this.form.channelId,
          price: this.form.price,
          allotCount: this.form.allotCount,
          enabled: this.form.enabled,
          remark: this.form.remark,
          successRateMin: a,
          successRateMax: b
        }
        if (this.form.id) {
          updateUserChannel(payload).then(() => {
            this.$modal.msgSuccess('修改成功')
            this.open = false
            this.getAssignList()
          })
        } else {
          addUserChannel(payload).then(() => {
            this.$modal.msgSuccess('新增成功')
            this.open = false
            this.getAssignList()
          })
        }
      })
    },
    handleDelete(row) {
      this.$modal.confirm('是否确认删除该线路分配？').then(() => {
        return delUserChannel(row.id)
      }).then(() => {
        this.$modal.msgSuccess('删除成功')
        this.getAssignList()
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
/* 布局与新户管理「nu」一致 */
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

.nu-card--empty {
  min-height: 400px;
}

.nu-card-left {
  padding-bottom: 10px;
}

.nu-left-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
  padding-bottom: 4px;
  border-bottom: 1px solid #f0f2f5;
}

.nu-left-title-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
}

.ca-head-ico {
  font-size: 18px;
  color: #1890ff;
}

.ca-left-refresh {
  padding: 6px 10px;
  border-radius: 4px;
  color: #606266;
}
.ca-left-refresh:hover {
  color: #1890ff;
  background: rgba(24, 144, 255, 0.08);
}

.nu-left-title {
  font-size: 16px;
  font-weight: 600;
  color: #1f1f1f;
  letter-spacing: 0.2px;
}

.nu-left-filters {
  display: flex;
  gap: 8px;
  margin-bottom: 12px;
}

.nu-left-filters .el-input {
  flex: 1;
}

.nu-status-select {
  width: 96px;
  flex-shrink: 0;
}

.nu-list-scroll {
  flex: 1;
  min-height: 200px;
}

.nu-list-inner {
  padding-right: 4px;
}

.nu-list-item {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 12px 12px 12px 14px;
  margin-bottom: 8px;
  border-radius: 8px;
  border: 1px solid #eef0f3;
  cursor: pointer;
  transition: background 0.18s, border-color 0.18s, box-shadow 0.18s;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.03);
}

.nu-list-item:hover {
  background: #f8fbff;
  border-color: #d9e8ff;
  box-shadow: 0 2px 8px rgba(24, 144, 255, 0.08);
}

.nu-list-item.active {
  background: linear-gradient(90deg, #e6f4ff 0%, #f0f9ff 100%);
  border-color: #91caff;
  border-left: 3px solid #1890ff;
  padding-left: 11px;
  box-shadow: 0 2px 10px rgba(24, 144, 255, 0.12);
}

.nu-nick {
  font-size: 15px;
  font-weight: 600;
  color: rgba(0, 0, 0, 0.85);
  line-height: 1.4;
}

.nu-login {
  font-size: 12px;
  color: #8c8c8c;
  margin-top: 4px;
}

.nu-st.ok {
  color: #52c41a;
  font-size: 12px;
}

.nu-st.off {
  color: #ff4d4f;
  font-size: 12px;
}

.nu-left-pager {
  padding-top: 12px;
  text-align: center;
  border-top: 1px solid #f0f0f0;
  margin-top: 8px;
}

.nu-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 400px;
}

.ca-empty >>> .el-empty__description {
  margin-top: 8px;
  color: #909399;
  font-size: 14px;
}

.nu-detail-card {
  padding-top: 12px;
}

.ca-toolbar {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px 12px;
  justify-content: flex-end;
  flex: 1;
  min-width: 200px;
}

.ca-filter-channel {
  min-width: 180px;
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
  flex-shrink: 0;
}

.ca-detail-ico {
  color: #1890ff;
  font-size: 18px;
}

.nu-detail-actions .el-button + .el-button {
  margin-left: 8px;
}

.ca-assign-table {
  width: 100%;
  border-radius: 8px;
  overflow: hidden;
}
.ca-assign-table >>> .el-table__header-wrapper th {
  font-weight: 600;
}
.ca-assign-table >>> .el-table--striped .el-table__body tr.el-table__row--striped td {
  background: #fafbfc;
}
.ca-assign-table >>> .el-table__body tr:hover > td {
  background: #f5f9ff !important;
}
.ca-btn-refresh {
  color: #606266;
  border-color: #dcdfe6;
}
.ca-btn-refresh:hover {
  color: #1890ff;
  border-color: #b3d8ff;
  background: #ecf5ff;
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
</style>
