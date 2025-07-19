// pages/order/list/list.js
Page({
  data: {
    currentStatus: '',
    orders: [],
    loading: false,
    hasMore: true,
    page: 1,
    isChef: false
  },

  onLoad: function(options) {
    // 检查用户是否是厨师
    this.checkUserRole();
    
    // 加载订单列表
    this.loadOrders();
  },

  onPullDownRefresh: function() {
    this.setData({
      orders: [],
      page: 1,
      hasMore: true
    });
    this.loadOrders().then(() => {
      wx.stopPullDownRefresh();
    });
  },

  onReachBottom: function() {
    if (this.data.hasMore && !this.data.loading) {
      this.loadMoreOrders();
    }
  },

  // 检查用户角色
  checkUserRole: function() {
    // 模拟检查用户角色
    setTimeout(() => {
      this.setData({
        isChef: true // 假设当前用户是厨师
      });
    }, 300);
  },

  // 切换订单状态
  switchStatus: function(e) {
    const status = e.currentTarget.dataset.status;
    
    this.setData({
      currentStatus: status,
      orders: [],
      page: 1,
      hasMore: true
    });
    
    this.loadOrders();
  },

  // 加载订单列表
  loadOrders: function() {
    this.setData({ loading: true });
    
    // 模拟加载订单列表
    return new Promise((resolve) => {
      setTimeout(() => {
        const mockOrders = this.getMockOrders();
        
        this.setData({
          orders: mockOrders,
          loading: false,
          hasMore: mockOrders.length >= 10
        });
        
        resolve();
      }, 500);
    });
  },

  // 加载更多订单
  loadMoreOrders: function() {
    if (this.data.loading) return;
    
    this.setData({ 
      loading: true,
      page: this.data.page + 1
    });
    
    // 模拟加载更多订单
    setTimeout(() => {
      if (this.data.page <= 2) {
        const moreOrders = this.getMockOrders();
        
        this.setData({
          orders: [...this.data.orders, ...moreOrders],
          loading: false,
          hasMore: this.data.page < 2
        });
      } else {
        this.setData({
          loading: false,
          hasMore: false
        });
      }
    }, 500);
  },

  // 获取模拟订单数据
  getMockOrders: function() {
    const status = this.data.currentStatus;
    
    // 模拟订单数据
    const allOrders = [
      {
        id: 1,
        orderNo: 'O2025071800001',
        status: 0,
        statusText: '待确认',
        statusClass: 'pending',
        recipes: [
          { id: 1, name: '红烧肉', image: 'https://img.yzcdn.cn/vant/cat.jpeg', quantity: 1 },
          { id: 2, name: '糖醋排骨', image: 'https://img.yzcdn.cn/vant/cat.jpeg', quantity: 2 }
        ],
        chefName: '张大厨',
        expectedTime: '12:30',
        createTime: '2025-07-18 10:30',
        hasReview: false
      },
      {
        id: 2,
        orderNo: 'O2025071800002',
        status: 1,
        statusText: '已确认',
        statusClass: 'confirmed',
        recipes: [
          { id: 3, name: '麻婆豆腐', image: 'https://img.yzcdn.cn/vant/cat.jpeg', quantity: 1 }
        ],
        chefName: '李师傅',
        expectedTime: '13:00',
        createTime: '2025-07-18 11:15',
        hasReview: false
      },
      {
        id: 3,
        orderNo: 'O2025071800003',
        status: 2,
        statusText: '制作中',
        statusClass: 'cooking',
        recipes: [
          { id: 4, name: '鱼香肉丝', image: 'https://img.yzcdn.cn/vant/cat.jpeg', quantity: 1 },
          { id: 5, name: '宫保鸡丁', image: 'https://img.yzcdn.cn/vant/cat.jpeg', quantity: 1 }
        ],
        chefName: '王厨师',
        expectedTime: '12:45',
        createTime: '2025-07-18 11:30',
        hasReview: false
      },
      {
        id: 4,
        orderNo: 'O2025071700001',
        status: 3,
        statusText: '已完成',
        statusClass: 'completed',
        recipes: [
          { id: 6, name: '水煮鱼', image: 'https://img.yzcdn.cn/vant/cat.jpeg', quantity: 1 }
        ],
        chefName: '张大厨',
        expectedTime: '18:30',
        createTime: '2025-07-17 17:45',
        hasReview: true
      },
      {
        id: 5,
        orderNo: 'O2025071700002',
        status: 3,
        statusText: '已完成',
        statusClass: 'completed',
        recipes: [
          { id: 7, name: '回锅肉', image: 'https://img.yzcdn.cn/vant/cat.jpeg', quantity: 1 },
          { id: 8, name: '青椒土豆丝', image: 'https://img.yzcdn.cn/vant/cat.jpeg', quantity: 1 }
        ],
        chefName: '李师傅',
        expectedTime: '19:00',
        createTime: '2025-07-17 18:15',
        hasReview: false
      }
    ];
    
    // 根据状态筛选
    if (status !== '') {
      return allOrders.filter(order => order.status === parseInt(status));
    }
    
    return allOrders;
  },

  // 跳转到订单详情
  goToDetail: function(e) {
    const id = e.currentTarget.dataset.id;
    wx.navigateTo({
      url: `/pages/order/detail/detail?id=${id}`
    });
  },

  // 取消订单
  cancelOrder: function(e) {
    const id = e.currentTarget.dataset.id;
    
    wx.showModal({
      title: '确认取消',
      content: '确定要取消该订单吗？',
      success: (res) => {
        if (res.confirm) {
          // 模拟取消订单
          const orders = this.data.orders.map(order => {
            if (order.id === id) {
              return {
                ...order,
                status: 4,
                statusText: '已取消',
                statusClass: 'canceled'
              };
            }
            return order;
          });
          
          this.setData({ orders });
          
          wx.showToast({
            title: '已取消订单',
            icon: 'success'
          });
        }
      }
    });
  },

  // 接单（确认订单）
  confirmOrder: function(e) {
    const id = e.currentTarget.dataset.id;
    
    // 模拟接单
    const orders = this.data.orders.map(order => {
      if (order.id === id) {
        return {
          ...order,
          status: 1,
          statusText: '已确认',
          statusClass: 'confirmed'
        };
      }
      return order;
    });
    
    this.setData({ orders });
    
    wx.showToast({
      title: '已接单',
      icon: 'success'
    });
  },

  // 开始制作
  startCooking: function(e) {
    const id = e.currentTarget.dataset.id;
    
    // 模拟开始制作
    const orders = this.data.orders.map(order => {
      if (order.id === id) {
        return {
          ...order,
          status: 2,
          statusText: '制作中',
          statusClass: 'cooking'
        };
      }
      return order;
    });
    
    this.setData({ orders });
    
    wx.showToast({
      title: '开始制作',
      icon: 'success'
    });
  },

  // 完成订单
  completeOrder: function(e) {
    const id = e.currentTarget.dataset.id;
    
    // 模拟完成订单
    const orders = this.data.orders.map(order => {
      if (order.id === id) {
        return {
          ...order,
          status: 3,
          statusText: '已完成',
          statusClass: 'completed'
        };
      }
      return order;
    });
    
    this.setData({ orders });
    
    wx.showToast({
      title: '订单已完成',
      icon: 'success'
    });
  },

  // 评价订单
  reviewOrder: function(e) {
    const id = e.currentTarget.dataset.id;
    wx.navigateTo({
      url: `/pages/order/review/review?id=${id}`
    });
  },

  // 跳转到点餐页面
  goToCreate: function() {
    wx.switchTab({
      url: '/pages/order/create/create'
    });
  }
});