<template>
  <div class="app-container">
    <el-card shadow="never">
      <div slot="header" class="clearfix">
        <span>智能路由</span>
        <el-button style="float:right;" type="primary" size="mini" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        <el-button
          style="float:right;margin-right:8px;"
          type="primary"
          size="mini"
          plain
          icon="el-icon-folder-add"
          v-hasPermi="['business:channel:edit']"
          @click="openAddGroup"
        >新增分组</el-button>
        <el-button style="float:right;margin-right:8px;" type="success" size="mini" icon="el-icon-plus" @click="openInitDialog">初始化通道</el-button>
      </div>

      <div v-loading="loading" class="router-body">
        <el-empty v-if="!loading && (!list || list.length === 0)" description="暂无数据" />
        <div
          v-for="group in groupedList"
          :key="group.key"
          class="country-group"
        >
          <div class="country-group__bar">
            <div class="country-group__left">
              <i class="el-icon-location-outline country-group__icon" />
              <div class="country-group__name-block">
                <span class="country-group__name-key">组名</span>
                <span
                  :class="['country-group__name-value', { 'country-group__name-value--editable': canEditChannel }]"
                  :title="canEditChannel ? '点击修改组名' : ''"
                  @click="onGroupTitleClick(group)"
                >{{ group.nameText }}</span>
              </div>
              <el-tag size="mini" type="info">{{ group.rows.length }} 条</el-tag>
            </div>
            <div class="country-group__actions">
              <el-button
                type="primary"
                plain
                size="mini"
                icon="el-icon-edit"
                v-hasPermi="['business:channel:edit']"
                :disabled="group.rows.length === 0"
                @click="openEditGroup(group)"
              >编辑分组</el-button>
              <el-button
                type="danger"
                plain
                size="mini"
                icon="el-icon-delete"
                v-hasPermi="['business:channel:edit']"
                :disabled="group.rows.length === 0"
                @click="deleteGroup(group)"
              >删除分组</el-button>
              <el-button
                type="warning"
                plain
                size="mini"
                icon="el-icon-refresh-right"
                :disabled="!groupHasTripped(group)"
                @click="resetBreakerGroup(group)"
              >重置本组熔断</el-button>
              <el-button
                type="info"
                plain
                size="mini"
                icon="el-icon-delete"
                :disabled="group.rows.length === 0"
                @click="resetWindowGroup(group)"
              >清空本组统计</el-button>
            </div>
          </div>
          <el-table :data="group.rows" border stripe size="small" class="country-group__table">
            <el-table-column label="通道名称" prop="channelName" min-width="140" />
            <el-table-column label="通道状态" align="center" width="90">
              <template slot-scope="scope">
                <el-tag :type="scope.row.channelStatus == 0 ? 'success' : 'danger'" size="mini">
                  {{ scope.row.channelStatus == 0 ? '启用' : '禁用' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="熔断状态" align="center" width="100">
              <template slot-scope="scope">
                <el-tag :type="circuitTagType(scope.row.circuitState)" size="small">
                  {{ circuitLabel(scope.row.circuitState) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="权重" align="center" width="80" prop="weight" />
            <el-table-column label="优先级" align="center" width="80" prop="priority" />
            <el-table-column label="成功/失败/总计" align="center" min-width="130">
              <template slot-scope="scope">
                <span style="color:#67c23a">{{ scope.row.successCount }}</span>
                /
                <span style="color:#f56c6c">{{ scope.row.failCount }}</span>
                /
                <span>{{ scope.row.totalCount }}</span>
              </template>
            </el-table-column>
            <el-table-column label="成功率" align="center" width="90">
              <template slot-scope="scope">
                <span :style="{ color: rateColor(scope.row.successRate) }">
                  {{ scope.row.successRate != null ? scope.row.successRate + '%' : '--' }}
                </span>
              </template>
            </el-table-column>
            <el-table-column label="平均响应(ms)" align="center" width="120" prop="avgResponseMs" />
            <el-table-column label="窗口起始" align="center" width="160" prop="windowStart" />
            <el-table-column label="熔断时间" align="center" width="160" prop="circuitOpenTime" />
            <el-table-column label="操作" align="center" min-width="240" fixed="right">
              <template slot-scope="scope">
                <el-button type="text" size="mini" icon="el-icon-edit" @click="openEdit(scope.row)">配置</el-button>
                <el-button
                  type="text"
                  size="mini"
                  style="color:#67c23a"
                  icon="el-icon-refresh-right"
                  :disabled="scope.row.circuitState === '0'"
                  @click="resetBreaker(scope.row)"
                >重置熔断</el-button>
                <el-button type="text" size="mini" style="color:#909399" @click="resetWindow(scope.row)">清空统计</el-button>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </div>
    </el-card>

    <el-dialog title="配置路由参数" :visible.sync="editDialog" width="400px" append-to-body>
      <el-form :model="editForm" label-width="80px" size="small">
        <el-form-item label="通道名称">
          <span>{{ editForm.channelName }}</span>
        </el-form-item>
        <el-form-item v-if="editForm.country" label="国家/地区">
          <span>{{ editForm.country }}</span>
        </el-form-item>
        <el-form-item label="权重">
          <el-input-number v-model="editForm.weight" :min="0" :max="100" style="width:160px" />
        </el-form-item>
        <el-form-item label="优先级">
          <el-input-number v-model="editForm.priority" :min="0" :max="100" style="width:160px" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="editDialog = false">取消</el-button>
        <el-button type="primary" @click="submitEdit">保存</el-button>
      </div>
    </el-dialog>

    <el-dialog title="新增分组" :visible.sync="addGroupDialog" width="480px" append-to-body>
      <p class="group-dialog__hint">选择通道并填写「组名」后，这些通道会聚合成一组。组名会写入通道的「国家/地区」字段（与路由/展示一致），可从其它分组迁入通道（会覆盖原国别）。</p>
      <el-form :model="addGroupForm" label-width="100px" size="small">
        <el-form-item label="组名" required>
          <el-input v-model="addGroupForm.country" placeholder="显示在组名后，如：巴西、美东" clearable maxlength="64" show-word-limit />
        </el-form-item>
        <el-form-item label="纳入通道" required>
          <el-select
            v-model="addGroupForm.channelIds"
            multiple
            filterable
            clearable
            placeholder="多选通道"
            style="width:100%"
            :loading="allChannelsLoading"
          >
            <el-option
              v-for="c in allChannelOptions"
              :key="c.id"
              :label="channelOptionLabel(c)"
              :value="c.id"
            />
          </el-select>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="addGroupDialog = false">取 消</el-button>
        <el-button type="primary" :disabled="!addGroupForm.channelIds.length" @click="submitAddGroup">保 存</el-button>
      </div>
    </el-dialog>

    <el-dialog title="修改组名" :visible.sync="editGroupDialog" width="440px" append-to-body>
      <p v-if="editTargetGroup" class="group-dialog__hint">
        当前组名：<strong>{{ editTargetGroup.nameText }}</strong>，本组 <strong>{{ editTargetGroup.rows.length }}</strong> 条通道。
        修改后的组名会显示在上方「组名」后，并同步到各通道的「国家/地区」（用于路由国别匹配）；若与已有组名相同，将自动合并到该组。
      </p>
      <el-form label-width="100px" size="small">
        <el-form-item label="组名" required>
          <el-input
            v-model="editGroupName"
            :placeholder="editNamePlaceholder"
            clearable
            maxlength="64"
            show-word-limit
          />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="editGroupDialog = false">取 消</el-button>
        <el-button type="primary" @click="submitEditGroup">保 存</el-button>
      </div>
    </el-dialog>

    <el-dialog title="初始化通道路由记录" :visible.sync="initDialog" width="360px" append-to-body>
      <el-form size="small" label-width="80px">
        <el-form-item label="选择通道">
          <el-select v-model="initChannelId" placeholder="通道" style="width:200px">
            <el-option
              v-for="c in uninitList"
              :key="c.id"
              :label="c.country ? (c.channelName + ' (' + c.country + ')') : c.channelName"
              :value="c.id"
            />
          </el-select>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="initDialog = false">取消</el-button>
        <el-button type="primary" :disabled="!initChannelId" @click="submitInit">初始化</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import request from '@/utils/request'
import { listChannel } from '@/api/business/channel'
import { updateChannelGroupCountry } from '@/api/business/channelRouter'
import { checkPermi } from '@/utils/permission'

export default {
  name: 'ChannelRouter',
  data() {
    return {
      loading: false,
      list: [],
      editDialog: false,
      editForm: { channelId: null, channelName: '', country: '', weight: 100, priority: 0 },
      initDialog: false,
      initChannelId: null,
      uninitList: [],
      addGroupDialog: false,
      addGroupForm: { country: '', channelIds: [] },
      allChannelOptions: [],
      allChannelsLoading: false,
      editGroupDialog: false,
      editGroupName: '',
      editTargetGroup: null
    }
  },
  computed: {
    canEditChannel() {
      return checkPermi(['business:channel:edit'])
    },
    /** 未设置时提示输入新组名 */
    editNamePlaceholder() {
      if (!this.editTargetGroup) return '输入新组名'
      return this.editTargetGroup.key === '__EMPTY__'
        ? '例如：巴西、美东-01（将写入本组各通道的「国家/地区」）'
        : '输入新组名'
    },
    groupedList() {
      const raw = this.list || []
      const map = new Map()
      for (const row of raw) {
        const co = row.country != null ? String(row.country).trim() : ''
        const key = co ? co : '__EMPTY__'
        if (!map.has(key)) {
          map.set(key, [])
        }
        map.get(key).push(row)
      }
      const keys = Array.from(map.keys())
      keys.sort((a, b) => {
        if (a === '__EMPTY__') return 1
        if (b === '__EMPTY__') return -1
        return a.localeCompare(b, 'zh-CN')
      })
      return keys.map(k => ({
        key: k,
        /** 组名展示：未设国别时显示「未设置」 */
        nameText: k === '__EMPTY__' ? '未设置' : k,
        rows: map.get(k)
      }))
    }
  },
  created() {
    this.loadList()
  },
  methods: {
    groupHasTripped(group) {
      return group.rows.some(r => r.circuitState != null && r.circuitState !== '0')
    },
    loadList() {
      this.loading = true
      request({ url: '/business/channelRouter/list', method: 'get' }).then(res => {
        this.list = res.data || []
        this.loading = false
      }).catch(() => { this.loading = false })
    },
    circuitLabel(state) {
      if (state === '0') return '正常'
      if (state === '1') return '已熔断'
      if (state === '2') return '半开'
      return '--'
    },
    circuitTagType(state) {
      if (state === '0') return 'success'
      if (state === '1') return 'danger'
      if (state === '2') return 'warning'
      return 'info'
    },
    rateColor(rate) {
      if (rate == null) return '#606266'
      if (rate >= 90) return '#67c23a'
      if (rate >= 70) return '#e6a23c'
      return '#f56c6c'
    },
    openEdit(row) {
      this.editForm = {
        channelId: row.channelId,
        channelName: row.channelName,
        country: row.country || '',
        weight: row.weight || 100,
        priority: row.priority || 0
      }
      this.editDialog = true
    },
    submitEdit() {
      request({
        url: '/business/channelRouter/weight/' + this.editForm.channelId,
        method: 'put',
        params: { weight: this.editForm.weight, priority: this.editForm.priority }
      }).then(res => {
        this.$message.success(res.msg || '已保存')
        this.editDialog = false
        this.loadList()
      })
    },
    resetBreaker(row) {
      this.$confirm('确认重置通道 [' + row.channelName + '] 的熔断器？重置后通道将恢复正常路由。', '确认', { type: 'warning' }).then(() => {
        request({ url: '/business/channelRouter/reset/' + row.channelId, method: 'put' }).then(res => {
          this.$message.success(res.msg || '已重置')
          this.loadList()
        })
      }).catch(() => {})
    },
    resetBreakerGroup(group) {
      const need = group.rows.filter(r => r.circuitState != null && r.circuitState !== '0')
      if (need.length === 0) {
        this.$message.info('本组无熔断/半开中的通道')
        return
      }
      const names = need.map(r => r.channelName).join('、')
      this.$confirm(
        '将对组名「' + group.nameText + '」下 ' + need.length + ' 个通道重置熔断：' + names + '。是否继续？',
        '重置本组熔断',
        { type: 'warning' }
      ).then(() => {
        const run = () => {
          let i = 0
          const next = () => {
            if (i >= need.length) {
              this.$message.success('本组熔断已处理完成')
              this.loadList()
              return
            }
            const r = need[i++]
            request({ url: '/business/channelRouter/reset/' + r.channelId, method: 'put' }).then(() => {
              next()
            }).catch(() => {
              next()
            })
          }
          next()
        }
        run()
      }).catch(() => {})
    },
    resetWindow(row) {
      this.$confirm('确认清空通道 [' + row.channelName + '] 的统计数据（成功/失败计数归零）？', '确认', { type: 'warning' }).then(() => {
        request({ url: '/business/channelRouter/resetWindow/' + row.channelId, method: 'put' }).then(res => {
          this.$message.success(res.msg || '已清空')
          this.loadList()
        })
      }).catch(() => {})
    },
    resetWindowGroup(group) {
      if (group.rows.length === 0) return
      this.$confirm(
        '将清空组名「' + group.nameText + '」下全部 ' + group.rows.length + ' 个通道的统计窗口（成功/失败计数归零）。是否继续？',
        '清空本组统计',
        { type: 'warning' }
      ).then(() => {
        let i = 0
        const next = () => {
          if (i >= group.rows.length) {
            this.$message.success('本组统计已清空')
            this.loadList()
            return
          }
          const r = group.rows[i++]
          request({ url: '/business/channelRouter/resetWindow/' + r.channelId, method: 'put' }).then(() => {
            next()
          }).catch(() => {
            next()
          })
        }
        next()
      }).catch(() => {})
    },
    openInitDialog() {
      this.initChannelId = null
      request({ url: '/business/channelRouter/uninit', method: 'get' }).then(res => {
        this.uninitList = res.data || []
        if (this.uninitList.length === 0) {
          this.$message.info('所有通道已在路由池中')
          return
        }
        this.initDialog = true
      })
    },
    submitInit() {
      request({ url: '/business/channelRouter/init/' + this.initChannelId, method: 'post' }).then(res => {
        this.$message.success(res.msg || '已初始化')
        this.initDialog = false
        this.loadList()
      })
    },
    openAddGroup() {
      this.addGroupForm = { country: '', channelIds: [] }
      this.allChannelsLoading = true
      listChannel({ pageNum: 1, pageSize: 999 })
        .then(res => {
          this.allChannelOptions = (res.rows || []).filter(c => c && c.id)
          this.addGroupDialog = true
        })
        .catch(() => {
          this.allChannelOptions = []
        })
        .finally(() => {
          this.allChannelsLoading = false
        })
    },
    channelOptionLabel(c) {
      const n = c.channelName || '—'
      const r = c.country && String(c.country).trim() ? c.country : '未设国别'
      return `${n}（${r}）`
    },
    submitAddGroup() {
      const t = (this.addGroupForm.country || '').trim()
      if (!t) {
        this.$message.warning('请填写组名')
        return
      }
      if (!this.addGroupForm.channelIds || this.addGroupForm.channelIds.length === 0) {
        this.$message.warning('请至少选择一个通道')
        return
      }
      updateChannelGroupCountry({ country: t, channelIds: this.addGroupForm.channelIds })
        .then(res => {
          this.$message.success(res.msg || '已保存')
          this.addGroupDialog = false
          this.loadList()
        })
        .catch(() => {})
    },
    onGroupTitleClick(group) {
      if (!this.canEditChannel) return
      this.openEditGroup(group)
    },
    openEditGroup(group) {
      this.editTargetGroup = group
      this.editGroupName = group.key === '__EMPTY__' ? '' : group.nameText
      this.editGroupDialog = true
    },
    submitEditGroup() {
      const t = (this.editGroupName || '').trim()
      if (!t) {
        this.$message.warning('请填写组名')
        return
      }
      if (!this.editTargetGroup || !this.editTargetGroup.rows.length) {
        return
      }
      const channelIds = this.editTargetGroup.rows.map(r => r.channelId)
      updateChannelGroupCountry({ country: t, channelIds })
        .then(res => {
          this.$message.success(res.msg || '已保存')
          this.editGroupDialog = false
          this.editTargetGroup = null
          this.loadList()
        })
        .catch(() => {})
    },
    deleteGroup(group) {
      if (!group || !group.rows.length) {
        return
      }
      this.$confirm(
        '将组名「' + group.nameText + '」下 ' + group.rows.length + ' 个通道的组名数据（国家/地区）清空，归入未设置。不删除通道本身。是否继续？',
        '删除分组',
        { type: 'warning' }
      )
        .then(() => {
          const channelIds = group.rows.map(r => r.channelId)
          return updateChannelGroupCountry({ clear: true, channelIds })
        })
        .then(res => {
          this.$message.success(res.msg || '已清空国别')
          this.loadList()
        })
        .catch(() => {})
    }
  }
}
</script>

<style scoped>
.router-body {
  min-height: 120px;
}

.country-group {
  margin-bottom: 24px;
}

.country-group:last-child {
  margin-bottom: 0;
}

.country-group__bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 10px;
  padding: 10px 12px;
  margin-bottom: 8px;
  background: linear-gradient(90deg, #f0f4ff 0%, #fafafa 100%);
  border: 1px solid #e4e7ed;
  border-radius: 6px;
}

.country-group__left {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.country-group__icon {
  color: #4361ee;
  font-size: 16px;
}

.country-group__name-block {
  display: inline-flex;
  align-items: baseline;
  gap: 8px;
  flex-wrap: wrap;
}

.country-group__name-key {
  font-size: 12px;
  font-weight: 500;
  color: #909399;
  letter-spacing: 0.02em;
}

.country-group__name-value {
  font-weight: 600;
  color: #303133;
  font-size: 15px;
}

.country-group__name-value--editable {
  cursor: pointer;
  border-bottom: 1px dashed transparent;
  transition: color 0.15s, border-color 0.15s;
}

.country-group__name-value--editable:hover {
  color: #409eff;
  border-bottom-color: #a0cfff;
}

.country-group__actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.country-group__table {
  width: 100%;
}

.group-dialog__hint {
  margin: 0 0 12px;
  font-size: 12px;
  line-height: 1.5;
  color: #606266;
}
</style>
