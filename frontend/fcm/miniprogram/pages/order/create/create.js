// pages/order/create/create.js
const app = getApp();
const menuService = require('../../../services/menu');
const orderService = require('../../../services/order');

Page({
  data: {
    // 搜索和筛选
    searchKeyword: '',
    currentCategory: 'all',
    categories: [
      { id: 'all', name: '全部' },
      { id: 'chinese', name: '中餐' },
      { id: 'western', name: '西餐' },
      { id: 'japanese', name: '日料' },
      { id: 'korean', name: '韩料' },
      { id: 'dessert', name: '甜点' }
    ],
    
    // 菜品数据
    recipes: [],
    filteredRecipes: [],
    
    // 购物车
    selectedCount: 0,
    selectedRecipes: [],
    totalPrice: 0,
    
    // 结算相关
    showCheckoutModal: false,
    selectedChefIndex: 0,
    chefOptions: ['随机分配', '张三', '李四', '王五'],
    expectedTime: '',
    remark: '',
    
    // 状态
    loading: false,
    submitting: false
  },

  onLoad: function(options) {
    this.loadRecipes();
  },

  // 加载菜品数据
  loadRecipes: function() {
    this.setData({ loading: true });

    // 获取公共菜谱
    menuService.getPublicMenus(1, 50)
      .then(data => {
        // 转换数据格式
        const recipes = (data.list || data).map(item => ({
          id: item.id,
          name: item.name,
          description: item.description || '暂无描述',
          image: item.image || '/images/default-recipe.png',
          cuisine: item.cuisine || '中餐',
          difficulty: item.difficulty || 1,
          price: item.price || 0,
          chefName: item.chef_name,
          chefAvatar: item.chef_avatar || '/images/default-avatar.png',
          quantity: 0
        }));

        this.setData({
          recipes: recipes,
          filteredRecipes: recipes,
          loading: false
        });
      })
      .catch(err => {
        console.error('加载菜谱失败:', err);
        // 如果接口失败，使用模拟数据
        this.loadMockRecipes();
        this.setData({ loading: false });
      });
  },

  // 加载模拟数据（接口失败时的备用方案）
  loadMockRecipes: function() {
    const recipes = [
      {
        id: 1,
        name: '红烧肉',
        description: '经典家常菜，肥而不腻',
        image: '/images/default-recipe.png',
        cuisine: '中餐',
        difficulty: 2,
        price: 25,
        chefName: '张三',
        chefAvatar: '/images/default-avatar.png',
        quantity: 0
      },
      {
        id: 2,
        name: '宫保鸡丁',
        description: '川菜经典，麻辣鲜香',
        image: '/images/default-recipe.png',
        cuisine: '中餐',
        difficulty: 1,
        price: 20,
        chefName: '李四',
        chefAvatar: '/images/default-avatar.png',
        quantity: 0
      },
      {
        id: 3,
        name: '意大利面',
        description: '经典西式料理',
        image: '/images/default-recipe.png',
        cuisine: '西餐',
        difficulty: 1,
        price: 30,
        chefName: '王五',
        chefAvatar: '/images/default-avatar.png',
        quantity: 0
      },
      {
        id: 4,
        name: '寿司拼盘',
        description: '新鲜美味日料',
        image: '/images/default-recipe.png',
        cuisine: '日料',
        difficulty: 3,
        price: 45,
        chefName: '张三',
        chefAvatar: '/images/default-avatar.png',
        quantity: 0
      },
      {
        id: 5,
        name: '提拉米苏',
        description: '意式经典甜点',
        image: '/images/default-recipe.png',
        cuisine: '甜点',
        difficulty: 2,
        price: 15,
        chefName: '李四',
        chefAvatar: '/images/default-avatar.png',
        quantity: 0
      }
    ];

    this.setData({
      recipes: recipes,
      filteredRecipes: recipes
    });
  },

  // 搜索输入
  onSearchInput: function(e) {
    const keyword = e.detail.value;
    this.setData({ searchKeyword: keyword });
    this.filterRecipes();
  },

  // 清除搜索
  clearSearch: function() {
    this.setData({ searchKeyword: '' });
    this.filterRecipes();
  },

  // 切换分类
  switchCategory: function(e) {
    const categoryId = e.currentTarget.dataset.id;
    this.setData({ currentCategory: categoryId });
    this.filterRecipes();
  },

  // 筛选菜品
  filterRecipes: function() {
    let filtered = this.data.recipes;
    
    // 按分类筛选
    if (this.data.currentCategory !== 'all') {
      filtered = filtered.filter(item => item.cuisine === this.data.categories.find(c => c.id === this.data.currentCategory).name);
    }
    
    // 按关键词搜索
    if (this.data.searchKeyword) {
      const keyword = this.data.searchKeyword.toLowerCase();
      filtered = filtered.filter(item => 
        item.name.toLowerCase().includes(keyword) ||
        item.description.toLowerCase().includes(keyword) ||
        (item.chefName && item.chefName.toLowerCase().includes(keyword))
      );
    }
    
    this.setData({ filteredRecipes: filtered });
  },

  // 增加数量
  increaseQuantity: function(e) {
    const id = e.currentTarget.dataset.id;
    const recipes = this.data.recipes.map(item => {
      if (item.id === id) {
        return { ...item, quantity: item.quantity + 1 };
      }
      return item;
    });
    
    this.setData({ recipes: recipes });
    this.updateCart();
    this.filterRecipes();
  },

  // 减少数量
  decreaseQuantity: function(e) {
    const id = e.currentTarget.dataset.id;
    const recipes = this.data.recipes.map(item => {
      if (item.id === id && item.quantity > 0) {
        return { ...item, quantity: item.quantity - 1 };
      }
      return item;
    });
    
    this.setData({ recipes: recipes });
    this.updateCart();
    this.filterRecipes();
  },

  // 更新购物车
  updateCart: function() {
    const selectedRecipes = this.data.recipes.filter(item => item.quantity > 0);
    const selectedCount = selectedRecipes.reduce((sum, item) => sum + item.quantity, 0);
    const totalPrice = selectedRecipes.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    
    this.setData({
      selectedRecipes: selectedRecipes,
      selectedCount: selectedCount,
      totalPrice: totalPrice
    });
  },

  // 显示结算弹窗
  showCheckoutModal: function() {
    this.setData({ showCheckoutModal: true });
  },

  // 隐藏结算弹窗
  hideCheckoutModal: function() {
    this.setData({ showCheckoutModal: false });
  },

  // 阻止事件冒泡
  stopPropagation: function() {
    // 阻止事件冒泡
  },

  // 选择厨师
  onChefChange: function(e) {
    this.setData({ selectedChefIndex: e.detail.value });
  },

  // 选择时间
  onTimeChange: function(e) {
    this.setData({ expectedTime: e.detail.value });
  },

  // 输入备注
  onRemarkInput: function(e) {
    this.setData({ remark: e.detail.value });
  },

  // 提交订单
  submitOrder: function() {
    if (this.data.selectedCount === 0) {
      wx.showToast({
        title: '请选择菜品',
        icon: 'none'
      });
      return;
    }

    if (!this.data.expectedTime) {
      wx.showToast({
        title: '请选择期望时间',
        icon: 'none'
      });
      return;
    }

    this.setData({ submitting: true });

    // 构建订单数据
    const orderData = {
      user_id: app.globalData.userInfo.id,
      family_id: app.globalData.userInfo.familyID,
      chef_name: this.data.chefOptions[this.data.selectedChefIndex],
      expected_time: this.data.expectedTime,
      remark: this.data.remark,
      total_price: this.data.totalPrice,
      items: this.data.selectedRecipes.map(item => ({
        menu_id: item.id,
        quantity: item.quantity,
        price: item.price
      }))
    };

    // 提交订单到后端
    orderService.createOrder(orderData)
      .then(result => {
        wx.showToast({
          title: '订单提交成功',
          icon: 'success'
        });

        // 清空购物车
        const recipes = this.data.recipes.map(item => ({ ...item, quantity: 0 }));
        this.setData({
          recipes: recipes,
          submitting: false,
          showCheckoutModal: false
        });
        this.updateCart();
        this.filterRecipes();

        // 跳转到订单列表
        setTimeout(() => {
          wx.switchTab({
            url: '/pages/order/list/list'
          });
        }, 1500);
      })
      .catch(err => {
        console.error('提交订单失败:', err);
        this.setData({ submitting: false });
        wx.showToast({
          title: '提交订单失败，请重试',
          icon: 'none'
        });
      });
  }
});