<template>
  <div class="app-container">
    <el-card shadow="never">
      <div slot="header" class="clearfix">
        <span>短信模板管理</span>
      </div>

      <el-row :gutter="10" class="mb8">
        <el-col :span="6">
          <el-input v-model="queryParams.templateName" placeholder="名称" clearable size="small" @keyup.enter.native="handleQuery" />
        </el-col>
        <el-col :span="6">
          <el-select v-model="queryParams.templateType" placeholder="类型" clearable size="small" style="width: 100%">
            <el-option label="普通" value="0" />
            <el-option label="营销" value="1" />
            <el-option label="通知" value="2" />
          </el-select>
        </el-col>
        <el-col :span="12">
          <el-button type="primary" icon="el-icon-search" size="mini" @click="handleQuery">搜索</el-button>
          <el-button icon="el-icon-refresh" size="mini" @click="resetQuery">重置</el-button>
          <el-button type="success" icon="el-icon-plus" size="mini" @click="handleAdd">新增模板</el-button>
          <el-button type="danger" icon="el-icon-delete" size="mini" :disabled="ids.length === 0" @click="handleBatchDelete">批量删除</el-button>
          <el-button type="warning" icon="el-icon-download" size="mini" @click="handleExport">导出</el-button>
        </el-col>
      </el-row>

      <el-table v-loading="loading" :data="templateList" @selection-change="handleSelectionChange">
        <el-table-column type="selection" width="55" />
        <el-table-column label="ID" prop="id" width="80" />
        <el-table-column label="模板名称" prop="templateName" width="200" />
        <el-table-column label="类型" width="100">
          <template slot-scope="scope">
            <el-tag size="mini" :type="scope.row.templateType === '1' ? 'warning' : (scope.row.templateType === '2' ? 'success' : 'info')">
              {{ typeLabel(scope.row.templateType) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100">
          <template slot-scope="scope">
            <el-tag size="mini" :type="scope.row.status === '0' ? 'success' : 'danger'">
              {{ scope.row.status === '0' ? '正常' : '停用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="关联任务" prop="refTaskId" width="100" align="center">
          <template slot-scope="scope">
            <span>{{ scope.row.refTaskId != null ? scope.row.refTaskId : '—' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="内容" prop="templateContent" show-overflow-tooltip />
        <el-table-column label="使用次数" prop="useCount" width="100" />
        <el-table-column label="创建时间" prop="createTime" width="180" />
        <el-table-column label="操作" width="180" fixed="right">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handleUpdate(scope.row)">编辑</el-button>
            <el-button size="mini" type="text" @click="handleUse(scope.row)">使用</el-button>
            <el-button size="mini" type="text" style="color:#f56c6c" @click="handleDelete(scope.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <pagination v-show="total > 0" :total="total" :page.sync="queryParams.pageNum" :limit.sync="queryParams.pageSize" @pagination="getList" />
    </el-card>

    <el-dialog :title="title" :visible.sync="open" width="680px" append-to-body>
      <el-form ref="form" :model="form" :rules="rules" label-width="90px">
        <template v-if="title === '新增模板'">
          <el-form-item label="选择日期">
            <el-date-picker
              v-model="refTaskDate"
              type="date"
              value-format="yyyy-MM-dd"
              placeholder="选日期"
              :clearable="false"
              style="width: 100%;"
              @change="onRefTaskDateChange"
            />
          </el-form-item>
          <el-form-item label="任务编号">
            <el-select
              v-model="refTaskNo"
              filterable
              clearable
              :loading="refTaskIdLoading"
              :disabled="!refTaskDate"
              placeholder="任务号"
              style="width: 100%;"
              @change="onRefTaskNoChange"
            >
              <el-option v-for="tid in refTaskIdOptions" :key="tid" :label="tid" :value="tid" />
            </el-select>
          </el-form-item>
        </template>
        <el-form-item v-else-if="form.refTaskId != null" label="关联任务">
          <span>ID {{ form.refTaskId }}</span>
        </el-form-item>
        <el-form-item label="模板名称" prop="templateName">
          <el-input v-model="form.templateName" maxlength="100" />
        </el-form-item>
        <el-form-item label="模板类型" prop="templateType">
          <el-radio-group v-model="form.templateType">
            <el-radio label="0">普通</el-radio>
            <el-radio label="1">营销</el-radio>
            <el-radio label="2">通知</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="form.status">
            <el-radio label="0">正常</el-radio>
            <el-radio label="1">停用</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="模板内容" prop="templateContent">
          <el-input type="textarea" :rows="6" v-model="form.templateContent" placeholder="正文" />
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
import { listTemplate, addTemplate, updateTemplate, delTemplate, exportTemplate, listTemplateTaskIdOptions, getSendTaskContentForTemplate } from '@/api/business/template'

export default {
  name: 'SmsTemplate',
  data() {
    return {
      loading: false,
      total: 0,
      templateList: [],
      ids: [],
      title: '',
      open: false,
      queryParams: {
        pageNum: 1,
        pageSize: 10,
        templateName: null,
        templateType: null
      },
      refTaskDate: null,
      refTaskNo: '',
      refTaskIdOptions: [],
      refTaskIdLoading: false,
      form: {
        id: null,
        templateName: '',
        templateContent: '',
        templateType: '0',
        status: '0',
        refTaskId: null
      },
      rules: {
        templateName: [{ required: true, message: '请输入模板名称', trigger: 'blur' }],
        templateContent: [{ required: true, message: '请输入模板内容', trigger: 'blur' }]
      }
    }
  },
  created() {
    this.getList()
  },
  methods: {
    typeLabel(v) {
      return v === '1' ? '营销' : (v === '2' ? '通知' : '普通')
    },
    getList() {
      this.loading = true
      listTemplate(this.queryParams).then(res => {
        this.templateList = res.rows || []
        this.total = res.total || 0
        this.loading = false
      }).catch(() => {
        this.loading = false
      })
    },
    defaultTaskDateStr() {
      const d = new Date()
      const y = d.getFullYear()
      const m = String(d.getMonth() + 1).padStart(2, '0')
      const day = String(d.getDate()).padStart(2, '0')
      return `${y}-${m}-${day}`
    },
    reset() {
      this.refTaskDate = null
      this.refTaskNo = ''
      this.refTaskIdOptions = []
      this.form = {
        id: null,
        templateName: '',
        templateContent: '',
        templateType: '0',
        status: '0',
        refTaskId: null
      }
    },
    onRefTaskDateChange() {
      this.refTaskNo = ''
      this.refTaskIdOptions = []
      this.form.refTaskId = null
      this.loadRefTaskIdOptions()
    },
    loadRefTaskIdOptions() {
      if (!this.refTaskDate) {
        this.refTaskIdOptions = []
        return
      }
      this.refTaskIdLoading = true
      listTemplateTaskIdOptions({ taskDate: this.refTaskDate })
        .then(res => {
          this.refTaskIdOptions = res.data || []
        })
        .catch(() => {
          this.refTaskIdOptions = []
        })
        .finally(() => {
          this.refTaskIdLoading = false
        })
    },
    onRefTaskNoChange(val) {
      if (!val) {
        this.form.refTaskId = null
        return
      }
      getSendTaskContentForTemplate(val)
        .then(res => {
          const d = res.data || {}
          this.form.templateContent = d.smsContent != null ? d.smsContent : ''
          this.form.refTaskId = d.refTaskId != null ? d.refTaskId : null
          if (!this.form.templateName) {
            this.form.templateName = '模板 ' + val
          }
        })
        .catch(() => {})
    },
    handleQuery() {
      this.queryParams.pageNum = 1
      this.getList()
    },
    resetQuery() {
      this.queryParams.templateName = null
      this.queryParams.templateType = null
      this.handleQuery()
    },
    handleAdd() {
      this.reset()
      this.title = '新增模板'
      this.refTaskDate = this.defaultTaskDateStr()
      this.open = true
      this.$nextTick(() => {
        this.loadRefTaskIdOptions()
      })
    },
    handleUpdate(row) {
      this.refTaskDate = null
      this.refTaskNo = ''
      this.refTaskIdOptions = []
      this.form = Object.assign({}, row)
      this.open = true
      this.title = '编辑模板'
    },
    handleUse(row) {
      this.$message.success('已复制模板内容，可在发送页面粘贴使用')
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(row.templateContent)
      }
    },
    submitForm() {
      this.$refs.form.validate(valid => {
        if (!valid) return
        const req = this.form.id ? updateTemplate(this.form) : addTemplate(this.form)
        req.then(() => {
          this.$message.success(this.form.id ? '修改成功' : '新增成功')
          this.open = false
          this.getList()
        })
      })
    },
    handleDelete(row) {
      this.$confirm('确认删除模板「' + row.templateName + '」吗？', '提示', { type: 'warning' }).then(() => {
        delTemplate(row.id).then(() => {
          this.$message.success('删除成功')
          this.getList()
        })
      }).catch(() => {})
    },
    handleSelectionChange(selection) {
      this.ids = selection.map(item => item.id)
    },
    handleBatchDelete() {
      this.$confirm('确认删除选中的' + this.ids.length + '个模板吗？', '提示', { type: 'warning' }).then(() => {
        delTemplate(this.ids.join(',')).then(() => {
          this.$message.success('删除成功')
          this.getList()
        })
      }).catch(() => {})
    },
    handleExport() {
      this.$confirm('确认导出模板数据吗？', '提示', { type: 'warning' }).then(() => {
        exportTemplate(this.queryParams).then(res => {
          const blob = new Blob([res])
          const url = window.URL.createObjectURL(blob)
          const a = document.createElement('a')
          a.href = url
          a.download = '短信模板.xlsx'
          a.click()
          window.URL.revokeObjectURL(url)
        })
      }).catch(() => {})
    },
    cancel() {
      this.open = false
      this.reset()
    }
  }
}
</script>

