<template>
  <div class="app-container home-overview dashboard-wrap">
    <div class="page-head">
      <h2 class="page-title">业务概览</h2>
    </div>

    <el-row :gutter="16" v-loading="overviewLoading">
      <el-col :span="6" v-for="card in cardList" :key="card.key">
        <el-card shadow="hover" class="metric-card">
          <div class="metric-label">
            {{ card.label }}
          </div>
          <div class="metric-value">{{ card.display }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="16" style="margin-top:16px">
      <el-col :span="12">
        <el-card shadow="never" class="panel-card">
          <div slot="header" class="panel-header">
            <span>发送质量</span>
          </div>
          <div class="gauge-wrap">
            <el-progress
              type="dashboard"
              :percentage="successRateDisplay"
              :color="successColor"
              :width="160"
            />
            <div class="gauge-meta">
              <p class="gauge-rate">成功率 {{ successRateDisplay }}%</p>
              <p class="gauge-foot">
                有结果笔数 {{ sendOutcomeTotal }}（成功 {{ overview.totalSuccess || 0 }} + 失败 {{ overview.totalFail || 0 }}）
              </p>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card shadow="never" class="panel-card">
          <div slot="header" class="panel-header">
            <span>任务状态分布</span>
          </div>
          <el-row :gutter="8">
            <el-col :span="12">
              <div class="state-box ok">
                <div class="state-label">成功</div>
                <div class="state-num">{{ formatInt(overview.totalSuccess) }}</div>
              </div>
            </el-col>
            <el-col :span="12">
              <div class="state-box err">
                <div class="state-label">失败</div>
                <div class="state-num">{{ formatInt(overview.totalFail) }}</div>
              </div>
            </el-col>
            <el-col :span="24" style="margin-top:8px">
              <div class="state-box pending">
                <div class="state-label">待发送</div>
                <div class="state-num">{{ formatInt(overview.totalPending) }}</div>
              </div>
            </el-col>
          </el-row>
        </el-card>
      </el-col>
    </el-row>

    <el-row style="margin-top:16px">
      <el-col :span="24">
        <el-card shadow="never" class="chart-card" v-loading="dailyLoading">
          <div slot="header" class="card-head">
            <div>
              <span class="card-title-text">发送量趋势</span>
            </div>
            <el-button type="text" icon="el-icon-refresh" :loading="dailyLoading" @click="loadDaily">刷新</el-button>
          </div>
          <div id="chartSendDailyHome" class="send-chart-box" />
        </el-card>
      </el-col>
    </el-row>

    <el-row style="margin-top:16px">
      <el-col :span="24">
        <el-card shadow="never" v-loading="dailyLoading">
          <div slot="header" class="card-head">
            <div>
              <span class="card-title-text">日发送明细</span>
            </div>
            <el-button type="text" icon="el-icon-refresh" :loading="dailyLoading" @click="loadDaily">刷新</el-button>
          </div>
          <el-table :data="dailyList" size="small" :empty-text="dailyEmptyText">
            <el-table-column label="日期" prop="statDate" width="120" fixed />
            <el-table-column label="总发送" align="right">
              <template slot-scope="scope">{{ formatInt(scope.row.totalCount) }}</template>
            </el-table-column>
            <el-table-column label="成功" align="right">
              <template slot-scope="scope">{{ formatInt(scope.row.successCount) }}</template>
            </el-table-column>
            <el-table-column label="失败" align="right">
              <template slot-scope="scope">{{ formatInt(scope.row.failCount) }}</template>
            </el-table-column>
            <el-table-column label="成功率" align="right" width="100">
              <template slot-scope="scope">
                {{ rate(scope.row) }}%
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import echarts from '@/utils/echarts'
import { getOverview, getDailyStats } from '@/api/business/dashboard'

const DAILY_DAYS = 7

export default {
  name: 'Index',
  data() {
    return {
      overview: {},
      dailyList: [],
      charts: [],
      overviewLoading: false,
      dailyLoading: false,
      dailyDays: DAILY_DAYS
    }
  },
  computed: {
    sendOutcomeTotal() {
      const s = Number(this.overview.totalSuccess || 0)
      const f = Number(this.overview.totalFail || 0)
      return s + f
    },
    successRateDisplay() {
      return Number((this.overview.successRate || 0).toFixed(2))
    },
    cardList() {
      const o = this.overview
      return [
        {
          key: 'task',
          label: '发送任务',
          display: this.formatInt(o.totalTask)
        },
        {
          key: 'tpl',
          label: '短信模板',
          display: this.formatInt(o.templateCount)
        },
        {
          key: 'contact',
          label: '联系人',
          display: this.formatInt(o.contactCount)
        },
        {
          key: 'bal',
          label: '账户余额',
          display: this.formatBalance(o.totalBalance)
        }
      ]
    },
    successColor() {
      const p = this.overview.successRate || 0
      if (p >= 95) return '#67c23a'
      if (p >= 80) return '#e6a23c'
      return '#f56c6c'
    },
    dailyEmptyText() {
      return this.dailyLoading ? '加载中…' : '暂无数据'
    }
  },
  created() {
    this.loadOverview()
    this.loadDaily()
  },
  mounted() {
    window.addEventListener('resize', this.onChartResize)
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.onChartResize)
    this.disposeCharts()
  },
  methods: {
    formatInt(v) {
      if (v === null || v === undefined || v === '') return '0'
      const n = Number(v)
      if (Number.isNaN(n)) return String(v)
      return n.toLocaleString('zh-CN', { maximumFractionDigits: 0 })
    },
    formatBalance(v) {
      if (v === null || v === undefined || v === '') return '0.00'
      const n = Number(v)
      if (Number.isNaN(n)) return String(v)
      return n.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
    },
    loadOverview() {
      this.overviewLoading = true
      getOverview()
        .then(res => {
          this.overview = res.data || {}
        })
        .finally(() => {
          this.overviewLoading = false
        })
    },
    loadDaily() {
      this.dailyLoading = true
      getDailyStats(DAILY_DAYS)
        .then(res => {
          this.dailyList = res.data || []
          this.$nextTick(() => {
            this.disposeCharts()
            this.renderSendTrend(this.dailyList)
          })
        })
        .finally(() => {
          this.dailyLoading = false
        })
    },
    disposeCharts() {
      this.charts.forEach(c => {
        try { c.dispose() } catch (e) {}
      })
      this.charts = []
    },
    renderSendTrend(rows) {
      const el = document.getElementById('chartSendDailyHome')
      if (!el) return
      const list = rows || []
      const chart = echarts.init(el)
      this.charts.push(chart)
      const dates = list.map(r => r.statDate)
      if (!list.length) {
        chart.setOption({
          graphic: [{
            type: 'text',
            left: 'center',
            top: 'middle',
            style: { text: '暂无数据', fill: '#C0C4CC', fontSize: 14 }
          }]
        })
        return
      }
      chart.setOption({
        tooltip: {
          trigger: 'axis',
          axisPointer: { type: 'cross' },
          formatter: params => {
            if (!params || !params.length) return ''
            const head = params[0].axisValue
            const lines = params.map(
              p => `${p.marker} ${p.seriesName}：<b>${this.formatInt(p.value)}</b> 条`
            )
            return `${head}<br/>${lines.join('<br/>')}`
          }
        },
        legend: { data: ['总发送', '成功', '失败'], bottom: 0 },
        grid: { left: '3%', right: '4%', bottom: '12%', top: '12%', containLabel: true },
        xAxis: {
          type: 'category',
          data: dates,
          boundaryGap: false,
          axisLabel: { rotate: dates.length > 10 ? 30 : 0 }
        },
        yAxis: {
          type: 'value',
          minInterval: 1,
          name: '条',
          nameTextStyle: { color: '#909399', fontSize: 11 }
        },
        series: [
          {
            name: '总发送',
            type: 'line',
            smooth: true,
            data: list.map(r => Number(r.totalCount || 0)),
            itemStyle: { color: '#409EFF' },
            symbolSize: 6
          },
          {
            name: '成功',
            type: 'line',
            smooth: true,
            data: list.map(r => Number(r.successCount || 0)),
            itemStyle: { color: '#67C23A' },
            symbolSize: 6
          },
          {
            name: '失败',
            type: 'line',
            smooth: true,
            data: list.map(r => Number(r.failCount || 0)),
            itemStyle: { color: '#F56C6C' },
            symbolSize: 6
          }
        ]
      })
    },
    rate(row) {
      const t = Number(row.totalCount || 0)
      const s = Number(row.successCount || 0)
      if (t <= 0) return '0.00'
      return ((s * 100) / t).toFixed(2)
    },
    onChartResize() {
      this.charts.forEach(c => {
        try {
          c.resize()
        } catch (e) {}
      })
    }
  }
}
</script>

