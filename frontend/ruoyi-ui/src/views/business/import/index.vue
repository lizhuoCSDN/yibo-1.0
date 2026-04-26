<template>
  <div class="app-container import-page send-page">
    <div class="sms-page-shell">
      <div class="sms-white-card">
        <!-- 顶部工具栏：通道 | 余额(含刷新) | 上传料子 | 料子复用 -->
        <div class="sms-top-toolbar">
          <el-select
            v-model="smsSend.channelId"
            placeholder="选择通道"
            clearable
            filterable
            class="sms-tb-channel"
            @change="onSmsChannelChange"
          >
            <el-option v-for="item in channelList" :key="item.id" :label="item.channelName" :value="item.id" />
          </el-select>
          <el-select
            v-model="smsSend.selectedSids"
            multiple
            collapse-tags
            clearable
            filterable
            :disabled="!smsSend.channelId"
            :placeholder="smsSidPlaceholder"
            class="sms-tb-sid"
            @visible-change="onSidSelectVisible"
          >
            <el-option
              v-for="o in channelSidOptions"
              :key="o.value"
              :label="o.label"
              :value="o.value"
            />
          </el-select>
          <el-button type="primary" class="sms-tb-balance" icon="el-icon-refresh" @click="refreshSmsBalance">
            余额 {{ smsChannelBalance !== null ? smsChannelBalance + ' 条' : '0 条' }}
          </el-button>
          <el-upload
            ref="smsToolbarUpload"
            class="sms-tb-upload"
            action="#"
            :show-file-list="false"
            :limit="1"
            :auto-upload="false"
            :on-change="onPhoneFileChange"
            :on-remove="onPhoneFileRemove"
            accept=".txt,.csv"
          >
            <el-button type="primary" icon="el-icon-upload2">上传料子</el-button>
          </el-upload>
          <el-button type="success" plain icon="el-icon-document-copy" class="sms-tb-reuse" @click="openMaterialReuse">料子复用</el-button>
          <span v-if="phoneFileName" class="sms-tb-file-name">已选号码文件：{{ phoneFileName }}</span>
        </div>

        <el-tabs v-model="activeTab" class="sms-inner-tabs" @tab-click="handleTabClick">
          <el-tab-pane label="群发" name="mass">
            <div class="sms-mass-panel sms-mass-pro">
          <!-- 发送内容 -->
          <div class="sms-section">
            <div class="sms-send-bar">
              <div class="sms-section-title sms-send-bar-title">发送内容</div>
              <div class="sms-send-bar-right">
                <span class="sms-stats-text">共 {{ smsEncodeStats.len }} 字 | {{ smsEncodeStats.seg }} 条</span>
                <el-tag :type="smsEncodeStats.gsm ? 'success' : 'warning'" size="mini" effect="dark">{{ smsEncodeStats.gsm ? 'GSM-7' : 'UCS2' }}</el-tag>
              </div>
            </div>
            <div class="sms-textarea-panel">
              <el-input
                v-model="smsSend.smsContent"
                type="textarea"
                :autosize="{ minRows: 8, maxRows: 18 }"
                maxlength="1000"
                show-word-limit
                placeholder="请输入短信内容..."
                class="sms-main-textarea"
              />
            </div>
          </div>

          <!-- 插入变量 -->
          <div class="sms-section">
            <div class="sms-section-title">插入变量</div>
            <el-table :data="varInsertTable" border stripe size="small" class="sms-var-table">
              <el-table-column prop="name" label="变量名称" width="120" align="center" />
              <el-table-column label="设置" width="188" align="center">
                <template slot-scope="scope">
                  <template v-if="scope.row.type === 'url'">
                    <el-button
                      type="primary"
                      plain
                      size="mini"
                      class="sms-var-one-link-btn sms-var-setting-w"
                      @click="openOneLinkDialog"
                    >添加一号一链</el-button>
                  </template>
                  <template v-else-if="scope.row.type === 'var'">
                    <el-button
                      type="success"
                      plain
                      size="mini"
                      icon="el-icon-link"
                      class="sms-var-add-rand-btn sms-var-setting-w"
                      @click="openRandomLinkDialog"
                    >添加随机链接</el-button>
                  </template>
                  <template v-else-if="scope.row.type === 'template'">
                    <el-select
                      v-model="smsTemplateInsertId"
                      placeholder="选择模板"
                      clearable
                      filterable
                      size="mini"
                      class="sms-var-template-select sms-var-setting-w"
                    >
                      <el-option v-for="tp in templateOptions" :key="tp.id" :label="tp.templateName" :value="tp.id" />
                    </el-select>
                  </template>
                  <template v-else-if="scope.row.type === 'len'">
                    <el-input-number
                      v-model="varLen[scope.row.lenKey]"
                      class="sms-var-setting-w"
                      :min="1"
                      :max="32"
                      size="mini"
                      controls-position="right"
                      @change="() => {}"
                    />
                  </template>
                </template>
              </el-table-column>
              <el-table-column label="变量代码" width="140" align="center">
                <template slot-scope="scope">
                  <code v-if="scope.row.type !== 'template'" class="sms-code">{{ scope.row.codePreview }}</code>
                  <span v-else class="sms-code-placeholder">—</span>
                </template>
              </el-table-column>
              <el-table-column label="操作" width="88" align="center">
                <template slot-scope="scope">
                  <el-button type="text" class="sms-insert-link" @click="insertVarRow(scope.row)">插入</el-button>
                </template>
              </el-table-column>
              <el-table-column prop="desc" label="说明" min-width="200" show-overflow-tooltip />
            </el-table>
          </div>

          <div class="sms-submit-bar">
            <el-button size="medium" icon="el-icon-time" @click="openScheduleDialog">定时</el-button>
            <el-button type="primary" size="medium" icon="el-icon-position" :loading="smsSubmitting" @click="submitSmsSend">提交发送</el-button>
          </div>
        </div>
      </el-tab-pane>

      <el-tab-pane label="发送任务" name="tasks">
        <el-table v-loading="taskLoading" :data="taskList" border size="small">
          <el-table-column prop="taskNo" label="任务号" min-width="170" show-overflow-tooltip />
          <el-table-column prop="channelName" label="通道" width="120" />
          <el-table-column prop="totalCount" label="总数" width="72" align="center" />
          <el-table-column prop="successCount" label="成功" width="72" align="center" />
          <el-table-column prop="failCount" label="失败" width="72" align="center" />
          <el-table-column prop="pendingCount" label="待发送" width="80" align="center" />
          <el-table-column label="点击号码数" width="100" align="center">
            <template slot-scope="scope">
              <span v-if="isSendTaskOneLink(scope.row)">
                {{ scope.row.clickPhoneCount != null && scope.row.clickPhoneCount !== '' ? scope.row.clickPhoneCount : 0 }}
              </span>
              <span v-else class="sms-click-phone-na">—</span>
            </template>
          </el-table-column>
          <el-table-column prop="status" label="状态" width="88" align="center" />
          <el-table-column prop="createTime" label="创建时间" width="160" />
          <el-table-column label="操作" width="100" align="center" fixed="right">
            <template slot-scope="scope">
              <el-button v-if="scope.row.status === '0' || scope.row.status === '5'" type="text" size="mini" @click="cancelTaskRow(scope.row)">取消</el-button>
            </template>
          </el-table-column>
        </el-table>
        <pagination
          v-show="taskTotal > 0"
          :total="taskTotal"
          :page.sync="taskQuery.pageNum"
          :limit.sync="taskQuery.pageSize"
          @pagination="loadTaskList"
        />
      </el-tab-pane>

      <el-tab-pane label="发送明细" name="records">
        <el-table v-loading="recordLoading" :data="recordList" border size="small">
          <el-table-column prop="taskNo" label="任务号" min-width="150" show-overflow-tooltip />
          <el-table-column prop="phoneNumber" label="手机号" width="140" />
          <el-table-column prop="status" label="状态" width="80" align="center" />
          <el-table-column prop="smsContent" label="内容" min-width="200" show-overflow-tooltip />
          <el-table-column prop="createTime" label="创建时间" width="160" />
        </el-table>
        <pagination
          v-show="recordTotal > 0"
          :total="recordTotal"
          :page.sync="recordQuery.pageNum"
          :limit.sync="recordQuery.pageSize"
          @pagination="loadRecordList"
        />
      </el-tab-pane>
    </el-tabs>
      </div>
    </div>

    <el-dialog
      title="料子复用"
      :visible.sync="materialReuseVisible"
      width="440px"
      append-to-body
      @open="onMaterialReuseDialogOpen"
    >
      <p class="sms-reuse-tip">从「数据仓库」已有分组导入号码到当前发送任务，在已有号码或文件基础上追加。</p>
      <el-form label-width="108px">
        <el-form-item label="数据仓库分组">
          <el-select
            v-model="materialReuseGroupId"
            placeholder="请选择分组"
            filterable
            clearable
            style="width: 100%"
          >
            <el-option v-for="g in contactGroupOptions" :key="g.id" :label="g.groupName" :value="g.id" />
          </el-select>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="materialReuseVisible = false">取 消</el-button>
        <el-button type="primary" @click="confirmMaterialReuse">导入号码</el-button>
      </div>
    </el-dialog>

    <el-dialog
      title="定时发送"
      :visible.sync="scheduleDialogVisible"
      width="440px"
      append-to-body
      @open="onScheduleDialogOpen"
    >
      <el-form label-width="88px">
        <el-form-item label="发送时间">
          <el-date-picker
            v-model="scheduleForm.sendAt"
            type="datetime"
            placeholder="选择发送时间"
            value-format="yyyy-MM-dd HH:mm:ss"
            :default-time="['09:00:00']"
            style="width: 100%"
          />
        </el-form-item>
      </el-form>
      <p class="sms-schedule-hint">到达设定时间后由系统自动发送；未执行前可在「发送任务」中取消。</p>
      <div slot="footer" class="dialog-footer">
        <el-button @click="scheduleDialogVisible = false">取 消</el-button>
        <el-button type="primary" :loading="smsSubmitting" @click="confirmScheduleSend">确 定</el-button>
      </div>
    </el-dialog>

    <el-dialog
      title="添加随机链接"
      :visible.sync="randomLinkDialogVisible"
      width="520px"
      append-to-body
    >
      <el-input
        v-model="smsSend.varUrlListText"
        type="textarea"
        :rows="6"
        :placeholder="randomLinkTextareaPlaceholder"
        class="sms-random-link-textarea"
      />
      <div slot="footer" class="dialog-footer">
        <el-button @click="clearRandomLinkList">清 空</el-button>
        <el-button type="primary" @click="saveRandomLinkList">保 存</el-button>
      </div>
    </el-dialog>

    <el-dialog
      title="添加一号一链"
      :visible.sync="oneLinkDialogVisible"
      width="580px"
      append-to-body
      @open="onOneLinkDialogOpen"
    >
      <el-form label-width="98px" class="sms-one-link-form">
        <el-form-item label="选择域名" required>
          <div class="sms-one-link-field-row">
            <el-select
              v-model="smsUrlOneLink.domainIds"
              multiple
              filterable
              clearable
              collapse-tags
              placeholder="请选择域名"
              class="sms-one-link-control"
            >
              <el-option
                v-for="d in domainList"
                :key="d.id"
                :label="d.domainName"
                :value="d.id"
              />
            </el-select>
            <el-button type="primary" plain size="small" @click="handleOneLinkCheckAllDomains">一键检测</el-button>
          </div>
        </el-form-item>
        <el-form-item label="原始链接" required>
          <div class="sms-one-link-field-row">
            <el-input
              v-model="smsUrlOneLink.originalUrl"
              clearable
              placeholder="请输入原始链接（必填）"
              class="sms-one-link-control"
            />
            <el-button type="primary" plain size="small" @click="handleOneLinkCheckOriginal">检测</el-button>
          </div>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="clearOneLink">清 空</el-button>
        <el-button type="primary" @click="saveOneLink">保 存</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getChannelBalance } from "@/api/business/channel";
