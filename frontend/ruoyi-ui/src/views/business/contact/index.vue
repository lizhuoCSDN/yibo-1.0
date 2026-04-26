<template>
  <div class="app-container contact-warehouse">
    <el-card class="group-panel" :body-style="{ padding: '0' }" shadow="hover">
      <div class="group-panel__toolbar">
        <el-input
          v-model="groupQuery.groupName"
          class="group-panel__search"
          placeholder="分组名"
          clearable
          size="small"
          prefix-icon="el-icon-search"
          @keyup.enter.native="loadGroups"
          @clear="loadGroups"
        />
        <el-button type="primary" size="small" round icon="el-icon-plus" @click="openGroupDialog()">新增分组</el-button>
      </div>
      <el-table
        v-loading="groupLoading"
        :data="groupList"
        class="group-table"
        size="small"
        stripe
        :header-cell-style="groupTableHeaderStyle"
        :row-class-name="groupTableRowClass"
      >
        <el-table-column prop="groupName" label="分组名称" min-width="120" show-overflow-tooltip />
        <el-table-column prop="contactCount" label="联系人数量" width="110" align="center" />
        <el-table-column label="操作" min-width="400" align="left">
          <template slot-scope="scope">
            <div class="group-ops" @click.stop>
              <div class="group-ops__line">
                <el-tooltip content="修改分组名称" placement="top" :open-delay="400">
                  <el-button
                    type="primary"
                    plain
                    size="mini"
                    icon="el-icon-edit"
                    @click="openGroupDialog(scope.row)"
                  >编辑分组</el-button>
                </el-tooltip>
                <el-tooltip content="删除该分组及组内全部联系人" placement="top" :open-delay="400">
                  <el-button
                    type="danger"
                    plain
                    size="mini"
                    icon="el-icon-delete"
                    @click="handleGroupDelete(scope.row)"
                  >删除分组</el-button>
                </el-tooltip>
              </div>
              <el-divider direction="vertical" class="group-ops__divider" />
              <div class="group-ops__line">
                <el-tooltip content="查看该组联系人列表" placement="top" :open-delay="400">
                  <el-button
                    type="primary"
                    size="mini"
                    icon="el-icon-s-data"
                    @click="openContactListDialog(scope.row)"
                  >查询数据</el-button>
                </el-tooltip>
                <el-tooltip content="从文本文件批量导入" placement="top" :open-delay="400">
                  <el-button
                    type="default"
                    size="mini"
                    icon="el-icon-upload2"
                    @click="openImportDialog(scope.row)"
                  >导入数据</el-button>
                </el-tooltip>
                <el-tooltip content="清空该组全部联系人，分组保留" placement="top" :open-delay="400">
                  <el-button
                    type="warning"
                    plain
                    size="mini"
                    icon="el-icon-document-delete"
                    @click="handleClearGroupContacts(scope.row)"
                  >删除数据</el-button>
                </el-tooltip>
              </div>
            </div>
          </template>
        </el-table-column>
        <template slot="empty">
          <div class="table-empty">
            <i class="el-icon-box" />
            <p>暂无分组，点击「新增分组」开始</p>
          </div>
        </template>
      </el-table>
    </el-card>

    <el-dialog
      :title="'联系人列表 — ' + (listDialogGroup && listDialogGroup.groupName ? listDialogGroup.groupName : '')"
      :visible.sync="contactListDialogVisible"
      width="520px"
      append-to-body
      custom-class="contact-list-dialog"
      @close="onContactListDialogClose"
    >
      <div v-if="listDialogGroup" class="contact-list-wrap">
        <el-table
          v-loading="contactLoading"
          :data="contactList"
          class="inner-contact-table"
          size="small"
          stripe
          :header-cell-style="groupTableHeaderStyle"
          max-height="420"
        >
          <el-table-column prop="phoneNumber" label="手机号" min-width="160" show-overflow-tooltip />
          <el-table-column prop="createTime" label="创建时间" min-width="160" />
        </el-table>
        <pagination
          v-show="contactTotal > 0"
          :total="contactTotal"
          :page.sync="contactQuery.pageNum"
          :limit.sync="contactQuery.pageSize"
          @pagination="loadContacts"
        />
      </div>
    </el-dialog>

    <el-dialog
      :title="'导入数据 — ' + (importTargetGroup && importTargetGroup.groupName ? importTargetGroup.groupName : '')"
      :visible.sync="importDialogVisible"
      width="560px"
      append-to-body
      @close="onImportDialogClose"
    >
      <el-tabs v-model="importTab" type="card" class="import-dialog-tabs" @tab-click="onImportTabClick">
        <el-tab-pane label="文本文件" name="file">
          <el-upload
            v-if="importTargetGroup"
            ref="importUpload"
            drag
            action="#"
            :show-file-list="true"
            :limit="1"
            accept=".txt,.csv,.log"
            :http-request="submitImport"
          >
            <i class="el-icon-upload" />
            <div class="el-upload__text">将文件拖到此处，或 <em>点击上传</em></div>
          </el-upload>
        </el-tab-pane>
        <el-tab-pane label="按任务编号" name="task">
          <el-form
            v-if="importTargetGroup"
            ref="importTaskFormRef"
            :model="importTaskForm"
            :rules="importTaskRules"
            label-width="108px"
            size="small"
            class="import-task-form"
          >
            <el-form-item label="选择日期" prop="taskDate">
              <el-date-picker
                v-model="importTaskForm.taskDate"
                type="date"
                value-format="yyyy-MM-dd"
                placeholder="选日期"
                :clearable="false"
                style="width: 100%;"
                @change="onImportTaskDateChange"
              />
            </el-form-item>
            <el-form-item label="任务编号" prop="taskId">
              <el-select
                v-model="importTaskForm.taskId"
                filterable
                clearable
                :loading="importTaskIdLoading"
                :disabled="!importTaskForm.taskDate"
                placeholder="任务号"
                style="width: 100%;"
              >
                <el-option
                  v-for="tid in importTaskIdOptions"
                  :key="tid"
                  :label="tid"
                  :value="tid"
                />
              </el-select>
            </el-form-item>
            <el-form-item label="设备类型" prop="clickTypes">
              <el-checkbox-group v-model="importTaskForm.clickTypes">
                <el-checkbox label="0">安卓</el-checkbox>
                <el-checkbox label="1">苹果</el-checkbox>
                <el-checkbox label="2">电脑</el-checkbox>
                <el-checkbox label="3">其他</el-checkbox>
              </el-checkbox-group>
            </el-form-item>
            <el-form-item label="点击次数≥" prop="minClick">
              <el-input-number
                v-model="importTaskForm.minClick"
                :min="1"
                :max="999999"
                controls-position="right"
                style="width: 100%;"
              />
            </el-form-item>
            <el-form-item label="点击次数≤" prop="maxClick">
              <el-input-number
                v-model="importTaskForm.maxClick"
                :min="importTaskForm.minClick != null ? importTaskForm.minClick : 1"
                :max="999999"
                controls-position="right"
                style="width: 100%;"
              />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="importTaskLoading" @click="submitImportFromTask">导 入</el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>
      </el-tabs>
    </el-dialog>

    <el-dialog :title="groupForm.id ? '编辑分组' : '新增分组'" :visible.sync="groupOpen" width="420px" append-to-body @close="resetGroupForm">
      <el-form ref="groupFormRef" :model="groupForm" :rules="groupRules" label-width="88px" size="small">
        <el-form-item label="分组名称" prop="groupName">
          <el-input v-model="groupForm.groupName" maxlength="100" show-word-limit placeholder="名称" />
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="groupOpen = false">取 消</el-button>
        <el-button type="primary" @click="submitGroup">确 定</el-button>
      </div>
    </el-dialog>

  </div>
