// pages/user/profile/profile.js
const app = getApp();
const authService = require('../../../services/auth');

Page({
  data: {
    userInfo: {},
    stats: {
      orderCount: 0,
      recipeCount: 0,
      reviewCount: 0
    }
  },

  onLoad: function(options) {
    this.loadUserInfo();
    this.loadUserStats();
  },

  onShow: function() {
    // 每次页面显示时刷新用户信息
    this.loadUserInfo();
  },

  // 加载用户信息
  loadUserInfo: function() {
    const userInfo = app.globalData.userInfo;
    
    if (userInfo) {
      this.setData({ userInfo });
    } else {
      // 未登录，跳转到登录页
      wx.redirectTo({
        url: '/pages/login/login'
      });
    }
  },

  // 加载用户统计数据
  loadUserStats: function() {
    // 模拟加载用户统计数据
    setTimeout(() => {
      this.setData({
        stats: {
          orderCount: 12,
          recipeCount: 5,
          reviewCount: 8
        }
      });
    }, 500);
  },

  // 页面导航
  navigateTo: function(e) {
    const url = e.currentTarget.dataset.url;
    wx.navigateTo({ url });
  },

  // 退出登录
  logout: function() {
    wx.showModal({
      title: '确认退出',
      content: '确定要退出登录吗？',
      success: (res) => {
        if (res.confirm) {
          // 调用退出登录API
          authService.logout()
            .then(() => {
              // 清除本地存储
              wx.removeStorageSync('token');
              wx.removeStorageSync('userInfo');
              
              // 清除全局数据
              app.globalData.userInfo = null;
              app.globalData.token = null;
              app.globalData.currentFamily = null;
              
              // 跳转到登录页
              wx.reLaunch({
                url: '/pages/login/login'
              });
            })
            .catch(err => {
              wx.showToast({
                title: '退出失败，请重试',
                icon: 'none'
              });
            });
        }
      }
    });
  }
});