import { channelsForUser } from "@/api/business/channelAssign";
import { list, checkOriginal, checkAllDomains } from "@/api/business/domain";
import { listSendTask, listSendRecord, submitSendTask, cancelSendTask } from '@/api/business/sendTask'
import { listContactGroup, listContact } from '@/api/business/contact'
import { listTemplate, getTemplate } from '@/api/business/template'
const SMS_VAR_URL_LIST_KEY = "yibo_import_sms_var_url_list";
const SMS_URL_ONE_LINK_KEY = "yibo_import_sms_url_one_link";

export default {
  name: "UserLinkImport",
  data() {
    return {
      activeTab: 'mass',
      contactGroupOptions: [],
      templateOptions: [],
      /** 插入变量表「短信模板」行：选中后点插入写入发送内容 */
      smsTemplateInsertId: null,
      varLen: {
        phone: 4,
        randnum: 4,
        randstr: 4,
        randstrnum: 4
      },
      smsSend: {
        channelId: null,
        /** 多选线路 SID，与通道 config 中 sids / sidList 联动 */
        selectedSids: [],
        smsContent: '',
        phonesText: '',
        /** 添加随机「${var}」：每行一个地址，发信时随机取一条替换 */
        varUrlListText: ''
      },
      channelSidOptions: [],
      materialReuseVisible: false,
      materialReuseGroupId: null,
      scheduleDialogVisible: false,
      scheduleForm: { sendAt: null },
      randomLinkDialogVisible: false,
      /** 添加一号一链：域名多选 + 原始链接，与 ${url} 配置一致 */
      oneLinkDialogVisible: false,
      smsUrlOneLink: {
        domainIds: [],
        originalUrl: ""
      },
      phoneFileRaw: null,
      phoneFileName: '',
      smsChannelBalance: null,
      smsSubmitting: false,
      taskLoading: false,
      taskList: [],
      taskTotal: 0,
      taskQuery: { pageNum: 1, pageSize: 10 },
      recordLoading: false,
      recordList: [],
      recordTotal: 0,
      recordQuery: { pageNum: 1, pageSize: 10 },
      domainList: [],
      channelList: [],

    };
  },

  computed: {
    smsSidPlaceholder() {
      if (!this.smsSend.channelId) {
        return '选择通道后可选SID'
      }
      return '默认SID'
    },
    smsEncodeStats() {
      const t = this.smsSend.smsContent || ''
      const len = t.length
      const gsm = this.isGsm7Only(t)
      const perSeg = gsm ? 160 : 70
      const seg = len === 0 ? 0 : Math.ceil(len / perSeg)
      return { len, seg, gsm }
    },
    randomLinkTextareaPlaceholder() {
      return '每行一个地址，例如：\nhttps://a.example.com/r1\nhttps://b.example.com/campaign'
    },
    varInsertTable() {
      const v = this.varLen
      return [
        { type: 'template', name: '短信模板', codePreview: '', desc: '在「设置」中选择模板，点「插入」将模板正文写入上方「发送内容」' },
        { type: 'len', name: '手机号截取', lenKey: 'phone', codePreview: '${phone#' + v.phone + '}', desc: '从号码末尾截取指定位数' },
        { type: 'len', name: '随机数字', lenKey: 'randnum', codePreview: '${randnum#' + v.randnum + '}', desc: '0-9 随机数字' },
        { type: 'len', name: '随机字母', lenKey: 'randstr', codePreview: '${randstr#' + v.randstr + '}', desc: 'a-z / A-Z 随机字母' },
        { type: 'len', name: '随机字母数字', lenKey: 'randstrnum', codePreview: '${randstrnum#' + v.randstrnum + '}', desc: '字母与数字随机组合' },
        { type: 'var', name: '变量替换', codePreview: '${var}', desc: '从变量列表随机取值' },
        { type: 'url', name: 'URL变量', codePreview: '${url}', desc: '动态生成的短链地址' }
      ]
    }
  },

  created() {
    this.loadVarUrlListFromStorage();
    this.loadUrlOneLinkFromStorage();
    // 如果原页面有获取域名的方法
    this.getDomainList();
    this.getChannelList();
    this.loadTemplateOptions();
    this.loadContactGroupOptions()
  },

  methods: {
    isGsm7Only(s) {
      if (!s) return true
      for (let i = 0; i < s.length; i++) {
        if (s.charCodeAt(i) > 127) return false
      }
      return true
    },
    loadTemplateOptions() {
      listTemplate({ pageNum: 1, pageSize: 500 }).then(res => {
        this.templateOptions = res.rows || []
      }).catch(() => {})
    },
    loadContactGroupOptions() {
      listContactGroup({}).then(res => {
        this.contactGroupOptions = res.rows || []
      }).catch(() => {})
    },
    /** 插入变量表内：用选中模板整段替换「发送内容」 */
    applySmsTemplateFromTable() {
      if (!this.smsTemplateInsertId) {
        this.$message.warning('请先在「设置」中选择短信模板')
        return
      }
      getTemplate(this.smsTemplateInsertId).then(res => {
        const d = res.data
        if (d && d.templateContent != null) {
          this.smsSend.smsContent = d.templateContent
          this.$message.success('已插入模板到发送内容')
        }
      }).catch(() => {})
    },
    /** 将数据仓库某分组下的号码追加到 smsSend.phonesText */
    importPhonesFromGroup(groupId) {
      return listContact({ groupId, pageNum: 1, pageSize: 10000 }).then(res => {
        const rows = res.rows || []
        const lines = rows.map(r => r.phoneNumber).filter(Boolean)
        if (!lines.length) {
          this.$message.warning('该分组暂无号码')
          return Promise.reject(new Error('empty'))
        }
        const cur = (this.smsSend.phonesText || '').trim()
        const merged = cur ? cur + '\n' + lines.join('\n') : lines.join('\n')
        this.smsSend.phonesText = merged
        this.$message.success('已导入 ' + lines.length + ' 个号码')
      })
    },
    onMaterialReuseDialogOpen() {
      if (!this.contactGroupOptions.length) {
        this.loadContactGroupOptions()
      }
    },
    openMaterialReuse() {
      this.materialReuseVisible = true
    },
    confirmMaterialReuse() {
      if (!this.materialReuseGroupId) {
        this.$message.warning('请选择数据仓库分组')
        return
      }
      this.importPhonesFromGroup(this.materialReuseGroupId)
        .then(() => {
          this.materialReuseVisible = false
          this.activeTab = 'mass'
        })
        .catch(() => {})
    },
    insertVarRow(row) {
      if (row.type === 'template') {
        this.applySmsTemplateFromTable()
      } else if (row.type === 'url') {
        this.openOneLinkDialog()
      } else if (row.type === 'var') {
        this.openRandomLinkDialog()
      } else if (row.type === 'len' && row.lenKey) {
        const n = this.varLen[row.lenKey]
        const map = { phone: 'phone', randnum: 'randnum', randstr: 'randstr', randstrnum: 'randstrnum' }
        const key = map[row.lenKey]
        if (key) {
          this.insSmsVar('${' + key + '#' + n + '}')
        }
      }
    },
    handleTabClick(tab) {
      if (tab.name === 'tasks') {
        this.loadTaskList()
      } else if (tab.name === 'records') {
        this.loadRecordList()
      }
    },
    /** 从通道 config(JSON) 解析可选 SID，支持：sids:[]、sidList:[{value,label}]、sid: "a,b" */
    parseChannelSidsFromConfig(ch) {
      if (!ch || !ch.config) {
        return []
      }
      try {
        const c = typeof ch.config === 'string' ? JSON.parse(ch.config) : ch.config
        if (Array.isArray(c.sids)) {
          return c.sids.map(s => ({ value: String(s), label: String(s) }))
        }
        if (Array.isArray(c.sidList)) {
          return c.sidList.map(x =>
            typeof x === 'string'
              ? { value: x, label: x }
              : { value: String(x.value), label: (x.label != null && x.label !== '') ? String(x.label) : String(x.value) }
          )
        }
        if (typeof c.sid === 'string' && c.sid.trim()) {
          return c.sid
            .split(/[,;|\s]+/)
            .map(s => s.trim())
            .filter(Boolean)
            .map(s => ({ value: s, label: s }))
        }
      } catch (e) {
        return []
      }
      return []
    },
    syncChannelSidOptions() {
      const ch = this.channelList.find(x => x.id === this.smsSend.channelId)
      this.channelSidOptions = this.parseChannelSidsFromConfig(ch)
      this.smsSend.selectedSids = (this.smsSend.selectedSids || []).filter(s =>
        this.channelSidOptions.some(o => o.value === s)
      )
    },
    onSidSelectVisible(visible) {
      if (visible) {
        this.syncChannelSidOptions()
      }
    },
    async onSmsChannelChange() {
      const val = this.smsSend.channelId
      if (!val) {
        this.smsChannelBalance = null
        this.channelSidOptions = []
        this.smsSend.selectedSids = []
        return
      }
      this.smsSend.selectedSids = []
      this.syncChannelSidOptions()
      try {
        const res = await getChannelBalance(val)
        const bal = res && (res.data !== undefined && res.data !== null ? res.data : res)
        if (bal !== undefined && bal !== null && bal !== '') {
          this.smsChannelBalance = Number(bal)
        } else {
          this.smsChannelBalance = null
        }
      } catch (e) {
        this.smsChannelBalance = null
      }
    },
    async refreshSmsBalance() {
      if (!this.smsSend.channelId) {
        this.$message.warning('请先选择通道')
        return
      }
      await this.onSmsChannelChange()
      this.$message.success('余额已更新')
    },
    insSmsVar(s) {
      this.smsSend.smsContent = (this.smsSend.smsContent || '') + s
    },
    /** 从「添加随机链接」多行框解析为地址列表 */
    parseVarUrlLines() {
      const raw = (this.smsSend.varUrlListText || '').split(/[\n\r]+/)
      const out = []
      for (const line of raw) {
        const t = line.trim()
        if (t) out.push(t)
      }
      return out
    },
    smsContentHasVarPlaceholder() {
      const t = this.smsSend.smsContent || ''
      return t.includes('${var}') || t.includes('{var}')
    },
    smsContentHasUrlPlaceholder() {
      const t = this.smsSend.smsContent || ''
      return t.includes('${url}') || t.includes('{url}')
    },
    /** 仅「一号一链」任务在列表中展示可解读的「点击号码数」 */
    isSendTaskOneLink(row) {
      if (!row) return false
      const url = (row.originalUrl != null) ? String(row.originalUrl).trim() : ''
      if (!url) return false
      const raw = (row.domainIds != null) ? String(row.domainIds).trim() : ''
      if (raw === '' || raw === '[]' || raw === 'null') return false
      try {
        const arr = JSON.parse(raw)
        return Array.isArray(arr) && arr.length > 0
      } catch (e) {
        return false
      }
    },
    openOneLinkDialog() {
      this.oneLinkDialogVisible = true
    },
    onOneLinkDialogOpen() {
      if (!this.domainList || this.domainList.length === 0) {
        this.getDomainList()
      }
    },
    loadUrlOneLinkFromStorage() {
      try {
        const raw = localStorage.getItem(SMS_URL_ONE_LINK_KEY)
        if (!raw) return
        const o = JSON.parse(raw)
        if (o && Array.isArray(o.domainIds)) {
          this.smsUrlOneLink.domainIds = o.domainIds
        }
        if (o && typeof o.originalUrl === 'string') {
          this.smsUrlOneLink.originalUrl = o.originalUrl
        }
      } catch (e) {
        /* ignore */
      }
    },
    saveOneLink() {
      const ids = this.smsUrlOneLink.domainIds || []
      const url = (this.smsUrlOneLink.originalUrl || '').trim()
      if (!ids.length) {
        this.$message.warning('请至少选择一个域名')
        return
      }
      if (!url) {
        this.$message.warning('请输入原始链接')
        return
      }
      const payload = { domainIds: ids.slice(), originalUrl: url }
      try {
        localStorage.setItem(SMS_URL_ONE_LINK_KEY, JSON.stringify(payload))
      } catch (e) {
        this.$message.error('无法写入本地，请检查浏览器是否禁用存储')
        return
      }
      this.smsUrlOneLink.domainIds = payload.domainIds
      this.smsUrlOneLink.originalUrl = payload.originalUrl
      if (!this.smsContentHasUrlPlaceholder()) {
        this.insSmsVar('${url}')
      }
      this.oneLinkDialogVisible = false
      this.$message.success('已保存一号一链配置')
    },
    clearOneLink() {
      this.smsUrlOneLink = { domainIds: [], originalUrl: "" }
      try {
        localStorage.removeItem(SMS_URL_ONE_LINK_KEY)
      } catch (e) {
        /* ignore */
      }
      this.$message.success('已清空')
    },
    handleOneLinkCheckOriginal() {
      const u = (this.smsUrlOneLink.originalUrl || "").trim();
      if (!u) {
        return this.$message.warning("请输入原始链接");
      }
      checkOriginal(u).then(res => {
        if (res.code === 200) {
          this.$message.success("原始链接可访问");
        } else {
          this.$message.error(res.msg || "链接无法访问，请修改");
        }
      }).catch(() => {});
    },
    handleOneLinkCheckAllDomains() {
      this.handleCheckAllDomains();
    },
    openRandomLinkDialog() {
      this.randomLinkDialogVisible = true
    },
    loadVarUrlListFromStorage() {
      try {
        const t = localStorage.getItem(SMS_VAR_URL_LIST_KEY)
        if (t != null) {
          this.smsSend.varUrlListText = t
        }
      } catch (e) {
        /* ignore */
      }
    },
    saveRandomLinkList() {
      const urls = this.parseVarUrlLines()
      if (!urls.length) {
        this.$message.warning('请至少输入一个链接地址（每行一个）')
        return
      }
      try {
        localStorage.setItem(SMS_VAR_URL_LIST_KEY, this.smsSend.varUrlListText || '')
      } catch (e) {
        this.$message.error('无法写入本地，请检查浏览器是否禁用存储')
        return
      }
      if (!this.smsContentHasVarPlaceholder()) {
        this.insSmsVar('${var}')
      }
      this.randomLinkDialogVisible = false
      this.$message.success('已保存 ' + urls.length + ' 个地址')
    },
    clearRandomLinkList() {
      this.smsSend.varUrlListText = ''
      try {
        localStorage.removeItem(SMS_VAR_URL_LIST_KEY)
      } catch (e) {
        /* ignore */
      }
      this.$message.success('已清空')
    },
    onPhoneFileChange(file, fileList) {
      this.phoneFileRaw = file && file.raw ? file.raw : null
      this.phoneFileName = file && file.name ? file.name : ''
    },
    onPhoneFileRemove() {
      this.phoneFileRaw = null
      this.phoneFileName = ''
    },
    submitSmsSend() {
      this.doSubmitSend(null)
    },
    openScheduleDialog() {
      this.scheduleDialogVisible = true
    },
    onScheduleDialogOpen() {
      const d = new Date(Date.now() + 10 * 60 * 1000)
      const p = n => (n < 10 ? '0' : '') + n
      this.scheduleForm = {
        sendAt: `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:00`
      }
    },
    confirmScheduleSend() {
      if (!this.scheduleForm.sendAt) {
        this.$message.warning('请选择发送时间')
        return
      }
      const t = new Date(this.scheduleForm.sendAt.replace(/-/g, '/'))
      if (Number.isNaN(t.getTime()) || t.getTime() <= Date.now() + 60000) {
        this.$message.warning('发送时间需晚于当前时间至少约 1 分钟')
        return
      }
      this.scheduleDialogVisible = false
      this.doSubmitSend(this.scheduleForm.sendAt)
    },
    doSubmitSend(scheduleTime) {
      if (!this.smsSend.channelId) {
        this.$message.warning('请选择通道')
        return
      }
      if (!this.smsSend.smsContent || !String(this.smsSend.smsContent).trim()) {
        this.$message.warning('请输入短信内容')
        return
      }
      if (this.smsContentHasVarPlaceholder() && this.parseVarUrlLines().length === 0) {
        this.$message.warning('内容含 ${var} 时，请打开「添加随机链接」并填写至少一个地址')
        return
      }
      const hasPhones = this.smsSend.phonesText && String(this.smsSend.phonesText).trim().length > 0
      if (!hasPhones && !this.phoneFileRaw) {
        this.$message.warning('请导入/上传号码，或使用料子复用')
        return
      }
      this.smsSubmitting = true
      const fd = new FormData()
      fd.append('channelId', this.smsSend.channelId)
      fd.append('smsContent', this.smsSend.smsContent)
      if (hasPhones) {
        fd.append('phonesText', this.smsSend.phonesText)
      }
      fd.append('phoneSource', 'manual')
      if (this.phoneFileRaw) {
        fd.append('phoneFile', this.phoneFileRaw)
      }
      if (scheduleTime) {
        fd.append('scheduleTime', scheduleTime)
      }
      if (this.smsSend.selectedSids && this.smsSend.selectedSids.length) {
        fd.append('channelSids', JSON.stringify(this.smsSend.selectedSids))
      }
      const varLines = this.parseVarUrlLines()
      if (varLines.length) {
        fd.append('varUrls', varLines.join('\n'))
      }
      if (
        this.smsContentHasUrlPlaceholder() &&
        (this.smsUrlOneLink.domainIds || []).length > 0 &&
        (this.smsUrlOneLink.originalUrl || '').trim()
      ) {
        fd.append('originalUrl', (this.smsUrlOneLink.originalUrl || '').trim())
        fd.append('domainIds', JSON.stringify(this.smsUrlOneLink.domainIds))
      }
      submitSendTask(fd).then(() => {
        this.$modal.msgSuccess(scheduleTime ? '定时任务已提交' : '任务已提交')
        this.taskQuery.pageNum = 1
        this.loadTaskList()
        this.activeTab = 'tasks'
      }).finally(() => {
        this.smsSubmitting = false
      })
    },
    loadTaskList() {
      this.taskLoading = true
      listSendTask(this.taskQuery).then(res => {
        this.taskList = res.rows || []
        this.taskTotal = res.total || 0
        this.taskLoading = false
      }).catch(() => { this.taskLoading = false })
    },
    loadRecordList() {
      this.recordLoading = true
      listSendRecord(this.recordQuery).then(res => {
        this.recordList = res.rows || []
        this.recordTotal = res.total || 0
        this.recordLoading = false
      }).catch(() => { this.recordLoading = false })
    },
    cancelTaskRow(row) {
      this.$modal.confirm('确认取消该任务？').then(() => {
        return cancelSendTask(row.id)
      }).then(() => {
        this.$modal.msgSuccess('已取消')
        this.loadTaskList()
      }).catch(() => {})
    },
    getDomainList() {
      list().then(res => {
        const rows = res || []
        this.domainList = Array.isArray(rows) ? rows : []
      }).catch(() => {})
    },
    async handleCheckAllDomains() {
      try {
        await this.$confirm("系统将检测数据库中所有域名是否可访问，并自动更新失效状态。是否继续？", "警告", {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        });

        // 使用 this.$loading 创建一个遮罩 loading
        const loading = this.$loading({
          lock: true,
          text: '正在检测所有域名，请稍候...',
          spinner: 'el-icon-loading',
          background: 'rgba(0, 0, 0, 0.5)'
        });

        let res;
        try {
          res = await checkAllDomains(); // 后端接口：/domain/checkAll
        } finally {
          // 确保一定关闭 loading
          loading.close();
        }

        if (res && res.code === 200) {
          const d = res.data || {};
          this.$message.success(`检测完成：总数 ${d.total || 0}，正常 ${d.reachableCount || 0}，失效 ${d.expiredCount || 0}`);
          if (d.failedList && d.failedList.length) {
            this.$alert(
              `<div style="max-height:40vh;overflow:auto">${d.failedList.map(it => `<div>${it.domainName}</div>`).join('')}</div>`,
              '不可达域名列表',
              { dangerouslyUseHTMLString: true, confirmButtonText: '我知道了' }
            );
          }
          // 刷新域名下拉列表（你已有的方法）
          this.getDomainList && this.getDomainList();
        } else {
          this.$message.error(res.msg || '检测失败，请稍后重试');
        }
      } catch (err) {
        if (err === 'cancel') {
          // 用户取消确认
          return;
        }
        // 如果是 confirm 的 reject，也会进入这里；区分处理
        if (err && err.message) {
          // 非用户取消的异常
          this.$message.error(err.message || '操作失败');
        }
      }
    },
    getChannelList() {
      const uid = this.$store.getters && this.$store.getters.id
      if (uid == null || uid === '') {
        this.channelList = []
        this.syncChannelSidOptions()
        return
      }
      channelsForUser(uid)
        .then(res => {
          const rows = res && (res.data !== undefined ? res.data : res)
          this.channelList = Array.isArray(rows) ? rows : []
          if (this.smsSend.channelId && !this.channelList.some(c => c && c.id === this.smsSend.channelId)) {
            this.smsSend.channelId = null
          }
          this.syncChannelSidOptions()
        })
        .catch(() => {
          this.channelList = []
        })
    }
  }
};
</script>

