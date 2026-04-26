<template>
  <div :class="['content-review-page', { 'is-embedded': embedded }]">
    <el-card shadow="hover" class="review-card">
      <div slot="header" class="card-header">
        <div class="card-title-row">
          <i class="el-icon-message-solid title-icon" />
          <span class="title-text">内容审核</span>
          <el-tag size="mini" type="warning" effect="plain" class="title-tag">待审</el-tag>
        </div>
      </div>

      <div class="filter-toolbar">
        <el-form :inline="true" :model="queryParams" size="small" class="filter-form" label-width="72px">
          <el-form-item label="提交人">
            <el-input
              v-model="queryParams.createBy"
              placeholder="提交人"
              clearable
              class="filter-input"
            />
          </el-form-item>
          <el-form-item label="任务编号">
            <el-input
              v-model="queryParams.taskNo"
              placeholder="任务编号"
              clearable
              class="filter-input filter-input-wide"
            />
          </el-form-item>
          <el-form-item class="filter-actions">
            <el-button type="primary" icon="el-icon-search" @click="handleQuery">搜索</el-button>
            <el-button icon="el-icon-refresh" @click="resetQuery">重置</el-button>
          </el-form-item>
        </el-form>
      </div>

      <div class="table-wrap">
        <el-table
          v-loading="loading"
          :data="list"
          stripe
          class="review-table"
          :header-cell-style="tableHeaderStyle"
        >
          <el-table-column prop="taskNo" label="任务编号" width="176" show-overflow-tooltip />
          <el-table-column prop="smsContent" label="短信内容" min-width="200" show-overflow-tooltip />
          <el-table-column prop="remark" label="命中敏感词" min-width="160" show-overflow-tooltip>
            <template slot-scope="scope">
              <el-tag v-if="scope.row.remark" type="danger" size="small" effect="plain">{{ scope.row.remark }}</el-tag>
              <span v-else class="cell-muted">—</span>
            </template>
          </el-table-column>
          <el-table-column prop="createBy" label="提交人" width="108" show-overflow-tooltip />
          <el-table-column prop="totalCount" label="号码数" width="88" align="center" />
          <el-table-column prop="channelName" label="通道" width="112" show-overflow-tooltip />
          <el-table-column prop="createTime" label="提交时间" width="168" show-overflow-tooltip />
          <el-table-column label="操作" width="132" align="center" class-name="col-actions" fixed="right">
            <template slot-scope="scope">
              <div class="action-col">
                <el-button type="success" plain size="mini" icon="el-icon-check" @click="handleApprove(scope.row)">直接通过</el-button>
                <el-button type="warning" plain size="mini" icon="el-icon-top" @click="handleEscalate(scope.row)">提交复核</el-button>
                <el-button type="danger" plain size="mini" icon="el-icon-close" @click="handleReject(scope.row)">果断拒绝</el-button>
              </div>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <pagination
        v-show="total > 0"
        :total="total"
        :page.sync="queryParams.pageNum"
        :limit.sync="queryParams.pageSize"
        class="review-pagination"
        @pagination="getList"
      />
    </el-card>
  </div>
</template>

<script>
import { listReview, approveReview, rejectReview, escalateReview } from '@/api/business/contentReview'

export default {
  name: 'ContentReview',
  props: {
    embedded: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      loading: false,
      total: 0,
      list: [],
      queryParams: {
        pageNum: 1,
        pageSize: 20,
        createBy: null,
        taskNo: null
      },
      tableHeaderStyle: {
        background: '#f5f7fa',
        color: '#606266',
        fontWeight: '600'
      }
    }
  },
  created() {
    this.getList()
  },
  methods: {
    getList() {
      this.loading = true
      listReview(this.queryParams).then(res => {
        this.list = res.rows || []
        this.total = res.total || 0
        this.loading = false
      }).catch(() => {
        this.loading = false
      })
    },
    handleQuery() {
      this.queryParams.pageNum = 1
      this.getList()
    },
    resetQuery() {
      this.queryParams.createBy = null
      this.queryParams.taskNo = null
      this.handleQuery()
    },
    handleApprove(row) {
      this.$confirm('直接通过任务 ' + row.taskNo + ' 并开始发送？', '直接通过', { type: 'warning' }).then(() => {
        approveReview(row.id).then(res => {
          this.$message.success(res.msg || '已通过，任务开始发送')
          this.getList()
        })
      }).catch(() => {})
    },
    handleReject(row) {
      this.$confirm('果断拒绝任务 ' + row.taskNo + '？拒绝后任务将不会发送。', '确认拒绝', { type: 'warning' }).then(() => {
        rejectReview(row.id).then(res => {
          this.$message.success(res.msg || '已拒绝')
          this.getList()
        })
      }).catch(() => {})
    },
    handleEscalate(row) {
      this.$confirm('将任务 ' + row.taskNo + ' 提交给更上级账户复核？', '提交复核', { type: 'warning' }).then(() => {
        escalateReview(row.id).then(res => {
          this.$message.success(res.msg || '已提交复核')
          this.getList()
        })
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.content-review-page {
  min-height: 100%;
}

.content-review-page:not(.is-embedded) {
  padding-bottom: 8px;
}

.content-review-page.is-embedded .review-card {
  border-radius: 8px;
}

.review-card {
  border-radius: 10px;
  border: 1px solid #ebeef5;
  overflow: hidden;
}

.review-card >>> .el-card__header {
  padding: 18px 22px;
  border-bottom: 1px solid #f0f2f5;
  background: linear-gradient(180deg, #fafbfc 0%, #fff 100%);
}

.review-card >>> .el-card__body {
  padding: 0 22px 22px;
}

.card-header {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.card-title-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.title-icon {
  font-size: 20px;
  color: #4361ee;
}

.title-text {
  font-size: 17px;
  font-weight: 600;
  color: #303133;
  letter-spacing: 0.02em;
}

.title-tag {
  margin-left: 2px;
}

.filter-toolbar {
  margin: 18px 0 16px;
  padding: 14px 16px;
  background: #f5f7fa;
  border-radius: 8px;
  border: 1px solid #ebeef5;
}

.filter-form {
  margin-bottom: 0;
}

.filter-form >>> .el-form-item {
  margin-bottom: 0;
  margin-right: 18px;
}

.filter-form >>> .el-form-item__label {
  color: #606266;
}

.filter-input {
  width: 160px;
}

.filter-input-wide {
  width: 200px;
}

.filter-actions {
  margin-left: 4px;
}

.table-wrap {
  width: 100%;
  overflow-x: auto;
  border-radius: 8px;
  border: 1px solid #ebeef5;
}

.review-table {
  width: 100%;
  min-width: 1120px;
}

.review-table >>> .el-table__empty-block {
  min-height: 200px;
}

.review-table >>> .el-table__body tr:hover > td {
  background-color: #f8faff !important;
}

.cell-muted {
  color: #c0c4cc;
}

.review-pagination {
  margin-top: 16px;
  padding-top: 4px;
}

.review-table >>> .col-actions .cell {
  white-space: normal;
  line-height: 1.2;
  padding: 8px 6px;
}

.action-col {
  display: flex;
  flex-direction: column;
  align-items: stretch;
  gap: 6px;
  max-width: 100%;
  box-sizing: border-box;
}

.action-col .el-button {
  margin: 0 !important;
  padding-left: 8px;
  padding-right: 8px;
  white-space: nowrap;
}
</style>
