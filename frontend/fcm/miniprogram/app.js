// app.js
App({
  globalData: {
    userInfo: null,
    token: null,
    currentFamily: null
  },
  
  onLaunch() {
    // 检查登录状态
    const token = wx.getStorageSync('token');
    const userInfo = wx.getStorageSync('userInfo');
    
    if (token && userInfo) {
      this.globalData.token = token;
      this.globalData.userInfo = userInfo;
      
      // 获取当前家庭信息
      this.getCurrentFamily();
    }
  },
  
  // 获取当前家庭信息
  getCurrentFamily() {
    // 模拟获取当前家庭信息
    setTimeout(() => {
      this.globalData.currentFamily = {
        id: 1,
        name: '我的家庭',
        avatar: 'https://img.yzcdn.cn/vant/cat.jpeg'
      };
    }, 300);
  }
})