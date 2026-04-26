<template>
  <div class="app-container statistics-page">
    <div class="page-head">
      <h2 class="page-title">统计分析</h2>
    </div>

    <el-card shadow="never" class="query-card">
      <div slot="header" class="query-card-head">
        <span>查询条件</span>
      </div>
      <el-form ref="queryForm" :model="queryParams" :rules="rules" :inline="true" size="small" label-width="88px">
        <el-form-item label="任务ID" prop="taskId">
          <el-input
            v-model="queryParams.taskId"
            clearable
            placeholder="任务Id"
            style="width:220px"
          />
        </el-form-item>
        <el-form-item label="原链接" prop="originalUrl">
          <el-input
            v-model="queryParams.originalUrl"
            clearable
            placeholder="原链接"
            style="width:320px"
          />
        </el-form-item>
        <el-form-item label="点击时间" prop="dateRange">
          <el-date-picker
            v-model="queryParams.dateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始"
            end-placeholder="结束"
            value-format="yyyy-MM-dd"
            :picker-options="dateShortcuts"
            style="width:300px"
            clearable
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" :loading="loading" @click="submitQuery">查询</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <div v-if="queried" class="query-summary">
      <el-tag size="small" type="info">任务 {{ queryParams.taskId || '—' }}</el-tag>
      <span class="summary-sep">·</span>
      <span class="summary-url" :title="queryParams.originalUrl">{{ ellipsisUrl(queryParams.originalUrl, 56) }}</span>
      <span class="summary-sep">·</span>
      <span>{{ dateRangeText }}</span>
    </div>

    <div v-if="queried" class="top-cards" v-loading="loading">
      <div class="card-item">
        <div class="card-title">
          时段内点击次数
        </div>
        <div class="card-value">{{ formatInt(overview.totalClicks) }}</div>
        <div class="card-foot">次</div>
      </div>
      <div class="card-item card-success">
        <div class="card-title">
          产生点击的短链数
        </div>
        <div class="card-value">{{ formatInt(overview.clickedLinks) }}</div>
        <div class="card-foot">条</div>
      </div>
      <div class="card-item">
        <div class="card-title">
          条均点击
        </div>
        <div class="card-value">{{ formatAvg(overview.avgClicksPerLink) }}</div>
        <div class="card-foot">次/条</div>
      </div>
    </div>

    <el-row :gutter="16" class="chart-row" v-loading="loading">
      <el-col :xs="24" :sm="24" :md="8">
        <el-card shadow="never" class="chart-card">
          <div slot="header" class="chart-card-head">
            <span>每日点击</span>
          </div>
          <div id="chartStatTrend" class="chart-box" />
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="24" :md="8">
        <el-card shadow="never" class="chart-card chart-card-gap-md">
          <div slot="header" class="chart-card-head">
            <span>点击时段</span>
          </div>
          <div id="chartStatHourly" class="chart-box" />
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="24" :md="8">
        <el-card shadow="never" class="chart-card chart-card-gap-md">
          <div slot="header" class="chart-card-head">
            <span>累计点击</span>
          </div>
          <div id="chartStatCumulative" class="chart-box" />
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import echarts from "@/utils/echarts";
import { getStatsDashboard } from "@/api/business/statistics";

