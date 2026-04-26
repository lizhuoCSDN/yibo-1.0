<template>
  <div class="app-container">
    <el-row :gutter="16" style="margin-bottom: 20px;">
      <el-col :span="6">
        <div class="summary-card">
          <div class="summary-icon" style="background: linear-gradient(135deg, #4361ee, #3a56d4);"><i class="el-icon-s-data"></i></div>
          <div class="summary-info">
            <div class="summary-value">{{ summary.totalUsed }}</div>
            <div class="summary-label">{{ ui.totalUsed }}</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="summary-card">
          <div class="summary-icon" style="background: linear-gradient(135deg, #06d6a0, #05b88a);"><i class="el-icon-coin"></i></div>
          <div class="summary-info">
            <div class="summary-value">{{ yen }}{{ formatMoney(summary.totalRevenue) }}</div>
            <div class="summary-label">{{ ui.totalRevenue }}</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="summary-card">
          <div class="summary-icon" style="background: linear-gradient(135deg, #e6a23c, #d4940f);"><i class="el-icon-money"></i></div>
          <div class="summary-info">
            <div class="summary-value">{{ yen }}{{ formatMoney(summary.totalCost) }}</div>
            <div class="summary-label">{{ ui.totalCost }}</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="summary-card">
          <div class="summary-icon" style="background: linear-gradient(135deg, #ef476f, #d43d60);"><i class="el-icon-wallet"></i></div>
          <div class="summary-info">
            <div class="summary-value">{{ yen }}{{ formatMoney(summary.totalProfit) }}</div>
            <div class="summary-label">{{ ui.totalProfit }}</div>
          </div>
        </div>
      </el-col>
    </el-row>

    <div style="margin-bottom: 10px;">
      <el-button type="primary" icon="el-icon-refresh" size="mini" @click="loadData">{{ ui.refresh }}</el-button>
    </div>

    <el-table v-loading="loading" :data="details" border stripe>
      <el-table-column :label="ui.userName" align="center" prop="userName" />
      <el-table-column :label="ui.nickName" align="center" prop="nickName" />
      <el-table-column :label="ui.used" align="center" prop="totalUsed" />
      <el-table-column :label="ui.revenue" align="center">
        <template slot-scope="scope">
          <span style="color: #409EFF;">{{ yen }}{{ formatMoney(scope.row.revenue) }}</span>
        </template>
      </el-table-column>
      <el-table-column :label="ui.cost" align="center">
        <template slot-scope="scope">
          <span style="color: #E6A23C;">{{ yen }}{{ formatMoney(scope.row.cost) }}</span>
        </template>
      </el-table-column>
      <el-table-column :label="ui.profit" align="center">
        <template slot-scope="scope">
          <span :style="{ color: Number(scope.row.profit) >= 0 ? '#67C23A' : '#F56C6C', fontWeight: 'bold' }">
            {{ yen }}{{ formatMoney(scope.row.profit) }}
          </span>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script>
import { getFinanceList } from '@/api/business/finance'

const ui = {
  totalUsed: '\u603b\u4f7f\u7528\u91cf',
  totalRevenue: '\u603b\u6536\u5165',
  totalCost: '\u603b\u6210\u672c',
  totalProfit: '\u603b\u5229\u6da6',
  refresh: '\u5237\u65b0',
  userName: '\u7528\u6237\u540d',
  nickName: '\u6635\u79f0',
  used: '\u4f7f\u7528\u91cf',
  revenue: '\u6536\u5165',
  cost: '\u6210\u672c',
  profit: '\u5229\u6da6'
}

export default {
  name: 'FinanceProfit',
  data() {
    return {
      ui,
      yen: '\u00a5',
      loading: false,
      summary: {
        totalUsed: 0,
        totalRevenue: 0,
        totalCost: 0,
        totalProfit: 0
      },
      details: []
    }
  },
  created() {
    this.loadData()
  },
  methods: {
    loadData() {
      this.loading = true
      getFinanceList().then(res => {
        if (res.data) {
          this.summary.totalUsed = res.data.totalUsed || 0
          this.summary.totalRevenue = res.data.totalRevenue || 0
          this.summary.totalCost = res.data.totalCost || 0
          this.summary.totalProfit = res.data.totalProfit || 0
          this.details = res.data.details || []
        }
        this.loading = false
      }).catch(() => {
        this.loading = false
      })
    },
    formatMoney(val) {
      if (val === null || val === undefined) return '0.00'
      return Number(val).toFixed(2)
    }
  }
}
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
