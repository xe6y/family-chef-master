// pages/ingredients/create/create.js
Page({
  data: {
    isEdit: false,
    ingredientId: null,
    saving: false,
    categories: ['蔬菜', '肉类', '海鲜', '乳制品', '谷物', '调味料'],
    categoryIndex: 0,
    formData: {
      name: '',
      category: '',
      price: '',
      stock: '',
      unit: '',
      description: '',
      nutrition: [],
      storage: '',
      usage: '',
      image: ''
    }
  },

  onLoad: function(options) {
    const id = options.id;
    if (id) {
      this.setData({ 
        isEdit: true, 
        ingredientId: id 
      });
      this.loadIngredientData(id);
    }
  },

  // 加载食材数据（编辑模式）
  loadIngredientData: function(id) {
    // 模拟加载食材数据
    const ingredient = {
      id: parseInt(id),
      name: '土豆',
      category: '蔬菜',
      price: '3.5',
      stock: '50',
      unit: '斤',
      description: '新鲜土豆，富含淀粉和维生素C，适合各种烹饪方式。',
      nutrition: [
        { name: '热量', value: '77千卡' },
        { name: '蛋白质', value: '2.0g' },
        { name: '脂肪', value: '0.1g' }
      ],
      storage: '存放在阴凉干燥处，避免阳光直射。',
      usage: '土豆去皮后可以切丝、切片、切块等不同形状。',
      image: '/images/default-recipe.png'
    };

    const categoryIndex = this.data.categories.findIndex(cat => cat === ingredient.category);
    
    this.setData({
      formData: ingredient,
      categoryIndex: categoryIndex >= 0 ? categoryIndex : 0
    });
  },

  // 选择图片
  chooseImage: function() {
    wx.chooseImage({
      count: 1,
      sizeType: ['compressed'],
      sourceType: ['album', 'camera'],
      success: (res) => {
        this.setData({
          'formData.image': res.tempFilePaths[0]
        });
      }
    });
  },

  // 输入处理函数
  onNameInput: function(e) {
    this.setData({ 'formData.name': e.detail.value });
  },

  onCategoryChange: function(e) {
    const index = e.detail.value;
    this.setData({
      categoryIndex: index,
      'formData.category': this.data.categories[index]
    });
  },

  onPriceInput: function(e) {
    this.setData({ 'formData.price': e.detail.value });
  },

  onStockInput: function(e) {
    this.setData({ 'formData.stock': e.detail.value });
  },

  onUnitInput: function(e) {
    this.setData({ 'formData.unit': e.detail.value });
  },

  onDescriptionInput: function(e) {
    this.setData({ 'formData.description': e.detail.value });
  },

  onStorageInput: function(e) {
    this.setData({ 'formData.storage': e.detail.value });
  },

  onUsageInput: function(e) {
    this.setData({ 'formData.usage': e.detail.value });
  },

  // 营养成分管理
  addNutrition: function() {
    const nutrition = this.data.formData.nutrition;
    nutrition.push({ name: '', value: '' });
    this.setData({ 'formData.nutrition': nutrition });
  },

  deleteNutrition: function(e) {
    const index = e.currentTarget.dataset.index;
    const nutrition = this.data.formData.nutrition;
    nutrition.splice(index, 1);
    this.setData({ 'formData.nutrition': nutrition });
  },

  onNutritionNameInput: function(e) {
    const index = e.currentTarget.dataset.index;
    const nutrition = this.data.formData.nutrition;
    nutrition[index].name = e.detail.value;
    this.setData({ 'formData.nutrition': nutrition });
  },

  onNutritionValueInput: function(e) {
    const index = e.currentTarget.dataset.index;
    const nutrition = this.data.formData.nutrition;
    nutrition[index].value = e.detail.value;
    this.setData({ 'formData.nutrition': nutrition });
  },

  // 表单验证
  validateForm: function() {
    const formData = this.data.formData;
    
    if (!formData.name.trim()) {
      wx.showToast({
        title: '请输入食材名称',
        icon: 'none'
      });
      return false;
    }

    if (!formData.category) {
      wx.showToast({
        title: '请选择分类',
        icon: 'none'
      });
      return false;
    }

    return true;
  },

  // 保存食材
  saveIngredient: function() {
    if (!this.validateForm()) {
      return;
    }

    this.setData({ saving: true });

    // 模拟保存操作
    setTimeout(() => {
      wx.showToast({
        title: this.data.isEdit ? '更新成功' : '添加成功',
        icon: 'success'
      });

      this.setData({ saving: false });

      // 返回上一页
      setTimeout(() => {
        wx.navigateBack();
      }, 1500);
    }, 1000);
  },

  // 返回上一页
  goBack: function() {
    wx.navigateBack();
  }
}); 