export default {
  name: "SmsStatistics",
  data() {
    return {
      queried: false,
      loading: false,
      dashboardData: null,
      queryParams: {
        taskId: "",
        originalUrl: "",
        dateRange: null
      },
      rules: {
        taskId: [{ required: true, message: "请填写任务ID", trigger: "blur" }],
        originalUrl: [{ required: true, message: "请填写原链接", trigger: "blur" }],
        dateRange: [{ required: true, message: "请选择点击时间范围", trigger: "change" }]
      },
      overview: {},
      charts: [],
      dateShortcuts: {
        shortcuts: [
          {
            text: "最近7天",
            onClick(picker) {
              const end = new Date();
              const start = new Date();
              start.setTime(start.getTime() - 3600 * 1000 * 24 * 6);
              picker.$emit("pick", [start, end]);
            }
          },
          {
            text: "最近30天",
            onClick(picker) {
              const end = new Date();
              const start = new Date();
              start.setTime(start.getTime() - 3600 * 1000 * 24 * 29);
              picker.$emit("pick", [start, end]);
            }
          }
        ]
      }
    };
  },

  computed: {
    dateRangeText() {
      const r = this.queryParams.dateRange;
      if (r && r.length === 2) return `${r[0]} ~ ${r[1]}`;
      return "";
    }
  },

  methods: {
    formatInt(v) {
      if (v === null || v === undefined || v === "") return "0";
      const n = Number(v);
      if (Number.isNaN(n)) return String(v);
      return n.toLocaleString("zh-CN", { maximumFractionDigits: 0 });
    },
    formatAvg(v) {
      if (v === null || v === undefined || v === "") return "0";
      const n = Number(v);
      if (Number.isNaN(n)) return String(v);
      return n.toLocaleString("zh-CN", { minimumFractionDigits: 0, maximumFractionDigits: 2 });
    },
    ellipsisUrl(s, max) {
      const t = (s || "").trim();
      if (!t) return "—";
      if (t.length <= max) return t;
      return t.slice(0, max - 1) + "…";
    },

    cumulativeFromDaily(daily) {
      const rows = daily || [];
      let sum = 0;
      const cum = rows.map(r => {
        sum += Number(r.clickCount != null ? r.clickCount : 0);
        return sum;
      });
      return { dates: rows.map(r => r.statDate), cum };
    },

    statsRequestParams() {
      const p = {
        singleTaskScope: true,
        days: 7
      };
      p.taskId = (this.queryParams.taskId || "").trim();
      p.originalUrl = (this.queryParams.originalUrl || "").trim();
      if (this.queryParams.dateRange && this.queryParams.dateRange.length === 2) {
        p.beginTime = this.queryParams.dateRange[0];
        p.endTime = this.queryParams.dateRange[1];
      }
      return p;
    },

    submitQuery() {
      this.$refs.queryForm.validate(valid => {
        if (!valid) return;
        this.loadDashboard();
      });
    },

    resetQuery() {
      this.queryParams = { taskId: "", originalUrl: "", dateRange: null };
      this.queried = false;
      this.overview = {};
      this.dashboardData = null;
      this.$nextTick(() => {
        this.disposeCharts();
        this.renderEmptyCharts();
      });
    },

    disposeCharts() {
      this.charts.forEach(c => {
        try {
          c.dispose();
        } catch (e) {}
      });
      this.charts = [];
    },

    pushChart(elId, option) {
      const el = document.getElementById(elId);
      if (!el) return;
      const chart = echarts.init(el);
      this.charts.push(chart);
      chart.setOption(option);
    },

    axisTooltipFormatter(unit) {
      return params => {
        if (!params || !params.length) return "";
        const head = params[0].axisValue;
        const lines = params.map(p => `${p.marker} ${p.seriesName}：<b>${this.formatInt(p.value)}</b> ${unit}`);
        return `${head}<br/>${lines.join("<br/>")}`;
      };
    },

    loadDashboard() {
      this.loading = true;
      getStatsDashboard(this.statsRequestParams())
        .then(res => {
          if (res.code !== 200) {
            this.$modal.msgError(res.msg || "查询失败");
            return;
          }
          const d = res.data || {};
          this.overview = d.overview || {};
          this.dashboardData = d;
          this.queried = true;
          this.$nextTick(() => {
            this.disposeCharts();
            this.renderDataCharts(d);
          });
        })
        .finally(() => {
          this.loading = false;
        });
    },

    renderEmptyCharts() {
      this.disposeCharts();
      const hint = {
        type: "text",
        left: "center",
        top: "middle",
        style: {
          text: "暂无数据",
          fill: "#C0C4CC",
          fontSize: 13
        }
      };
      const grid = { left: "3%", right: "4%", bottom: "10%", top: "14%", containLabel: true };

      this.pushChart("chartStatTrend", {
        tooltip: { trigger: "axis" },
        legend: { data: ["每日点击"], bottom: 0 },
        grid,
        graphic: [hint],
        xAxis: { type: "category", data: [] },
        yAxis: { type: "value", minInterval: 1, name: "次", nameTextStyle: { color: "#909399", fontSize: 11 } },
        series: [
          {
            name: "每日点击",
            type: "line",
            data: [],
            smooth: true,
            itemStyle: { color: "#409EFF" }
          }
        ]
      });

      const hours = Array.from({ length: 24 }, (_, i) => i);
      this.pushChart("chartStatHourly", {
        tooltip: { trigger: "axis", axisPointer: { type: "shadow" } },
        legend: { data: ["点击次数"], bottom: 0 },
        grid,
        graphic: [hint],
        xAxis: { type: "category", data: hours.map(h => h + "时") },
        yAxis: { type: "value", minInterval: 1, name: "次", nameTextStyle: { color: "#909399", fontSize: 11 } },
        series: [{ name: "点击次数", type: "bar", data: hours.map(() => 0), itemStyle: { color: "#E6A23C" } }]
      });

      this.pushChart("chartStatCumulative", {
        tooltip: { trigger: "axis" },
        legend: { data: ["累计点击"], bottom: 0 },
        grid,
        graphic: [hint],
        xAxis: { type: "category", data: [] },
        yAxis: { type: "value", minInterval: 1, name: "次", nameTextStyle: { color: "#909399", fontSize: 11 } },
        series: [
          {
            name: "累计点击",
            type: "line",
            data: [],
            smooth: true,
            itemStyle: { color: "#67C23A" },
            areaStyle: { color: "rgba(103, 194, 58, 0.12)" }
          }
        ]
      });
    },

    renderDataCharts(d) {
      const daily = d.dailyTrend || [];
      const dates = daily.map(r => r.statDate);
      this.pushChart("chartStatTrend", {
        tooltip: {
          trigger: "axis",
          formatter: this.axisTooltipFormatter("次")
        },
        legend: { data: ["每日点击"], bottom: 0 },
        grid: { left: "3%", right: "4%", bottom: "10%", top: "14%", containLabel: true },
        xAxis: {
          type: "category",
          data: dates,
          axisLabel: { rotate: dates.length > 12 ? 30 : 0 }
        },
        yAxis: { type: "value", minInterval: 1, name: "次", nameTextStyle: { color: "#909399", fontSize: 11 } },
        series: [
          {
            name: "每日点击",
            type: "line",
            data: daily.map(r => r.clickCount),
            smooth: true,
            itemStyle: { color: "#409EFF" },
            symbolSize: 6
          }
        ]
      });

      const hourly = d.hourlyDist || [];
      const hourArr = Array.from({ length: 24 }, (_, i) => i);
      const hourMap = {};
      hourly.forEach(r => {
        hourMap[r.hourVal] = r.totalCount;
      });
      this.pushChart("chartStatHourly", {
        tooltip: {
          trigger: "axis",
          axisPointer: { type: "shadow" },
          formatter: this.axisTooltipFormatter("次")
        },
        legend: { data: ["点击次数"], bottom: 0 },
        grid: { left: "3%", right: "4%", bottom: "10%", top: "14%", containLabel: true },
        xAxis: { type: "category", data: hourArr.map(h => h + "时") },
        yAxis: { type: "value", minInterval: 1, name: "次", nameTextStyle: { color: "#909399", fontSize: 11 } },
        series: [
          {
            name: "点击次数",
            type: "bar",
            data: hourArr.map(h => hourMap[h] || 0),
            itemStyle: { color: "#E6A23C" }
          }
        ]
      });

      const { dates: cumDates, cum } = this.cumulativeFromDaily(daily);
      this.pushChart("chartStatCumulative", {
        tooltip: {
          trigger: "axis",
          formatter: this.axisTooltipFormatter("次")
        },
        legend: { data: ["累计点击"], bottom: 0 },
        grid: { left: "3%", right: "4%", bottom: "10%", top: "14%", containLabel: true },
        xAxis: {
          type: "category",
          data: cumDates,
          axisLabel: { rotate: cumDates.length > 12 ? 30 : 0 }
        },
        yAxis: { type: "value", min: 0, name: "次", nameTextStyle: { color: "#909399", fontSize: 11 } },
        series: [
          {
            name: "累计点击",
            type: "line",
            data: cum,
            smooth: true,
            itemStyle: { color: "#67C23A" },
            areaStyle: { color: "rgba(103, 194, 58, 0.15)" },
            symbolSize: 6
          }
        ]
      });
    },

    onChartResize() {
      this.charts.forEach(c => {
        try {
          c.resize();
        } catch (e) {}
      });
    }
  },

  mounted() {
    window.addEventListener("resize", this.onChartResize);
    this.$nextTick(() => {
      if (!this.dashboardData) {
        this.renderEmptyCharts();
      }
    });
  },

  beforeDestroy() {
    window.removeEventListener("resize", this.onChartResize);
    this.disposeCharts();
  }
};
</script>

