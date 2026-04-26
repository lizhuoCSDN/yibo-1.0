<template>
  <div class="app-container">
    <el-form :model="queryParams" ref="queryForm" :inline="true" size="small">
      <el-form-item label="AppId" prop="appId">
        <el-input v-model="queryParams.appId" placeholder="AppId" clearable style="width: 170px" @keyup.enter.native="handleQuery" />
      </el-form-item>
      <el-form-item label="应用名称" prop="appName">
        <el-input v-model="queryParams.appName" placeholder="名称" clearable style="width: 140px" @keyup.enter.native="handleQuery" />
      </el-form-item>
      <el-form-item label="用户ID" prop="userId">
        <el-input-number v-model="queryParams.userId" :min="1" :controls="false" placeholder="用户ID" clearable style="width: 120px" />
      </el-form-item>
      <el-form-item label="状态" prop="status">
        <el-select v-model="queryParams.status" placeholder="状态" clearable style="width: 100px">
          <el-option label="正常" value="0" />
          <el-option label="停用" value="1" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="el-icon-search" @click="handleQuery">搜索</el-button>
        <el-button icon="el-icon-refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5">
        <el-button type="primary" plain icon="el-icon-plus" size="mini" @click="handleAdd" v-hasPermi="['business:apikey:add']">新增密钥</el-button>
      </el-col>
    </el-row>

    <el-table v-loading="loading" :data="list" border size="small">
      <el-table-column label="ID" prop="id" width="68" align="center" />
      <el-table-column label="用户" prop="userName" min-width="100" show-overflow-tooltip />
      <el-table-column label="应用名称" prop="appName" min-width="120" show-overflow-tooltip />
      <el-table-column label="AppId" prop="appId" min-width="200" show-overflow-tooltip />
      <el-table-column label="限流(次/分)" prop="rateLimit" width="110" align="center" />
      <el-table-column label="售价(元/条)" width="120" align="center" show-overflow-tooltip>
        <template slot-scope="scope">
          <span>{{ formatSalePriceCol(scope.row.salePrice) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="状态" prop="status" width="80" align="center">
        <template slot-scope="scope">
          <el-tag :type="scope.row.status === '0' ? 'success' : 'danger'" size="mini">{{ scope.row.status === '0' ? '正常' : '停用' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="HTTP" prop="apiOpen" width="72" align="center">
        <template slot-scope="scope">
          <el-tag :type="scope.row.apiOpen === '1' ? 'success' : 'info'" size="mini">{{ scope.row.apiOpen === '1' ? '开' : '关' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="SMPP" prop="smppOpen" width="72" align="center">
        <template slot-scope="scope">
          <el-tag :type="scope.row.smppOpen === '1' ? 'success' : 'info'" size="mini">{{ scope.row.smppOpen === '1' ? '开' : '关' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="IP 白名单" prop="whitelistIps" min-width="140" show-overflow-tooltip />
      <el-table-column label="创建时间" prop="createTime" width="160" align="center">
        <template slot-scope="scope">
          <span>{{ parseTime(scope.row.createTime) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="220" align="center" fixed="right" class-name="small-padding fixed-width">
        <template slot-scope="scope">
          <el-button size="mini" type="text" icon="el-icon-view" @click="handleViewSecret(scope.row)" v-hasPermi="['business:apikey:query']">密钥</el-button>
          <el-button size="mini" type="text" icon="el-icon-edit" @click="handleUpdate(scope.row)" v-hasPermi="['business:apikey:edit']">修改</el-button>
          <el-button size="mini" type="text" icon="el-icon-delete" @click="handleDelete(scope.row)" v-hasPermi="['business:apikey:remove']">删除</el-button>
          <tech-assist-button
            page-code="apikey"
            page-label="API外放"
            :ref-id="scope.row.id"
            :ref-summary="(scope.row.appName || scope.row.appId || 'ID' + scope.row.id)"
          />
        </template>
      </el-table-column>
    </el-table>

    <pagination
      v-show="total > 0"
      :total="total"
      :page.sync="queryParams.pageNum"
      :limit.sync="queryParams.pageSize"
      @pagination="getList"
    />

    <el-dialog :title="dialogTitle" :visible.sync="open" width="560px" append-to-body @close="cancelForm">
      <el-form ref="form" :model="form" :rules="rules" label-width="108px" size="small">
        <el-form-item label="所属用户" prop="userId">
          <el-select v-model="form.userId" filterable placeholder="用户" style="width: 100%" :disabled="!!form.id">
            <el-option v-for="u in userOptions" :key="u.userId" :label="formatUserLabel(u)" :value="u.userId" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="form.id" label="AppId">
          <el-input v-model="form.appId" readonly />
        </el-form-item>
        <el-form-item label="应用名称" prop="appName">
          <el-input v-model="form.appName" placeholder="应用名" maxlength="100" />
        </el-form-item>
        <el-form-item v-if="form.id" label="AppSecret">
          <el-input v-model="form.appSecret" type="password" show-password placeholder="密钥" autocomplete="new-password" />
        </el-form-item>
        <el-form-item label="限流" prop="rateLimit">
          <el-input-number v-model="form.rateLimit" :min="1" :max="999999" style="width: 100%" controls-position="right" />
        </el-form-item>
        <el-form-item label="售价(元/条)" prop="salePrice">
          <el-input-number
            v-model="form.salePrice"
            :precision="4"
            :min="0"
            :max="1000000"
            :step="0.0001"
            controls-position="right"
            style="width: 100%"
            placeholder="选填，不填表示未设"
          />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="form.status">
            <el-radio label="0">正常</el-radio>
            <el-radio label="1">停用</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="开放 HTTP" prop="apiOpen">
          <el-switch v-model="form.apiOpen" active-value="1" inactive-value="0" />
        </el-form-item>
        <el-form-item label="开放 SMPP" prop="smppOpen">
          <el-switch v-model="form.smppOpen" active-value="1" inactive-value="0" />
        </el-form-item>
        <el-form-item label="IP 白名单" prop="whitelistIps">
          <el-input v-model="form.whitelistIps" type="textarea" :rows="2" placeholder="每行一个IP" maxlength="500" show-word-limit />
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
import { listApiKey, getApiKey, addApiKey, updateApiKey, delApiKey } from '@/api/business/apikey'
import { channelsForUser } from '@/api/business/channelAssign'
import { listUser } from '@/api/system/user'
import TechAssistButton from '@/components/TechAssistButton'

export default {
  name: 'BusinessApiKey',
  components: { TechAssistButton },
  data() {
    return {
      loading: false,
      list: [],
      total: 0,
      queryParams: {
        pageNum: 1,
        pageSize: 10,
        appId: undefined,
        appName: undefined,
        userId: undefined,
        status: undefined
      },
      userOptions: [],
      open: false,
      dialogTitle: '',
      form: {},
      rules: {
        userId: [{ required: true, message: '请选择用户', trigger: 'change' }]
      }
    }
  },
  created() {
    this.loadUserOptions()
    this.getList()
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
    formatUserLabel(u) {
      return u.nickName ? `${u.userName} (${u.nickName})` : u.userName
    },
    loadUserOptions() {
      listUser({ pageNum: 1, pageSize: 500, status: '0' })
        .then(res => {
          this.userOptions = res.rows || []
        })
        .catch(() => {})
    },
    getList() {
      this.loading = true
      const q = { ...this.queryParams }
      if (q.userId == null || q.userId === '') delete q.userId
      listApiKey(q)
        .then(r => {
          this.list = r.rows || []
          this.total = r.total || 0
          this.loading = false
        })
        .catch(() => {
          this.loading = false
        })
    },
    handleQuery() {
      this.queryParams.pageNum = 1
      this.getList()
    },
    resetQuery() {
      this.queryParams = {
        pageNum: 1,
        pageSize: 10,
        appId: undefined,
        appName: undefined,
        userId: undefined,
        status: undefined
      }
      this.resetForm('queryForm')
      this.handleQuery()
    },
    resetFormModel() {
      this.form = {
        id: undefined,
        userId: undefined,
        appId: undefined,
        appSecret: undefined,
        appName: undefined,
        rateLimit: 300,
        salePrice: undefined,
        status: '0',
        apiOpen: '1',
        smppOpen: '1',
        whitelistIps: undefined,
        remark: undefined
      }
    },
    cancelForm() {
      this.resetFormModel()
    },
    handleAdd() {
      this.resetFormModel()
      this.dialogTitle = '新增外放密钥'
      this.open = true
      this.$nextTick(() => {
        this.$refs.form && this.$refs.form.clearValidate()
      })
    },
    handleUpdate(row) {
      this.resetFormModel()
      getApiKey(row.id).then(res => {
        const d = res.data || {}
        this.form = {
          id: d.id,
          userId: d.userId,
          appId: d.appId,
          appSecret: '',
          appName: d.appName,
          rateLimit: d.rateLimit != null ? d.rateLimit : 300,
          status: d.status != null ? String(d.status) : '0',
          apiOpen: d.apiOpen != null ? String(d.apiOpen) : '1',
          smppOpen: d.smppOpen != null ? String(d.smppOpen) : '1',
          salePrice: d.salePrice != null ? Number(d.salePrice) : undefined,
          whitelistIps: d.whitelistIps,
          remark: d.remark
        }
        this.dialogTitle = '修改外放密钥'
        this.open = true
        this.$nextTick(() => {
          this.$refs.form && this.$refs.form.clearValidate()
        })
      })
    },
    handleViewSecret(row) {
      getApiKey(row.id).then(res => {
        const d = res.data || {}
        const secret = d.appSecret || '—'
        this.$alert(
          `<div style="word-break:break-all"><strong>AppId</strong><br/>${d.appId || '—'}</div><div style="margin-top:12px;word-break:break-all"><strong>AppSecret</strong><br/>${secret}</div>`,
          '密钥信息',
          { dangerouslyUseHTMLString: true, confirmButtonText: '我知道了' }
        )
      })
    },
    submitForm() {
      this.$refs.form.validate(valid => {
        if (!valid) return
        const saveUpdate = () => {
          const payload = {
            id: this.form.id,
            userId: this.form.userId,
            appId: this.form.appId,
            appName: this.form.appName,
            rateLimit: this.form.rateLimit,
            status: this.form.status,
            apiOpen: this.form.apiOpen,
            smppOpen: this.form.smppOpen,
            salePrice: this.form.salePrice,
            whitelistIps: this.form.whitelistIps,
            remark: this.form.remark
          }
          if (this.form.appSecret && String(this.form.appSecret).trim()) {
            payload.appSecret = this.form.appSecret.trim()
          } else {
            payload.appSecret = ''
          }
          return updateApiKey(payload).then(() => {
            this.$modal.msgSuccess('修改成功')
            this.open = false
            this.getList()
          })
        }
        const saveAdd = () =>
          addApiKey({
            userId: this.form.userId,
            appName: this.form.appName,
            rateLimit: this.form.rateLimit,
            status: this.form.status,
            apiOpen: this.form.apiOpen,
            smppOpen: this.form.smppOpen,
            salePrice: this.form.salePrice,
            whitelistIps: this.form.whitelistIps,
            remark: this.form.remark
          }).then(() => {
            this.$modal.msgSuccess('新增成功，请在列表中点击「密钥」查看 AppId 与 AppSecret')
            this.open = false
            this.getList()
          })
        const run = () => {
          if (this.form.id) {
            return saveUpdate()
          }
          return saveAdd()
        }
        channelsForUser(this.form.userId)
          .then(r => {
            const rows = (r && (r.data !== undefined ? r.data : r)) || []
            const list = Array.isArray(rows) ? rows : []
            if (list.length < 1) {
              this.$modal
                .confirm(
                  '该用户在「新户-线路分配」中暂无已启用的平台通道（与 SMPP/通道管理 外放可选线路一致），即使开放 HTTP 仍无法发信。是否仍保存？'
                )
                .then(run)
                .catch(() => {})
            } else {
              run()
            }
          })
          .catch(() => {
            run()
          })
      })
    },
    handleDelete(row) {
      this.$modal
        .confirm('是否确认删除该外放密钥？（逻辑删除）')
        .then(() => delApiKey(row.id))
        .then(() => {
          this.$modal.msgSuccess('删除成功')
          this.getList()
        })
        .catch(() => {})
    }
  }
}
</script>

<style scoped>
.mb8 {
  margin-bottom: 8px;
}
</style>
