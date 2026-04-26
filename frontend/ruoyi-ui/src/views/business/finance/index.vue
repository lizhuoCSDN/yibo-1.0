<template>
  <div class="app-container">
    <el-tabs v-model="activeTab">
      <el-tab-pane label="利润统计" name="summary">
        <!-- 汇总卡片 -->
        <el-row :gutter="16" style="margin-bottom: 20px;">
          <el-col :span="6">
            <div class="summary-card">
              <div class="summary-icon" style="background: linear-gradient(135deg, #4361ee, #3a56d4);"><i class="el-icon-s-data"></i></div>
              <div class="summary-info">
                <div class="summary-value">{{ summary.totalUsed }}</div>
                <div class="summary-label">总使用量</div>
              </div>
            </div>
          </el-col>
          <el-col :span="6">
            <div class="summary-card">
              <div class="summary-icon" style="background: linear-gradient(135deg, #06d6a0, #05b88a);"><i class="el-icon-coin"></i></div>
              <div class="summary-info">
                <div class="summary-value">¥{{ formatMoney(summary.totalRevenue) }}</div>
                <div class="summary-label">总收入</div>
              </div>
            </div>
          </el-col>
          <el-col :span="6">
            <div class="summary-card">
              <div class="summary-icon" style="background: linear-gradient(135deg, #e6a23c, #d4940f);"><i class="el-icon-money"></i></div>
              <div class="summary-info">
                <div class="summary-value">¥{{ formatMoney(summary.totalCost) }}</div>
                <div class="summary-label">总成本</div>
              </div>
            </div>
          </el-col>
          <el-col :span="6">
            <div class="summary-card">
              <div class="summary-icon" style="background: linear-gradient(135deg, #ef476f, #d43d60);"><i class="el-icon-wallet"></i></div>
              <div class="summary-info">
                <div class="summary-value">¥{{ formatMoney(summary.totalProfit) }}</div>
                <div class="summary-label">总利润</div>
              </div>
            </div>
          </el-col>
        </el-row>

        <div style="margin-bottom: 10px;">
          <el-button type="primary" icon="el-icon-refresh" size="mini" @click="loadData">刷新</el-button>
        </div>

        <el-table v-loading="loading" :data="details" border stripe>
          <el-table-column label="用户名" align="center" prop="userName" />
          <el-table-column label="昵称" align="center" prop="nickName" />
          <el-table-column label="使用量" align="center" prop="totalUsed" />
          <el-table-column label="收入" align="center">
            <template slot-scope="scope">
              <span style="color: #409EFF;">¥{{ formatMoney(scope.row.revenue) }}</span>
            </template>
          </el-table-column>
          <el-table-column label="成本" align="center">
            <template slot-scope="scope">
              <span style="color: #E6A23C;">¥{{ formatMoney(scope.row.cost) }}</span>
            </template>
          </el-table-column>
          <el-table-column label="利润" align="center">
            <template slot-scope="scope">
              <span :style="{ color: Number(scope.row.profit) >= 0 ? '#67C23A' : '#F56C6C', fontWeight: 'bold' }">
                ¥{{ formatMoney(scope.row.profit) }}
              </span>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>

      <el-tab-pane label="消费明细" name="balanceLog">
        <div style="margin-bottom: 10px;">
          <el-form :inline="true" :model="logQuery" size="small">
            <el-form-item label="用户名">
              <el-input v-model="logQuery.userName" placeholder="账号" clearable style="width: 120px" />
            </el-form-item>
            <el-form-item label="通道ID">
              <el-input v-model="logQuery.channelId" placeholder="通道ID" clearable style="width: 100px" />
            </el-form-item>
            <el-form-item label="类型">
              <el-select v-model="logQuery.changeType" placeholder="类型" clearable style="width: 100px">
                <el-option label="全部" value="" />
                <el-option label="增加" value="1" />
                <el-option label="扣除" value="2" />
                <el-option label="消费" value="3" />
              </el-select>
            </el-form-item>
            <el-form-item label="时间">
              <el-date-picker v-model="logQuery.timeRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="yyyy-MM-dd HH:mm:ss" style="width: 240px" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" icon="el-icon-search" @click="loadBalanceLog">查询</el-button>
              <el-button @click="resetLogQuery">重置</el-button>
              <el-button type="success" icon="el-icon-download" @click="exportBalanceLog" style="margin-left: 8px;">导出</el-button>
            </el-form-item>
          </el-form>
        </div>
        <el-table v-loading="logLoading" :data="balanceLogList" border stripe>
          <el-table-column label="用户名" align="center" prop="userName" />
          <el-table-column label="类型" align="center" prop="changeType">
            <template slot-scope="scope">
              <span v-if="scope.row.changeType==='1'">增加</span>
              <span v-else-if="scope.row.changeType==='2'">扣除</span>
              <span v-else-if="scope.row.changeType==='3'">消费</span>
              <span v-else>--</span>
            </template>
          </el-table-column>
          <el-table-column label="变动数量" align="center" prop="changeCount" />
          <el-table-column label="变动前余额" align="center" prop="balanceBefore" />
          <el-table-column label="变动后余额" align="center" prop="balanceAfter" />
          <el-table-column label="通道ID" align="center" prop="channelId" />
          <el-table-column label="通道名称" align="center" prop="channelName" />
          <el-table-column label="操作人" align="center" prop="operatorName" />
          <el-table-column label="时间" align="center" prop="createTime" />
          <el-table-column label="备注" align="center" prop="remark" />
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
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script>
import { getFinanceList, getBalanceLogList } from "@/api/business/finance";

