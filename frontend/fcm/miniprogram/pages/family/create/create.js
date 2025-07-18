// pages/family/create/create.js
Page({
  data: {
    formData: {
      name: '',
      description: '',
      avatar: ''
    },
    errors: {},
    loading: false
  },

  // 输入家庭名称
  inputName: function(e) {
    this.setData({
      'formData.name': e.detail.value,
      'errors.name': ''
    });
  },

  // 输入家庭简介
  inputDescription: function(e) {
    this.setData({
      'formData.description': e.detail.value
    });
  },

  // 选择图片
  chooseImage: function() {
    wx.chooseImage({
      count: 1,
      sizeType: ['compressed'],
      sourceType: ['album', 'camera'],
      success: (res) => {
        const tempFilePath = res.tempFilePaths[0];
        // 模拟上传图片
        this.setData({
          'formData.avatar': tempFilePath
        });
      }
    });
  },

  // 表单验证
  validateForm: function() {
    let isValid = true;
    const errors = {};
    
    if (!this.data.formData.name) {
      errors.name = '请输入家庭名称';
      isValid = false;
    }
    
    this.setData({ errors });
    return isValid;
  },

  // 提交表单
  submitForm: function(e) {
    if (!this.validateForm()) {
      return;
    }
    
    this.setData({ loading: true });
    
    // 模拟创建家庭
    setTimeout(() => {
      wx.showToast({
        title: '创建成功',
        icon: 'success'
      });
      
      // 延迟跳转
      setTimeout(() => {
        wx.switchTab({
          url: '/pages/index/index'
        });
      }, 1500);
      
      this.setData({ loading: false });
    }, 1000);
  }
});