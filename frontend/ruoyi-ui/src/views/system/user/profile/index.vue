<template>
  <div class="app-container profile-page">
    <el-row :gutter="20">
      <el-col :span="6" :xs="24">
        <el-card class="box-card profile-card" shadow="hover">
          <div slot="header" class="clearfix profile-card__head">
            <span><i class="el-icon-user profile-card__head-ico" /> 个人信息</span>
          </div>
          <div>
            <div class="text-center">
              <userAvatar />
            </div>
            <ul class="list-group list-group-striped">
              <li class="list-group-item">
                <svg-icon icon-class="user" />账户名称
                <div class="pull-right">{{ user.userName }}</div>
              </li>
              <li class="list-group-item">
                <svg-icon icon-class="email" />用户邮箱
                <div class="pull-right">{{ user.email }}</div>
              </li>
              <li class="list-group-item">
                <svg-icon icon-class="peoples" />所属角色
                <div class="pull-right">{{ roleGroup }}</div>
              </li>
              <li class="list-group-item">
                <svg-icon icon-class="date" />创建日期
                <div class="pull-right">{{ user.createTime }}</div>
              </li>
            </ul>
          </div>
        </el-card>
      </el-col>
      <el-col :span="18" :xs="24">
        <el-card class="profile-card" shadow="hover">
          <div slot="header" class="clearfix profile-card__head">
            <span><i class="el-icon-edit-outline profile-card__head-ico" /> 基本资料</span>
          </div>
          <el-tabs v-model="selectedTab" class="profile-tabs">
            <el-tab-pane label="基本资料" name="userinfo">
              <userInfo :user="user" />
            </el-tab-pane>
            <el-tab-pane label="修改密码" name="resetPwd">
              <resetPwd />
            </el-tab-pane>
          </el-tabs>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import userAvatar from "./userAvatar"
import userInfo from "./userInfo"
import resetPwd from "./resetPwd"
import { getUserProfile } from "@/api/system/user"

export default {
  name: "Profile",
  components: { userAvatar, userInfo, resetPwd },
  data() {
    return {
      user: {},
      roleGroup: {},
      selectedTab: "userinfo"
    }
  },
  created() {
    const activeTab = this.$route.params && this.$route.params.activeTab
    if (activeTab) {
      this.selectedTab = activeTab
    }
    this.getUser()
  },
  methods: {
    getUser() {
      getUserProfile().then(response => {
        this.user = response.data
        this.roleGroup = response.roleGroup
      })
    }
  }
}
</script>

<style scoped>
.profile-page {
  min-height: calc(100vh - 120px);
  background: linear-gradient(165deg, #f0f4f8 0%, #e9eef4 45%, #f2f4f7 100%);
  padding: 20px;
  box-sizing: border-box;
}
.profile-card {
  border-radius: 10px;
  border: 1px solid rgba(0, 0, 0, 0.06);
}
.profile-card >>> .el-card__header {
  padding: 14px 18px;
  border-bottom: 1px solid #f0f2f5;
  background: linear-gradient(180deg, #fafbfc 0%, #fff 100%);
}
.profile-card__head {
  font-size: 15px;
  font-weight: 600;
  color: #303133;
}
.profile-card__head-ico {
  color: #1890ff;
  margin-right: 4px;
}
.profile-card >>> .el-card__body {
  padding: 18px;
}
.profile-card .list-group-item {
  border-radius: 8px;
  margin-bottom: 8px;
  border: 1px solid #eef0f3 !important;
  padding: 12px 14px !important;
  background: #fafbfc;
}
.profile-tabs >>> .el-tabs__header {
  margin-bottom: 16px;
}
.profile-tabs >>> .el-tabs__item.is-active {
  color: #1890ff;
  font-weight: 600;
}
.profile-tabs >>> .el-tabs__active-bar {
  background-color: #1890ff;
}
</style>
