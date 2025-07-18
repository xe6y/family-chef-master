// pages/login/login.js
const app = getApp();

Page({
  data: {
    loading: false
  },

  onLoad: function(options) {
    // 页面加载时执行
  },

  // 处理用户信息授权
  handleUserInfo: function(e) {
    if (e.detail.userInfo) {
      this.setData({ loading: true });
      
      // 获取微信登录凭证
      wx.login({
        success: (res) => {
          if (res.code) {
            // 模拟登录成功
            setTimeout(() => {
              // 存储用户信息
              app.globalData.userInfo = e.detail.userInfo;
              app.globalData.token = "mock_token_123456";
              
              wx.showToast({
                title: '登录成功',
                icon: 'success'
              });
              
              // 跳转到首页
              setTimeout(() => {
                wx.switchTab({
                  url: '/pages/index/index'
                });
              }, 1500);
              
              this.setData({ loading: false });
            }, 1000);
          } else {
            this.setData({ loading: false });
            wx.showToast({
              title: '登录失败，请重试',
              icon: 'none'
            });
          }
        },
        fail: () => {
          this.setData({ loading: false });
          wx.showToast({
            title: '登录失败，请重试',
            icon: 'none'
          });
        }
      });
    }
  },
  
  // 显示用户协议
  showAgreement: function() {
    wx.showModal({
      title: '用户协议',
      content: '这是用户协议内容...',
      showCancel: false
    });
  },
  
  // 显示隐私政策
  showPrivacy: function() {
    wx.showModal({
      title: '隐私政策',
      content: '这是隐私政策内容...',
      showCancel: false
    });
  }
});