<style scoped>
.statistics-page {
  padding: 20px 20px 28px;
}

.page-head {
  margin-bottom: 16px;
}

.page-title {
  margin: 0 0 8px;
  font-size: 20px;
  font-weight: 600;
  color: #303133;
}

.query-card {
  margin-bottom: 16px;
}

.query-card ::v-deep .el-card__header {
  padding: 12px 16px;
}

.query-card-head {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  gap: 10px;
  font-weight: 600;
  color: #303133;
}

.query-summary {
  margin: 0 0 16px;
  padding: 10px 14px;
  background: #f5f7fa;
  border-radius: 6px;
  font-size: 13px;
  color: #606266;
  line-height: 1.5;
  word-break: break-all;
}

.summary-sep {
  margin: 0 6px;
  color: #C0C4CC;
}

.summary-url {
  color: #409eff;
}

.top-cards {
  display: flex;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.card-item {
  flex: 1;
  min-width: 160px;
  padding: 18px 16px;
  margin-right: 12px;
  margin-bottom: 10px;
  background: #fff;
  border-radius: 8px;
  text-align: center;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.04);
  border: 1px solid #ebeef5;
}

.card-item:last-child {
  margin-right: 0;
}

.card-success {
  border-color: #e1f3d8;
}

.card-success .card-value {
  color: #67c23a;
}

.card-title {
  font-size: 13px;
  color: #909399;
}

.card-value {
  font-size: 28px;
  font-weight: 700;
  margin-top: 10px;
  color: #303133;
  letter-spacing: -0.02em;
}

.card-foot {
  margin-top: 6px;
  font-size: 12px;
  color: #C0C4CC;
}

.chart-row {
  margin-top: 4px;
}

.chart-card {
  margin-bottom: 0;
}

.chart-card ::v-deep .el-card__header {
  padding: 10px 14px;
}

.chart-card-head {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  gap: 8px;
  font-weight: 600;
  color: #303133;
}

.chart-card-gap-md {
  margin-top: 16px;
}

@media (min-width: 992px) {
  .chart-card-gap-md {
    margin-top: 0;
  }
}

.chart-box {
  height: 300px;
  width: 100%;
}
</style>
