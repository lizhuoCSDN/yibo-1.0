<template>
  <div class="app-container">
    <el-form :model="queryParams" ref="queryForm" size="small" :inline="true" v-show="showSearch" label-width="68px">
      <el-form-item label="通道名称" prop="channelName">
        <el-input
          v-model="queryParams.channelName"
          placeholder="名称"
          clearable
          @keyup.enter.native="handleQuery"
        />
      </el-form-item>
      <el-form-item label="通道编码" prop="channelCode">
        <el-input
          v-model="queryParams.channelCode"
          placeholder="编码"
          clearable
          @keyup.enter.native="handleQuery"
        />
      </el-form-item>
      <el-form-item label="状态" prop="status">
        <el-select v-model="queryParams.status" placeholder="状态" clearable>
          <el-option
            v-for="dict in dict.type.channel_status"
            :key="dict.value"
            :label="dict.label"
            :value="dict.value"
          />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="el-icon-search" size="mini" @click="handleQuery">搜索</el-button>
        <el-button icon="el-icon-refresh" size="mini" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5">
        <el-button
          type="primary"
          plain
          icon="el-icon-plus"
          size="mini"
          @click="handleAdd"
          v-hasPermi="['business:channel:add']"
        >新增</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button
          type="success"
          plain
          icon="el-icon-edit"
          size="mini"
          :disabled="single"
          @click="handleUpdate"
          v-hasPermi="['business:channel:edit']"
        >修改</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button
          type="danger"
          plain
          icon="el-icon-delete"
          size="mini"
          :disabled="multiple"
          @click="handleDelete"
          v-hasPermi="['business:channel:remove']"
        >删除</el-button>
      </el-col>
      <right-toolbar :showSearch.sync="showSearch" @queryTable="getList"></right-toolbar>
    </el-row>

    <el-table v-loading="loading" :data="channelList" @selection-change="handleSelectionChange" border size="small">
      <el-table-column type="selection" width="55" align="center" />
      <el-table-column label="主键ID" align="center" prop="id" width="72" />
      <el-table-column label="通道名称" align="center" prop="channelName" min-width="120" show-overflow-tooltip />
      <el-table-column label="通道编码" align="center" prop="channelCode" min-width="100" show-overflow-tooltip />
      <el-table-column label="对接方式" align="center" width="100">
        <template slot-scope="scope">
          <el-tag :type="connectorLabel(scope.row) === 'SMPP' ? 'warning' : 'success'" size="mini">
            {{ connectorLabel(scope.row) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="API/线路" align="center" min-width="128" show-overflow-tooltip>
        <template slot-scope="scope">
          <span class="ch-proto-label">{{ lineProtocolLabel(scope.row) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="状态" align="center" prop="status" width="88">
        <template slot-scope="scope">
          <dict-tag :options="dict.type.channel_status" :value="scope.row.status"/>
        </template>
      </el-table-column>
      <el-table-column label="成本价" align="center" width="110" show-overflow-tooltip>
        <template slot-scope="scope">
          <span>{{ formatCostPriceCol(scope.row.costPrice) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="线路使用" align="center" min-width="150" show-overflow-tooltip>
        <template slot-scope="scope">
          <span>{{ formatChannelUsageCol(scope.row) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="备注" align="center" prop="remark" min-width="100" show-overflow-tooltip />
      <el-table-column label="操作" align="center" class-name="small-padding fixed-width" min-width="260">
        <template slot-scope="scope">
          <el-button
            size="mini"
            type="text"
            icon="el-icon-view"
            @click="openDetail(scope.row)"
          >详情</el-button>
          <el-button
            size="mini"
            type="text"
            icon="el-icon-edit"
            @click="handleUpdate(scope.row)"
            v-hasPermi="['business:channel:edit']"
          >修改</el-button>
          <el-button
            size="mini"
            type="text"
            icon="el-icon-delete"
            @click="handleDelete(scope.row)"
            v-hasPermi="['business:channel:remove']"
          >删除</el-button>
          <tech-assist-button
            page-code="channel"
            page-label="通道管理"
            :ref-id="scope.row.id"
            :ref-summary="refSummaryChannel(scope.row)"
          />
        </template>
      </el-table-column>
    </el-table>

    <pagination
      v-show="total>0"
      :total="total"
      :page.sync="queryParams.pageNum"
      :limit.sync="queryParams.pageSize"
      @pagination="getList"
    />

    <!-- 供应商详情（行业常见：概览 + KPI + 分栏） -->
    <el-dialog
      :visible.sync="detailOpen"
      width="940px"
      top="2vh"
      append-to-body
      custom-class="sp-channel-detail"
      @close="onDetailClose"
    >
      <div slot="title" class="sp-ct__head">
        <div class="sp-ct__head-main">
          <i class="el-icon-office-building sp-ct__head-icon" />
          <div>
            <div class="sp-ct__head-name">{{ (detail && detail.channelName) || '—' }}</div>
            <div class="sp-ct__head-sub">供应商号 SP-{{ (detail && detail.id) != null ? detail.id : '—' }} ｜ 产品编码 <code class="ch-code ch-code--inline">{{ (detail && detail.channelCode) || '—' }}</code></div>
          </div>
        </div>
      </div>

      <div v-loading="detailLoading" class="sp-ct__body">
        <template v-if="detail && detail.id != null">
          <!-- 状态与标签（顶部信息条） -->
          <div class="sp-ct__strip">
            <div class="sp-ct__strip-item">
              <span class="sp-ct__strip-k">运营状态</span>
              <dict-tag :options="dict.type.channel_status" :value="detail.status"/>
            </div>
            <div class="sp-ct__strip-item">
              <span class="sp-ct__strip-k">对接类型</span>
              <el-tag :type="(detail.dockingType || (detailView.connectorType === 'smpp' ? 'SMPP' : 'API')) === 'SMPP' ? 'warning' : 'primary'" size="small" effect="plain">
                {{ detail.dockingType || (detailView.connectorType === 'smpp' ? 'SMPP' : 'API') }}
              </el-tag>
            </div>
            <div v-if="detailHealth" class="sp-ct__strip-item">
              <span class="sp-ct__strip-k">线路熔断</span>
              <el-tag :type="circuitTagType(detailHealth.circuitState)" size="small">
                {{ circuitLabel(detailHealth.circuitState) }}
              </el-tag>
            </div>
            <div v-if="(detail && detail.country) || (detailHealth && detailHealth.country)" class="sp-ct__strip-item">
              <span class="sp-ct__strip-k">国别(路由)</span>
              <span>{{ (detail && detail.country) || (detailHealth && detailHealth.country) || '—' }}</span>
            </div>
          </div>

          <!-- KPI 指标卡（与智能路由统计窗口一致） -->
          <el-row :gutter="12" class="sp-ct__kpi-row">
            <el-col v-for="card in detailKpiCards" :key="card.key" :xs="12" :sm="6">
              <div class="sp-ct__kpi">
                <div class="sp-ct__kpi-label">{{ card.label }}</div>
                <div class="sp-ct__kpi-value" :style="card.valueStyle || {}">{{ card.value }}</div>
              </div>
            </el-col>
          </el-row>

          <el-tabs v-model="detailTab" class="sp-ct__tabs">
            <el-tab-pane label="概览" name="ov">
              <el-descriptions :column="2" border size="small" class="sp-ct__desc">
                <el-descriptions-item label="成本价(元/条)">{{ formatCostPriceCol(detail.costPrice) }}</el-descriptions-item>
                <el-descriptions-item label="线路使用(全站)">{{ formatChannelUsageCol(detail) }}</el-descriptions-item>
                <el-descriptions-item label="创建时间" :span="1">{{ parseTime(detail.createTime) || '—' }}</el-descriptions-item>
                <el-descriptions-item label="最后更新" :span="1">{{ parseTime(detail.updateTime) || '—' }}</el-descriptions-item>
                <el-descriptions-item label="备注" :span="2">{{ detail.remark || '—' }}</el-descriptions-item>
              </el-descriptions>
            </el-tab-pane>

            <el-tab-pane label="连接与鉴权" name="auth">
              <div v-if="!detail.config" class="ch-detail-empty" />
              <template v-else-if="detailView.connectorType === 'api' && detailView.apiProvider === 'ta_sms_openapi'">
                <p class="sp-ct__protocol-title"><i class="el-icon-link" /> 国际短信 OpenAPI v2 (ta-sms)</p>
                <el-descriptions :column="1" border size="small" class="sp-ct__desc">
                  <el-descriptions-item label="根域名 (taBaseUrl)">
                    <span class="ch-mono break-all">{{ detailView.taBaseUrl || "—" }}</span>
                  </el-descriptions-item>
                  <el-descriptions-item label="通道编号 (username)">{{ detailView.taUsername || "—" }}</el-descriptions-item>
                  <el-descriptions-item label="apiKey（签名）">
                    <span class="ch-sensitive">{{ maskSensitive(detailView.taApiKeyRaw) }}</span>
                  </el-descriptions-item>
                  <el-descriptions-item label="signType">{{ detailView.taSignType || "MD5" }}</el-descriptions-item>
                  <el-descriptions-item label="spNumber">{{ detailView.taSpNumber || "—" }}</el-descriptions-item>
                  <el-descriptions-item label="发送相对路径" :span="1">
                    <span class="ch-mono">/ta-sms/openapi/submittal</span>（与 taBaseUrl 拼接）
                  </el-descriptions-item>
                  <el-descriptions-item label="余额相对路径" :span="1">
                    <span class="ch-mono">/ta-sms/openapi/balance</span>
                  </el-descriptions-item>
                </el-descriptions>
              </template>
              <template v-else-if="detailView.connectorType === 'api' && detailView.apiProvider === 'laaffic'">
                <p class="sp-ct__protocol-title"><i class="el-icon-link" /> Laaffic API v3（<a href="https://www.laaffic.com/api/sms/sendSms/" target="_blank" rel="noopener">官方说明</a>）</p>
                <el-descriptions :column="1" border size="small" class="sp-ct__desc">
                  <el-descriptions-item label="协议">LAAFFIC v3 · Sign=MD5(apiKey+apiSecret+Timestamp)</el-descriptions-item>
                  <el-descriptions-item label="发送地址">
                    <span class="ch-mono break-all">{{ detailView.sendUrl || 'https://api.laaffic.com/v3/sendSms' }}</span>
                  </el-descriptions-item>
                  <el-descriptions-item label="余额地址">
                    <span class="ch-mono break-all">{{ detailView.balanceUrl || 'https://api.laaffic.com/v3/getBalance' }}</span>
                  </el-descriptions-item>
                  <el-descriptions-item label="AppId（短信应用）">{{ detailView.laafficAppId || '—' }}</el-descriptions-item>
                  <el-descriptions-item label="Api-Key">
                    <span class="ch-sensitive">{{ maskSensitive(detailView.appKeyRaw) }}</span>
                  </el-descriptions-item>
                  <el-descriptions-item label="API Secret">
                    <span class="ch-sensitive">{{ maskSecretOnly(detailView.appSecretRaw) }}</span>
                  </el-descriptions-item>
                  <el-descriptions-item label="SenderId">{{ detailView.laafficSenderId || '—' }}</el-descriptions-item>
                </el-descriptions>
              </template>
              <template v-else-if="detailView.connectorType === 'api'">
                <p class="sp-ct__protocol-title"><i class="el-icon-link" /> HTTP 开放接口（JSON）</p>
                <el-descriptions :column="1" border size="small" class="sp-ct__desc">
                  <el-descriptions-item label="发送 / Batch 地址">
                    <span class="ch-mono break-all">{{ detailView.sendUrl || '—' }}</span>
                  </el-descriptions-item>
                  <el-descriptions-item label="余额查询地址">
                    <span class="ch-mono break-all">{{ detailView.balanceUrl || '—' }}</span>
                  </el-descriptions-item>
                  <el-descriptions-item label="appKey">
                    <span class="ch-sensitive">{{ maskSensitive(detailView.appKeyRaw) }}</span>
                  </el-descriptions-item>
                  <el-descriptions-item label="appCode">{{ detailView.appCode || '—' }}</el-descriptions-item>
                  <el-descriptions-item label="appSecret">
                    <span class="ch-sensitive">{{ maskSecretOnly(detailView.appSecretRaw) }}</span>
                  </el-descriptions-item>
                  <el-descriptions-item label="扩展码 extend">{{ detailView.extend || '—' }}</el-descriptions-item>
                </el-descriptions>
              </template>
              <template v-else-if="detailView.connectorType === 'smpp' && detailView.smppProvider === 'laaffic'">
                <p class="sp-ct__protocol-title">
                  <i class="el-icon-connection" /> Laaffic SMPP（<a href="https://www.laaffic.com/api/sms/" target="_blank" rel="noopener">平台文档</a>）
                </p>
                <p class="ch-hint ch-hint--sm">对接域名 <span class="ch-mono">smpp.laaffic.com</span>、端口 <strong>8001</strong>。用户名=API Key，密码=API Secret（与 HTTP 接口相同；在客户端中查看或新增 SMPP 鉴权）。</p>
                <el-descriptions :column="2" border size="small" class="sp-ct__desc">
                  <el-descriptions-item label="API Key（bind 用户名）" :span="2">
                    <span class="ch-sensitive">{{ maskSensitive(detailView.smppSystemIdRaw) }}</span>
                  </el-descriptions-item>
                  <el-descriptions-item label="对接主机" :span="2">
                    <span class="ch-mono">{{ detailView.host || 'smpp.laaffic.com' }}</span>
                  </el-descriptions-item>
                  <el-descriptions-item label="对接端口">{{ detailView.port != null ? detailView.port : '—' }}</el-descriptions-item>
                  <el-descriptions-item label="CPS 限制">{{ detailView.cps != null ? detailView.cps + ' 条/秒' : '—' }}</el-descriptions-item>
                  <el-descriptions-item label="system_type">{{ detailView.smppSystemType || '—' }}</el-descriptions-item>
                  <el-descriptions-item label="service_type">{{ detailView.smppServiceType || '—' }}</el-descriptions-item>
                  <el-descriptions-item label="源号码" :span="2">{{ detailView.smppSourceAddr || '—' }}</el-descriptions-item>
                  <el-descriptions-item label="API Secret（bind 密码）" :span="2">
                    <span class="ch-sensitive">{{ maskSecretOnly(detailView.passwordRaw) }}</span>
                  </el-descriptions-item>
                </el-descriptions>
              </template>
              <template v-else-if="detailView.connectorType === 'smpp'">
                <p class="sp-ct__protocol-title"><i class="el-icon-connection" /> SMPP 3.3 / 3.4（本系统以 ESME 连接上游）</p>
                <el-descriptions :column="2" border size="small" class="sp-ct__desc">
                  <el-descriptions-item label="系统号" :span="2">
                    <span class="ch-sensitive">{{ maskSensitive(detailView.smppSystemIdRaw) }}</span>
                  </el-descriptions-item>
                  <el-descriptions-item label="对端 IP / 主机" :span="2">
                    <span class="ch-mono">{{ detailView.host || '—' }}</span>
                  </el-descriptions-item>
                  <el-descriptions-item label="端口">{{ detailView.port != null ? detailView.port : '—' }}</el-descriptions-item>
                  <el-descriptions-item label="CPS 限制">{{ detailView.cps != null ? detailView.cps + ' 条/秒' : '—' }}</el-descriptions-item>
                  <el-descriptions-item label="system_type">{{ detailView.smppSystemType || '—' }}</el-descriptions-item>
                  <el-descriptions-item label="service_type">{{ detailView.smppServiceType || '—' }}</el-descriptions-item>
                  <el-descriptions-item label="源号码" :span="2">{{ detailView.smppSourceAddr || '—' }}</el-descriptions-item>
                  <el-descriptions-item label="SMPP 密码" :span="2">
                    <span class="ch-sensitive">{{ maskSecretOnly(detailView.passwordRaw) }}</span>
                  </el-descriptions-item>
                </el-descriptions>
              </template>
            </el-tab-pane>

            <el-tab-pane label="容量与监控" name="ops">
              <template v-if="detailHealth">
                <el-descriptions :column="2" border size="small" class="sp-ct__desc">
                  <el-descriptions-item label="路由权重" :span="1">{{ detailHealth.weight != null ? detailHealth.weight : '—' }}</el-descriptions-item>
                  <el-descriptions-item label="路由优先级" :span="1">{{ detailHealth.priority != null ? detailHealth.priority : '—' }}</el-descriptions-item>
                  <el-descriptions-item label="成功 / 失败 / 本窗合计" :span="2">
                    <span style="color:#67c23a">{{ detailHealth.successCount != null ? detailHealth.successCount : 0 }}</span>
                    ／
                    <span style="color:#f56c6c">{{ detailHealth.failCount != null ? detailHealth.failCount : 0 }}</span>
                    ／
                    <span>{{ detailHealth.totalCount != null ? detailHealth.totalCount : 0 }}</span>
                  </el-descriptions-item>
                  <el-descriptions-item label="成功率" :span="1">
                    <span :style="{ color: rateColor(detailHealth.successRate) }">
                      {{ formatSuccessRate(detailHealth.successRate) }}
                    </span>
                  </el-descriptions-item>
                  <el-descriptions-item label="平均响应" :span="1">
                    {{ detailHealth.avgResponseMs != null ? detailHealth.avgResponseMs + ' ms' : '—' }}
                  </el-descriptions-item>
                  <el-descriptions-item label="统计窗口起点" :span="1">{{ parseTime(detailHealth.windowStart) || '—' }}</el-descriptions-item>
                  <el-descriptions-item label="熔断发生时间" :span="1">{{ parseTime(detailHealth.circuitOpenTime) || '—' }}</el-descriptions-item>
                </el-descriptions>
                <el-button type="text" icon="el-icon-s-operation" @click="goChannelRouter">智能路由</el-button>
              </template>
              <el-empty v-else description="暂无" :image-size="80" />
            </el-tab-pane>
          </el-tabs>
        </template>
      </div>

      <div slot="footer" class="dialog-footer">
        <el-button type="primary" plain icon="el-icon-edit" v-hasPermi="['business:channel:edit']" @click="fromDetailToEdit">编辑配置</el-button>
        <el-button @click="detailOpen = false">关 闭</el-button>
      </div>
    </el-dialog>

    <el-dialog :title="title" :visible.sync="open" width="820px" append-to-body @close="onDialogClose">
      <el-form ref="form" :model="form" :rules="rules" label-width="112px" size="small">
        <el-form-item label="通道名称" prop="channelName">
          <el-input v-model="form.channelName" placeholder="名称" />
        </el-form-item>
        <el-form-item label="通道编码" prop="channelCode">
          <el-input v-model="form.channelCode" placeholder="编码" />
        </el-form-item>
        <el-form-item label="国别(路由)" prop="country">
          <el-input
            v-model="form.country"
            placeholder="如 86、1、44，与发信号码国别一致；不填=全球/任意号码可用"
            clearable
            maxlength="32"
            show-word-limit
          />
        </el-form-item>
        <el-form-item label="对接方式">
          <el-radio-group v-model="channelCfg.connectorType" @change="onConnectorTypeChange">
            <el-radio label="api">API 对接（HTTP）</el-radio>
            <el-radio label="smpp">SMPP 对接</el-radio>
          </el-radio-group>
        </el-form-item>

        <template v-if="channelCfg.connectorType === 'api'">
          <el-alert
            type="info"
            :closable="false"
            show-icon
            class="ch-channel-api-top-alert"
            title="选「API 对接」后，在下方「API 协议」下拉里可切换：云发 / Laaffic / 国际短信(ta-sms)。国际短信为 PDF 对接说明里的 ta-sms，与云发 sendUrl+appKey 三件套不是同一套。"
          />
          <el-form-item label="API 协议">
            <el-select
              v-model="channelCfg.apiProvider"
              filterable
              placeholder="点这里展开 — 含「国际短信（ta-sms）」"
              style="width: 100%"
              @change="onApiProviderChange"
            >
              <el-option label="① 通用（原云发 / 自定义 Post JSON）" value="default" />
              <el-option label="② Laaffic v3" value="laaffic" />
              <el-option label="③ 国际短信（OpenAPI v2 / ta-sms）" value="ta_sms_openapi" />
            </el-select>
            <p class="ch-hint ch-hint--sm ch-api-provider-tip">
              国际短信使用 <span class="ch-mono">taBaseUrl</span>、<span class="ch-mono">username</span>、<span class="ch-mono">apiKey</span> 签名，路径 <span class="ch-mono">/ta-sms/openapi/…</span>。Laaffic 文档见
              <a href="https://www.laaffic.com/api/sms/sendSms/" target="_blank" rel="noopener">官方发送说明</a>。
            </p>
          </el-form-item>
          <template v-if="channelCfg.apiProvider === 'laaffic'">
            <el-divider content-position="left">Laaffic（控制台 API Key + SMS AppId）</el-divider>
            <el-form-item label="发送地址">
              <el-input v-model="channelCfg.sendUrl" placeholder="默认 https://api.laaffic.com/v3/sendSms" clearable />
            </el-form-item>
            <el-form-item label="余额地址">
              <el-input v-model="channelCfg.balanceUrl" placeholder="默认 https://api.laaffic.com/v3/getBalance" clearable />
            </el-form-item>
            <el-form-item label="AppId (短信)">
              <el-input v-model="channelCfg.laafficAppId" placeholder="账户 — App 管理中的 AppId" clearable />
            </el-form-item>
            <el-form-item label="Api-Key">
              <el-input v-model="channelCfg.appKey" placeholder="控制台的 API Key" clearable />
            </el-form-item>
            <el-form-item label="API Secret">
              <el-input v-model="channelCfg.appSecret" type="password" placeholder="与 Api-Key 配对的 Secret" show-password clearable />
            </el-form-item>
            <el-form-item label="SenderId">
              <el-input v-model="channelCfg.laafficSenderId" placeholder="选填，最大 32 字符" clearable />
            </el-form-item>
          </template>
          <template v-else-if="channelCfg.apiProvider === 'ta_sms_openapi'">
            <el-divider content-position="left">国际短信平台 (ta-sms v2，PDF 对接说明 v3.2)</el-divider>
            <p class="ch-hint ch-hint--sm">
              本系统对 <span class="ch-mono">taBaseUrl</span> 自动拼接
              <span class="ch-mono">/ta-sms/openapi/submittal</span> 与
              <span class="ch-mono">/ta-sms/openapi/balance</span>；请求头 <span class="ch-mono">ta-version: v2</span>。域名需向供应商索取。
            </p>
            <el-form-item label="API 根域名 (taBaseUrl)">
              <el-input v-model="channelCfg.taBaseUrl" placeholder="https://业务域名 无尾斜杠" clearable />
            </el-form-item>
            <el-form-item label="通道编号 (username)">
              <el-input v-model="channelCfg.taUsername" placeholder="平台单独提供的通道号" clearable />
            </el-form-item>
            <el-form-item label="apiKey (签名)">
              <el-input v-model="channelCfg.taApiKey" type="password" show-password placeholder="与 PDF 中 key=apiKey 一致" clearable />
            </el-form-item>
            <el-form-item label="signType">
              <el-select v-model="channelCfg.taSignType" style="width: 100%" placeholder="当前仅实现 MD5">
                <el-option label="MD5" value="MD5" />
              </el-select>
            </el-form-item>
            <el-form-item label="spNumber（选填）">
              <el-input v-model="channelCfg.taSpNumber" placeholder="不填则请求体不含该字段" clearable />
            </el-form-item>
          </template>
          <template v-else>
            <el-divider content-position="left">API 参数</el-divider>
            <el-form-item label="发送地址">
              <el-input v-model="channelCfg.sendUrl" placeholder="发送URL" />
            </el-form-item>
            <el-form-item label="余额查询地址">
              <el-input v-model="channelCfg.balanceUrl" placeholder="余额URL" />
            </el-form-item>
            <el-form-item label="appKey">
              <el-input v-model="channelCfg.appKey" placeholder="Key" />
            </el-form-item>
            <el-form-item label="appCode">
              <el-input v-model="channelCfg.appCode" placeholder="Code" />
            </el-form-item>
            <el-form-item label="appSecret">
              <el-input v-model="channelCfg.appSecret" type="password" placeholder="Secret" show-password />
            </el-form-item>
            <el-form-item label="扩展码 extend">
              <el-input v-model="channelCfg.extend" placeholder="扩展" />
            </el-form-item>
          </template>
        </template>

        <template v-else>
          <el-form-item label="SMPP 线路">
            <el-radio-group v-model="channelCfg.smppProvider" @change="onSmppProviderChange">
              <el-radio label="default">通用 SMPP</el-radio>
              <el-radio label="laaffic">Laaffic SMPP</el-radio>
            </el-radio-group>
            <div v-if="channelCfg.smppProvider === 'laaffic'" class="ch-hint ch-hint--sm">
              官方对接：<span class="ch-mono">smpp.laaffic.com:8001</span>。对接用户名=控制台 <strong>API Key</strong>，对接密码=<strong>API Secret</strong>，需在 LAAFFIC 客户端中查看或手动新增 SMPP 鉴权。HTTP 与 SMPP 使用同一套 Key/Secret。详见
              <a href="https://www.laaffic.com/api/sms/" target="_blank" rel="noopener">LAAFFIC 文档</a>。
            </div>
            <p v-else class="ch-hint ch-hint--sm">填「系统号 + SMPP 密码 + 主机 + 端口」。若与网页登录不同，以供应商 SMPP 文档为准。</p>
          </el-form-item>
          <el-divider content-position="left">SMPP 参数（本系统以 ESME 连上游 SMSC）</el-divider>
          <el-form-item :label="channelCfg.smppProvider === 'laaffic' ? '对接用户名（API Key）' : '系统号 system_id'">
            <el-input
              v-model="channelCfg.smppSystemId"
              :placeholder="channelCfg.smppProvider === 'laaffic' ? '与 HTTP Api-Key 相同，用于 bind' : '如 cs_xxx，bind 时与密码一起校验'"
              clearable
            />
          </el-form-item>
          <el-form-item :label="channelCfg.smppProvider === 'laaffic' ? '对接域名 / 主机' : 'IP 地址 / 主机'">
            <el-input v-model="channelCfg.smppHost" :placeholder="channelCfg.smppProvider === 'laaffic' ? '默认 smpp.laaffic.com' : 'SMSC 主机或域名'" />
          </el-form-item>
          <el-form-item :label="channelCfg.smppProvider === 'laaffic' ? '对接端口' : '端口'">
            <el-input-number v-model="channelCfg.smppPort" :min="1" :max="65535" controls-position="right" style="width:100%" />
          </el-form-item>
          <el-form-item :label="channelCfg.smppProvider === 'laaffic' ? '对接密码（API Secret）' : 'SMPP 密码'">
            <el-input
              v-model="channelCfg.smppPassword"
              type="password"
              show-password
              :placeholder="channelCfg.smppProvider === 'laaffic' ? '与 HTTP 接口的 API Secret 相同' : 'bind 密码'"
            />
          </el-form-item>
          <el-form-item label="system_type">
            <el-input v-model="channelCfg.smppSystemType" placeholder="选填，通常留空" clearable />
          </el-form-item>
          <el-form-item label="源号码 / 发件人">
            <el-input v-model="channelCfg.smppSourceAddr" placeholder="选填，部分 SMSC 要求" clearable />
          </el-form-item>
          <el-form-item label="service_type">
            <el-input v-model="channelCfg.smppServiceType" placeholder="选填，空即可；需时填如 CMT" clearable />
          </el-form-item>
          <el-form-item label="CPS 流速">
            <el-input-number v-model="channelCfg.smppCps" :min="1" :max="100000" controls-position="right" style="width:100%" />
          </el-form-item>
        </template>

        <el-form-item label="成本价(元/条)">
          <el-input-number
            v-model="channelCfg.costPrice"
            :min="0"
            :precision="4"
            :step="0.0001"
            controls-position="right"
            style="width:100%"
            placeholder="对供应商成本，选填；写入配置 JSON 的 costPrice"
          />
        </el-form-item>

        <el-form-item label="状态" prop="status">
          <el-select v-model="form.status" placeholder="状态" style="width: 100%">
            <el-option
              v-for="dict in dict.type.channel_status"
              :key="dict.value"
              :label="dict.label"
              :value="parseInt(dict.value, 10)"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="form.remark" type="textarea" :rows="2" placeholder="选填" />
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button type="primary" @click="submitForm">确 定</el-button>
        <el-button @click="cancel">取 消</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { listChannel, getChannel, getChannelDetail, delChannel, addChannel, updateChannel } from "@/api/business/channel"
import { connectorLabel, lineProtocolLabel } from '@/utils/smsChannelLabels'
import TechAssistButton from '@/components/TechAssistButton'

/** 新增通道时 API 参数应为空，由运营按实际供应商填写；不再预填示例站避免误以为是「已有数据」 */

export default {
  name: "Channel",
  components: { TechAssistButton },
  dicts: ['channel_status'],
  data() {
    return {
      loading: true,
      ids: [],
      single: true,
      multiple: true,
      showSearch: true,
      total: 0,
      channelList: [],
      title: "",
      open: false,
      /** 详情弹窗 */
      detailOpen: false,
      detailLoading: false,
      detail: {},
      /** 智能路由 joined 行（含统计 / 熔断） */
      detailHealth: null,
      detailTab: "ov",
      detailView: {
        connectorType: "api",
        apiProvider: "default",
        taBaseUrl: "",
        taUsername: "",
        taApiKeyRaw: "",
        taSignType: "MD5",
        taSpNumber: "",
        laafficAppId: "",
        laafficSenderId: "",
        sendUrl: "",
        balanceUrl: "",
        appKeyRaw: "",
        appCode: "",
        appSecretRaw: "",
        extend: "",
        host: "",
        port: null,
        cps: null,
        passwordRaw: "",
        smppSystemIdRaw: "",
        smppSystemType: "",
        smppServiceType: "",
        smppSourceAddr: "",
        smppProvider: "default"
      },
      queryParams: {
        pageNum: 1,
        pageSize: 10,
        channelName: null,
        channelCode: null,
        config: null,
        status: null
      },
      form: {},
      channelCfg: {
        connectorType: "api",
        apiProvider: "default",
        laafficAppId: "",
        laafficSenderId: "",
        costPrice: null,
        sendUrl: "",
        balanceUrl: "",
        appKey: "",
        appCode: "",
        appSecret: "",
        extend: "",
        smppSystemId: "",
        smppHost: "",
        smppPort: 2775,
        smppPassword: "",
        smppSystemType: "",
        smppSourceAddr: "",
        smppServiceType: "",
        smppCps: 50,
        smppProvider: "default",
        taBaseUrl: "",
        taUsername: "",
        taApiKey: "",
        taSignType: "MD5",
        taSpNumber: ""
      },
      rules: {
        channelName: [{ required: true, message: "通道名称不能为空", trigger: "blur" }],
        channelCode: [{ required: true, message: "通道编码不能为空", trigger: "blur" }],
        status: [{ required: true, message: "状态不能为空", trigger: "change" }]
      }
    }
  },
  created() {
    this.getList()
  },
  computed: {
    detailKpiCards() {
      const h = this.detailHealth
      const has = h != null
      const rate = has ? h.successRate : null
      return [
        {
          key: "tot",
          label: "本窗提交量",
          value: has ? (h.totalCount != null ? h.totalCount : 0) : "—"
        },
        {
          key: "rate",
          label: "窗口成功率",
          value: has ? this.formatSuccessRate(rate) : "—",
          valueStyle: has && rate != null ? { color: this.rateColor(rate) } : {}
        },
        {
          key: "lat",
          label: "平均响应时延",
          value: has && h.avgResponseMs != null ? h.avgResponseMs + " ms" : "—"
        },
        {
          key: "wp",
          label: "路由权重 / 优先级",
          value: has ? (h.weight != null ? h.weight : "—") + " / " + (h.priority != null ? h.priority : "—") : "—"
        }
      ]
    }
  },
  methods: {
    formatCostPriceCol(v) {
      if (v == null || v === "") {
        return "—"
      }
      const n = Number(v)
      if (Number.isNaN(n)) {
        return "—"
      }
      return n.toFixed(4)
    },
    formatChannelUsageCol(row) {
      if (!row) {
        return "—"
      }
      const u = row.usedTotal
      const a = row.allotTotal
      if (u == null && a == null) {
        return "—"
      }
      const uu = u != null ? Number(u) : 0
      const aa = a != null ? Number(a) : 0
      let extra = ""
      if (aa > 0) {
        extra = "（" + ((uu / aa) * 100).toFixed(1) + "%）"
      }
      return uu + " / " + aa + extra
    },
    circuitLabel(state) {
      if (state === "0" || state === 0) return "正常"
      if (state === "1" || state === 1) return "已熔断"
      if (state === "2" || state === 2) return "半开探测"
      return "—"
    },
    circuitTagType(state) {
      if (state === "0" || state === 0) return "success"
      if (state === "1" || state === 1) return "danger"
      if (state === "2" || state === 2) return "warning"
      return "info"
    },
    rateColor(rate) {
      if (rate == null) return "#606266"
      const n = Number(rate)
      if (n >= 90) return "#67c23a"
      if (n >= 70) return "#e6a23c"
      return "#f56c6c"
    },
    formatSuccessRate(rate) {
      if (rate == null) return "—"
      return Number(rate).toFixed(2) + "%"
    },
    goChannelRouter() {
      this.$router.push({ path: "/smsOps/channelRouter" }).catch(() => {})
    },
    initChannelCfg() {
      this.channelCfg = {
        connectorType: "api",
        apiProvider: "default",
        laafficAppId: "",
        laafficSenderId: "",
        costPrice: null,
        sendUrl: "",
        balanceUrl: "",
        appKey: "",
        appCode: "",
        appSecret: "",
        extend: "",
        smppSystemId: "",
        smppHost: "",
        smppPort: 2775,
        smppPassword: "",
        smppSystemType: "",
        smppSourceAddr: "",
        smppServiceType: "",
        smppCps: 50,
        smppProvider: "default",
        taBaseUrl: "",
        taUsername: "",
        taApiKey: "",
        taSignType: "MD5",
        taSpNumber: ""
      }
    },
    onSmppProviderChange(val) {
      if (val === "laaffic") {
        if (!(this.channelCfg.smppHost || "").trim()) {
          this.channelCfg.smppHost = "smpp.laaffic.com"
        }
        if (this.channelCfg.smppPort == null || this.channelCfg.smppPort < 1) {
          this.channelCfg.smppPort = 8001
        } else if (this.channelCfg.smppPort === 2775) {
          this.channelCfg.smppPort = 8001
        }
      }
    },
    onApiProviderChange(val) {
      if (val === "laaffic") {
        if (!(this.channelCfg.sendUrl || "").trim()) {
          this.channelCfg.sendUrl = "https://api.laaffic.com/v3/sendSms"
        }
        if (!(this.channelCfg.balanceUrl || "").trim()) {
          this.channelCfg.balanceUrl = "https://api.laaffic.com/v3/getBalance"
        }
      }
    },
    onConnectorTypeChange() {
      // 切换时保留两侧已填，便于改错重选
    },
    onDialogClose() {
      this.initChannelCfg()
    },
    onDetailClose() {
      this.detail = {}
      this.detailHealth = null
      this.detailTab = "ov"
    },
    /** 敏感字段仅示意，不落明文 */
    maskSensitive(val) {
      if (val == null || val === "") return "—"
      const s = String(val)
      if (s.length <= 2) return "**"
      if (s.length <= 6) return s[0] + "***" + s[s.length - 1]
      return s.slice(0, 3) + "***" + s.slice(-2)
    },
    maskSecretOnly(val) {
      if (val == null || val === "") return "—"
      return "••••••••"
    },
    refSummaryChannel(row) {
      if (!row) return ""
      return [row.channelName, row.channelCode].filter(Boolean).join(" / ") || "ID " + row.id
    },
    buildDetailView(configStr) {
      const d = {
        connectorType: "api",
        apiProvider: "default",
        taBaseUrl: "",
        taUsername: "",
        taApiKeyRaw: "",
        taSignType: "MD5",
        taSpNumber: "",
        laafficAppId: "",
        laafficSenderId: "",
        costPrice: null,
        sendUrl: "",
        balanceUrl: "",
        appKeyRaw: "",
        appCode: "",
        appSecretRaw: "",
        extend: "",
        host: "",
        port: null,
        cps: null,
        passwordRaw: "",
        smppSystemIdRaw: "",
        smppSystemType: "",
        smppServiceType: "",
        smppSourceAddr: "",
        smppProvider: "default"
      }
      if (!configStr) {
        return d
      }
      try {
        const o = JSON.parse(configStr)
        if (o && o.costPrice != null && o.costPrice !== "") {
          d.costPrice = Number(o.costPrice)
        }
        if (o && (o.connectorType === "smpp" || o.protocol === "smpp")) {
          d.connectorType = "smpp"
          d.smppProvider = o.smppProvider === "laaffic" ? "laaffic" : "default"
          d.host = o.host
          d.port = o.port != null ? o.port : null
          d.cps = o.cps != null ? o.cps : null
          d.passwordRaw = o.password
          d.smppSystemIdRaw = o.systemId != null && o.systemId !== "" ? String(o.systemId) : ""
          d.smppSystemType = o.systemType != null && o.systemType !== "" ? String(o.systemType) : ""
          d.smppServiceType = o.serviceType != null && o.serviceType !== "" ? String(o.serviceType) : ""
          d.smppSourceAddr = o.sourceAddr != null && o.sourceAddr !== "" ? String(o.sourceAddr) : ""
          return d
        }
        d.connectorType = "api"
        if (
          o &&
          (o.apiProvider === "ta_sms_openapi" ||
            o.httpAdapter === "ta_sms_openapi_v2" ||
            (o.taBaseUrl && o.username && o.apiKey))
        ) {
          d.apiProvider = "ta_sms_openapi"
          d.taBaseUrl = o.taBaseUrl != null ? String(o.taBaseUrl) : ""
          d.taUsername = o.username != null && o.username !== "" ? String(o.username) : ""
          d.taApiKeyRaw = o.apiKey != null && o.apiKey !== "" ? String(o.apiKey) : ""
          d.taSignType = o.signType != null && o.signType !== "" ? String(o.signType) : "MD5"
          d.taSpNumber = o.spNumber != null && o.spNumber !== "" ? String(o.spNumber) : ""
          return d
        }
        d.apiProvider = o.apiProvider === "laaffic" ? "laaffic" : "default"
        d.sendUrl = o.sendUrl
        d.balanceUrl = o.balanceUrl
        d.appKeyRaw = o.appKey
        d.appCode = o.appCode
        d.appSecretRaw = o.appSecret
        d.extend = o.extend != null ? String(o.extend) : ""
        d.laafficAppId = o.appId != null && o.appId !== "" ? String(o.appId) : ""
        d.laafficSenderId = o.senderId != null && o.senderId !== "" ? String(o.senderId) : ""
        return d
      } catch (e) {
        return d
      }
    },
    openDetail(row) {
      if (!row || !row.id) {
        return
      }
      this.detailOpen = true
      this.detailLoading = true
      this.detail = {}
      this.detailHealth = null
      this.detailTab = "ov"
      const applyDetailPayload = (payload) => {
        this.detail = (payload && payload.channel) || {}
        this.detailHealth = payload && payload.health != null ? payload.health : null
        this.detailView = this.buildDetailView(this.detail.config)
      }
      getChannelDetail(row.id)
        .then(res => {
          const payload = res && res.data !== undefined ? res.data : res
          applyDetailPayload(payload)
        })
        .catch(() => {
          // 老后端无 /detail/{id} 时回退为普通详情（无健康统计）
          return getChannel(row.id).then(res => {
            const d = res && res.data !== undefined ? res.data : res
            applyDetailPayload({ channel: d, health: null })
          })
        })
        .finally(() => {
          this.detailLoading = false
        })
    },
    fromDetailToEdit() {
      const row = { ...this.detail }
      this.detailOpen = false
      this.$nextTick(() => {
        this.handleUpdate(row)
      })
    },
    connectorLabel,
    lineProtocolLabel,
    applyConfigFromString(configStr) {
      this.initChannelCfg()
      if (!configStr) return
      try {
        const o = JSON.parse(configStr)
        if (o && o.costPrice != null && o.costPrice !== "") {
          this.channelCfg.costPrice = Number(o.costPrice)
        }
        if (o && (o.connectorType === "smpp" || o.protocol === "smpp")) {
          this.channelCfg.connectorType = "smpp"
          this.channelCfg.smppProvider = o.smppProvider === "laaffic" ? "laaffic" : "default"
          this.channelCfg.smppSystemId = o.systemId != null && o.systemId !== "" ? String(o.systemId) : ""
          this.channelCfg.smppHost = o.host || ""
          this.channelCfg.smppPort = o.port != null ? Number(o.port) : 2775
          this.channelCfg.smppPassword = o.password || ""
          this.channelCfg.smppSystemType = o.systemType != null ? String(o.systemType) : ""
          this.channelCfg.smppSourceAddr = o.sourceAddr != null ? String(o.sourceAddr) : ""
          this.channelCfg.smppServiceType = o.serviceType != null ? String(o.serviceType) : ""
          this.channelCfg.smppCps = o.cps != null ? Number(o.cps) : 50
        } else {
          this.channelCfg.connectorType = "api"
          if (
            o &&
            (o.apiProvider === "ta_sms_openapi" ||
              o.httpAdapter === "ta_sms_openapi_v2" ||
              (o.taBaseUrl && o.username && o.apiKey))
          ) {
            this.channelCfg.apiProvider = "ta_sms_openapi"
            this.channelCfg.taBaseUrl = o.taBaseUrl != null ? String(o.taBaseUrl) : ""
            this.channelCfg.taUsername = o.username != null && o.username !== "" ? String(o.username) : ""
            this.channelCfg.taApiKey = o.apiKey != null && o.apiKey !== "" ? String(o.apiKey) : ""
            this.channelCfg.taSignType = o.signType != null && o.signType !== "" ? String(o.signType) : "MD5"
            this.channelCfg.taSpNumber = o.spNumber != null && o.spNumber !== "" ? String(o.spNumber) : ""
          } else {
            this.channelCfg.apiProvider = o.apiProvider === "laaffic" ? "laaffic" : "default"
            this.channelCfg.sendUrl = o.sendUrl || ""
            this.channelCfg.balanceUrl = o.balanceUrl || ""
            this.channelCfg.appKey = o.appKey || ""
            this.channelCfg.appCode = o.appCode != null && o.appCode !== "" ? String(o.appCode) : ""
            this.channelCfg.appSecret = o.appSecret || ""
            this.channelCfg.extend = o.extend != null && o.extend !== "" ? String(o.extend) : ""
            this.channelCfg.laafficAppId = o.appId != null && o.appId !== "" ? String(o.appId) : ""
            this.channelCfg.laafficSenderId = o.senderId != null && o.senderId !== "" ? String(o.senderId) : ""
          }
        }
      } catch (e) {
        /* ignore */
      }
    },
    buildConfigJson() {
      const withCost = (base) => {
        base.upstreamSchema = 1
        if (this.channelCfg.costPrice != null && this.channelCfg.costPrice !== "") {
          const n = Number(this.channelCfg.costPrice)
          if (!Number.isNaN(n) && n >= 0) {
            base.costPrice = n
          }
        }
        return JSON.stringify(base)
      }
      if (this.channelCfg.connectorType === "smpp") {
        const s = {
          connectorType: "smpp",
          host: (this.channelCfg.smppHost || "").trim(),
          port: Number(this.channelCfg.smppPort) || 2775,
          systemId: (this.channelCfg.smppSystemId || "").trim(),
          password: this.channelCfg.smppPassword || "",
          cps: Number(this.channelCfg.smppCps) || 1
        }
        if (this.channelCfg.smppProvider === "laaffic") {
          s.smppProvider = "laaffic"
        }
        const st = (this.channelCfg.smppSystemType || "").trim()
        if (st) {
          s.systemType = st
        }
        const src = (this.channelCfg.smppSourceAddr || "").trim()
        if (src) {
          s.sourceAddr = src
        }
        const svc = (this.channelCfg.smppServiceType || "").trim()
        if (svc) {
          s.serviceType = svc
        }
        return withCost(s)
      }
      if (this.channelCfg.apiProvider === "laaffic") {
        const base = {
          connectorType: "api",
          apiProvider: "laaffic",
          sendUrl: (this.channelCfg.sendUrl || "").trim() || "https://api.laaffic.com/v3/sendSms",
          balanceUrl: (this.channelCfg.balanceUrl || "").trim() || "https://api.laaffic.com/v3/getBalance",
          appId: (this.channelCfg.laafficAppId || "").trim(),
          appKey: (this.channelCfg.appKey || "").trim(),
          appSecret: (this.channelCfg.appSecret || "").trim()
        }
        const sid = (this.channelCfg.laafficSenderId || "").trim()
        if (sid) {
          base.senderId = sid
        }
        return withCost(base)
      }
      if (this.channelCfg.apiProvider === "ta_sms_openapi") {
        const base = {
          connectorType: "api",
          apiProvider: "ta_sms_openapi",
          httpAdapter: "ta_sms_openapi_v2",
          taBaseUrl: (this.channelCfg.taBaseUrl || "").trim(),
          username: (this.channelCfg.taUsername || "").trim(),
          apiKey: (this.channelCfg.taApiKey || "").trim(),
          signType: (this.channelCfg.taSignType || "MD5").trim() || "MD5"
        }
        const sp = (this.channelCfg.taSpNumber || "").trim()
        if (sp) {
          base.spNumber = sp
        }
        return withCost(base)
      }
      return withCost({
        connectorType: "api",
        sendUrl: (this.channelCfg.sendUrl || "").trim(),
        balanceUrl: (this.channelCfg.balanceUrl || "").trim(),
        appKey: (this.channelCfg.appKey || "").trim(),
        appCode: (this.channelCfg.appCode || "").trim() || "1000",
        appSecret: (this.channelCfg.appSecret || "").trim(),
        extend: this.channelCfg.extend != null ? String(this.channelCfg.extend) : "123"
      })
    },
    validateConnector() {
      if (this.channelCfg.connectorType === "api") {
        if (this.channelCfg.apiProvider === "laaffic") {
          if (!(this.channelCfg.laafficAppId || "").trim()) {
            this.$message.warning("请填写 Laaffic 的 AppId（短信应用）")
            return false
          }
          if (!(this.channelCfg.appKey || "").trim()) {
            this.$message.warning("请填写 Api-Key")
            return false
          }
          if (!(this.channelCfg.appSecret || "").trim()) {
            this.$message.warning("请填写 API Secret")
            return false
          }
          return true
        }
        if (this.channelCfg.apiProvider === "ta_sms_openapi") {
          if (!(this.channelCfg.taBaseUrl || "").trim()) {
            this.$message.warning("请填写 API 根域名 (taBaseUrl)，由供应商提供")
            return false
          }
          if (!(this.channelCfg.taUsername || "").trim()) {
            this.$message.warning("请填写通道编号 (username)")
            return false
          }
          if (!(this.channelCfg.taApiKey || "").trim()) {
            this.$message.warning("请填写 apiKey")
            return false
          }
          return true
        }
        if (!(this.channelCfg.sendUrl || "").trim()) {
          this.$message.warning("请填写 API 发送地址")
          return false
        }
        if (!(this.channelCfg.balanceUrl || "").trim()) {
          this.$message.warning("请填写余额查询地址")
          return false
        }
        if (!(this.channelCfg.appKey || "").trim()) {
          this.$message.warning("请填写 appKey")
          return false
        }
        if (!(this.channelCfg.appSecret || "").trim()) {
          this.$message.warning("请填写 appSecret")
          return false
        }
        return true
      }
      if (!(this.channelCfg.smppSystemId || "").trim()) {
        this.$message.warning("请填写 SMPP 系统号 (system_id)")
        return false
      }
      if (!(this.channelCfg.smppHost || "").trim()) {
        this.$message.warning("请填写 SMPP IP 地址")
        return false
      }
      if (this.channelCfg.smppPort == null || this.channelCfg.smppPort < 1) {
        this.$message.warning("请填写有效端口")
        return false
      }
      if (!(this.channelCfg.smppPassword || "").trim()) {
        this.$message.warning("请填写 SMPP 密码")
        return false
      }
      if (this.channelCfg.smppCps == null || this.channelCfg.smppCps < 1) {
        this.$message.warning("请填写 CPS 流速（≥1）")
        return false
      }
      return true
    },
    getList() {
      this.loading = true
      listChannel(this.queryParams).then(response => {
        this.channelList = response.rows
        this.total = response.total
        this.loading = false
      })
    },
    cancel() {
      this.open = false
      this.reset()
    },
    reset() {
      this.form = {
        id: null,
        channelName: null,
        channelCode: null,
        country: null,
        config: null,
        status: 0,
        remark: null
      }
      this.initChannelCfg()
      this.resetForm("form")
    },
    handleQuery() {
      this.queryParams.pageNum = 1
      this.getList()
    },
    resetQuery() {
      this.resetForm("queryForm")
      this.handleQuery()
    },
    handleSelectionChange(selection) {
      this.ids = selection.map(item => item.id)
      this.single = selection.length !== 1
      this.multiple = !selection.length
    },
    handleAdd() {
      this.reset()
      this.open = true
      this.title = "添加短信通道"
    },
    handleUpdate(row) {
      this.reset()
      const id = row.id || this.ids
      getChannel(id).then(res => {
        this.form = res.data
        this.applyConfigFromString(this.form.config)
        this.open = true
        this.title = "修改短信通道"
      })
    },
    submitForm() {
      if (!this.validateConnector()) {
        return
      }
      this.form.config = this.buildConfigJson()
      this.$refs["form"].validate(valid => {
        if (!valid) return
        if (this.form.id != null) {
          updateChannel(this.form).then(() => {
            this.$modal.msgSuccess("修改成功")
            this.open = false
            this.getList()
          })
        } else {
          addChannel(this.form).then(() => {
            this.$modal.msgSuccess("新增成功")
            this.open = false
            this.getList()
          })
        }
      })
    },
    handleDelete(row) {
      const ids = row.id || this.ids
      this.$modal.confirm('是否确认删除短信通道管理编号为"' + ids + '"的数据项？').then(() => {
        return delChannel(ids)
      }).then(() => {
        this.getList()
        this.$modal.msgSuccess("删除成功")
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.ch-hint {
  margin-top: 8px;
  font-size: 12px;
  color: #909399;
  line-height: 1.5;
}
.ch-channel-api-top-alert {
  margin-bottom: 14px;
}
.ch-channel-api-top-alert .el-alert__content {
  line-height: 1.45;
}
.ch-api-provider-tip {
  margin-top: 6px;
}
.ch-proto-label {
  font-size: 12px;
  color: #606266;
}
.ch-hint--sm a {
  color: #409eff;
}
.ch-detail-body {
  min-height: 80px;
}

.ch-detail-block {
  margin-bottom: 16px;
}

.ch-detail-subtitle {
  font-size: 14px;
  font-weight: 600;
  color: #303133;
  margin: 16px 0 10px;
  padding-left: 8px;
  border-left: 3px solid #1890ff;
}

.ch-code {
  font-size: 13px;
  background: #f5f7fa;
  padding: 2px 8px;
  border-radius: 4px;
}

.ch-mono {
  font-family: Consolas, Menlo, Monaco, monospace;
  font-size: 12px;
}

.break-all {
  word-break: break-all;
}

.ch-sensitive {
  color: #606266;
  letter-spacing: 0.5px;
}

.ch-detail-empty {
  font-size: 13px;
  color: #909399;
  padding: 12px;
  background: #fafbfc;
  border-radius: 4px;
  border: 1px dashed #e4e7ed;
}

.ch-code--inline {
  font-size: 12px;
  padding: 0 6px;
}

/* 供应商详情 — 内容区（与行业控制台类似的信息架构） */
.sp-ct__head {
  user-select: text;
}
.sp-ct__head-main {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding-right: 28px;
}
.sp-ct__head-icon {
  font-size: 32px;
  color: #1890ff;
  margin-top: 2px;
}
.sp-ct__head-name {
  font-size: 18px;
  font-weight: 600;
  color: #1f2d3d;
  line-height: 1.3;
}
.sp-ct__head-sub {
  font-size: 12px;
  color: #909399;
  margin-top: 6px;
}
.sp-ct__body {
  min-height: 100px;
}
.sp-ct__strip {
  display: flex;
  flex-wrap: wrap;
  gap: 12px 24px;
  padding: 12px 14px;
  background: #f5f7fa;
  border-radius: 6px;
  border: 1px solid #ebeef5;
  margin-bottom: 14px;
}
.sp-ct__strip-item {
  display: flex;
  align-items: center;
  gap: 8px;
}
.sp-ct__strip-k {
  font-size: 12px;
  color: #909399;
}
.sp-ct__kpi-row {
  margin-bottom: 16px;
}
.sp-ct__kpi {
  background: #fff;
  border: 1px solid #ebeef5;
  border-radius: 8px;
  padding: 12px 14px;
  min-height: 88px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.04);
}
.sp-ct__kpi-label {
  font-size: 12px;
  color: #909399;
  margin-bottom: 6px;
}
.sp-ct__kpi-value {
  font-size: 22px;
  font-weight: 600;
  color: #303133;
  line-height: 1.2;
}
.sp-ct__tabs >>> .el-tabs__header {
  margin-bottom: 12px;
}
.sp-ct__tabs >>> .el-tabs__item {
  font-weight: 500;
}
.sp-ct__desc {
  margin-top: 4px;
}
.sp-ct__protocol-title {
  font-size: 14px;
  font-weight: 600;
  color: #303133;
  margin: 0 0 8px;
}
.sp-ct__protocol-title i {
  margin-right: 6px;
  color: #1890ff;
}
</style>

<style lang="scss">
/* 弹窗外壳（挂到 body，不用 scoped） */
.sp-channel-detail.el-dialog {
  border-radius: 10px;
  overflow: hidden;
  margin-bottom: 2vh;
}
.sp-channel-detail .el-dialog__header {
  padding: 14px 20px 8px;
  background: linear-gradient(180deg, #fafbfc 0%, #fff 100%);
  border-bottom: 1px solid #ebeef5;
}
.sp-channel-detail .el-dialog__title {
  width: 100%;
}
.sp-channel-detail .el-dialog__body {
  padding: 4px 20px 12px;
  max-height: calc(96vh - 200px);
  overflow-y: auto;
}
.sp-channel-detail .el-dialog__footer {
  border-top: 1px solid #f0f0f0;
  padding: 10px 20px 14px;
  background: #fafafa;
}
</style>
