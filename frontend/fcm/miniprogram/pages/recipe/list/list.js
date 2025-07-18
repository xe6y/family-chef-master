// pages/recipe/list/list.js
Page({
  data: {
    recipes: [],
    searchKeyword: '',
    activeFilter: '', // cuisine, taste, ingredient
    filterOptions: {
      cuisine: [
        { label: '川菜', value: '川菜', selected: false },
        { label: '粤菜', value: '粤菜', selected: false },
        { label: '湘菜', value: '湘菜', selected: false },
        { label: '鲁菜', value: '鲁菜', selected: false },
        { label: '浙菜', value: '浙菜', selected: false },
        { label: '闽菜', value: '闽菜', selected: false },
        { label: '徽菜', value: '徽菜', selected: false },
        { label: '苏菜', value: '苏菜', selected: false }
      ],
      taste: [
        { label: '酸', value: '酸', selected: false },
        { label: '甜', value: '甜', selected: false },
        { label: '苦', value: '苦', selected: false },
        { label: '辣', value: '辣', selected: false },
        { label: '咸', value: '咸', selected: false },
        { label: '鲜', value: '鲜', selected: false }
      ],
      ingredient: [
        { label: '肉类', value: '肉类', selected: false },
        { label: '蔬菜', value: '蔬菜', selected: false },
        { label: '海鲜', value: '海鲜', selected: false },
        { label: '豆制品', value: '豆制品', selected: false },
        { label: '蛋类', value: '蛋类', selected: false },
        { label: '菌类', value: '菌类', selected: false }
      ]
    },
    appliedFilters: {
      cuisine: [],
      taste: [],
      ingredient: []
    },
    loading: false,
    page: 1,
    hasMore: true
  },

  onLoad: function(options) {
    this.loadMockRecipes();
  },

  onPullDownRefresh: function() {
    this.setData({
      recipes: [],
      page: 1,
      hasMore: true
    });
    this.loadMockRecipes();
    wx.stopPullDownRefresh();
  },

  onReachBottom: function() {
    if (this.data.hasMore && !this.data.loading) {
      this.loadMoreMockRecipes();
    }
  },

  // 加载模拟菜谱数据
  loadMockRecipes: function() {
    this.setData({ loading: true });
    
    // 模拟数据
    const mockRecipes = [
      {
        id: 1,
        name: '红烧肉',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        cuisine: '川菜',
        difficulty: 3,
        chefName: '张大厨',
        chefAvatar: 'https://img.yzcdn.cn/vant/cat.jpeg'
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
        difficulty: 2,
        chefName: '李师傅',
        chefAvatar: 'https://img.yzcdn.cn/vant/cat.jpeg'
      },
      {
        id: 4,
        name: '鱼香肉丝',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        cuisine: '湘菜',
        difficulty: 3
      }
    ];
    
    setTimeout(() => {
      this.setData({
        recipes: mockRecipes,
        loading: false
      });
    }, 500);
  },

  // 加载更多模拟菜谱
  loadMoreMockRecipes: function() {
    if (this.data.loading) return;
    
    this.setData({ 
      loading: true,
      page: this.data.page + 1
    });
    
    // 模拟更多数据
    const moreMockRecipes = [
      {
        id: 5,
        name: '宫保鸡丁',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        cuisine: '川菜',
        difficulty: 3
      },
      {
        id: 6,
        name: '水煮鱼',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        cuisine: '川菜',
        difficulty: 4,
        chefName: '王厨师',
        chefAvatar: 'https://img.yzcdn.cn/vant/cat.jpeg'
      }
    ];
    
    setTimeout(() => {
      if (this.data.page <= 2) {
        this.setData({
          recipes: [...this.data.recipes, ...moreMockRecipes],
          loading: false
        });
      } else {
        this.setData({
          hasMore: false,
          loading: false
        });
      }
    }, 500);
  },

  // 搜索输入
  onSearchInput: function(e) {
    this.setData({
      searchKeyword: e.detail.value
    });
  },

  // 执行搜索
  onSearch: function() {
    // 模拟搜索
    wx.showToast({
      title: '搜索: ' + this.data.searchKeyword,
      icon: 'none'
    });
    this.loadMockRecipes();
  },

  // 清除搜索
  clearSearch: function() {
    this.setData({
      searchKeyword: ''
    });
    this.loadMockRecipes();
  },

  // 切换筛选面板
  toggleFilter: function(e) {
    const type = e.currentTarget.dataset.type;
    
    if (this.data.activeFilter === type) {
      this.setData({ activeFilter: '' });
    } else {
      this.setData({ activeFilter: type });
    }
  },

  // 选择筛选选项
  selectFilterOption: function(e) {
    const index = e.currentTarget.dataset.index;
    const type = this.data.activeFilter;
    const options = [...this.data.filterOptions[type]];
    
    options[index].selected = !options[index].selected;
    
    this.setData({
      [`filterOptions.${type}`]: options
    });
  },

  // 重置筛选
  resetFilter: function() {
    const type = this.data.activeFilter;
    const options = this.data.filterOptions[type].map(item => ({
      ...item,
      selected: false
    }));
    
    this.setData({
      [`filterOptions.${type}`]: options
    });
  },

  // 确认筛选
  confirmFilter: function() {
    const type = this.data.activeFilter;
    const selectedValues = this.data.filterOptions[type]
      .filter(item => item.selected)
      .map(item => item.value);
    
    this.setData({
      [`appliedFilters.${type}`]: selectedValues,
      activeFilter: ''
    });
    
    // 模拟筛选
    wx.showToast({
      title: '已应用筛选',
      icon: 'none'
    });
    this.loadMockRecipes();
  },

  // 跳转到菜谱详情
  goToDetail: function(e) {
    const id = e.currentTarget.dataset.id;
    wx.navigateTo({
      url: `/pages/recipe/detail/detail?id=${id}`
    });
  },

  // 跳转到创建菜谱
  goToCreate: function() {
    wx.navigateTo({
      url: '/pages/recipe/create/create'
    });
  }
});