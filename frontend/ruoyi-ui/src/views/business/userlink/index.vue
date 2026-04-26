<template>
  <div class="app-container">
    <el-form :model="queryParams" ref="queryForm" size="small" :inline="true" v-show="showSearch" label-width="68px">
      <el-form-item label="任务Id" prop="taskId">
        <el-input
          v-model="queryParams.taskId"
          placeholder="任务Id"
          clearable
          @keyup.enter.native="handleQuery"
        />
      </el-form-item>

      <el-form-item label="任务时间" prop="timeRange">
        <el-date-picker
          v-model="queryParams.timeRange"
          type="datetimerange"
          unlink-panels
          start-placeholder="开始"
          end-placeholder="结束"
          value-format="yyyy-MM-dd HH:mm:ss"
          placeholder="起止时间"
          clearable>
        </el-date-picker>
      </el-form-item>

      <el-form-item label="原始链接" prop="originalUrl">
        <el-input
          v-model="queryParams.originalUrl"
          placeholder="链接"
          clearable
          @keyup.enter.native="handleQuery"
        />
      </el-form-item>


      <el-form-item label="电话号码" prop="phoneNumber">
        <el-input
          v-model="queryParams.phoneNumber"
          placeholder="手机号"
          clearable
          @keyup.enter.native="handleQuery"
        />
      </el-form-item>

      <el-form-item label="点击类型" prop="clickType">
        <el-select v-model="queryParams.clickType" placeholder="点击类型" clearable>
          <el-option
            v-for="dict in dict.type.click_type"
            :key="dict.value"
            :label="dict.label"
            :value="dict.value"
          />
        </el-select>
      </el-form-item>

      <el-form-item label="点击次数">
        <el-select
          v-model="queryParams.startClick"
          clearable
          placeholder="起"
          style="width: 120px; margin-right: 10px;"
        >
          <el-option
            v-for="n in 11"
            :key="n-1"
            :label="n-1"
            :value="n-1"
          ></el-option>
        </el-select>

        <span> - </span>

        <el-select
          v-model="queryParams.endClick"
          clearable
          placeholder="止"
          style="width: 120px; margin-left: 10px;"
        >
          <el-option
            v-for="n in 11"
            :key="n-1"
            :label="n-1"
            :value="n-1"
          ></el-option>
        </el-select>
      </el-form-item>





      <el-form-item>
        <el-button type="primary" icon="el-icon-search" size="mini" @click="handleQuery">搜索</el-button>
        <el-button icon="el-icon-refresh" size="mini" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5">
        <el-button type="primary" size="mini" @click="openDomainDialog">
          管理域名
        </el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button
          type="danger"
          plain
          icon="el-icon-delete"
          size="mini"
          :disabled="multiple"
          @click="handleDelete"
          v-hasPermi="['business:userlink:remove']"
        >删除</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button
          type="warning"
          plain
          icon="el-icon-download"
          size="mini"
          @click="handleExport"
          v-hasPermi="['business:userlink:export']"
        >导出</el-button>
      </el-col>
      <right-toolbar :showSearch.sync="showSearch" @queryTable="getList"></right-toolbar>
    </el-row>

    <el-table v-loading="loading" :data="userlinkList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="55" align="center" />
      <el-table-column label="任务Id" align="center" prop="taskId" />
      <el-table-column label="任务时间" align="center" prop="createTime" />
      <el-table-column label="原始链接" align="center" prop="originalUrl" />
      <el-table-column label="电话号码" align="center" prop="phoneNumber" />
      <el-table-column label="转换后链接" align="center" prop="afterUrl" />

      <el-table-column label="点击类型" align="center" prop="clickType">
        <template slot-scope="scope">
          <dict-tag :options="dict.type.click_type" :value="scope.row.clickType"/>
        </template>
      </el-table-column>
      <el-table-column label="点击次数" align="center" prop="clickCount" />
      <el-table-column label="操作" align="center" class-name="small-padding fixed-width">
        <template slot-scope="scope">
          <el-button
            size="mini"
            type="text"
            icon="el-icon-delete"
            @click="handleDelete(scope.row)"
            v-hasPermi="['business:userlink:remove']"
          >删除</el-button>
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

    <!-- 添加或修改用户链接对话框 -->
    <el-dialog :title="title" :visible.sync="open" width="2000px" append-to-body>
      <el-form ref="form" :model="form" :rules="rules" label-width="80px">
        <el-form-item label="电话号码" prop="phoneNumber">
          <el-input v-model="form.phoneNumber" placeholder="手机号" />
        </el-form-item>
        <el-form-item label="原始链接" prop="originalUrl">
          <el-input v-model="form.originalUrl" type="textarea" placeholder="URL" />
        </el-form-item>
        <el-form-item label="短链接" prop="shortUrl">
          <el-input v-model="form.shortUrl" placeholder="短链" />
        </el-form-item>
        <el-form-item label="域名" prop="domainId">
          <el-input v-model="form.domainId" placeholder="域名Id" />
        </el-form-item>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="form.remark" type="textarea" placeholder="选填" />
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button type="primary" @click="submitForm">确 定</el-button>
        <el-button @click="cancel">取 消</el-button>
      </div>
    </el-dialog>

    <!-- 域名管理弹窗 -->
    <el-dialog
      title="域名管理"
      :visible.sync="domainDialogVisible"
      width="800px"
    >
      <div>
        <!-- 新增按钮 -->
        <el-button
          type="primary"
          plain
          icon="el-icon-plus"
          size="mini"
          @click="handleDomainAdd"
        >新增</el-button>

        <!-- 删除按钮（根据选中项） -->
        <el-button
          type="danger"
          plain
          icon="el-icon-delete"
          size="mini"
          :disabled="domainSelected.length === 0"
          @click="handleDomainDelete"
        >删除</el-button>

        <el-button
          v-hasPermi="['business:domain:edit']"
          type="primary"
          plain
          icon="el-icon-s-custom"
          size="mini"
          :disabled="domainSelected.length !== 1"
          @click="domainToolbarAssign"
        >分配</el-button>
        <el-button
          v-hasPermi="['business:domain:edit']"
          type="warning"
          plain
          icon="el-icon-refresh-left"
          size="mini"
          :disabled="domainSelected.length !== 1"
          @click="domainToolbarRevoke"
        >回收</el-button>

        <p v-if="!domainLoading && !domainList.length" class="domain-empty-hint">
          暂无域名。请先点「新增」添加；添加后在列表中勾选一条，再点上方「分配」或「回收」。
        </p>

        <el-table
          v-loading="domainLoading"
          :data="domainList"
          @selection-change="domainSelectionChange"
          style="margin-top: 10px"
        >
          <el-table-column type="selection" width="55" />
          <el-table-column label="域名" prop="domainName" />
          <el-table-column label="是否失效" prop="isExpired">
            <template slot-scope="scope">
              <dict-tag :options="dict.type.sys_yes_no" :value="scope.row.isExpired"/>
            </template>
          </el-table-column>
          <el-table-column label="备注" prop="remark" />
        </el-table>

        <pagination
          v-show="domainTotal > 0"
          :total="domainTotal"
          :page.sync="domainQuery.pageNum"
          :limit.sync="domainQuery.pageSize"
          @pagination="getDomainList"
        />
      </div>

      <!-- 新增域名子弹窗 -->
      <el-dialog
        title="新增域名"
        :visible.sync="domainAddVisible"
        width="400px"
        append-to-body
      >
        <el-form ref="domainForm" :model="domainForm" :rules="domainRules" label-width="80px">
          <el-form-item label="域名" prop="domainName">
            <el-input v-model="domainForm.domainName" placeholder="域名" />
          </el-form-item>
          <el-form-item label="备注" prop="remark">
            <el-input type="textarea" v-model="domainForm.remark" />
          </el-form-item>
        </el-form>

        <div slot="footer">
          <el-button @click="domainAddVisible = false">取消</el-button>
          <el-button type="primary" @click="submitDomainAdd">确定</el-button>
        </div>
      </el-dialog>
    </el-dialog>

    <el-dialog
      title="分配域名"
      :visible.sync="assignVisible"
      width="440px"
      append-to-body
      @open="onAssignOpen"
    >
      <el-form size="small" label-width="88px">
        <el-form-item label="目标用户">
          <el-select
            v-model="assignUserId"
            filterable
            remote
            clearable
            :remote-method="remoteUserSearch"
            :loading="assignUserLoading"
            placeholder="搜用户"
            style="width: 100%;"
            value-key="userId"
          >
            <el-option
              v-for="u in assignUserOptions"
              :key="u.userId"
              :label="(u.nickName || u.userName) + ' / ' + u.userName"
              :value="u.userId"
            />
          </el-select>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="assignVisible = false">取 消</el-button>
        <el-button type="primary" :loading="assignSubmitLoading" @click="submitAssign">确 定</el-button>
      </div>
    </el-dialog>

    <el-dialog
      title="回收域名分配"
      :visible.sync="revokeVisible"
      width="560px"
      append-to-body
    >
      <p v-if="revokeCurrentDomain" class="revoke-hint">域名：{{ revokeCurrentDomain.domainName }}</p>
      <el-button
        v-if="revokeList.length"
        type="warning"
        size="small"
        :loading="revokeAllLoading"
        @click="submitRevokeAll"
      >全部回收</el-button>
      <el-table v-loading="revokeLoading" :data="revokeList" size="small" style="margin-top: 10px" max-height="360">
        <el-table-column label="用户" min-width="160" show-overflow-tooltip>
          <template slot-scope="scope">
            <span>{{ scope.row.nickName || scope.row.userName || '—' }}</span>
            <span v-if="scope.row.userName" class="el-text-muted"> ({{ scope.row.userName }})</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100" align="center">
          <template slot-scope="scope">
            <el-button type="text" size="mini" :loading="scope.row._lo" @click="submitRevokeOne(scope.row)">回收</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-empty v-if="!revokeLoading && !revokeList.length" description="暂无下级分配" :image-size="64" />
      <div slot="footer">
        <el-button @click="revokeVisible = false">关 闭</el-button>
      </div>
    </el-dialog>

  </div>
