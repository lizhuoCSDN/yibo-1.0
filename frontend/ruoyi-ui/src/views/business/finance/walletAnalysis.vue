<template>
  <div class="app-container">
    <el-tabs v-model="activeTab" type="border-card">
      <el-tab-pane :label="ui.tabBind" name="bind">
        <el-form :inline="true" size="small" style="margin-bottom: 10px;">
          <el-form-item :label="ui.accountCode">
            <el-input v-model="bindQuery.accountCode" clearable placeholder="账户" style="width: 160px" />
          </el-form-item>
          <el-form-item :label="ui.usdtAddress">
            <el-input v-model="bindQuery.usdtAddress" clearable placeholder="USDT" style="width: 220px" />
          </el-form-item>
          <el-form-item :label="ui.userType">
            <el-select v-model="bindQuery.bindRole" clearable placeholder="身份" style="width: 120px">
              <el-option v-for="o in userTypeOptions" :key="o.value" :label="o.label" :value="o.value" />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" icon="el-icon-search" @click="loadBindList">{{ ui.query }}</el-button>
            <el-button type="primary" plain icon="el-icon-plus" @click="openBindForm()">{{ ui.add }}</el-button>
          </el-form-item>
        </el-form>
        <el-table v-loading="bindLoading" :data="bindList" border stripe>
          <el-table-column :label="ui.accountCode" align="center" prop="accountCode" min-width="120" show-overflow-tooltip />
          <el-table-column :label="ui.usdtAddress" align="center" prop="usdtAddress" min-width="220" show-overflow-tooltip />
          <el-table-column :label="ui.userType" align="center" width="100">
            <template slot-scope="scope">{{ userTypeText(scope.row.bindRole) }}</template>
          </el-table-column>
          <el-table-column :label="ui.remark" align="center" prop="remark" min-width="120" show-overflow-tooltip />
          <el-table-column :label="ui.createTime" align="center" prop="createTime" width="160" />
          <el-table-column :label="ui.actions" align="center" width="180" fixed="right">
            <template slot-scope="scope">
              <template v-if="canEditRow(scope.row)">
                <el-button type="text" size="mini" @click="openBindForm(scope.row)">{{ ui.edit }}</el-button>
                <el-button type="text" size="mini" style="color:#F56C6C" @click="removeBind(scope.row)">{{ ui.del }}</el-button>
              </template>
              <span v-else class="op-muted" title="仅超级管理员可维护内部地址">超管</span>
            </template>
          </el-table-column>
        </el-table>
        <el-pagination
          style="margin-top: 10px; text-align: right;"
          background
          layout="total, prev, pager, next, sizes"
          :total="bindTotal"
          :page-size="bindQuery.pageSize"
          :current-page="bindQuery.pageNum"
          @size-change="s => { bindQuery.pageSize = s; loadBindList() }"
          @current-change="p => { bindQuery.pageNum = p; loadBindList() }"
        />
      </el-tab-pane>

      <el-tab-pane :label="ui.tabAnalyze" name="analyze">
        <el-form :inline="true" size="small" style="margin-bottom: 16px;">
          <el-form-item :label="ui.analyzeAddr">
            <el-select
              v-model="analyzeAddr"
              filterable
              allow-create
              default-first-option
              placeholder="选地址"
              style="width: 420px"
            >
              <el-option
                v-for="b in bindOptions"
                :key="b.id"
                :label="b.accountCode + ' — ' + b.usdtAddress"
                :value="b.usdtAddress"
              />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" icon="el-icon-data-analysis" :loading="analyzeLoading" @click="runAnalyze">{{ ui.runAnalyze }}</el-button>
          </el-form-item>
        </el-form>

        <el-row v-if="analyzeResult" :gutter="16" style="margin-bottom: 20px;">
          <el-col :span="6">
            <div class="summary-card">
              <div class="summary-icon" style="background: linear-gradient(135deg, #06d6a0, #05b88a);"><i class="el-icon-bottom" /></div>
              <div class="summary-info">
                <div class="summary-value">{{ formatAmt(analyzeResult.totalIn) }}</div>
                <div class="summary-label">{{ ui.totalIn }}</div>
              </div>
            </div>
          </el-col>
          <el-col :span="6">
            <div class="summary-card">
              <div class="summary-icon" style="background: linear-gradient(135deg, #ef476f, #d43d60);"><i class="el-icon-top" /></div>
              <div class="summary-info">
                <div class="summary-value">{{ formatAmt(analyzeResult.totalOut) }}</div>
                <div class="summary-label">{{ ui.totalOut }}</div>
              </div>
            </div>
          </el-col>
          <el-col :span="6">
            <div class="summary-card">
              <div class="summary-icon" style="background: linear-gradient(135deg, #4361ee, #3a56d4);"><i class="el-icon-sort" /></div>
              <div class="summary-info">
                <div class="summary-value" :style="{ color: netColor(analyzeResult.net) }">{{ formatAmt(analyzeResult.net) }}</div>
                <div class="summary-label">{{ ui.net }}</div>
              </div>
            </div>
          </el-col>
          <el-col :span="6">
            <div class="summary-card">
              <div class="summary-icon" style="background: linear-gradient(135deg, #e6a23c, #d4940f);"><i class="el-icon-data-line" /></div>
              <div class="summary-info">
                <div class="summary-value">{{ analyzeResult.flowStrength }}</div>
                <div class="summary-label">{{ ui.flowStrength }}</div>
              </div>
            </div>
          </el-col>
        </el-row>

        <el-descriptions v-if="analyzeResult" :column="2" border size="small" style="margin-bottom: 16px;">
          <el-descriptions-item :label="ui.bindAccount">{{ analyzeResult.bindAccountCode || '—' }}</el-descriptions-item>
          <el-descriptions-item :label="ui.txCount">{{ analyzeResult.txCount }}</el-descriptions-item>
          <el-descriptions-item :label="ui.totalVolume">{{ formatAmt(analyzeResult.totalVolume) }}</el-descriptions-item>
          <el-descriptions-item :label="ui.knownCp">{{ analyzeResult.knownCounterpartyCount }}</el-descriptions-item>
        </el-descriptions>

        <el-table v-if="analyzeResult" :data="cpList" border stripe max-height="420">
          <el-table-column :label="ui.cpAddr" align="center" prop="otherAddress" min-width="200" show-overflow-tooltip />
          <el-table-column :label="ui.known" align="center" width="90">
            <template slot-scope="scope">
              <el-tag v-if="scope.row.knownInSystem" type="success" size="mini">{{ ui.yes }}</el-tag>
              <el-tag v-else type="info" size="mini">{{ ui.no }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column :label="ui.knownAccount" align="center" prop="knownAccountCode" min-width="120" show-overflow-tooltip />
          <el-table-column :label="ui.cpTx" align="center" prop="txCount" width="90" />
          <el-table-column :label="ui.inAmt" align="center" width="130">
            <template slot-scope="scope">{{ formatAmt(scope.row.inAmount) }}</template>
          </el-table-column>
          <el-table-column :label="ui.outAmt" align="center" width="130">
            <template slot-scope="scope">{{ formatAmt(scope.row.outAmount) }}</template>
          </el-table-column>
          <el-table-column :label="ui.netToUs" align="center" width="130">
            <template slot-scope="scope">
              <span :style="{ color: netColor(scope.row.netToUs), fontWeight: '600' }">{{ formatAmt(scope.row.netToUs) }}</span>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
    </el-tabs>

    <el-dialog :title="bindForm.id ? ui.editBind : ui.addBind" :visible.sync="bindVisible" width="520px" append-to-body @close="resetBindForm">
      <el-form ref="bindFormRef" :model="bindForm" :rules="bindRules" label-width="100px" size="small">
        <el-form-item :label="ui.accountCode" prop="accountCode">
          <el-input v-model="bindForm.accountCode" maxlength="64" show-word-limit />
        </el-form-item>
        <el-form-item :label="ui.usdtAddress" prop="usdtAddress">
          <el-input v-model="bindForm.usdtAddress" type="textarea" :rows="2" />
        </el-form-item>
        <el-form-item :label="ui.userType" prop="bindRole">
          <el-select v-model="bindForm.bindRole" style="width: 100%">
            <el-option v-for="o in userTypeFormOptions" :key="o.value" :label="o.label" :value="o.value" />
          </el-select>
        </el-form-item>
        <el-form-item :label="ui.remark" prop="remark">
          <el-input v-model="bindForm.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="bindVisible = false">{{ ui.cancel }}</el-button>
        <el-button type="primary" size="small" @click="submitBind">{{ ui.save }}</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import {
  listWalletBind,
  listWalletBindOptions,
  addWalletBind,
  updateWalletBind,
  delWalletBind,
  analyzeWallet
} from '@/api/business/walletAnalysis'

const USER_TYPE_OPTIONS = [
  { value: 'INTERNAL', label: '\u5185\u90e8' },
  { value: 'COMPETITOR', label: '\u540c\u884c' },
  { value: 'CUSTOMER', label: '\u5ba2\u6237' }
]

const ui = {
  tabBind: '\u5730\u5740\u7ed1\u5b9a',
  tabAnalyze: '\u5206\u6790\u770b\u677f',
  accountCode: '\u8d26\u6237\u6807\u8bc6',
  usdtAddress: 'USDT\u5730\u5740',
  userType: '\u7528\u6237\u7c7b\u578b',
  remark: '\u5907\u6ce8',
  createTime: '\u521b\u5efa\u65f6\u95f4',
  actions: '\u64cd\u4f5c',
  add: '\u65b0\u589e',
  edit: '\u7f16\u8f91',
  del: '\u5220\u9664',
  query: '\u67e5\u8be2',
  analyzeAddr: '\u5206\u6790\u5730\u5740',
  runAnalyze: '\u5206\u6790',
  totalIn: '\u7d2f\u8ba1\u8f6c\u5165',
  totalOut: '\u7d2f\u8ba1\u8f6c\u51fa',
  net: '\u51c0\u6d41\u5165',
  flowStrength: '\u6d41\u6c34\u5b9e\u529b',
  bindAccount: '\u7ed1\u5b9a\u8d26\u6237',
  txCount: '\u7b14\u6570',
  totalVolume: '\u5f80\u6765\u603b\u91cf',
  knownCp: '\u7cfb\u7edf\u5185\u5df2\u77e5\u5bf9\u624b\u6570',
  cpAddr: '\u5bf9\u624b\u5730\u5740',
  known: '\u5df2\u7ed1\u5b9a',
  yes: '\u662f',
  no: '\u5426',
  knownAccount: '\u5bf9\u624b\u8d26\u6237',
  cpTx: '\u7b14\u6570',
  inAmt: '\u8f6c\u5165\u672c\u5730\u5740',
  outAmt: '\u4ece\u672c\u5730\u5740\u8f6c\u51fa',
  netToUs: '\u51c0\u6536\u5165(\u672c\u5730\u89c6\u89d2)',
  addBind: '\u65b0\u589e\u7ed1\u5b9a',
  editBind: '\u7f16\u8f91\u7ed1\u5b9a',
  cancel: '\u53d6\u6d88',
  save: '\u4fdd\u5b58'
}

export default {
  name: 'WalletAnalysis',
  data() {
    return {
      ui,
      userTypeOptions: USER_TYPE_OPTIONS,
      activeTab: 'bind',
      bindLoading: false,
      bindList: [],
      bindTotal: 0,
      bindQuery: { accountCode: '', usdtAddress: '', bindRole: '', pageNum: 1, pageSize: 10 },
      bindOptions: [],
      bindVisible: false,
      bindForm: { id: null, accountCode: '', usdtAddress: '', bindRole: 'CUSTOMER', remark: '' },
      bindRules: {
        accountCode: [{ required: true, message: '\u5fc5\u586b', trigger: 'blur' }],
        usdtAddress: [{ required: true, message: '\u5fc5\u586b', trigger: 'blur' }],
        bindRole: [{ required: true, message: '\u5fc5\u586b', trigger: 'change' }]
      },
      analyzeAddr: '',
      analyzeLoading: false,
      analyzeResult: null
    }
  },
  computed: {
    ...mapGetters(['id']),
    isSuperAdmin() {
      return this.id === 1
    },
    userTypeFormOptions() {
      if (this.isSuperAdmin) {
        return USER_TYPE_OPTIONS
      }
      return USER_TYPE_OPTIONS.filter(o => o.value !== 'INTERNAL')
    },
    cpList() {
      return (this.analyzeResult && this.analyzeResult.counterparties) || []
    }
  },
  created() {
    this.loadBindList()
    this.loadBindOptions()
  },
  methods: {
    canEditRow(row) {
      if (!row) return true
      if (row.bindRole === 'INTERNAL' && !this.isSuperAdmin) {
        return false
      }
      return true
    },
    userTypeText(v) {
      if (!v) return '—'
      const f = this.userTypeOptions.find(o => o.value === v)
      return f ? f.label : v
    },
    formatAmt(v) {
      if (v === null || v === undefined) return '—'
      const n = Number(v)
      if (Number.isNaN(n)) return String(v)
      return n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 8 })
    },
    netColor(v) {
      const n = Number(v)
      if (Number.isNaN(n)) return '#303133'
      if (n > 0) return '#67C23A'
      if (n < 0) return '#F56C6C'
      return '#303133'
    },
    loadBindOptions() {
      listWalletBindOptions().then(res => {
        this.bindOptions = res.data || []
      })
    },
    loadBindList() {
      this.bindLoading = true
      listWalletBind(this.bindQuery).then(res => {
        this.bindList = res.rows || []
        this.bindTotal = res.total || 0
        this.bindLoading = false
      }).catch(() => { this.bindLoading = false })
    },
    openBindForm(row) {
      if (row && row.bindRole === 'INTERNAL' && !this.isSuperAdmin) {
        this.$modal.msgError('仅超级管理员可维护「内部」类型地址')
        return
      }
      if (row) {
        this.bindForm = { id: row.id, accountCode: row.accountCode, usdtAddress: row.usdtAddress, bindRole: row.bindRole || 'CUSTOMER', remark: row.remark || '' }
      } else {
        this.bindForm = { id: null, accountCode: '', usdtAddress: '', bindRole: 'CUSTOMER', remark: '' }
      }
      this.bindVisible = true
      this.$nextTick(() => this.$refs.bindFormRef && this.$refs.bindFormRef.clearValidate())
    },
    resetBindForm() {
      this.bindForm = { id: null, accountCode: '', usdtAddress: '', bindRole: 'CUSTOMER', remark: '' }
    },
    submitBind() {
      this.$refs.bindFormRef.validate(valid => {
        if (!valid) return
        const p = { ...this.bindForm }
        if (p.id == null) p.chainType = 'TRC20'
        const req = p.id ? updateWalletBind(p) : addWalletBind(p)
        req.then(() => {
          this.$modal.msgSuccess('\u6210\u529f')
          this.bindVisible = false
          this.loadBindList()
          this.loadBindOptions()
        })
      })
    },
    removeBind(row) {
      if (row && row.bindRole === 'INTERNAL' && !this.isSuperAdmin) {
        this.$modal.msgError('仅超级管理员可删除「内部」类型地址')
        return
      }
      this.$modal.confirm('\u786e\u8ba4\u5220\u9664\uff1f').then(() => {
        return delWalletBind(row.id)
      }).then(() => {
        this.$modal.msgSuccess('\u6210\u529f')
        this.loadBindList()
        this.loadBindOptions()
      }).catch(() => {})
    },
    runAnalyze() {
      const addr = (this.analyzeAddr || '').trim()
      if (!addr) {
        this.$modal.msgWarning('\u8bf7\u9009\u62e9\u6216\u8f93\u5165\u5730\u5740')
        return
      }
      this.analyzeLoading = true
      analyzeWallet(addr).then(res => {
        this.analyzeResult = res.data
        this.analyzeLoading = false
      }).catch(() => { this.analyzeLoading = false })
    }
  }
}
</script>

<style scoped>
.op-muted {
  color: #c0c4cc;
  font-size: 12px;
  cursor: default;
}
.summary-card {
  display: flex;
  align-items: center;
  padding: 16px;
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  border: 1px solid #ebeef5;
}
.summary-icon {
  width: 48px;
  height: 48px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: 22px;
  margin-right: 14px;
}
.summary-info { flex: 1; min-width: 0; }
.summary-value { font-size: 18px; font-weight: 600; color: #303133; word-break: break-all; }
.summary-label { font-size: 13px; color: #909399; margin-top: 4px; }
</style>
