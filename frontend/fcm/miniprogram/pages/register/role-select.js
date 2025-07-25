// pages/register/role-select.js
const app = getApp();
const userService = require('../../services/user');

Page({
  data: {
    userInfo: null,
    selectedRole: '',
    roles: [
      {
        id: 'chef',
        name: '大厨',
        description: '擅长烹饪，喜欢制作美食',
        icon: '/images/icons/chef.png'
      },
      {
        id: 'foodie',
        name: '美食家',
        description: '热爱美食，喜欢品尝和分享',
        icon: '/images/icons/favorite.png'
      }
    ],
    loading: false
  },

  onLoad: function(options) {
    // 获取从注册页面传递的用户信息
    if (options.userInfo) {
      const userInfo = JSON.parse(decodeURIComponent(options.userInfo));
      this.setData({ userInfo: userInfo });
    }
  },

  // 选择身份
  selectRole: function(e) {
    const roleId = e.currentTarget.dataset.role;
    this.setData({ selectedRole: roleId });
  },

  // 确认选择
  confirmRole: function() {
    if (!this.data.selectedRole) {
      wx.showToast({
        title: '请选择身份',
        icon: 'none'
      });
      return;
    }

    this.setData({ loading: true });

    // 更新用户身份信息
    userService.updateUser(this.data.userInfo.id, {
      role: this.data.selectedRole
    })
      .then(() => {
        // 更新全局用户信息
        app.globalData.userInfo = {
          ...this.data.userInfo,
          role: this.data.selectedRole
        };

        wx.showToast({
          title: '注册完成',
          icon: 'success'
        });

        // 跳转到首页
        setTimeout(() => {
          wx.switchTab({
            url: '/pages/index/index'
          });
        }, 1500);
      })
      .catch(err => {
        console.error('更新身份失败:', err);
        wx.showToast({
          title: '更新身份失败，请重试',
          icon: 'none'
        });
      })
      .finally(() => {
        this.setData({ loading: false });
      });
  }
}); 