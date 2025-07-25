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
    // 调用后端微信登录接口
    const { post } = require('../../utils/request');
    
    post('/auth/wechat-login', {
      code: code,
      userInfo: userInfo
    })
      .then(response => {
        // 检查用户是否已注册
        if (response.isRegistered) {
          // 用户已注册，直接登录成功
          this.loginSuccess(response.user, userInfo);
        } else {
          // 用户未注册，跳转到注册页面
          this.goToRegister(response.openID, userInfo);
        }
      })
      .catch(err => {
        // 登录失败
        this.setData({ loading: false });
        console.error('微信登录失败:', err);
        wx.showToast({
          title: '登录失败，请重试',
          icon: 'none'
        });
      });
  },

  // 跳转到注册页面
  goToRegister: function(openID, userInfo) {
    // 将用户信息传递给注册页面
    const userInfoStr = encodeURIComponent(JSON.stringify({
      ...userInfo,
      openid: openID
    }));
    
    wx.navigateTo({
      url: `/pages/register/register?userInfo=${userInfoStr}`
    });
    
    this.setData({ loading: false });
  },

  // 创建新用户
  createNewUser: function(openID, userInfo) {
    const userData = {
      openid: openID,        // 改为 openid
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
      openID: user.openid,
      role: user.role,
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