</template>

<script>
import { listUserlink, getUserlink, delUserlink, addUserlink, updateUserlink } from "@/api/business/userlink"
import { list, delDomain, addDomain, assignDomain, revokeDomainGrant, revokeAllDomainGrants, listDomainGrants } from "@/api/business/domain"
import { listUser } from "@/api/system/user"
import { getToken } from "@/utils/auth";
export default {
  name: "Userlink",
  dicts: ['sys_yes_no','click_type'],
  data() {
    return {
      // 域名管理弹窗
      domainDialogVisible: false,

      domainLoading: false,
      domainSelected: [],
      domainTotal: 0,

      domainQuery: {
        pageNum: 1,
        pageSize: 10
      },

      // 新增域名
      domainAddVisible: false,
      domainForm: {
        domainName: "",
        remark: ""
      },
      domainRules: {
        domainName: [
          { required: true, message: "域名不能为空", trigger: "blur" }
        ],
      },
      assignVisible: false,
      assignDomainId: null,
      assignUserId: null,
      assignUserOptions: [],
      assignUserLoading: false,
      assignSubmitLoading: false,
      revokeVisible: false,
      revokeCurrentDomain: null,
      revokeList: [],
      revokeLoading: false,
      revokeAllLoading: false,
      // 用户导入参数
      upload: {
        // 是否显示弹出层（用户导入）
        open: false,
        // 弹出层标题（用户导入）
        title: "",
        // 是否禁用上传
        isUploading: false,
        // 是否更新已经存在的用户数据
        updateSupport: 0,
        originalUrl: "",
        // 设置上传的请求头部
        headers: { Authorization: "Bearer " + getToken() },
        // 上传的地址
        url: process.env.VUE_APP_BASE_API + "/business/userlink/importData",
        domainIds: [],
      },
      domainList: [],
      // 遮罩层
      loading: true,
      // 选中数组
      ids: [],
      // 非单个禁用
      single: true,
      // 非多个禁用
      multiple: true,
      // 显示搜索条件
      showSearch: true,
      // 总条数
      total: 0,
      // 用户链接表格数据
      userlinkList: [],
      // 弹出层标题
      title: "",
      // 是否显示弹出层
      open: false,
      // 查询参数
      queryParams: {
        pageNum: 1,
        pageSize: 10,
        startTime:null,
        endTime:null,
        phoneNumber: null,
        originalUrl: null,
        afterUrl: null,
        shortUrl: null,
        domainId: null,
        isClicked: null,
        clickType: null,
        taskId: null,
        timeRange: [],   // 用于日期组件绑定
        startClick: null,
        endClick: null,
      },
      // 表单参数
      form: {},
      // 表单校验
      rules: {
        phoneNumber: [
          { required: true, message: "电话号码不能为空", trigger: "blur" }
        ],
        originalUrl: [
          { required: true, message: "原始链接不能为空", trigger: "blur" }
        ],
        shortUrl: [
          { required: true, message: "短链接不能为空", trigger: "blur" }
        ],
        domainId: [
          { required: true, message: "域名不能为空", trigger: "blur" }
        ],
        isClicked: [
          { required: true, message: "是否点击不能为空", trigger: "change" }
        ],
        clickCount: [
          { required: true, message: "点击次数不能为空", trigger: "blur" }
        ],
      }
    }
  },
  created() {
    this.getList()
  },
  methods: {
    // 打开域名管理弹窗
    openDomainDialog() {
      this.domainDialogVisible = true
      this.getDomainList()
    },

// 表格选择
    domainSelectionChange(val) {
      this.domainSelected = val
    },

// 删除域名
    handleDomainDelete() {
      const ids = this.domainSelected.map(item => item.id)
      this.$modal.confirm("确认删除选中的域名吗？").then(() => {
        return delDomain(ids)
      }).then(() => {
        this.$modal.msgSuccess("删除成功")
        this.getDomainList()
      })
    },

// 点击新增按钮
    handleDomainAdd() {
      this.domainForm = { domainName: "", remark: "" }
      this.domainAddVisible = true
    },

// 提交新增
    submitDomainAdd() {
      this.$refs.domainForm.validate(valid => {
        if (!valid) return
        addDomain(this.domainForm).then(() => {
          this.$modal.msgSuccess("新增成功")
          this.domainAddVisible = false
          this.getDomainList()
        })
      })
    },


    getDomainList() {
      this.domainLoading = true
      list().then(res => {
        const rows = res || []
        this.domainList = Array.isArray(rows) ? rows : []
        this.domainTotal = this.domainList.length
        this.domainSelected = []

        // ⭐ 关键代码：设置默认选中
        this.upload.domainIds = this.domainList.length ? [this.domainList[0].id] : []
      }).finally(() => {
        this.domainLoading = false
      })
    },
    domainToolbarAssign() {
      if (this.domainSelected.length !== 1) {
        this.$message.warning("请先在列表中勾选一条域名")
        return
      }
      this.openAssignDomain(this.domainSelected[0])
    },
    domainToolbarRevoke() {
      if (this.domainSelected.length !== 1) {
        this.$message.warning("请先在列表中勾选一条域名")
        return
      }
      this.openRevokeDomain(this.domainSelected[0])
    },
    onAssignOpen() {
      this.assignUserId = null
      this.remoteUserSearch("")
    },
    remoteUserSearch(q) {
      this.assignUserLoading = true
      listUser({
        pageNum: 1,
        pageSize: 50,
        userName: q || undefined,
        status: "0"
      })
        .then(res => {
          this.assignUserOptions = res.rows || []
        })
        .catch(() => {
          this.assignUserOptions = []
        })
        .finally(() => {
          this.assignUserLoading = false
        })
    },
    openAssignDomain(row) {
      this.assignDomainId = row.id
      this.assignUserId = null
      this.assignUserOptions = []
      this.assignVisible = true
    },
    submitAssign() {
      if (!this.assignDomainId || !this.assignUserId) {
        this.$message.warning("请选择目标用户")
        return
      }
      this.assignSubmitLoading = true
      assignDomain({ domainId: this.assignDomainId, userId: this.assignUserId })
        .then(() => {
          this.$modal.msgSuccess("分配成功")
          this.assignVisible = false
        })
        .catch(() => {})
        .finally(() => {
          this.assignSubmitLoading = false
        })
    },
    openRevokeDomain(row) {
      this.revokeCurrentDomain = row
      this.revokeList = []
      this.revokeVisible = true
      this.revokeLoading = true
      listDomainGrants(row.id)
        .then(res => {
          this.revokeList = (res && res.data) || []
        })
        .catch(() => {
          this.revokeList = []
        })
        .finally(() => {
          this.revokeLoading = false
        })
    },
    submitRevokeOne(row) {
      this.$set(row, "_lo", true)
      revokeDomainGrant({ grantId: row.id })
        .then(() => {
          this.$modal.msgSuccess("已回收")
          this.reloadRevokeList()
        })
        .catch(() => {})
        .finally(() => {
          this.$set(row, "_lo", false)
        })
    },
    reloadRevokeList() {
      if (!this.revokeCurrentDomain) return
      this.revokeLoading = true
      listDomainGrants(this.revokeCurrentDomain.id)
        .then(res => {
          this.revokeList = (res && res.data) || []
        })
        .catch(() => {
          this.revokeList = []
        })
        .finally(() => {
          this.revokeLoading = false
        })
    },
    submitRevokeAll() {
      if (!this.revokeCurrentDomain) return
      this.$modal
        .confirm("确认回收该域名对全部下级的分配？")
        .then(() => {
          this.revokeAllLoading = true
          return revokeAllDomainGrants({ domainId: this.revokeCurrentDomain.id })
        })
        .then(() => {
          this.$modal.msgSuccess("已全部回收")
          this.reloadRevokeList()
        })
        .catch(() => {})
        .finally(() => {
          this.revokeAllLoading = false
        })
    }
    ,
    /** 下载模板操作 */
    importTemplate() {
      this.download('business/userlink/importTemplate', {
      }, `user_template_${new Date().getTime()}.xlsx`)
    },
// 文件上传中处理
    handleFileUploadProgress(event, file, fileList) {
      this.upload.isUploading = true
    },
// 文件上传成功处理
    handleFileSuccess(response, file, fileList) {
      this.upload.open = false
      this.upload.isUploading = false
      this.$refs.upload.clearFiles()
      this.$alert("<div style='overflow: auto;overflow-x: hidden;max-height: 70vh;padding: 10px 20px 0;'>" + response.msg + "</div>", "导入结果", { dangerouslyUseHTMLString: true })
      this.getList()
    },
// 提交上传文件
    submitFileForm() {
      if (!this.upload.domainIds.length) {
        this.$message.error("请选择至少一个域名！");
        return;
      }
      if (!this.upload.originalUrl){
        this.$message.error("请输入原始链接！");
        return;
      }
      this.$refs.upload.submit();
    }
    ,
    /** 查询用户链接列表 */
    getList() {
      this.loading = true
      listUserlink(this.queryParams).then(response => {
        this.userlinkList = response.rows
        this.total = response.total
        this.loading = false
      })
    },
    // 取消按钮
    cancel() {
      this.open = false
      this.reset()
    },
    // 表单重置
    reset() {
      this.form = {
        id: null,
        phoneNumber: null,
        originalUrl: null,
        shortUrl: null,
        domainId: null,
        isClicked: null,
        clickCount: null,
        createBy: null,
        createTime: null,
        updateBy: null,
        updateTime: null,
        delFlag: null,
        remark: null
      }
      this.resetForm("form")
    },
    /** 搜索按钮操作 */
    handleQuery() {
      if (this.queryParams.timeRange && this.queryParams.timeRange.length === 2) {
        this.queryParams.startTime = this.queryParams.timeRange[0];
        this.queryParams.endTime = this.queryParams.timeRange[1];
      } else {
        this.queryParams.startTime = null;
        this.queryParams.endTime = null;
      }
      const { startClick, endClick } = this.queryParams;
      if (startClick != null && endClick != null && startClick > endClick) {
        this.$message.error('开始点击次数不能大于结束点击次数');
        return;
      }
      this.queryParams.pageNum = 1
      this.getList()
    },
    /** 重置按钮操作 */
    resetQuery() {
      this.resetForm("queryForm")
      this.handleQuery()
      this.queryParams.startClick = null
      this.queryParams.endClick = null
    },
    // 多选框选中数据
    handleSelectionChange(selection) {
      this.ids = selection.map(item => item.id)
      this.single = selection.length!==1
      this.multiple = !selection.length
    },
    /** 提交按钮 */
    submitForm() {
      this.$refs["form"].validate(valid => {
        if (valid) {
            updateUserlink(this.form).then(response => {
              this.$modal.msgSuccess("修改成功")
              this.open = false
              this.getList()
            })
        }
      })
    },
    /** 删除按钮操作 */
    handleDelete(row) {
      const ids = row.id || this.ids
      this.$modal.confirm('是否确认删除用户链接编号为"' + ids + '"的数据项？').then(function() {
        return delUserlink(ids)
      }).then(() => {
        this.getList()
        this.$modal.msgSuccess("删除成功")
      }).catch(() => {})
    },
    /** 导出按钮操作 */
    handleExport() {
      this.download('business/userlink/export', {
        ...this.queryParams
      }, `用户链接导出_${new Date().getTime()}.xlsx`)
    }
  }
}

</script>

<style scoped>
.revoke-hint {
  margin: 0 0 12px;
  color: #606266;
  font-size: 13px;
}
.el-text-muted {
  color: #c0c4cc;
  font-size: 12px;
}
.domain-empty-hint {
  margin: 10px 0 0;
  padding: 8px 12px;
  background: #f4f4f5;
  border-radius: 4px;
  font-size: 13px;
  color: #606266;
  line-height: 1.5;
}
</style>

