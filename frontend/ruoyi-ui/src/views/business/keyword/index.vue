<template>
  <div class="app-container keyword-page">
    <el-card shadow="never" class="keyword-card">
      <div slot="header" class="keyword-card__header">
        <div class="keyword-card__title-row">
          <i class="el-icon-warning-outline keyword-card__icon" />
          <span class="keyword-card__title">敏感词管理</span>
          <el-tag v-if="total > 0" size="mini" type="info" effect="plain" class="keyword-card__count">共 {{ total }} 个词 · {{ groupedKeywordRows.length }} 组</el-tag>
        </div>
      </div>

      <div class="filter-toolbar">
        <el-form
          :inline="true"
          :model="queryParams"
          ref="queryForm"
          size="small"
          class="filter-form"
          label-width="72px"
          @submit.native.prevent
        >
          <el-form-item label="关键词">
            <el-input
              v-model="queryParams.keyword"
              placeholder="敏感词"
              clearable
              class="filter-input filter-input--keyword"
              @keyup.enter.native="handleQuery"
            />
          </el-form-item>
          <el-form-item label="分类">
            <el-select v-model="queryParams.category" placeholder="分类" clearable class="filter-input filter-input--cat">
              <el-option label="默认" value="默认" />
              <el-option label="赌博" value="赌博" />
              <el-option label="色情" value="色情" />
              <el-option label="诈骗" value="诈骗" />
              <el-option label="违禁" value="违禁" />
              <el-option label="政治" value="政治" />
            </el-select>
          </el-form-item>
          <el-form-item label="状态">
            <el-select v-model="queryParams.status" placeholder="状态" clearable class="filter-input filter-input--status">
              <el-option label="启用" value="0" />
              <el-option label="禁用" value="1" />
            </el-select>
          </el-form-item>
          <el-form-item class="filter-actions">
            <el-button type="primary" icon="el-icon-search" @click="handleQuery">搜索</el-button>
            <el-button icon="el-icon-refresh" @click="resetQuery">重置</el-button>
          </el-form-item>
        </el-form>
      </div>

      <div class="keyword-toolbar">
        <el-button type="primary" plain icon="el-icon-plus" size="small" v-hasPermi="['business:keyword:add','business:keyword:list']" @click="handleAdd">新增</el-button>
        <el-button type="danger" plain icon="el-icon-delete" size="small" :disabled="multiple" v-hasPermi="['business:keyword:remove','business:keyword:list']" @click="handleDelete">批量删除</el-button>
        <el-button type="warning" plain icon="el-icon-refresh" size="small" v-hasPermi="['business:keyword:reload','business:keyword:edit','business:keyword:list']" @click="handleRefreshCache">刷新缓存</el-button>
      </div>

      <div class="table-wrap">
        <el-table
          v-loading="loading"
          :data="groupedKeywordRows"
          stripe
          border
          size="small"
          class="keyword-table"
          :header-cell-style="tableHeaderStyle"
          row-key="_rowKey"
          @selection-change="handleSelectionChange"
        >
          <el-table-column type="expand" width="40">
            <template slot-scope="props">
              <el-table :data="props.row.members" size="mini" border class="keyword-inner-table">
                <el-table-column prop="keyword" label="关键词" min-width="140" />
                <el-table-column prop="createTime" label="创建时间" width="168" />
                <el-table-column label="操作" width="140" align="center">
                  <template slot-scope="inner">
                    <el-button type="text" size="mini" icon="el-icon-edit" @click="handleEdit(inner.row)" v-hasPermi="['business:keyword:edit','business:keyword:list']">编辑</el-button>
                    <el-button type="text" size="mini" icon="el-icon-delete" class="btn-del" @click="handleDelete(inner.row)" v-hasPermi="['business:keyword:remove','business:keyword:list']">删除</el-button>
                  </template>
                </el-table-column>
              </el-table>
            </template>
          </el-table-column>
          <el-table-column type="selection" width="48" align="center" />
          <el-table-column label="关键词" min-width="220">
            <template slot-scope="scope">
              <div class="kw-merge-box">{{ scope.row.keywordsJoined }}</div>
            </template>
          </el-table-column>
          <el-table-column prop="category" label="分类" width="108" align="center">
            <template slot-scope="scope">
              <el-tag :type="categoryTagType(scope.row.category)" size="small" effect="plain">
                {{ scope.row.category }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="matchType" label="匹配方式" width="100" align="center">
            <template slot-scope="scope">
              <el-tag :type="scope.row.matchType === '1' ? 'warning' : 'success'" size="mini" effect="plain">
                {{ scope.row.matchType === '1' ? '正则' : '包含' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="status" label="状态" width="88" align="center">
            <template slot-scope="scope">
              <el-tag :type="scope.row.status === '0' ? 'success' : 'info'" size="small" effect="plain">
                {{ scope.row.status === '0' ? '启用' : '禁用' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="displayTime" label="最近创建" width="168" show-overflow-tooltip />
          <el-table-column label="操作" width="168" align="center" fixed="right">
            <template slot-scope="scope">
              <el-button type="text" size="mini" class="btn-edit" icon="el-icon-edit" @click="handleEditGroup(scope.row)" v-hasPermi="['business:keyword:edit','business:keyword:list']">编辑本组</el-button>
              <el-button type="text" size="mini" icon="el-icon-delete" class="btn-del" @click="handleDeleteGroup(scope.row)" v-hasPermi="['business:keyword:remove','business:keyword:list']">删本组</el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <pagination
        v-show="total > 0"
        :total="total"
        :page.sync="queryParams.pageNum"
        :limit.sync="queryParams.pageSize"
        @pagination="getList"
      />

      <el-dialog
        :title="dialogTitle"
        :visible.sync="showDialog"
        width="520px"
        append-to-body
        custom-class="keyword-dialog"
        :close-on-click-modal="false"
      >
        <el-form ref="form" :model="form" :rules="rules" label-width="96px" size="small">
          <el-form-item label="关键词" prop="keyword">
            <el-input v-model="form.keyword" placeholder="词" />
          </el-form-item>
          <el-form-item label="分类" prop="category">
            <el-select v-model="form.category" placeholder="分类" style="width: 100%;">
              <el-option label="默认" value="默认" />
              <el-option label="赌博" value="赌博" />
              <el-option label="色情" value="色情" />
              <el-option label="诈骗" value="诈骗" />
              <el-option label="违禁" value="违禁" />
              <el-option label="政治" value="政治" />
            </el-select>
          </el-form-item>
          <el-form-item label="匹配方式" prop="matchType">
            <el-radio-group v-model="form.matchType">
              <el-radio label="0">包含匹配</el-radio>
              <el-radio label="1">正则匹配</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="状态" prop="status">
            <el-radio-group v-model="form.status">
              <el-radio label="0">启用</el-radio>
              <el-radio label="1">禁用</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="备注">
            <el-input v-model="form.remark" type="textarea" :rows="3" maxlength="200" show-word-limit placeholder="选填" />
          </el-form-item>
        </el-form>
        <div slot="footer" class="dialog-footer">
          <el-button @click="showDialog = false">取 消</el-button>
          <el-button type="primary" @click="submitForm">确 定</el-button>
        </div>
      </el-dialog>

      <el-dialog
        title="编辑本组"
        :visible.sync="showGroupDialog"
        width="540px"
        append-to-body
        custom-class="keyword-dialog"
        :close-on-click-modal="false"
        @close="onGroupDialogClose"
      >
        <el-form ref="groupForm" :model="groupForm" :rules="groupRules" label-width="96px" size="small">
          <el-form-item label="关键词" prop="keywordLines">
            <el-input
              v-model="groupForm.keywordLines"
              type="textarea"
              :rows="6"
              placeholder="每行一词，或同一行用顿号、逗号分隔；保存后将按序对应本组原有词条并更新/增删"
            />
          </el-form-item>
          <el-form-item label="分类" prop="category">
            <el-select v-model="groupForm.category" placeholder="分类" style="width: 100%;">
              <el-option label="默认" value="默认" />
              <el-option label="赌博" value="赌博" />
              <el-option label="色情" value="色情" />
              <el-option label="诈骗" value="诈骗" />
              <el-option label="违禁" value="违禁" />
              <el-option label="政治" value="政治" />
            </el-select>
          </el-form-item>
          <el-form-item label="匹配方式" prop="matchType">
            <el-radio-group v-model="groupForm.matchType">
              <el-radio label="0">包含匹配</el-radio>
              <el-radio label="1">正则匹配</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="状态" prop="status">
            <el-radio-group v-model="groupForm.status">
              <el-radio label="0">启用</el-radio>
              <el-radio label="1">禁用</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="备注">
            <el-input v-model="groupForm.remark" type="textarea" :rows="2" maxlength="200" show-word-limit placeholder="本组各词条共用备注（可空）" />
          </el-form-item>
        </el-form>
        <div slot="footer" class="dialog-footer">
          <el-button @click="showGroupDialog = false">取 消</el-button>
          <el-button type="primary" :loading="groupSaving" @click="submitGroupForm">保 存</el-button>
        </div>
      </el-dialog>
    </el-card>
  </div>
</template>

<script>
import { listKeyword, addKeyword, updateKeyword, delKeyword, refreshKeywordCache } from "@/api/business/keyword";

export default {
  name: "SmsKeyword",
  data() {
    return {
      loading: false,
      keywordList: [],
      total: 0,
      ids: [],
      multiple: true,
      queryParams: { pageNum: 1, pageSize: 2000, keyword: '', category: '', status: '' },
      showDialog: false,
      showGroupDialog: false,
      groupSaving: false,
      groupEditRow: null,
      groupForm: {
        keywordLines: '',
        category: '默认',
        matchType: '0',
        status: '0',
        remark: ''
      },
      groupRules: {
        keywordLines: [{ required: true, message: '请填写至少一个关键词', trigger: 'blur' }],
        category: [{ required: true, message: '请选择分类', trigger: 'change' }]
      },
      dialogTitle: '',
      form: {},
      rules: {
        keyword: [{ required: true, message: '关键词不能为空', trigger: 'blur' }],
        category: [{ required: true, message: '请选择分类', trigger: 'change' }]
      },
      tableHeaderStyle: {
        background: '#f5f7fa',
        color: '#606266',
        fontWeight: '600'
      }
    };
  },

  created() {
    this.getList();
  },

  computed: {
    groupedKeywordRows() {
      const list = this.keywordList || [];
      const map = new Map();
      for (const row of list) {
        const key = [row.category || '', row.matchType || '', row.status || ''].join('\u0001');
        if (!map.has(key)) {
          map.set(key, []);
        }
        map.get(key).push(row);
      }
      const out = [];
      let i = 0;
      for (const [, members] of map) {
        members.sort((a, b) => {
          const ta = a.createTime ? new Date(a.createTime).getTime() : 0;
          const tb = b.createTime ? new Date(b.createTime).getTime() : 0;
          return tb - ta;
        });
        const words = members.map(m => m.keyword).filter(Boolean);
        out.push({
          _rowKey: 'g' + i++,
          category: members[0].category,
          matchType: members[0].matchType,
          status: members[0].status,
          keywordsJoined: words.join('、'),
          members,
          memberIds: members.map(m => m.id),
          displayTime: members[0].createTime
        });
      }
      out.sort((a, b) => (b.displayTime || '').localeCompare(a.displayTime || ''));
      return out;
    }
  },

  methods: {
    categoryTagType(cat) {
      const m = {
        赌博: 'warning',
        色情: 'danger',
        诈骗: 'warning',
        违禁: 'danger',
        政治: 'info',
        默认: ''
      };
      return m[cat] != null ? m[cat] : 'info';
    },

    getList() {
      this.loading = true;
      listKeyword(this.queryParams)
        .then(res => {
          this.keywordList = res.rows;
          this.total = res.total;
        })
        .finally(() => {
          this.loading = false;
        });
    },

    handleQuery() {
      this.queryParams.pageNum = 1;
      this.getList();
    },

    resetQuery() {
      this.queryParams = { pageNum: 1, pageSize: 2000, keyword: '', category: '', status: '' };
      this.getList();
    },

    handleSelectionChange(selection) {
      const ids = [];
      selection.forEach(item => {
        (item.memberIds || []).forEach(id => ids.push(id));
      });
      this.ids = ids;
      this.multiple = !selection.length;
    },

    handleDeleteGroup(row) {
      if (!row.memberIds || !row.memberIds.length) return;
      this.$modal.confirm('确认删除该分类下共 ' + row.memberIds.length + ' 个关键词？').then(() => {
        delKeyword(row.memberIds.join(',')).then(() => {
          this.$modal.msgSuccess('删除成功');
          this.getList();
        });
      }).catch(() => {});
    },

    parseKeywordLines(s) {
      if (!s || !String(s).trim()) {
        return [];
      }
      return String(s)
        .replace(/[、,，;；,]/g, '\n')
        .split(/\r?\n+/)
        .map(t => t.trim())
        .filter(Boolean);
    },

    handleEditGroup(row) {
      if (!row.members || !row.members.length) return;
      this.groupEditRow = row;
      this.groupForm = {
        keywordLines: row.members.map(m => m.keyword).join('\n'),
        category: row.category || '默认',
        matchType: String(row.matchType != null ? row.matchType : '0'),
        status: String(row.status != null ? row.status : '0'),
        remark: (row.members[0] && row.members[0].remark) || ''
      };
      this.showGroupDialog = true;
      this.$nextTick(() => {
        if (this.$refs.groupForm) {
          this.$refs.groupForm.clearValidate();
        }
      });
    },

    onGroupDialogClose() {
      this.groupEditRow = null;
    },

    submitGroupForm() {
      this.$refs.groupForm.validate(valid => {
        if (!valid) return;
        const lines = this.parseKeywordLines(this.groupForm.keywordLines);
        if (!lines.length) {
          this.$modal.msgError('请至少保留一个有效关键词');
          return;
        }
        const { category, matchType, status, remark } = this.groupForm;
        const members = this.groupEditRow.members;
        this.groupSaving = true;
        const minLen = Math.min(lines.length, members.length);
        const updatePromises = [];
        for (let i = 0; i < minLen; i++) {
          const m = { ...members[i], keyword: lines[i], category, matchType, status, remark: remark || members[i].remark || '' };
          updatePromises.push(updateKeyword(m));
        }
        const addPromises = [];
        for (let i = minLen; i < lines.length; i++) {
          addPromises.push(
            addKeyword({
              keyword: lines[i],
              category,
              matchType,
              status,
              remark: remark || ''
            })
          );
        }
        const deleteIds = [];
        for (let i = lines.length; i < members.length; i++) {
          deleteIds.push(members[i].id);
        }
        Promise.all(updatePromises)
          .then(() => Promise.all(addPromises))
          .then(() => {
            if (deleteIds.length) {
              return delKeyword(deleteIds.join(','));
            }
            return Promise.resolve();
          })
          .then(() => {
            this.$modal.msgSuccess('本组已保存');
            this.showGroupDialog = false;
            this.getList();
          })
          .catch(() => {
            this.$modal.msgError('部分保存失败，请检查后重试');
          })
          .finally(() => {
            this.groupSaving = false;
          });
      });
    },

    handleAdd() {
      this.form = { keyword: '', category: '默认', matchType: '0', status: '0', remark: '' };
      this.dialogTitle = '新增关键词';
      this.showDialog = true;
    },

    handleEdit(row) {
      this.form = Object.assign({}, row);
      this.dialogTitle = '编辑关键词';
      this.showDialog = true;
    },

    submitForm() {
      this.$refs.form.validate(valid => {
        if (!valid) return;
        const req = this.form.id ? updateKeyword(this.form) : addKeyword(this.form);
        req.then(() => {
          this.$modal.msgSuccess(this.form.id ? '修改成功' : '新增成功');
          this.showDialog = false;
          this.getList();
        });
      });
    },

    handleDelete(row) {
      const delIds = row.id ? [row.id] : this.ids;
      this.$modal.confirm('确认删除选中的关键词?').then(() => {
        delKeyword(delIds.join(',')).then(() => {
          this.$modal.msgSuccess('删除成功');
          this.getList();
        });
      }).catch(() => {});
    },

    handleRefreshCache() {
      refreshKeywordCache().then(() => {
        this.$modal.msgSuccess('缓存刷新成功');
      });
    }
  }
};
</script>

<style scoped>
.keyword-page {
  padding-bottom: 8px;
}

.keyword-card {
  border-radius: 10px;
  border: 1px solid #ebeef5;
  overflow: hidden;
}

.keyword-card >>> .el-card__header {
  padding: 16px 20px;
  border-bottom: 1px solid #f0f2f5;
  background: linear-gradient(180deg, #fafbfc 0%, #fff 100%);
}

.keyword-card >>> .el-card__body {
  padding: 0 20px 20px;
}

.keyword-card__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.keyword-card__title-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.keyword-card__icon {
  font-size: 18px;
  color: #e6a23c;
}

.keyword-card__title {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
  letter-spacing: 0.02em;
}

.keyword-card__count {
  margin-left: 4px;
}

.filter-toolbar {
  margin-bottom: 14px;
  padding: 14px 16px;
  background: #fafbfc;
  border-radius: 8px;
  border: 1px solid #eef0f4;
}

.filter-form {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  gap: 0 8px;
}

.filter-form >>> .el-form-item {
  margin-bottom: 0;
}

.filter-input--keyword {
  width: 200px;
}

.filter-input--cat {
  width: 140px;
}

.filter-input--status {
  width: 100px;
}

.filter-actions {
  margin-left: 4px;
}

.keyword-toolbar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
  margin-bottom: 12px;
}

.table-wrap {
  border-radius: 8px;
  overflow: hidden;
}

.keyword-table {
  width: 100%;
}

.keyword-table >>> .el-table__body tr:hover > td {
  background-color: #fafcff !important;
}

.btn-edit {
  color: #409eff !important;
}

.btn-edit:hover {
  color: #66b1ff !important;
}

.btn-del {
  color: #f56c6c !important;
}

.btn-del:hover {
  color: #f78989 !important;
}

.kw-merge-box {
  padding: 8px 10px;
  line-height: 1.5;
  border: 1px solid #e4e7ed;
  border-radius: 6px;
  background: #fafbfc;
  color: #303133;
  word-break: break-all;
}

.keyword-inner-table {
  margin: 4px 0 8px 24px;
  max-width: 720px;
}
</style>

<style>
.keyword-dialog .el-dialog__body {
  padding: 12px 20px 8px;
}
</style>
