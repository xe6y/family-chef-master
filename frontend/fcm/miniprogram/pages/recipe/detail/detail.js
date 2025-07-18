// pages/recipe/detail/detail.js
Page({
  data: {
    recipe: {},
    isFavorite: false,
    loading: false
  },

  onLoad: function(options) {
    const id = options.id;
    this.loadRecipeDetail(id);
  },

  // 加载菜谱详情
  loadRecipeDetail: function(id) {
    this.setData({ loading: true });
    
    // 模拟加载菜谱详情
    setTimeout(() => {
      const mockRecipe = {
        id: id,
        name: '红烧肉',
        image: 'https://img.yzcdn.cn/vant/cat.jpeg',
        cuisine: '川菜',
        taste: '咸鲜',
        difficulty: 3,
        cookingTime: 60,
        servingSize: 4,
        chefName: '张大厨',
        chefAvatar: 'https://img.yzcdn.cn/vant/cat.jpeg',
        skillLevel: 5,
        tags: ['家常菜', '肉类', '下饭菜'],
        ingredients: [
          { id: 1, name: '五花肉', amount: 500, unit: 'g' },
          { id: 2, name: '生姜', amount: 3, unit: '片' },
          { id: 3, name: '大葱', amount: 2, unit: '段' },
          { id: 4, name: '料酒', amount: 2, unit: '勺' },
          { id: 5, name: '生抽', amount: 3, unit: '勺' },
          { id: 6, name: '老抽', amount: 1, unit: '勺' },
          { id: 7, name: '冰糖', amount: 30, unit: 'g' }
        ],
        steps: [
          { text: '五花肉切成大块，放入冷水锅中，加入葱姜，料酒，煮开后捞出，冲洗干净', image: 'https://img.yzcdn.cn/vant/cat.jpeg' },
          { text: '锅中放入少量油，加入冰糖小火炒至融化，呈棕色', image: 'https://img.yzcdn.cn/vant/cat.jpeg' },
          { text: '放入焯好的五花肉，翻炒上色', image: 'https://img.yzcdn.cn/vant/cat.jpeg' },
          { text: '加入生抽，老抽，料酒，开水没过肉', image: 'https://img.yzcdn.cn/vant/cat.jpeg' },
          { text: '大火烧开后转小火，盖上锅盖炖1小时', image: 'https://img.yzcdn.cn/vant/cat.jpeg' },
          { text: '最后收汁，出锅装盘', image: 'https://img.yzcdn.cn/vant/cat.jpeg' }
        ],
        tutorialUrl: 'https://www.bilibili.com/video/BV1GJ411x7h7',
        reviews: [
          {
            id: 1,
            userName: '美食家',
            userAvatar: 'https://img.yzcdn.cn/vant/cat.jpeg',
            rating: 5,
            content: '非常好吃，肥而不腻，入口即化！',
            images: ['https://img.yzcdn.cn/vant/cat.jpeg', 'https://img.yzcdn.cn/vant/cat.jpeg'],
            createdAt: '2025-07-15'
          },
          {
            id: 2,
            userName: '吃货小王',
            userAvatar: 'https://img.yzcdn.cn/vant/cat.jpeg',
            rating: 4,
            content: '味道不错，就是有点咸了',
            images: [],
            createdAt: '2025-07-10'
          }
        ]
      };
      
      this.setData({
        recipe: mockRecipe,
        loading: false
      });
    }, 500);
  },

  // 切换收藏状态
  toggleFavorite: function() {
    this.setData({
      isFavorite: !this.data.isFavorite
    });
    
    wx.showToast({
      title: this.data.isFavorite ? '已收藏' : '已取消收藏',
      icon: 'success'
    });
  },

  // 分享菜谱
  shareRecipe: function() {
    wx.showShareMenu({
      withShareTicket: true,
      menus: ['shareAppMessage', 'shareTimeline']
    });
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

  // 打开教程链接
  openTutorial: function() {
    const url = this.data.recipe.tutorialUrl;
    
    // 复制链接到剪贴板
    wx.setClipboardData({
      data: url,
      success: () => {
        wx.showModal({
          title: '链接已复制',
          content: '视频链接已复制到剪贴板，请在浏览器中打开',
          showCancel: false
        });
      }
    });
  },

  // 查看所有评价
  viewAllReviews: function() {
    wx.navigateTo({
      url: `/pages/recipe/reviews/reviews?id=${this.data.recipe.id}`
    });
  },

  // 点餐
  orderRecipe: function() {
    wx.navigateTo({
      url: `/pages/order/create/create?recipeId=${this.data.recipe.id}`
    });
  },

  // 分享给朋友
  onShareAppMessage: function() {
    return {
      title: this.data.recipe.name,
      path: `/pages/recipe/detail/detail?id=${this.data.recipe.id}`,
      imageUrl: this.data.recipe.image
    };
  },

  // 分享到朋友圈
  onShareTimeline: function() {
    return {
      title: this.data.recipe.name,
      query: `id=${this.data.recipe.id}`,
      imageUrl: this.data.recipe.image
    };
  }
});