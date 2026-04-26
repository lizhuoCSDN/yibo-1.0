<template>
  <div class="app-container tech-assist-page">
    <el-card shadow="hover" class="ta-card">
      <div slot="header" class="ta-head">
        <div class="ta-title-row">
          <i class="el-icon-question title-icon" />
          <span class="title-text">技术协助</span>
          <el-tag size="mini" type="info" effect="plain">待处理</el-tag>
        </div>
      </div>

      <el-form :inline="true" :model="queryParams" size="small" class="ta-filters" label-width="72px" @submit.native.prevent>
        <el-form-item label="来源">
          <el-select v-model="queryParams.pageCode" clearable placeholder="来源" class="ta-sel">
            <el-option label="通道管理" value="channel" />
            <el-option label="智能路由" value="channelRouter" />
            <el-option label="API外放" value="apikey" />
            <el-option label="SMPP" value="smpp" />
          </el-select>
        </el-form-item>
        <el-form-item label="提交人">
          <el-input v-model="queryParams.createBy" clearable placeholder="提交人" class="ta-inp" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleQuery">搜索</el-button>
          <el-button icon="el-icon-refresh" @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table v-loading="loading" :data="list" border stripe class="ta-table" size="small">
        <el-table-column prop="id" label="单号" width="72" align="center" />
        <el-table-column label="来源" width="100" show-overflow-tooltip>
          <template slot-scope="s">{{ pageLabel(s.row.pageCode) }}</template>
        </el-table-column>
        <el-table-column prop="refSummary" label="关联" min-width="120" show-overflow-tooltip />
        <el-table-column prop="question" label="问题" min-width="200" show-overflow-tooltip />
        <el-table-column label="当前层级" width="88" align="center">
          <template slot-scope="s">
            <el-tag size="mini" type="warning">L{{ s.row.pendingLevel }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createBy" label="提交人" width="100" show-overflow-tooltip />
        <el-table-column prop="createTime" label="时间" width="160" show-overflow-tooltip />
        <el-table-column label="操作" width="220" align="center" fixed="right">
          <template slot-scope="s">
            <el-button
              v-if="canAct(s.row)"
              type="success"
              plain
              size="mini"
              @click="doPass(s.row)"
            >通过</el-button>
            <el-button
              v-if="canAct(s.row) && s.row.pendingLevel < 4"
              type="primary"
              plain
              size="mini"
              @click="doEscalate(s.row)"
            >{{ s.row.pendingLevel === 1 ? '提交上级' : '复核' }}</el-button>
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
    </el-card>
  </div>
</template>

<script>
import { listTechAssist, passTechAssist, escalateTechAssist } from '@/api/business/techAssist'
import { checkPermi } from '@/utils/permission'

const H = {
  1: 'business:techAssist:handle1',
  2: 'business:techAssist:handle2',
  3: 'business:techAssist:handle3',
  4: 'business:techAssist:handle4'
}

export default {
  name: 'TechAssist',
  data() {
    return {
      loading: false,
      list: [],
      total: 0,
      queryParams: {
        pageNum: 1,
        pageSize: 20,
        pageCode: null,
        createBy: null
      }
    }
  },
  created() {
    this.getList()
  },
  methods: {
    pageLabel(code) {
      const m = { channel: '通道', channelRouter: '智能路由', apikey: 'API外放', smpp: 'SMPP' }
      return m[code] || code || '—'
    },
    canAct(row) {
      const perm = H[row.pendingLevel]
      if (!perm) return false
      return checkPermi([perm])
    },
    getList() {
      this.loading = true
      listTechAssist(this.queryParams)
        .then(res => {
          this.list = res.rows || []
          this.total = res.total || 0
        })
        .finally(() => {
          this.loading = false
        })
    },
    handleQuery() {
      this.queryParams.pageNum = 1
      this.getList()
    },
    resetQuery() {
      this.queryParams.pageCode = null
      this.queryParams.createBy = null
      this.handleQuery()
    },
    doPass(row) {
      this.$prompt('备注（选填）', '确认通过', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        inputPlaceholder: '可填写处理说明'
      })
        .then(({ value }) => {
          return passTechAssist(row.id, value)
        })
        .then(res => {
          this.$modal.msgSuccess(res.msg || '已通过')
          this.getList()
        })
        .catch(() => {})
    },
    doEscalate(row) {
      this.$prompt('请说明需上级或复核原因（选填）', '提交上一处理层级', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        inputPlaceholder: '如：已尝试……仍无法解决'
      })
        .then(({ value }) => {
          return escalateTechAssist(row.id, value)
        })
        .then(res => {
          this.$modal.msgSuccess(res.msg || '已转交')
          this.getList()
        })
        .catch(() => {})
    }
  }
}
</script>

<style scoped>
.tech-assist-page {
  min-height: 100%;
}
.ta-card {
  border-radius: 10px;
}
.ta-card >>> .el-card__header {
  padding: 16px 20px;
  border-bottom: 1px solid #ebeef5;
}
.ta-title-row {
  display: flex;
  align-items: center;
  gap: 8px;
}
.title-icon {
  color: #409eff;
  font-size: 18px;
}
.title-text {
  font-size: 16px;
  font-weight: 600;
}
.ta-filters {
  margin-bottom: 12px;
}
.ta-sel {
  width: 140px;
}
.ta-inp {
  width: 140px;
}
.ta-table {
  width: 100%;
}
</style>