<style scoped>
.import-page {
  padding: 16px;
  background: #f0f2f5;
  min-height: calc(100vh - 84px);
  box-sizing: border-box;
}

.send-page .sms-page-shell {
  max-width: 1200px;
  margin: 0 auto;
}

.send-page .sms-white-card {
  background: #fff;
  border-radius: 10px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.06);
  border: 1px solid #e8eaed;
  padding: 18px 22px 22px;
  margin-bottom: 16px;
}

.send-page .sms-top-toolbar {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 16px;
  padding: 12px 14px;
  background: #fafafa;
  border: 1px solid #e8e8e8;
  border-radius: 4px;
}

.send-page .sms-tb-channel {
  width: 220px;
}

.send-page .sms-tb-sid {
  min-width: 200px;
  width: 260px;
}

.send-page .sms-tb-balance {
  font-weight: 600;
}

.send-page .sms-tb-upload >>> .el-upload {
  display: inline-block;
}

.send-page .sms-tb-reuse {
  font-weight: 500;
}

.send-page .sms-reuse-tip {
  font-size: 13px;
  color: #606266;
  line-height: 1.5;
  margin: 0 0 14px;
}

.send-page .sms-inner-tabs >>> .el-tabs__header {
  margin: 0 0 16px;
  border-bottom: 1px solid #e8e8e8;
}

