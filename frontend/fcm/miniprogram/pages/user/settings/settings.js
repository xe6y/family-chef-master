// pages/user/settings/settings.js
const app = getApp();

Page({
  data: {
    userInfo: {},
    notifications: {
      order: true,
      system: true
    },
    cacheSize: '0KB'
  },

  onLoad: function(options) {
    this.loadUserInfo();
    this.loadCacheSize();
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

  // 加载缓存大小
  loadCacheSize: function() {
    // 模拟加载缓存大小
    setTimeout(() => {
      this.setData({
        cacheSize: '2.5MB'
      });
    }, 300);
  },

  // 编辑个人资料
  editProfile: function() {
    wx.navigateTo({
      url: '/pages/user/edit-profile/edit-profile'
    });
  },

  // 绑定手机号
  bindPhone: function() {
    wx.navigateTo({
      url: '/pages/user/bind-phone/bind-phone'
    });
  },

  // 切换订单通知
  toggleOrderNotification: function(e) {
    this.setData({
      'notifications.order': e.detail.value
    });
    
    wx.showToast({
      title: e.detail.value ? '已开启订单通知' : '已关闭订单通知',
      icon: 'none'
    });
  },

  // 切换系统通知
  toggleSystemNotification: function(e) {
    this.setData({
      'notifications.system': e.detail.value
    });
    
    wx.showToast({
      title: e.detail.value ? '已开启系统通知' : '已关闭系统通知',
      icon: 'none'
    });
  },

  // 清除缓存
  clearCache: function() {
    wx.showModal({
      title: '确认清除',
      content: '确定要清除缓存吗？',
      success: (res) => {
        if (res.confirm) {
          // 模拟清除缓存
          setTimeout(() => {
            this.setData({
              cacheSize: '0KB'
            });
            
            wx.showToast({
              title: '缓存已清除',
              icon: 'success'
            });
          }, 500);
        }
      }
    });
  },

  // 检查更新
  checkUpdate: function() {
    wx.showLoading({
      title: '检查更新中...'
    });
    
    // 模拟检查更新
    setTimeout(() => {
      wx.hideLoading();
      
      wx.showModal({
        title: '检查更新',
        content: '当前已是最新版本',
        showCancel: false
      });
    }, 1000);
  },

  // 页面导航
  navigateTo: function(e) {
    const url = e.currentTarget.dataset.url;
    wx.navigateTo({ url });
  }
});