export default {
  name: "Finance",
  data() {
    return {
      activeTab: 'summary',
      loading: false,
      summary: {
        totalUsed: 0,
        totalRevenue: 0,
        totalCost: 0,
        totalProfit: 0
      },
      details: [],
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
    };
  },
  created() {
    this.loadData();
  },
  methods: {
    loadData() {
      this.loading = true;
      getFinanceList().then(res => {
        if (res.data) {
          this.summary.totalUsed = res.data.totalUsed || 0;
          this.summary.totalRevenue = res.data.totalRevenue || 0;
          this.summary.totalCost = res.data.totalCost || 0;
          this.summary.totalProfit = res.data.totalProfit || 0;
          this.details = res.data.details || [];
        }
        this.loading = false;
      }).catch(() => {
        this.loading = false;
      });
    },
    loadBalanceLog() {
      this.logLoading = true;
      const params = { ...this.logQuery };
      if (params.timeRange && params.timeRange.length === 2) {
        params.beginTime = params.timeRange[0];
        params.endTime = params.timeRange[1];
      }
      getBalanceLogList(params).then(res => {
        this.balanceLogList = res.rows || [];
        this.logTotal = res.total || 0;
        this.logLoading = false;
      }).catch(() => {
        this.logLoading = false;
      });
    },
    handleLogPageChange(page) {
      this.logQuery.pageNum = page;
      this.loadBalanceLog();
    },
    handleLogSizeChange(size) {
      this.logQuery.pageSize = size;
      this.loadBalanceLog();
    },
    exportBalanceLog() {
      const header = ['用户名','类型','变动数量','变动前余额','变动后余额','通道ID','通道名称','操作人','时间','备注'];
      const rows = this.balanceLogList.map(row => [
        row.userName || '',
        row.changeType === '1' ? '增加' : row.changeType === '2' ? '扣除' : row.changeType === '3' ? '消费' : '',
        row.changeCount || '',
        row.balanceBefore || '',
        row.balanceAfter || '',
        row.channelId || '',
        row.channelName || '',
        row.operatorName || '',
        row.createTime || '',
        row.remark || ''
      ]);
      const csv = [header, ...rows].map(e => e.map(v => '"'+String(v).replace(/"/g,'""')+'"').join(',')).join('\n');
      const blob = new Blob([csv], { type: 'text/csv' });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = '消费明细.csv';
      a.click();
      window.URL.revokeObjectURL(url);
    },
    resetLogQuery() {
      this.logQuery = { userName: '', channelId: '', changeType: '', timeRange: [], pageNum: 1, pageSize: 20 };
      this.loadBalanceLog();
    },
    formatMoney(val) {
      if (val === null || val === undefined) return "0.00";
      return Number(val).toFixed(2);
    }
  }
};
</script>

<style scoped>
.summary-card {
  display: flex;
  align-items: center;
  padding: 20px;
  background: #fff;
  border-radius: 10px;
  border: 1px solid #e8ecf4;
  transition: box-shadow 0.3s, transform 0.3s;
}
.summary-card:hover {
  box-shadow: 0 4px 16px rgba(0,0,0,0.08);
  transform: translateY(-2px);
}
.summary-icon {
  width: 52px;
  height: 52px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 16px;
  flex-shrink: 0;
}
.summary-icon i { font-size: 24px; color: #fff; }
.summary-info { flex: 1; }
.summary-value { font-size: 22px; font-weight: 700; color: #1a1a2e; line-height: 1.2; }
.summary-label { font-size: 13px; color: #909399; margin-top: 4px; }
</style>
