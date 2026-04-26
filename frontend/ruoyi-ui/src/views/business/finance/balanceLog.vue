<template>
  <div class="app-container">
    <div style="margin-bottom: 10px;">
      <el-form :inline="true" :model="logQuery" size="small">
        <el-form-item :label="ui.userName">
          <el-input v-model="logQuery.userName" placeholder="账号" clearable style="width: 120px" />
        </el-form-item>
        <el-form-item :label="ui.channelId">
          <el-input v-model="logQuery.channelId" placeholder="通道ID" clearable style="width: 100px" />
        </el-form-item>
        <el-form-item :label="ui.changeType">
          <el-select v-model="logQuery.changeType" placeholder="类型" clearable style="width: 100px">
            <el-option :label="ui.all" value="" />
            <el-option :label="ui.add" value="1" />
            <el-option :label="ui.deduct" value="2" />
            <el-option :label="ui.consume" value="3" />
          </el-select>
        </el-form-item>
        <el-form-item :label="ui.time">
          <el-date-picker
            v-model="logQuery.timeRange"
            type="daterange"
            :range-separator="ui.to"
            start-placeholder="开始"
            end-placeholder="结束"
            value-format="yyyy-MM-dd HH:mm:ss"
            style="width: 240px"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="loadBalanceLog">{{ ui.query }}</el-button>
          <el-button @click="resetLogQuery">{{ ui.reset }}</el-button>
          <el-button type="success" icon="el-icon-download" style="margin-left: 8px;" @click="exportBalanceLog">{{ ui.export }}</el-button>
        </el-form-item>
      </el-form>
    </div>
    <el-table v-loading="logLoading" :data="balanceLogList" border stripe>
      <el-table-column :label="ui.userName" align="center" prop="userName" />
      <el-table-column :label="ui.changeTypeCol" align="center" prop="changeType">
        <template slot-scope="scope">
          <span v-if="scope.row.changeType==='1'">{{ ui.add }}</span>
          <span v-else-if="scope.row.changeType==='2'">{{ ui.deduct }}</span>
          <span v-else-if="scope.row.changeType==='3'">{{ ui.consume }}</span>
          <span v-else>--</span>
        </template>
      </el-table-column>
      <el-table-column :label="ui.changeCount" align="center" prop="changeCount" />
      <el-table-column :label="ui.balanceBefore" align="center" prop="balanceBefore" />
      <el-table-column :label="ui.balanceAfter" align="center" prop="balanceAfter" />
      <el-table-column :label="ui.channelId" align="center" prop="channelId" />
      <el-table-column :label="ui.channelName" align="center" prop="channelName" />
      <el-table-column :label="ui.operator" align="center" prop="operatorName" />
      <el-table-column :label="ui.timeCol" align="center" prop="createTime" />
      <el-table-column :label="ui.remark" align="center" prop="remark" />
    </el-table>
    <el-pagination
      style="margin-top: 10px; text-align: right;"
      background
      layout="total, prev, pager, next, sizes, jumper"
      :total="logTotal"
      :page-size="logQuery.pageSize"
      :current-page="logQuery.pageNum"
      @size-change="handleLogSizeChange"
      @current-change="handleLogPageChange"
    />
  </div>
</template>

<script>
import { getBalanceLogList } from '@/api/business/finance'

const ui = {
  userName: '\u7528\u6237\u540d',
  channelId: '\u901a\u9053ID',
  changeType: '\u7c7b\u578b',
  all: '\u5168\u90e8',
  add: '\u589e\u52a0',
  deduct: '\u6263\u9664',
  consume: '\u6d88\u8d39',
  time: '\u65f6\u95f4',
  to: '\u81f3',
  query: '\u67e5\u8be2',
  reset: '\u91cd\u7f6e',
  export: '\u5bfc\u51fa',
  changeTypeCol: '\u7c7b\u578b',
  changeCount: '\u53d8\u52a8\u6570\u91cf',
  balanceBefore: '\u53d8\u52a8\u524d\u4f59\u989d',
  balanceAfter: '\u53d8\u52a8\u540e\u4f59\u989d',
  channelName: '\u901a\u9053\u540d\u79f0',
  operator: '\u64cd\u4f5c\u4eba',
  timeCol: '\u65f6\u95f4',
  remark: '\u5907\u6ce8',
  csvName: '\u6d88\u8d39\u660e\u7ec6.csv'
}

export default {
  name: 'FinanceBalanceLog',
  data() {
    return {
      ui,
      logLoading: false,
      logTotal: 0,
      balanceLogList: [],
      logQuery: {
        userName: '',
        channelId: '',
        changeType: '',
        timeRange: [],
        pageNum: 1,
        pageSize: 20
      }
    }
  },
  created() {
    this.loadBalanceLog()
  },
  methods: {
    loadBalanceLog() {
      this.logLoading = true
      const params = { ...this.logQuery }
      if (params.timeRange && params.timeRange.length === 2) {
        params.beginTime = params.timeRange[0]
        params.endTime = params.timeRange[1]
      }
      getBalanceLogList(params).then(res => {
        this.balanceLogList = res.rows || []
        this.logTotal = res.total || 0
        this.logLoading = false
      }).catch(() => {
        this.logLoading = false
      })
    },
    handleLogPageChange(page) {
      this.logQuery.pageNum = page
      this.loadBalanceLog()
    },
    handleLogSizeChange(size) {
      this.logQuery.pageSize = size
      this.loadBalanceLog()
    },
    exportBalanceLog() {
      const header = [
        ui.userName, ui.changeTypeCol, ui.changeCount, ui.balanceBefore, ui.balanceAfter,
        ui.channelId, ui.channelName, ui.operator, ui.timeCol, ui.remark
      ]
      const rows = this.balanceLogList.map(row => [
        row.userName || '',
        row.changeType === '1' ? ui.add : row.changeType === '2' ? ui.deduct : row.changeType === '3' ? ui.consume : '',
        row.changeCount || '',
        row.balanceBefore || '',
        row.balanceAfter || '',
        row.channelId || '',
        row.channelName || '',
        row.operatorName || '',
        row.createTime || '',
        row.remark || ''
      ])
      const csv = [header, ...rows].map(e => e.map(v => '"' + String(v).replace(/"/g, '""') + '"').join(',')).join('\n')
      const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8' })
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = ui.csvName
      a.click()
      window.URL.revokeObjectURL(url)
    },
    resetLogQuery() {
      this.logQuery = { userName: '', channelId: '', changeType: '', timeRange: [], pageNum: 1, pageSize: 20 }
      this.loadBalanceLog()
    }
  }
}
</script>
