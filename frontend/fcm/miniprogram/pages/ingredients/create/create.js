// pages/order/create/create.js
Page({
  data: {
    recipes: [],
    chefs: [],
    selectedChefId: 0,
    expectedTime: '',
    remark: '',
    selectedCount: 0,
    loading: false
  },

  onLoad: function(options) {
    // 如果有指定菜谱ID，则预选该菜谱
    const recipeId = options.recipeId;
    
    this.loadRecipes(recipeId);
    this.loadChefs();
  },

  // 加载菜谱列表
  loadRecipes: function(selectedId) {
    // 模拟加载菜谱列表
    setTimeout(() => {
      const mockRecipes = [
        {
          id: 1,
          name: '红烧肉',
          image: 'https://img.yzcdn.cn/vant/cat.jpeg',
          cuisine: '川菜',
          difficulty: 3,
          chefName: '张大厨',
          chefAvatar: 'https://img.yzcdn.cn/vant/cat.jpeg',
          selected: selectedId == 1,
          quantity: selectedId == 1 ? 1 : 0
        },
        {
          id: 2,
          name: '糖醋排骨',
          image: 'https://img.yzcdn.cn/vant/cat.jpeg',
          cuisine: '粤菜',
          difficulty: 4,
          selected: selectedId == 2,
          quantity: selectedId == 2 ? 1 : 0
        },
        {
          id: 3,
          name: '麻婆豆腐',
          image: 'https://img.yzcdn.cn/vant/cat.jpeg',
          cuisine: '川菜',
          difficulty: 2,
          chefName: '李师傅',
          chefAvatar: 'https://img.yzcdn.cn/vant/cat.jpeg',
          selected: selectedId == 3,
          quantity: selectedId == 3 ? 1 : 0
        },
        {
          id: 4,
          name: '鱼香肉丝',
          image: 'https://img.yzcdn.cn/vant/cat.jpeg',
          cuisine: '湘菜',
          difficulty: 3,
          selected: selectedId == 4,
          quantity: selectedId == 4 ? 1 : 0
        }
      ];
      
      this.setData({
        recipes: mockRecipes,
        selectedCount: selectedId ? 1 : 0
      });
    }, 500);
  },

  // 加载厨师列表
  loadChefs: function() {
    // 模拟加载厨师列表
    setTimeout(() => {
      const mockChefs = [
        {
          id: 1,
          name: '张大厨',
          avatar: 'https://img.yzcdn.cn/vant/cat.jpeg',
          skillCount: 3
        },
        {
          id: 2,
          name: '李师傅',
          avatar: 'https://img.yzcdn.cn/vant/cat.jpeg',
          skillCount: 2
        },
        {
          id: 3,
          name: '王厨师',
          avatar: 'https://img.yzcdn.cn/vant/cat.jpeg',
          skillCount: 1
        }
      ];
      
      this.setData({
        chefs: mockChefs
      });
    }, 500);
  },

  // 选择/取消选择菜谱
  toggleRecipe: function(e) {
    const id = e.currentTarget.dataset.id;
    const recipes = this.data.recipes;
    const index = recipes.findIndex(item => item.id === id);
    
    if (index !== -1) {
      const selected = !recipes[index].selected;
      recipes[index].selected = selected;
      recipes[index].quantity = selected ? 1 : 0;
      
      let selectedCount = 0;
      recipes.forEach(item => {
        if (item.selected) {
          selectedCount += item.quantity;
        }
      });
      
      this.setData({
        recipes,
        selectedCount
      });
    }
  },

  // 阻止事件冒泡
  stopPropagation: function(e) {
    return;
  },

  // 减少菜品数量
  decreaseQuantity: function(e) {
    const id = e.currentTarget.dataset.id;
    const recipes = this.data.recipes;
    const index = recipes.findIndex(item => item.id === id);
    
    if (index !== -1 && recipes[index].quantity > 0) {
      recipes[index].quantity--;
      
      if (recipes[index].quantity === 0) {
        recipes[index].selected = false;
      }
      
      let selectedCount = 0;
      recipes.forEach(item => {
        if (item.selected) {
          selectedCount += item.quantity;
        }
      });
      
      this.setData({
        recipes,
        selectedCount
      });
    }
  },

  // 增加菜品数量
  increaseQuantity: function(e) {
    const id = e.currentTarget.dataset.id;
    const recipes = this.data.recipes;
    const index = recipes.findIndex(item => item.id === id);
    
    if (index !== -1) {
      recipes[index].quantity++;
      recipes[index].selected = true;
      
      let selectedCount = 0;
      recipes.forEach(item => {
        if (item.selected) {
          selectedCount += item.quantity;
        }
      });
      
      this.setData({
        recipes,
        selectedCount
      });
    }
  },

  // 输入菜品数量
  inputQuantity: function(e) {
    const id = e.currentTarget.dataset.id;
    const value = parseInt(e.detail.value) || 0;
    const recipes = this.data.recipes;
    const index = recipes.findIndex(item => item.id === id);
    
    if (index !== -1) {
      recipes[index].quantity = value;
      recipes[index].selected = value > 0;
      
      let selectedCount = 0;
      recipes.forEach(item => {
        if (item.selected) {
          selectedCount += item.quantity;
        }
      });
      
      this.setData({
        recipes,
        selectedCount
      });
    }
  },

  // 选择厨师
  selectChef: function(e) {
    const id = e.currentTarget.dataset.id;
    this.setData({
      selectedChefId: id
    });
  },

  // 选择期望完成时间
  changeExpectedTime: function(e) {
    this.setData({
      expectedTime: e.detail.value
    });
  },

  // 输入备注
  inputRemark: function(e) {
    this.setData({
      remark: e.detail.value
    });
  },

  // 跳转到菜谱列表
  goToRecipeList: function() {
    wx.switchTab({
      url: '/pages/recipe/list/list'
    });
  },

  // 提交订单
  submitOrder: function() {
    if (this.data.selectedCount === 0) {
      return;
    }
    
    this.setData({ loading: true });
    
    // 构建订单数据
    const orderData = {
      chefId: this.data.selectedChefId,
      expectedTime: this.data.expectedTime,
      remark: this.data.remark,
      items: this.data.recipes
        .filter(item => item.selected && item.quantity > 0)
        .map(item => ({
          recipeId: item.id,
          quantity: item.quantity
        }))
    };
    
    // 模拟提交订单
    setTimeout(() => {
      console.log('提交订单:', orderData);
      
      wx.showToast({
        title: '下单成功',
        icon: 'success'
      });
      
      setTimeout(() => {
        wx.redirectTo({
          url: '/pages/order/list/list'
        });
      }, 1500);
      
      this.setData({ loading: false });
    }, 1000);
  }
});