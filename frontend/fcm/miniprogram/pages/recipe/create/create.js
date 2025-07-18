// pages/recipe/create/create.js
Page({
  data: {
    formData: {
      name: '',
      image: '',
      description: '',
      cuisine: '',
      taste: '',
      difficulty: 1,
      cookingTime: '',
      servingSize: '',
      ingredients: [
        { name: '', amount: '', unit: '' }
      ],
      steps: [
        { text: '', image: '' }
      ],
      tutorialUrl: '',
      tags: [],
      isPrivate: false
    },
    tagInput: '',
    errors: {},
    loading: false,
    cuisineOptions: ['川菜', '粤菜', '湘菜', '鲁菜', '浙菜', '闽菜', '徽菜', '苏菜'],
    cuisineIndex: null,
    tasteOptions: ['酸', '甜', '苦', '辣', '咸', '鲜'],
    tasteIndex: null,
    difficultyOptions: ['1', '2', '3', '4', '5'],
    difficultyIndex: 0
  },

  // 输入菜谱名称
  inputName: function(e) {
    this.setData({
      'formData.name': e.detail.value,
      'errors.name': ''
    });
  },

  // 选择菜谱图片
  chooseImage: function() {
    wx.chooseImage({
      count: 1,
      sizeType: ['compressed'],
      sourceType: ['album', 'camera'],
      success: (res) => {
        const tempFilePath = res.tempFilePaths[0];
        this.setData({
          'formData.image': tempFilePath,
          'errors.image': ''
        });
      }
    });
  },

  // 输入菜谱描述
  inputDescription: function(e) {
    this.setData({
      'formData.description': e.detail.value
    });
  },

  // 选择菜系
  changeCuisine: function(e) {
    const index = e.detail.value;
    this.setData({
      cuisineIndex: index,
      'formData.cuisine': this.data.cuisineOptions[index]
    });
  },

  // 选择口味
  changeTaste: function(e) {
    const index = e.detail.value;
    this.setData({
      tasteIndex: index,
      'formData.taste': this.data.tasteOptions[index]
    });
  },

  // 选择难度
  changeDifficulty: function(e) {
    const index = e.detail.value;
    this.setData({
      difficultyIndex: index,
      'formData.difficulty': parseInt(this.data.difficultyOptions[index])
    });
  },

  // 输入烹饪时间
  inputCookingTime: function(e) {
    this.setData({
      'formData.cookingTime': e.detail.value
    });
  },

  // 输入份量
  inputServingSize: function(e) {
    this.setData({
      'formData.servingSize': e.detail.value
    });
  },

  // 输入食材名称
  inputIngredientName: function(e) {
    const index = e.currentTarget.dataset.index;
    const ingredients = this.data.formData.ingredients;
    ingredients[index].name = e.detail.value;
    this.setData({
      'formData.ingredients': ingredients
    });
  },

  // 输入食材用量
  inputIngredientAmount: function(e) {
    const index = e.currentTarget.dataset.index;
    const ingredients = this.data.formData.ingredients;
    ingredients[index].amount = e.detail.value;
    this.setData({
      'formData.ingredients': ingredients
    });
  },

  // 输入食材单位
  inputIngredientUnit: function(e) {
    const index = e.currentTarget.dataset.index;
    const ingredients = this.data.formData.ingredients;
    ingredients[index].unit = e.detail.value;
    this.setData({
      'formData.ingredients': ingredients
    });
  },

  // 添加食材
  addIngredient: function() {
    const ingredients = this.data.formData.ingredients;
    ingredients.push({ name: '', amount: '', unit: '' });
    this.setData({
      'formData.ingredients': ingredients
    });
  },

  // 删除食材
  deleteIngredient: function(e) {
    const index = e.currentTarget.dataset.index;
    const ingredients = this.data.formData.ingredients;
    
    if (ingredients.length > 1) {
      ingredients.splice(index, 1);
      this.setData({
        'formData.ingredients': ingredients
      });
    } else {
      wx.showToast({
        title: '至少需要一种食材',
        icon: 'none'
      });
    }
  },

  // 输入步骤描述
  inputStepText: function(e) {
    const index = e.currentTarget.dataset.index;
    const steps = this.data.formData.steps;
    steps[index].text = e.detail.value;
    this.setData({
      'formData.steps': steps
    });
  },

  // 选择步骤图片
  chooseStepImage: function(e) {
    const index = e.currentTarget.dataset.index;
    
    wx.chooseImage({
      count: 1,
      sizeType: ['compressed'],
      sourceType: ['album', 'camera'],
      success: (res) => {
        const tempFilePath = res.tempFilePaths[0];
        const steps = this.data.formData.steps;
        steps[index].image = tempFilePath;
        this.setData({
          'formData.steps': steps
        });
      }
    });
  },

  // 添加步骤
  addStep: function() {
    const steps = this.data.formData.steps;
    steps.push({ text: '', image: '' });
    this.setData({
      'formData.steps': steps
    });
  },

  // 删除步骤
  deleteStep: function(e) {
    const index = e.currentTarget.dataset.index;
    const steps = this.data.formData.steps;
    
    if (steps.length > 1) {
      steps.splice(index, 1);
      this.setData({
        'formData.steps': steps
      });
    } else {
      wx.showToast({
        title: '至少需要一个步骤',
        icon: 'none'
      });
    }
  },

  // 输入教程链接
  inputTutorialUrl: function(e) {
    this.setData({
      'formData.tutorialUrl': e.detail.value
    });
  },

  // 输入标签
  inputTag: function(e) {
    this.setData({
      tagInput: e.detail.value
    });
  },

  // 添加标签
  addTag: function(e) {
    const tag = this.data.tagInput.trim();
    
    if (tag) {
      const tags = this.data.formData.tags;
      
      if (tags.indexOf(tag) === -1) {
        tags.push(tag);
        this.setData({
          'formData.tags': tags,
          tagInput: ''
        });
      } else {
        wx.showToast({
          title: '标签已存在',
          icon: 'none'
        });
      }
    }
  },

  // 删除标签
  deleteTag: function(e) {
    const index = e.currentTarget.dataset.index;
    const tags = this.data.formData.tags;
    tags.splice(index, 1);
    this.setData({
      'formData.tags': tags
    });
  },

  // 切换私家菜
  togglePrivate: function(e) {
    this.setData({
      'formData.isPrivate': e.detail.value.includes('private')
    });
  },

  // 表单验证
  validateForm: function() {
    let isValid = true;
    const errors = {};
    const formData = this.data.formData;
    
    if (!formData.name) {
      errors.name = '请输入菜谱名称';
      isValid = false;
    }
    
    if (!formData.image) {
      errors.image = '请上传菜谱图片';
      isValid = false;
    }
    
    // 验证食材
    const validIngredients = formData.ingredients.filter(item => item.name.trim());
    if (validIngredients.length === 0) {
      errors.ingredients = '请至少添加一种食材';
      isValid = false;
    }
    
    // 验证步骤
    const validSteps = formData.steps.filter(item => item.text.trim());
    if (validSteps.length === 0) {
      errors.steps = '请至少添加一个步骤';
      isValid = false;
    }
    
    this.setData({ errors });
    return isValid;
  },

  // 提交表单
  submitForm: function(e) {
    if (!this.validateForm()) {
      wx.showToast({
        title: '请完善菜谱信息',
        icon: 'none'
      });
      return;
    }
    
    this.setData({ loading: true });
    
    // 模拟提交
    setTimeout(() => {
      wx.showToast({
        title: '保存成功',
        icon: 'success'
      });
      
      setTimeout(() => {
        wx.navigateBack();
      }, 1500);
      
      this.setData({ loading: false });
    }, 1000);
  }
});