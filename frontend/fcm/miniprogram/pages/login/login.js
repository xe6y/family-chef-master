// pages/login/login.js
const app = getApp();
const userService = require('../../services/user');
const { setToken } = require('../../utils/request');

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
            this.loginWithWechat(res.code, e.detail.userInfo);
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

  // 微信登录处理
  loginWithWechat: function(code, userInfo) {
    // 先尝试根据OpenID获取用户信息
    userService.getUserByOpenID(code)
      .then(user => {
        // 用户已存在，直接登录
        this.loginSuccess(user, userInfo);
      })
      .catch(err => {
        // 用户不存在，创建新用户
        this.createNewUser(code, userInfo);
      });
  },

  // 创建新用户
  createNewUser: function(openID, userInfo) {
    const userData = {
      open_id: openID,
      nickname: userInfo.nickName,
      avatar: userInfo.avatarUrl,
      phone: ''
    };

    userService.createUser(userData)
      .then(user => {
        this.loginSuccess(user, userInfo);
      })
      .catch(err => {
        this.setData({ loading: false });
        console.error('创建用户失败:', err);
        wx.showToast({
          title: '创建用户失败，请重试',
          icon: 'none'
        });
      });
  },

  // 登录成功处理
  loginSuccess: function(user, userInfo) {
    // 存储用户信息到全局
    app.globalData.userInfo = {
      ...userInfo,
      id: user.id,
      openID: user.open_id,
      familyID: user.family_id,
      familyRole: user.family_role
    };

    // 生成模拟token（实际项目中应该从后端获取）
    const token = 'mock_token_' + user.id + '_' + Date.now();
    setToken(token);

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