.send-page .sms-inner-tabs >>> .el-tabs__nav-wrap::after {
  display: none;
}

.send-page .sms-inner-tabs >>> .el-tabs__item {
  height: 44px;
  line-height: 44px;
  padding: 0 20px;
  font-size: 14px;
  color: rgba(0, 0, 0, 0.65);
}

.send-page .sms-inner-tabs >>> .el-tabs__item.is-active {
  color: #1890ff;
  font-weight: 600;
}

.send-page .sms-inner-tabs >>> .el-tabs__active-bar {
  height: 2px;
  background-color: #1890ff;
  border-radius: 1px;
}

.send-page .sms-inner-tabs >>> .el-tabs__content {
  padding: 0;
}

.send-page .sms-insert-link {
  color: #1890ff;
  padding: 0;
}

.send-page .sms-insert-link:hover {
  color: #40a9ff;
}

/* 群发：分区布局 */
.send-page .sms-mass-pro {
  max-width: 1100px;
  margin: 0 auto 16px;
  padding: 0 8px 16px;
  box-sizing: border-box;
}
.send-page .sms-section {
  margin-bottom: 20px;
}
.send-page .sms-section-title {
  font-size: 15px;
  font-weight: 600;
  color: #303133;
  margin: 0 0 12px 4px;
  padding-left: 8px;
  border-left: 3px solid #1890ff;
}
.send-page .sms-send-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 8px 12px;
  margin-bottom: 10px;
}
.send-page .sms-send-bar-title {
  margin-bottom: 0;
  flex: 0 0 auto;
}
.send-page .sms-send-bar-right {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-left: auto;
}
.send-page .sms-textarea-panel {
  border: 1px solid #e8e8e8;
  border-radius: 4px;
  padding: 10px 12px 12px;
  background: #fafafa;
}
.send-page .sms-stats-text {
  font-size: 13px;
  color: #606266;
}
.send-page .sms-main-textarea >>> .el-textarea__inner {
  font-family: 'Helvetica Neue', Helvetica, 'PingFang SC', 'Microsoft YaHei', Arial, sans-serif;
  line-height: 1.55;
}
.send-page .sms-var-table {
  width: 100%;
}
/* 「设置」列：下拉、按钮、数字框统一为列宽，视觉对齐 */
.send-page .sms-var-table .sms-var-setting-w {
  width: 100%;
  max-width: 100%;
  box-sizing: border-box;
  margin: 0 auto;
}
.send-page .sms-var-table .sms-var-setting-w.el-button {
  display: block;
}
.send-page .sms-var-table .sms-var-setting-w.el-select {
  display: block;
}
.send-page .sms-var-table .sms-var-setting-w.el-select >>> .el-input {
  display: block;
  width: 100%;
}
.send-page .sms-var-table .sms-var-setting-w.el-input-number {
  display: block;
  width: 100% !important;
}
.send-page .sms-var-table .sms-var-setting-w.el-input-number >>> .el-input {
  display: block;
  width: 100%;
}
.send-page .sms-var-table .sms-var-setting-w.el-input-number >>> .el-input__inner {
  text-align: left;
}
.send-page .sms-code {
  font-family: Consolas, 'Courier New', monospace;
  font-size: 12px;
  color: #e6a23c;
  background: #fdf6ec;
  padding: 2px 6px;
  border-radius: 3px;
}
.send-page .sms-code-placeholder {
  color: #c0c4cc;
  font-size: 13px;
}
.send-page .sms-var-template-select {
  min-width: 0;
  display: block;
}
.send-page .sms-set-hint {
  font-size: 13px;
  color: #606266;
}
.sms-random-link-textarea >>> .el-textarea__inner {
  font-family: inherit;
  font-size: 13px;
  line-height: 1.5;
}
.sms-one-link-form .el-form-item {
  margin-bottom: 16px;
}
.sms-one-link-field-row {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
}
.sms-one-link-control {
  flex: 1;
  min-width: 0;
}
.send-page .sms-var-one-link-btn {
  font-weight: 500;
}
.send-page .sms-var-add-rand-btn {
  font-weight: 500;
}
.send-page .sms-tb-file-name {
  font-size: 12px;
  color: #606266;
  max-width: 220px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.send-page .sms-submit-bar {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
  padding: 8px 0 0;
}
.send-page .sms-submit-bar .el-button {
  min-width: 120px;
}
.send-page .sms-schedule-hint {
  font-size: 12px;
  color: #909399;
  line-height: 1.5;
  margin: 0;
  padding: 0 4px 8px;
}

.send-page .sms-submit-bar .el-button--primary {
  background-color: #1890ff;
  border-color: #1890ff;
}

.send-page .sms-submit-bar .el-button--primary:hover {
  background-color: #40a9ff;
  border-color: #40a9ff;
}

</style>
