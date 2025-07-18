// index.js
const app = getApp();

Page({
  data: {
    userInfo: {},
    hasUserInfo: false,
    greeting: '早上好',
    currentFamily: {
      id: 1,
      name: '我的家庭'
    },
    banners: [
      {
        id: 1,
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        url: '/pages/recipe/list/list'
      },
      {
        id: 2,
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        url: '/pages/recipe/list/list'
      },
      {
        id: 3,
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        url: '/pages/recipe/list/list'
      }
    ],
    navItems: [
      {
        id: 1,
        text: '点餐',
        icon: '/images/icons/order.png',
        url: '/pages/order/create/create'
      },
      {
        id: 2,
        text: '菜谱',
        icon: '/images/icons/recipe.png',
        url: '/pages/recipe/list/list'
      },
      {
        id: 3,
        text: '食材',
        icon: '/images/icons/ingredient.png',
        url: '/pages/ingredient/list/list'
      },
      {
        id: 4,
        text: '家宴',
        icon: '/images/icons/memory.png',
        url: '/pages/memory/list/list'
      },
      {
        id: 5,
        text: '采购',
        icon: '/images/icons/purchase.png',
        url: '/pages/ingredient/purchase/purchase'
      },
      {
        id: 6,
        text: '成员',
        icon: '/images/icons/member.png',
        url: '/pages/family/members/members'
      },
      {
        id: 7,
        text: '统计',
        icon: '/images/icons/statistics.png',
        url: '/pages/statistics/statistics'
      },
      {
        id: 8,
        text: '更多',
        icon: '/images/icons/more.png',
        url: '/pages/more/more'
      }
    ],
    recommendRecipes: [
      {
        id: 1,
        name: '红烧肉',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        cuisine: '川菜',
        difficulty: 3
      },
      {
        id: 2,
        name: '糖醋排骨',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        cuisine: '粤菜',
        difficulty: 4
      },
      {
        id: 3,
        name: '麻婆豆腐',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        cuisine: '川菜',
        difficulty: 2
      },
      {
        id: 4,
        name: '鱼香肉丝',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        cuisine: '湘菜',
        difficulty: 3
      }
    ],
    pendingOrders: [
      {
        id: 1,
        orderNo: 'O2025071800001',
        statusText: '待确认',
        recipes: [
          { id: 1, name: '红烧肉', quantity: 1 },
          { id: 2, name: '糖醋排骨', quantity: 2 }
        ],
        createTime: '2025-07-18 10:30',
        userName: '张三'
      },
      {
        id: 2,
        orderNo: 'O2025071800002',
        statusText: '制作中',
        recipes: [
          { id: 3, name: '麻婆豆腐', quantity: 1 },
          { id: 4, name: '鱼香肉丝', quantity: 1 }
        ],
        createTime: '2025-07-18 11:15',
        userName: '李四'
      }
    ],
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
    ]
  },

  onLoad() {
    this.setGreeting();
    
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

  // 切换家庭
  switchFamily() {
    wx.showActionSheet({
      itemList: ['我的家庭', '创建新家庭', '加入家庭'],
      success: (res) => {
        if (res.tapIndex === 1) {
          wx.navigateTo({
            url: '/pages/family/create/create'
          });
        } else if (res.tapIndex === 2) {
          wx.navigateTo({
            url: '/pages/family/join/join'
          });
        }
      }
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
  }
});