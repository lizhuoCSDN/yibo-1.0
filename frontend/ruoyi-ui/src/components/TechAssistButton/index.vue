<template>
  <span class="ta-btn-wrap">
    <el-button
      type="text"
      size="mini"
      icon="el-icon-question"
      v-hasPermi="['business:techAssist:add']"
      @click="open = true"
    >技术协助</el-button>
    <el-dialog title="技术协助" :visible.sync="open" width="520px" append-to-body @close="reset">
      <el-form size="small" label-width="88px" @submit.native.prevent>
        <el-form-item v-if="refSummary" label="当前位置">
          <span class="ta-ref">{{ refSummary }}</span>
        </el-form-item>
        <el-form-item label="问题描述" required>
          <el-input
            v-model="question"
            type="textarea"
            :rows="5"
            maxlength="2000"
            show-word-limit
            placeholder=""
          />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="open = false">取 消</el-button>
        <el-button type="primary" :loading="saving" @click="submit">提 交</el-button>
      </div>
    </el-dialog>
  </span>
</template>

<script>
import { addTechAssist } from '@/api/business/techAssist'

export default {
  name: 'TechAssistButton',
  props: {
    pageCode: { type: String, required: true },
    pageLabel: { type: String, default: '' },
    refId: { type: [Number, String], default: null },
    refSummary: { type: String, default: '' }
  },
  data() {
    return {
      open: false,
      question: '',
      saving: false
    }
  },
  methods: {
    reset() {
      this.question = ''
    },
    submit() {
      const q = (this.question || '').trim()
      if (!q) {
        this.$message.warning('请填写问题描述')
        return
      }
      this.saving = true
      const payload = {
        pageCode: this.pageCode,
        pageLabel: this.pageLabel || this.pageCode,
        refId: this.refId != null && this.refId !== '' ? this.refId : null,
        refSummary: this.refSummary || null,
        question: q
      }
      addTechAssist(payload)
        .then(() => {
          this.$modal.msgSuccess('已提交，请在「账户管理-技术协助」中查看与处理')
          this.open = false
          this.reset()
        })
        .finally(() => {
          this.saving = false
        })
    }
  }
}
</script>

<style scoped>
.ta-ref {
  color: #606266;
  word-break: break-all;
}
.ta-btn-wrap {
  display: inline-block;
  margin-left: 4px;
}
</style>