<style scoped>
.home-overview {
  padding-bottom: 24px;
}

.page-head {
  margin-bottom: 20px;
}

.page-title {
  margin: 0 0 8px;
  font-size: 20px;
  font-weight: 600;
  color: #303133;
}

.metric-card {
  border-radius: 12px;
  min-height: 108px;
}

.metric-label {
  color: #909399;
  font-size: 13px;
  display: flex;
  align-items: center;
  gap: 4px;
}

.metric-value {
  margin-top: 10px;
  font-size: 28px;
  font-weight: 700;
  color: #303133;
  letter-spacing: -0.02em;
}

.panel-card ::v-deep .el-card__header {
  padding: 12px 16px;
}

.panel-header {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.gauge-wrap {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
  gap: 24px;
  padding: 8px 0 4px;
}

.gauge-meta {
  text-align: left;
  max-width: 280px;
}

.gauge-rate {
  margin: 0 0 8px;
  font-size: 18px;
  font-weight: 600;
  color: #303133;
}

.gauge-foot {
  margin: 0;
  font-size: 12px;
  color: #909399;
  line-height: 1.5;
}

.state-box {
  padding: 12px 10px;
  border-radius: 8px;
  text-align: center;
}

.state-label {
  font-size: 12px;
  opacity: 0.9;
  margin-bottom: 6px;
}

.state-num {
  font-size: 22px;
  font-weight: 700;
}

.state-box.ok {
  background: #f0f9eb;
  color: #67c23a;
}

.state-box.err {
  background: #fef0f0;
  color: #f56c6c;
}

.state-box.pending {
  background: #f4f4f5;
  color: #909399;
}

.chart-card {
  margin-bottom: 0;
}

.send-chart-box {
  height: 340px;
  width: 100%;
}

.card-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-title-text {
  font-weight: 600;
  color: #303133;
}
</style>
