<template>
  <div class="app-container">
    <el-form :model="queryParams" ref="queryForm" :inline="true" v-show="showSearch" size="small">
      <el-form-item :label="ui.systemId" prop="systemId">
        <el-input v-model="queryParams.systemId" :placeholder="ui.phSystemId" clearable @keyup.enter.native="handleQuery"/>
      </el-form-item>
      <el-form-item :label="ui.status" prop="status">
        <el-select v-model="queryParams.status" :placeholder="ui.all" clearable>
          <el-option :label="ui.on" value="0"/>
          <el-option :label="ui.off" value="1"/>
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="el-icon-search" size="mini" @click="handleQuery">{{ ui.search }}</el-button>
        <el-button icon="el-icon-refresh" size="mini" @click="resetQuery">{{ ui.reset }}</el-button>
      </el-form-item>
    </el-form>

    <div class="mb8 smpp-toolbar">
      <el-button type="primary" plain icon="el-icon-plus" size="mini" @click="handleAdd" v-hasPermi="['business:smppAccount:add']">{{ ui.add }}</el-button>
      <el-button type="danger" plain icon="el-icon-delete" size="mini" :disabled="multiple" @click="handleDelete" v-hasPermi="['business:smppAccount:remove']">{{ ui.del }}</el-button>
      <right-toolbar :showSearch.sync="showSearch" @queryTable="getList" class="smpp-toolbar__right" />
    </div>

    <el-table v-loading="loading" :data="accountList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="55" align="center"/>
      <el-table-column label="ID" prop="id" width="60" align="center"/>
      <el-table-column :label="ui.user" prop="userName" width="100" align="center"/>
      <el-table-column :label="ui.systemId" prop="systemId" min-width="120" :show-overflow-tooltip="true"/>
      <el-table-column :label="ui.pwd" min-width="120" align="center">
        <template slot-scope="scope">
          <span>******</span>
        </template>
      </el-table-column>
      <el-table-column :label="ui.rate" prop="rateLimit" width="110" align="center"/>
      <el-table-column :label="ui.salePrice" width="120" align="center" show-overflow-tooltip>
        <template slot-scope="scope">
          <span>{{ formatSalePriceCol(scope.row.salePrice) }}</span>
        </template>
      </el-table-column>
      <el-table-column :label="ui.channel" prop="channelName" min-width="120" :show-overflow-tooltip="true"/>
      <el-table-column :label="ui.status" width="80" align="center">
        <template slot-scope="scope">
          <el-tag :type="scope.row.status === '0' ? 'success' : 'danger'" size="small">
            {{ scope.row.status === '0' ? ui.on : ui.off }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column :label="ui.createTime" prop="createTime" width="160" align="center"/>
      <el-table-column :label="ui.actions" width="240" align="center">
        <template slot-scope="scope">
          <el-button size="mini" type="text" icon="el-icon-edit" @click="handleUpdate(scope.row)" v-hasPermi="['business:smppAccount:edit']">{{ ui.edit }}</el-button>
          <el-button size="mini" type="text" icon="el-icon-delete" @click="handleDelete(scope.row)" v-hasPermi="['business:smppAccount:remove']">{{ ui.del }}</el-button>
          <tech-assist-button
            page-code="smpp"
            page-label="SMPP外放"
            :ref-id="scope.row.id"
            :ref-summary="refSummaryForAssist(scope.row)"
          />
        </template>
      </el-table-column>
    </el-table>
    <pagination v-show="total > 0" :total="total" :page.sync="queryParams.pageNum" :limit.sync="queryParams.pageSize" @pagination="getList"/>

    <el-dialog :title="dialogTitle" :visible.sync="dialogVisible" width="560px" append-to-body @close="dialogClose">
      <el-form ref="smppForm" :model="form" :rules="rules" label-width="120px">
        <el-form-item :label="ui.userId" prop="userId">
          <el-input-number v-model="form.userId" :min="1" :placeholder="ui.phUserId" @change="onUserIdChangeInDialog"/>
        </el-form-item>
        <el-form-item :label="ui.systemId" prop="systemId">
          <el-input v-model="form.systemId" :placeholder="ui.phSysUnique"/>
        </el-form-item>
        <el-form-item :label="ui.pwd" prop="password">
          <el-input v-model="form.password" show-password :placeholder="form.id ? ui.phPwdKeep : ui.phPwdBind"/>
        </el-form-item>
        <el-form-item :label="ui.rate" prop="rateLimit">
          <el-input-number v-model="form.rateLimit" :min="0" :max="100000"/>
        </el-form-item>
        <el-form-item :label="ui.salePrice" prop="salePrice">
          <el-input-number
            v-model="form.salePrice"
            :precision="4"
            :min="0"
            :max="1000000"
            :step="0.0001"
            controls-position="right"
            style="width:100%"
            :placeholder="ui.phSalePrice"
          />
        </el-form-item>
        <el-form-item :label="ui.defChannel" prop="channelId">
          <el-select v-model="form.channelId" :placeholder="ui.phChannel" clearable filterable style="width:100%">
            <el-option
              v-for="c in channelList"
              :key="'ch-'+c.id"
              :label="(c && c.channelName) ? c.channelName : ('#' + c.id)"
              :value="c.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item :label="ui.status" prop="status">
          <el-radio-group v-model="form.status">
            <el-radio label="0">{{ ui.on }}</el-radio>
            <el-radio label="1">{{ ui.off }}</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item :label="ui.remark" prop="remark">
          <el-input v-model="form.remark" type="textarea" :rows="2" :placeholder="ui.phRemark"/>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button type="primary" @click="submitForm">{{ ui.ok }}</el-button>
        <el-button @click="dialogVisible = false">{{ ui.cancel }}</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { listSmppAccount, getSmppAccount, addSmppAccount, updateSmppAccount, delSmppAccount } from '@/api/business/smppAccount'
import { channelsForUser } from '@/api/business/channelAssign'
import TechAssistButton from '@/components/TechAssistButton'

function zh() {
  return {
    systemId: '\u7cfb\u7edfID',
    phSystemId: '\u7cfb\u7edfId',
    status: '\u72b6\u6001',
    all: '\u5168\u90e8',
    on: '\u542f\u7528',
    off: '\u505c\u7528',
    search: '\u641c\u7d22',
    reset: '\u91cd\u7f6e',
    add: '\u65b0\u589e',
    del: '\u5220\u9664',
    user: '\u7528\u6237',
    pwd: '\u5bc6\u7801',
    rate: '\u901f\u7387(\u6761/\u5206)',
    salePrice: '\u552e\u4ef7(\u5143/\u6761)',
    phSalePrice: '\u9009\u586b\uff0c\u4e0d\u586b\u8868\u793a\u672a\u8bbe',
    channel: '\u901a\u9053',
    createTime: '\u521b\u5efa\u65f6\u95f4',
    actions: '\u64cd\u4f5c',
    edit: '\u4fee\u6539',
    userId: '\u7528\u6237ID',
    phUserId: '\u7528\u6237Id',
    phSysUnique: '\u552f\u4e00\u6807\u8bc6',
    phPwdKeep: '\u4e0d\u6539\u8bf7\u7a7a',
    phPwdBind: '\u5bc6\u7801',
    defChannel: '\u9ed8\u8ba4\u901a\u9053',
    phChannel: '\u901a\u9053',
    remark: '\u5907\u6ce8',
    phRemark: '\u5907\u6ce8',
    ok: '\u786e\u5b9a',
    cancel: '\u53d6\u6d88',
    titleAdd: '\u65b0\u589e SMPP \u63a5\u53e3\u5916\u653e',
    titleEdit: '\u4fee\u6539 SMPP \u63a5\u53e3\u5916\u653e',
    msgPwd: '\u8bf7\u8f93\u5165\u5bc6\u7801',
    msgUserId: '\u8bf7\u8f93\u5165\u7528\u6237ID',
    msgSystemId: '\u8bf7\u8f93\u5165\u7cfb\u7edfID',
    msgSaveOk: '\u4fdd\u5b58\u6210\u529f',
    msgAddOk: '\u65b0\u589e\u6210\u529f',
    msgDelConfirm: '\u662f\u5426\u786e\u8ba4\u5220\u9664\u9009\u4e2d\u7684 SMPP \u8d26\u53f7\uff1f',
    msgDelOk: '\u5220\u9664\u6210\u529f'
  }
}

export default {
  name: 'SmppAccountIndex',
  components: { TechAssistButton },
  data() {
    const ui = zh()
    return {
      ui,
      loading: false,
      showSearch: true,
      multiple: true,
      ids: [],
      total: 0,
      accountList: [],
      channelList: [],
      dialogTitle: '',
      dialogVisible: false,
      queryParams: {
        pageNum: 1,
        pageSize: 10,
        systemId: undefined,
        status: undefined
      },
      form: {
        id: undefined,
        userId: undefined,
        systemId: undefined,
        password: undefined,
        rateLimit: 100,
        salePrice: undefined,
        channelId: undefined,
        status: '0',
        remark: undefined
      },
      rules: {
        userId: [{ required: true, message: ui.msgUserId, trigger: 'blur' }],
        systemId: [{ required: true, message: ui.msgSystemId, trigger: 'blur' }],
        password: []
      }
    }
  },
  created() {
    this.getList()
  },
  watch: {
    dialogVisible(visible) {
      if (visible) {
        this.$nextTick(() => this.loadChannelsForUser())
      } else {
        this.channelList = []
      }
    }
  },
  methods: {
    formatSalePriceCol(v) {
      if (v == null || v === '') {
        return '—'
      }
      const n = Number(v)
      if (Number.isNaN(n)) {
        return '—'
      }
      return n.toFixed(4)
    },
    refSummaryForAssist(row) {
      const base = (row && row.systemId) || ''
      const ch = row && row.channelName ? ' / ' + row.channelName : ''
      return base + ch
    },
    onUserIdChangeInDialog() {
      this.loadChannelsForUser()
    },
    loadChannelsForUser() {
      const uid = this.form && this.form.userId
      if (uid == null || uid < 1) {
        this.channelList = []
        if (this.form) this.form.channelId = undefined
        return
      }
      channelsForUser(uid)
        .then(res => {
          const rows = res.data
          this.channelList = Array.isArray(rows) ? rows.filter(r => r && r.id != null) : []
          if (this.form && this.form.channelId != null) {
            const ok = this.channelList.some(c => c.id === this.form.channelId)
            if (!ok) {
              this.form.channelId = undefined
            }
          }
        })
        .catch(() => {
          this.channelList = []
        })
    },
    getList() {
      this.loading = true
      listSmppAccount(this.queryParams).then(response => {
        this.accountList = response.rows || []
        this.total = response.total || 0
      }).catch(() => {
        this.accountList = []
        this.total = 0
      }).finally(() => {
        this.loading = false
      })
    },
    handleQuery() {
      this.queryParams.pageNum = 1
      this.getList()
    },
    resetQuery() {
      this.resetForm('queryForm')
      this.handleQuery()
    },
    handleSelectionChange(selection) {
      this.ids = selection.map(item => item.id)
      this.multiple = !selection.length
    },
    initForm() {
      this.form = {
        id: undefined,
        userId: undefined,
        systemId: undefined,
        password: undefined,
        rateLimit: 100,
        salePrice: undefined,
        channelId: undefined,
        status: '0',
        remark: undefined
      }
    },
    dialogClose() {
      if (this.$refs.smppForm) {
        this.$refs.smppForm.resetFields()
      }
    },
    handleAdd() {
      this.initForm()
      this.channelList = []
      this.dialogTitle = this.ui.titleAdd
      this.dialogVisible = true
      this.rules.password = [{ required: true, message: this.ui.msgPwd, trigger: 'blur' }]
      this.$nextTick(() => {
        if (this.$refs.smppForm) this.$refs.smppForm.clearValidate()
        this.loadChannelsForUser()
      })
    },
    handleUpdate(row) {
      this.initForm()
      this.channelList = []
      const id = row.id || this.ids[0]
      getSmppAccount(id).then(response => {
        const d = response.data || {}
        this.form = { ...d, password: d.password || '' }
        this.dialogTitle = this.ui.titleEdit
        this.dialogVisible = true
        this.rules.password = []
        this.$nextTick(() => this.loadChannelsForUser())
      })
    },
    submitForm() {
      this.$refs.smppForm.validate(valid => {
        if (!valid) return
        const payload = { ...this.form }
        if (this.form.id && (!payload.password || payload.password === '')) {
          delete payload.password
        }
        if (this.form.id != null) {
          updateSmppAccount(payload).then(() => {
            this.$modal.msgSuccess(this.ui.msgSaveOk)
            this.dialogVisible = false
            this.getList()
          })
        } else {
          addSmppAccount(payload).then(() => {
            this.$modal.msgSuccess(this.ui.msgAddOk)
            this.dialogVisible = false
            this.getList()
          })
        }
      })
    },
    handleDelete(row) {
      const idList = row.id ? [row.id] : this.ids
      this.$modal.confirm(this.ui.msgDelConfirm).then(() => {
        return delSmppAccount(idList.join(','))
      }).then(() => {
        this.getList()
        this.$modal.msgSuccess(this.ui.msgDelOk)
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.smpp-toolbar {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
}
.smpp-toolbar__right {
  margin-left: auto;
}
</style>
