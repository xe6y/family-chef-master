// pages/ingredients/list/list.js
Page({
  data: {
    // 搜索和筛选
    searchKeyword: '',
    currentCategory: 'all',
    categories: [
      { id: 'all', name: '全部' },
      { id: 'vegetables', name: '蔬菜' },
      { id: 'meat', name: '肉类' },
      { id: 'seafood', name: '海鲜' },
      { id: 'dairy', name: '乳制品' },
      { id: 'grains', name: '谷物' },
      { id: 'spices', name: '调味料' }
    ],
    
    // 食材数据
    ingredients: [],
    filteredIngredients: []
  },

  onLoad: function(options) {
    this.loadIngredients();
  },

  onShow: function() {
    // 页面显示时刷新数据
    this.loadIngredients();
  },

  // 加载食材数据
  loadIngredients: function() {
    // 模拟食材数据
    const ingredients = [
      {
        id: 1,
        name: '土豆',
        description: '新鲜土豆，适合各种烹饪方式',
        image: '/images/default-recipe.png',
        category: '蔬菜',
        stock: 50,
        price: 3.5
      },
      {
        id: 2,
        name: '胡萝卜',
        description: '营养丰富的胡萝卜',
        image: '/images/default-recipe.png',
        category: '蔬菜',
        stock: 30,
        price: 2.8
      },
      {
        id: 3,
        name: '猪肉',
        description: '新鲜猪肉，肉质鲜嫩',
        image: '/images/default-recipe.png',
        category: '肉类',
        stock: 20,
        price: 25.0
      },
      {
        id: 4,
        name: '鸡蛋',
        description: '新鲜鸡蛋，营养丰富',
        image: '/images/default-recipe.png',
        category: '乳制品',
        stock: 100,
        price: 1.2
      },
      {
        id: 5,
        name: '大米',
        description: '优质大米，口感好',
        image: '/images/default-recipe.png',
        category: '谷物',
        stock: 200,
        price: 5.5
      },
      {
        id: 6,
        name: '盐',
        description: '食用盐，调味必备',
        image: '/images/default-recipe.png',
        category: '调味料',
        stock: 0,
        price: 2.0
      }
    ];

    this.setData({
      ingredients: ingredients,
      filteredIngredients: ingredients
    });
  },

  // 搜索输入
  onSearchInput: function(e) {
    const keyword = e.detail.value;
    this.setData({ searchKeyword: keyword });
    this.filterIngredients();
  },

  // 清除搜索
  clearSearch: function() {
    this.setData({ searchKeyword: '' });
    this.filterIngredients();
  },

  // 切换分类
  switchCategory: function(e) {
    const categoryId = e.currentTarget.dataset.id;
    this.setData({ currentCategory: categoryId });
    this.filterIngredients();
  },

  // 筛选食材
  filterIngredients: function() {
    let filtered = this.data.ingredients;
    
    // 按分类筛选
    if (this.data.currentCategory !== 'all') {
      const categoryName = this.data.categories.find(c => c.id === this.data.currentCategory).name;
      filtered = filtered.filter(item => item.category === categoryName);
    }
    
    // 按关键词搜索
    if (this.data.searchKeyword) {
      const keyword = this.data.searchKeyword.toLowerCase();
      filtered = filtered.filter(item => 
        item.name.toLowerCase().includes(keyword) ||
        item.description.toLowerCase().includes(keyword) ||
        item.category.toLowerCase().includes(keyword)
      );
    }
    
    this.setData({ filteredIngredients: filtered });
  },

  // 跳转到食材详情
  goToDetail: function(e) {
    const id = e.currentTarget.dataset.id;
    wx.navigateTo({
      url: `/pages/ingredients/detail/detail?id=${id}`
    });
  },

  // 跳转到添加食材页面
  goToCreate: function() {
    wx.navigateTo({
      url: '/pages/ingredients/create/create'
    });
  }
}); 