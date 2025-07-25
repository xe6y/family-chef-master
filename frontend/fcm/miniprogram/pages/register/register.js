// pages/register/register.js
const app = getApp();
const userService = require('../../services/user');
const familyService = require('../../services/family');
const { setToken } = require('../../utils/request');

Page({
  data: {
    userInfo: null,
    formData: {
      nickname: '',
      phone: '',
      inviteCode: ''
    },
    errors: {},
    loading: false,
    showInviteInput: false
  },

  onLoad: function(options) {
    // 获取从登录页面传递的用户信息
    if (options.userInfo) {
      const userInfo = JSON.parse(decodeURIComponent(options.userInfo));
      this.setData({
        userInfo: userInfo,
        'formData.nickname': userInfo.nickName || '',
        'formData.avatar': userInfo.avatarUrl || ''
      });
    }
  },

  // 输入昵称
  inputNickname: function(e) {
    this.setData({
      'formData.nickname': e.detail.value,
      'errors.nickname': ''
    });
  },

  // 输入手机号
  inputPhone: function(e) {
    this.setData({
      'formData.phone': e.detail.value,
      'errors.phone': ''
    });
  },

  // 输入邀请码
  inputInviteCode: function(e) {
    this.setData({
      'formData.inviteCode': e.detail.value,
      'errors.inviteCode': ''
    });
  },

  // 切换邀请码输入显示
  toggleInviteInput: function() {
    this.setData({
      showInviteInput: !this.data.showInviteInput
    });
  },

  // 表单验证
  validateForm: function() {
    let isValid = true;
    const errors = {};
    
    if (!this.data.formData.nickname.trim()) {
      errors.nickname = '请输入昵称';
      isValid = false;
    }
    
    // 手机号验证（可选）
    if (this.data.formData.phone && !/^1[3-9]\d{9}$/.test(this.data.formData.phone)) {
      errors.phone = '请输入正确的手机号';
      isValid = false;
    }
    
    this.setData({ errors });
    return isValid;
  },

  // 提交注册
  submitRegister: function() {
    if (!this.validateForm()) {
      return;
    }
    
    this.setData({ loading: true });
    
    const registerData = {
      openid: this.data.userInfo.openid,
      nickname: this.data.formData.nickname,
      avatar: this.data.formData.avatar,
      phone: this.data.formData.phone,
      invite_code: this.data.formData.inviteCode.trim()
    };

    // 调用新的注册接口
    const { post } = require('../../utils/request');
    
    post('/auth/register', registerData)
      .then(response => {
        // 注册成功，根据是否有邀请码决定跳转
        const userInfo = {
          ...this.data.userInfo,
          id: response.user.id,
          openID: response.user.openid,
          familyID: response.user.family_id,
          familyRole: response.user.family_role
        };

        if (this.data.formData.inviteCode.trim()) {
          // 有邀请码，直接跳转到身份选择页面
          const userInfoStr = encodeURIComponent(JSON.stringify(userInfo));
          wx.navigateTo({
            url: `/pages/register/role-select?userInfo=${userInfoStr}`
          });
        } else {
          // 无邀请码，跳转到家庭创建页面
          const userInfoStr = encodeURIComponent(JSON.stringify(userInfo));
          wx.navigateTo({
            url: `/pages/family/create/create?userInfo=${userInfoStr}`
          });
        }
      })
      .catch(err => {
        console.error('注册失败:', err);
        console.error('错误详情:', err.message, err.stack);
        wx.showToast({
          title: err.message || '注册失败，请重试',
          icon: 'none'
        });
      })
      .finally(() => {
        this.setData({ loading: false });
      });
  },



  // 跳过注册（临时）
  skipRegister: function() {
    wx.showModal({
      title: '提示',
      content: '跳过注册将无法使用完整功能，确定要跳过吗？',
      success: (res) => {
        if (res.confirm) {
          wx.switchTab({
            url: '/pages/index/index'
          });
        }
      }
    });
  }
}); 