</template>

<script>
import {
  listContactGroup,
  addContactGroup,
  updateContactGroup,
  delContactGroup,
  listContact,
  clearContactsByGroup,
  importContact,
  importContactFromTask,
  listImportTaskIdOptions
} from '@/api/business/contact'

export default {
  name: 'SmsContactWarehouse',
  data() {
    return {
      groupTableHeaderStyle: {
        background: '#eef1f6',
        color: '#303133',
        fontWeight: '600',
        fontSize: '13px'
      },
      groupLoading: false,
      groupList: [],
      groupQuery: { groupName: null },
      groupOpen: false,
      groupForm: { id: null, groupName: '' },
      groupRules: {
        groupName: [{ required: true, message: '请输入分组名称', trigger: 'blur' }]
      },
      contactListDialogVisible: false,
      listDialogGroup: null,
      importDialogVisible: false,
      importTargetGroup: null,
      importTab: 'file',
      importTaskLoading: false,
      importTaskIdLoading: false,
      importTaskIdOptions: [],
      importTaskForm: {
        taskDate: null,
        taskId: '',
        clickTypes: ['0', '1', '2', '3'],
        minClick: 1,
        maxClick: null
      },
      importTaskRules: {
        taskDate: [{ required: true, message: '请选择日期', trigger: 'change' }],
        taskId: [{ required: true, message: '请选择任务编号', trigger: 'change' }],
        clickTypes: [{ type: 'array', required: true, min: 1, message: '请至少选择一种设备', trigger: 'change' }],
        minClick: [{ required: true, type: 'number', message: '请填写点击次数下限', trigger: 'change' }],
        maxClick: [{
          validator: (rule, value, callback) => {
            const minV = this.importTaskForm.minClick
            if (value != null && value !== '' && minV != null && value < minV) {
              callback(new Error('上限不能小于下限'))
            } else {
              callback()
            }
          },
          trigger: ['change', 'blur']
        }]
      },
      contactLoading: false,
      contactList: [],
      contactTotal: 0,
      contactQuery: {
        pageNum: 1,
        pageSize: 10,
        groupId: null,
        phoneNumber: null,
        contactName: null
      }
    }
  },
  created() {
    this.loadGroups()
  },
  methods: {
    groupTableRowClass() {
      return 'group-table-row'
    },
    loadGroups() {
      this.groupLoading = true
      listContactGroup(this.groupQuery).then(res => {
        this.groupList = res.rows || []
        this.groupLoading = false
        if (this.listDialogGroup && !this.groupList.some(g => g.id === this.listDialogGroup.id)) {
          this.contactListDialogVisible = false
          this.listDialogGroup = null
          this.contactQuery.groupId = null
        }
        if (this.contactListDialogVisible && this.contactQuery.groupId) {
          this.loadContacts()
        }
      }).catch(() => { this.groupLoading = false })
    },
    openContactListDialog(row) {
      this.listDialogGroup = row
      this.contactQuery.groupId = row.id
      this.contactQuery.pageNum = 1
      this.contactQuery.phoneNumber = null
      this.contactQuery.contactName = null
      this.contactListDialogVisible = true
      this.$nextTick(() => {
        this.loadContacts()
      })
    },
    onContactListDialogClose() {
      this.listDialogGroup = null
      this.contactQuery.groupId = null
      this.contactList = []
      this.contactTotal = 0
    },
    loadContacts() {
      if (!this.contactQuery.groupId) {
        this.contactList = []
        this.contactTotal = 0
        this.contactLoading = false
        return
      }
      this.contactLoading = true
      const q = { ...this.contactQuery }
      listContact(q).then(res => {
        this.contactList = res.rows || []
        this.contactTotal = res.total || 0
        this.contactLoading = false
      }).catch(() => { this.contactLoading = false })
    },
    getDefaultTaskDateString() {
      const d = new Date()
      const p = n => (n < 10 ? '0' : '') + n
      return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`
    },
    loadImportTaskIdOptions() {
      if (!this.importTaskForm || !this.importTaskForm.taskDate) {
        this.importTaskIdOptions = []
        return
      }
      this.importTaskIdLoading = true
      listImportTaskIdOptions({ taskDate: this.importTaskForm.taskDate }).then(res => {
        const d = (res && res.data !== undefined) ? res.data : (res && res.rows) ? res.rows : []
        this.importTaskIdOptions = Array.isArray(d) ? d : []
      }).catch(() => { this.importTaskIdOptions = [] }).finally(() => { this.importTaskIdLoading = false })
    },
    onImportTaskDateChange() {
      this.importTaskForm.taskId = ''
      this.loadImportTaskIdOptions()
    },
    onImportTabClick(tab) {
      if (tab && tab.name === 'task' && this.importTargetGroup) {
        this.ensureTaskImportIdOptions()
      }
    },
    ensureTaskImportIdOptions() {
      if (!this.importTaskForm) return
      if (!this.importTaskForm.taskDate) {
        this.$set(this.importTaskForm, 'taskDate', this.getDefaultTaskDateString())
      }
      this.loadImportTaskIdOptions()
    },
    openImportDialog(row) {
      this.importTargetGroup = row
      this.importTab = 'file'
      this.resetImportTaskForm()
      this.importDialogVisible = true
      this.$nextTick(() => {
        if (this.$refs.importUpload) {
          this.$refs.importUpload.clearFiles()
        }
        if (this.$refs.importTaskFormRef) {
          this.$refs.importTaskFormRef.clearValidate()
        }
      })
    },
    onImportDialogClose() {
      this.importTargetGroup = null
      this.importTab = 'file'
      this.resetImportTaskForm()
    },
    resetImportTaskForm() {
      this.importTaskIdOptions = []
      this.importTaskForm = {
        taskDate: this.getDefaultTaskDateString(),
        taskId: '',
        clickTypes: ['0', '1', '2', '3'],
        minClick: 1,
        maxClick: null
      }
    },
    submitImportFromTask() {
      if (!this.importTargetGroup || !this.importTargetGroup.id) {
        return
      }
      this.$refs.importTaskFormRef.validate(valid => {
        if (!valid) return
        const minV = this.importTaskForm.minClick
        const maxV = this.importTaskForm.maxClick
        const targetGid = this.importTargetGroup.id
        const payload = {
          groupId: targetGid,
          taskId: (this.importTaskForm.taskId || '').trim(),
          clickTypes: this.importTaskForm.clickTypes,
          minClick: minV,
          maxClick: maxV == null || maxV === undefined ? null : maxV
        }
        this.importTaskLoading = true
        importContactFromTask(payload).then(res => {
          this.$modal.msgSuccess(res.msg || '导入完成')
          this.importDialogVisible = false
          this.importTargetGroup = null
          this.$nextTick(() => {
            if (this.$refs.importUpload) {
              this.$refs.importUpload.clearFiles()
            }
          })
          this.loadGroups()
          if (this.contactListDialogVisible && this.contactQuery.groupId === targetGid) {
            this.loadContacts()
          }
        }).catch(() => {}).finally(() => { this.importTaskLoading = false })
      })
    },
    submitImport(req) {
      if (!this.importTargetGroup || !this.importTargetGroup.id) {
        return
      }
      const targetGid = this.importTargetGroup.id
      importContact(targetGid, req.file).then(res => {
        this.$modal.msgSuccess(res.msg || '导入完成')
        this.importDialogVisible = false
        this.importTargetGroup = null
        this.$nextTick(() => {
          if (this.$refs.importUpload) {
            this.$refs.importUpload.clearFiles()
          }
        })
        this.loadGroups()
        if (this.contactListDialogVisible && this.contactQuery.groupId === targetGid) {
          this.loadContacts()
        }
      }).catch(() => {})
    },
    handleClearGroupContacts(row) {
      this.$modal.confirm('将清空分组「' + row.groupName + '」下的全部联系人，分组本身保留。是否继续？').then(() => {
        return clearContactsByGroup(row.id)
      }).then(res => {
        this.$modal.msgSuccess((res && res.msg) || '已清空联系人数据')
        if (this.listDialogGroup && this.listDialogGroup.id === row.id) {
          this.loadContacts()
        }
        this.loadGroups()
      }).catch(() => {})
    },
    openGroupDialog(row) {
      this.resetGroupForm()
      if (row && row.id) {
        this.groupForm = { id: row.id, groupName: row.groupName }
      }
      this.groupOpen = true
      this.$nextTick(() => this.$refs.groupFormRef && this.$refs.groupFormRef.clearValidate())
    },
    resetGroupForm() {
      this.groupForm = { id: null, groupName: '' }
    },
    submitGroup() {
      this.$refs.groupFormRef.validate(valid => {
        if (!valid) return
        const req = this.groupForm.id
          ? updateContactGroup(this.groupForm)
          : addContactGroup(this.groupForm)
        req.then(() => {
          this.$modal.msgSuccess(this.groupForm.id ? '修改成功' : '新增成功')
          this.groupOpen = false
          this.loadGroups()
        })
      })
    },
    handleGroupDelete(row) {
      this.$modal.confirm('是否确认删除分组「' + row.groupName + '」及其下联系人？').then(() => {
        return delContactGroup(row.id)
      }).then(() => {
        this.$modal.msgSuccess('删除成功')
        if (this.listDialogGroup && this.listDialogGroup.id === row.id) {
          this.contactListDialogVisible = false
        }
        this.loadGroups()
      }).catch(() => {})
    },
  }
}
</script>

<style scoped>
.contact-warehouse {
  background: linear-gradient(180deg, #f5f7fa 0%, #eef0f4 100%);
  min-height: calc(100vh - 84px);
  padding: 8px 4px 24px;
}

.group-panel {
  border: none;
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 2px 14px rgba(15, 36, 84, 0.08);
}

.group-panel__toolbar {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 12px;
  padding: 16px 22px 12px;
  background: #fafbfc;
  border-bottom: 1px solid #ebeef5;
}

.group-panel__toolbar > .el-button {
  flex-shrink: 0;
}

.group-panel__search {
  flex: 1;
  min-width: 0;
}

.group-panel__search >>> .el-input__inner {
  border-radius: 20px;
}

.group-table {
  width: 100%;
}

.group-table >>> .el-table__body tr.group-table-row:hover > td {
  background-color: #f0f7ff !important;
}

.group-ops {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px 10px;
  padding: 4px 0;
}

.group-ops__line {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
}

.group-ops__divider {
  margin: 0 2px;
  height: 22px;
}

.table-empty {
  padding: 36px 16px 48px;
  text-align: center;
  color: #909399;
}

.table-empty i {
  font-size: 48px;
  color: #dcdfe6;
  display: block;
  margin-bottom: 12px;
}

.table-empty p {
  margin: 0;
  font-size: 13px;
}

.contact-list-wrap {
  margin: -8px 0 0;
}

.import-dialog-tabs >>> .el-tabs__content {
  padding-top: 12px;
}

</style>

<style>
/* 弹窗标题与内边距（非 scoped，作用于 append-to-body） */
.contact-list-dialog .el-dialog__header {
  padding: 16px 20px 10px;
  border-bottom: 1px solid #ebeef5;
}

.contact-list-dialog .el-dialog__body {
  padding: 12px 20px 20px;
}

.contact-list-dialog .inner-contact-table {
  border-radius: 6px;
  overflow: hidden;
}
</style>
