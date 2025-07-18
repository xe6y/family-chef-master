// pages/family/join/join.js
const familyService = require('../../../services/family');

Page({
  data: {
    inviteCode: '',
    error: '',
    loading: false
  },

  // 输入邀请码
  inputInviteCode: function(e) {
    this.setData({
      inviteCode: e.detail.value,
      error: ''
    });
  },

  // 加入家庭
  joinFamily: function() {
    if (!this.data.inviteCode) {
      this.setData({
        error: '请输入邀请码'
      });
      return;
    }

    this.setData({ loading: true });

    // 调用加入家庭API
    familyService.joinFamily(this.data.inviteCode)
      .then(res => {
        if (res.status === 0) {
          wx.showModal({
            title: '申请已提交',
            content: '您的加入申请已提交，请等待家庭管理员审核',
            showCancel: false,
            success: () => {
              wx.switchTab({
                url: '/pages/index/index'
              });
            }
          });
        } else {
          wx.showToast({
            title: '加入成功',
            icon: 'success'
          });
          
          setTimeout(() => {
            wx.switchTab({
              url: '/pages/index/index'
            });
          }, 1500);
        }
      })
      .catch(err => {
        this.setData({
          error: err.message || '邀请码无效或已过期'
        });
      })
      .finally(() => {
        this.setData({ loading: false });
      });
  }
});