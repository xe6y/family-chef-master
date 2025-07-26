// index.js
const app = getApp();

Page({
  data: {
    userInfo: {},
    hasUserInfo: false,
    greeting: '早上好',
    unreadCount: 3, // 未读通知数量
    currentFamily: {
      id: 1,
      name: '我的家庭'
    },
    // 今日菜单
    menuList: [
      {
        id: 1,
        name: '红烧肉',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        cookingTime: 45,
        isFavorite: true
      },
      {
        id: 2,
        name: '糖醋排骨',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        cookingTime: 30,
        isFavorite: false
      },
      {
        id: 3,
        name: '麻婆豆腐',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        cookingTime: 20,
        isFavorite: true
      }
    ],
    // 今日推荐
    recommendations: [
      {
        id: 1,
        name: '宫保鸡丁',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        chefName: '张师傅',
        rating: 4.8
      },
      {
        id: 2,
        name: '水煮鱼',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        chefName: '李师傅',
        rating: 4.6
      },
      {
        id: 3,
        name: '回锅肉',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        chefName: '王师傅',
        rating: 4.9
      }
    ],
    // 最近活动
    activities: [
      {
        id: 1,
        userName: '妈妈',
        userAvatar: 'https://img.yzcdn.cn/vant/cat.jpeg',
        action: '制作了红烧肉',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        time: '2小时前'
      },
      {
        id: 2,
        userName: '爸爸',
        userAvatar: 'https://img.yzcdn.cn/vant/cat.jpeg',
        action: '分享了新菜谱',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        time: '4小时前'
      },
      {
        id: 3,
        userName: '姐姐',
        userAvatar: 'https://img.yzcdn.cn/vant/cat.jpeg',
        action: '完成了订单',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        time: '6小时前'
      }
    ],
    // 家宴回忆
    memories: [
      {
        id: 1,
        title: '家庭聚餐',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        date: '2025-07-15'
      },
      {
        id: 2,
        title: '周末烧烤',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        date: '2025-07-10'
      }
    ],
    // 本周统计
    stats: {
      weeklyOrders: 12,
      weeklyRecipes: 8,
      weeklyTime: '6.5h',
      weeklyRating: 4.7
    }
  },

  onLoad() {
    this.setGreeting();
    this.loadPageData();
    
    // 检查是否已登录
    if (app.globalData.userInfo) {
      this.setData({
        userInfo: app.globalData.userInfo,
        hasUserInfo: true
      });
    } else {
      // 未登录，跳转到登录页
      wx.redirectTo({
        url: '/pages/login/login'
      });
    }
  },

  onShow() {
    // 页面显示时刷新数据
    this.loadPageData();
  },

  // 加载页面数据
  loadPageData() {
    this.loadMenuList();
    this.loadRecommendations();
    this.loadActivities();
    this.loadStats();
    this.loadNotifications();
  },

  // 加载今日菜单
  loadMenuList() {
    // TODO: 调用API获取今日菜单
    console.log('加载今日菜单');
  },

  // 加载推荐菜谱
  loadRecommendations() {
    // TODO: 调用API获取推荐菜谱
    console.log('加载推荐菜谱');
  },

  // 加载最近活动
  loadActivities() {
    // TODO: 调用API获取最近活动
    console.log('加载最近活动');
  },

  // 加载统计数据
  loadStats() {
    // TODO: 调用API获取统计数据
    console.log('加载统计数据');
  },

  // 加载通知
  loadNotifications() {
    // TODO: 调用API获取通知数量
    console.log('加载通知');
  },

  // 设置问候语
  setGreeting() {
    const hour = new Date().getHours();
    let greeting = '';
    
    if (hour < 6) {
      greeting = '凌晨好';
    } else if (hour < 9) {
      greeting = '早上好';
    } else if (hour < 12) {
      greeting = '上午好';
    } else if (hour < 14) {
      greeting = '中午好';
    } else if (hour < 17) {
      greeting = '下午好';
    } else if (hour < 19) {
      greeting = '傍晚好';
    } else {
      greeting = '晚上好';
    }
    
    this.setData({ greeting });
  },

  // 显示通知
  showNotifications() {
    wx.navigateTo({
      url: '/pages/notification/list/list'
    });
  },

  // 切换收藏状态
  toggleFavorite(e) {
    const id = e.currentTarget.dataset.id;
    const menuList = this.data.menuList.map(item => {
      if (item.id === id) {
        return { ...item, isFavorite: !item.isFavorite };
      }
      return item;
    });
    
    this.setData({ menuList });
    
    // TODO: 调用API更新收藏状态
    wx.showToast({
      title: menuList.find(item => item.id === id).isFavorite ? '已收藏' : '已取消收藏',
      icon: 'success'
    });
  },

  // 页面导航
  navigateTo(e) {
    const url = e.currentTarget.dataset.url;
    if (url.startsWith('/pages/')) {
      if (url.indexOf('pages/index/') === -1 && url.indexOf('pages/recipe/list/') === -1 && 
          url.indexOf('pages/order/create/') === -1 && url.indexOf('pages/user/profile/') === -1) {
        wx.navigateTo({ url });
      } else {
        wx.switchTab({ url });
      }
    }
  },

  // 跳转到活动详情
  goToActivity(e) {
    const id = e.currentTarget.dataset.id;
    wx.navigateTo({
      url: `/pages/activity/detail/detail?id=${id}`
    });
  },

  // 跳转到菜谱详情
  goToRecipeDetail(e) {
    const id = e.currentTarget.dataset.id;
    wx.navigateTo({
      url: `/pages/recipe/detail/detail?id=${id}`
    });
  },

  // 跳转到订单详情
  goToOrderDetail(e) {
    const id = e.currentTarget.dataset.id;
    wx.navigateTo({
      url: `/pages/order/detail/detail?id=${id}`
    });
  },

  // 跳转到家宴回忆详情
  goToMemoryDetail(e) {
    const id = e.currentTarget.dataset.id;
    wx.navigateTo({
      url: `/pages/memory/detail/detail?id=${id}`
    });
  },

  // 下拉刷新
  onPullDownRefresh() {
    this.loadPageData();
    wx.stopPullDownRefresh();
  },

  // 分享页面
  onShareAppMessage() {
    return {
      title: '家庭厨师 - 让美食连接每个家庭',
      path: '/pages/index/index'
    };
  }
});