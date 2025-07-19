// pages/ingredients/detail/detail.js
const ingredientService = require('../../../services/ingredient');

Page({
  data: {
    ingredient: {},
    isFavorite: false,
    quantity: 1,
    relatedRecipes: [],
    loading: false
  },

  onLoad: function(options) {
    const id = options.id;
    if (id) {
      this.loadIngredientDetail(id);
      this.loadRelatedRecipes(id);
    }
  },

  // 加载食材详情
  loadIngredientDetail: function(id) {
    this.setData({ loading: true });

    ingredientService.getIngredient(id)
      .then(ingredient => {
        // 转换数据格式
        const formattedIngredient = {
          id: ingredient.id,
          name: ingredient.name,
          description: ingredient.description || '暂无描述',
          image: ingredient.image || '/images/default-recipe.png',
          category: ingredient.category || '其他',
          stock: ingredient.stock || 0,
          price: ingredient.price || 0,
          unit: ingredient.unit || '件',
          nutrition: ingredient.nutrition || [],
          storage: ingredient.storage || '',
          usage: ingredient.usage || ''
        };

        this.setData({ 
          ingredient: formattedIngredient,
          loading: false
        });
      })
      .catch(err => {
        console.error('加载食材详情失败:', err);
        // 如果接口失败，使用模拟数据
        this.loadMockIngredientDetail(id);
        this.setData({ loading: false });
      });
  },

  // 加载模拟食材详情数据（接口失败时的备用方案）
  loadMockIngredientDetail: function(id) {
    const ingredient = {
      id: parseInt(id),
      name: '土豆',
      description: '新鲜土豆，富含淀粉和维生素C，适合各种烹饪方式。可以炒、煮、烤、炸等多种做法，是家庭烹饪的常用食材。',
      image: '/images/default-recipe.png',
      category: '蔬菜',
      stock: 50,
      price: 3.5,
      unit: '斤',
      nutrition: [
        { name: '热量', value: '77千卡' },
        { name: '蛋白质', value: '2.0g' },
        { name: '脂肪', value: '0.1g' },
        { name: '碳水化合物', value: '17.2g' },
        { name: '膳食纤维', value: '2.2g' },
        { name: '维生素C', value: '27mg' }
      ],
      storage: '存放在阴凉干燥处，避免阳光直射。室温下可保存1-2周，冰箱冷藏可保存更长时间。',
      usage: '土豆去皮后可以切丝、切片、切块等不同形状。炒制时注意火候，避免糊锅。煮制时加入适量盐调味。'
    };

    this.setData({ ingredient: ingredient });
  },

  // 加载相关菜谱
  loadRelatedRecipes: function(ingredientId) {
    // 这里可以调用菜谱服务获取相关菜谱
    // 暂时使用模拟数据
    const recipes = [
      {
        id: 1,
        name: '土豆丝炒肉',
        image: '/images/default-recipe.png'
      },
      {
        id: 2,
        name: '土豆炖牛肉',
        image: '/images/default-recipe.png'
      },
      {
        id: 3,
        name: '土豆泥',
        image: '/images/default-recipe.png'
      },
      {
        id: 4,
        name: '炸薯条',
        image: '/images/default-recipe.png'
      }
    ];

    this.setData({ relatedRecipes: recipes });
  },

  // 返回上一页
  goBack: function() {
    wx.navigateBack();
  },

  // 切换收藏状态
  toggleFavorite: function() {
    const isFavorite = !this.data.isFavorite;
    this.setData({ isFavorite: isFavorite });
    
    wx.showToast({
      title: isFavorite ? '已收藏' : '已取消收藏',
      icon: 'success'
    });
  },

  // 分享食材
  shareIngredient: function() {
    wx.showShareMenu({
      withShareTicket: true,
      menus: ['shareAppMessage', 'shareTimeline']
    });
  },

  // 增加数量
  increaseQuantity: function() {
    this.setData({
      quantity: this.data.quantity + 1
    });
  },

  // 减少数量
  decreaseQuantity: function() {
    if (this.data.quantity > 1) {
      this.setData({
        quantity: this.data.quantity - 1
      });
    }
  },

  // 查看更多菜谱
  viewMoreRecipes: function() {
    wx.navigateTo({
      url: '/pages/recipe/list/list?ingredient=' + this.data.ingredient.name
    });
  },

  // 跳转到菜谱详情
  goToRecipe: function(e) {
    const id = e.currentTarget.dataset.id;
    wx.navigateTo({
      url: `/pages/recipe/detail/detail?id=${id}`
    });
  },

  // 编辑食材
  editIngredient: function() {
    wx.navigateTo({
      url: `/pages/ingredients/create/create?id=${this.data.ingredient.id}`
    });
  },

  // 删除食材
  deleteIngredient: function() {
    wx.showModal({
      title: '确认删除',
      content: '确定要删除这个食材吗？删除后无法恢复。',
      confirmText: '删除',
      confirmColor: '#f5222d',
      success: (res) => {
        if (res.confirm) {
          wx.showLoading({
            title: '删除中...'
          });
          
          ingredientService.deleteIngredient(this.data.ingredient.id)
            .then(() => {
              wx.hideLoading();
              wx.showToast({
                title: '删除成功',
                icon: 'success'
              });
              
              // 返回上一页
              setTimeout(() => {
                wx.navigateBack();
              }, 1500);
            })
            .catch(err => {
              wx.hideLoading();
              console.error('删除食材失败:', err);
              wx.showToast({
                title: '删除失败，请重试',
                icon: 'none'
              });
            });
        }
      }
    });
  },

  // 分享配置
  onShareAppMessage: function() {
    return {
      title: `${this.data.ingredient.name} - 食材详情`,
      path: `/pages/ingredients/detail/detail?id=${this.data.ingredient.id}`,
      imageUrl: this.data.ingredient.image
    };
  },

  onShareTimeline: function() {
    return {
      title: `${this.data.ingredient.name} - 食材详情`,
      imageUrl: this.data.ingredient.image
    };
  }
}); 