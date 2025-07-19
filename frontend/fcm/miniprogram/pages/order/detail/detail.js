// pages/order/detail/detail.js
Page({
  data: {
    order: {},
    isChef: false,
    loading: false
  },

  onLoad: function(options) {
    const id = options.id;
    
    // 检查用户是否是厨师
    this.checkUserRole();
    
    // 加载订单详情
    this.loadOrderDetail(id);
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

  // 加载订单详情
  loadOrderDetail: function(id) {
    this.setData({ loading: true });
    
    // 模拟加载订单详情
    setTimeout(() => {
      // 模拟订单数据
      const mockOrder = {
        id: parseInt(id),
        orderNo: `O202507180000${id}`,
        status: 0,
        statusText: '待确认',
        statusClass: 'pending',
        statusDesc: '等待厨师接单',
        recipes: [
          { 
            id: 1, 
            name: '红烧肉', 
            image: 'https://img.yzcdn.cn/vant/cat.jpeg', 
            cuisine: '川菜',
            quantity: 1,
            isChefSkill: true
          },
          { 
            id: 2, 
            name: '糖醋排骨', 
            image: 'https://img.yzcdn.cn/vant/cat.jpeg', 
            cuisine: '粤菜',
            quantity: 2,
            isChefSkill: false
          }
        ],
        chefName: '张大厨',
        expectedTime: '12:30',
        createTime: '2025-07-18 10:30',
        completedTime: '',
        remark: '排骨不要太甜，红烧肉多放点葱姜蒜',
        review: null
      };
      
      // 根据ID调整状态
      if (id == 2) {
        mockOrder.status = 1;
        mockOrder.statusText = '已确认';
        mockOrder.statusClass = 'confirmed';
        mockOrder.statusDesc = '厨师已接单，准备制作';
      } else if (id == 3) {
        mockOrder.status = 2;
        mockOrder.statusText = '制作中';
        mockOrder.statusClass = 'cooking';
        mockOrder.statusDesc = '厨师正在制作中';
      } else if (id == 4) {
        mockOrder.status = 3;
        mockOrder.statusText = '已完成';
        mockOrder.statusClass = 'completed';
        mockOrder.statusDesc = '订单已完成';
        mockOrder.completedTime = '2025-07-17 19:15';
        mockOrder.review = {
          rating: 5,
          content: '非常好吃，肥而不腻，入口即化！',
          images: ['https://img.yzcdn.cn/vant/cat.jpeg', 'https://img.yzcdn.cn/vant/cat.jpeg'],
          createdAt: '2025-07-17 19:30'
        };
      } else if (id == 5) {
        mockOrder.status = 3;
        mockOrder.statusText = '已完成';
        mockOrder.statusClass = 'completed';
        mockOrder.statusDesc = '订单已完成';
        mockOrder.completedTime = '2025-07-17 19:45';
      }
      
      this.setData({
        order: mockOrder,
        loading: false
      });
    }, 500);
  },

  // 预览图片
  previewImage: function(e) {
    const url = e.currentTarget.dataset.url;
    const urls = e.currentTarget.dataset.urls || [url];
    
    wx.previewImage({
      current: url,
      urls: urls
    });
  },

  // 取消订单
  cancelOrder: function() {
    wx.showModal({
      title: '确认取消',
      content: '确定要取消该订单吗？',
      success: (res) => {
        if (res.confirm) {
          this.setData({
            'order.status': 4,
            'order.statusText': '已取消',
            'order.statusClass': 'canceled',
            'order.statusDesc': '订单已取消'
          });
          
          wx.showToast({
            title: '已取消订单',
            icon: 'success'
          });
        }
      }
    });
  },

  // 接单（确认订单）
  confirmOrder: function() {
    this.setData({
      'order.status': 1,
      'order.statusText': '已确认',
      'order.statusClass': 'confirmed',
      'order.statusDesc': '厨师已接单，准备制作'
    });
    
    wx.showToast({
      title: '已接单',
      icon: 'success'
    });
  },

  // 开始制作
  startCooking: function() {
    this.setData({
      'order.status': 2,
      'order.statusText': '制作中',
      'order.statusClass': 'cooking',
      'order.statusDesc': '厨师正在制作中'
    });
    
    wx.showToast({
      title: '开始制作',
      icon: 'success'
    });
  },

  // 完成订单
  completeOrder: function() {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const completedTime = `${year}-${month}-${day} ${hours}:${minutes}`;
    
    this.setData({
      'order.status': 3,
      'order.statusText': '已完成',
      'order.statusClass': 'completed',
      'order.statusDesc': '订单已完成',
      'order.completedTime': completedTime
    });
    
    wx.showToast({
      title: '订单已完成',
      icon: 'success'
    });
  },

  // 跳转到评价页面
  goToReview: function() {
    wx.navigateTo({
      url: `/pages/order/review/review?id=${this.data.order.id}`
    });
  }
});