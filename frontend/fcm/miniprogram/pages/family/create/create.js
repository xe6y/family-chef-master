// pages/family/create/create.js
const app = getApp();
const { post } = require('../../../utils/request');

Page({
  data: {
    userInfo: null,
    formData: {
      name: '',
      description: '',
      avatar: ''
    },
    errors: {},
    loading: false,
    showAvatarPicker: false
  },

  onLoad: function(options) {
    // 获取从注册页面传递的用户信息
    if (options.userInfo) {
      const userInfo = JSON.parse(decodeURIComponent(options.userInfo));
      this.setData({ userInfo: userInfo });
    }
  },

  // 输入家庭名称
  inputName: function(e) {
    this.setData({
      'formData.name': e.detail.value,
      'errors.name': ''
    });
  },

  // 输入家庭描述
  inputDescription: function(e) {
    this.setData({
      'formData.description': e.detail.value,
      'errors.description': ''
    });
  },

  // 选择头像
  chooseAvatar: function() {
    wx.chooseImage({
      count: 1,
      sizeType: ['compressed'],
      sourceType: ['album', 'camera'],
      success: (res) => {
        const tempFilePath = res.tempFilePaths[0];
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
    
    if (!this.data.formData.name.trim()) {
      errors.name = '请输入家庭名称';
      isValid = false;
    }
    
    if (this.data.formData.name.length > 20) {
      errors.name = '家庭名称不能超过20个字符';
      isValid = false;
    }
    
    if (this.data.formData.description.length > 100) {
      errors.description = '家庭描述不能超过100个字符';
      isValid = false;
    }
    
    this.setData({ errors });
    return isValid;
  },

  // 提交创建家庭
  submitCreate: function() {
    if (!this.validateForm()) {
      return;
    }
    
    this.setData({ loading: true });
    
    const familyData = {
      name: this.data.formData.name.trim(),
      description: this.data.formData.description.trim(),
      avatar: this.data.formData.avatar,
      owner_id: this.data.userInfo.id
    };

    // 如果有头像，先上传
    if (this.data.formData.avatar) {
      this.uploadAvatarAndCreate(familyData);
    } else {
      this.createFamily(familyData);
    }
  },

  // 上传头像并创建家庭
  uploadAvatarAndCreate: function(familyData) {
    wx.uploadFile({
      url: 'http://localhost:8080/api/v1/upload',
      filePath: this.data.formData.avatar,
      name: 'file',
      success: (res) => {
        const data = JSON.parse(res.data);
        if (data.code === 200) {
          familyData.avatar = data.data.url;
          this.createFamily(familyData);
        } else {
          this.setData({ loading: false });
          wx.showToast({
            title: '头像上传失败',
            icon: 'none'
          });
        }
      },
      fail: () => {
        this.setData({ loading: false });
        wx.showToast({
          title: '头像上传失败',
          icon: 'none'
        });
      }
    });
  },

  // 创建家庭
  createFamily: function(familyData) {
    post('/families', familyData)
      .then(family => {
        // 更新用户信息
        return post(`/users/${this.data.userInfo.id}`, {
          family_id: family.id,
          family_role: 'owner'
        }).then(() => {
          return family;
        });
      })
      .then(family => {
        // 更新全局用户信息
        app.globalData.userInfo = {
          ...this.data.userInfo,
          familyID: family.id,
          familyRole: 'owner'
        };

        wx.showToast({
          title: '家庭创建成功',
          icon: 'success'
        });

        // 跳转到身份选择页面
        const userInfo = {
          ...this.data.userInfo,
          familyID: family.id,
          familyRole: 'owner'
        };
        const userInfoStr = encodeURIComponent(JSON.stringify(userInfo));
        
        setTimeout(() => {
          wx.navigateTo({
            url: `/pages/register/role-select?userInfo=${userInfoStr}`
          });
        }, 1500);
      })
      .catch(err => {
        console.error('创建家庭失败:', err);
        wx.showToast({
          title: err.message || '创建家庭失败，请重试',
          icon: 'none'
        });
      })
      .finally(() => {
        this.setData({ loading: false });
      });
  },

  // 跳过创建家庭
  skipCreate: function() {
    wx.showModal({
      title: '提示',
      content: '跳过创建家庭将无法使用家庭相关功能，确定要跳过吗？',
      success: (res) => {
        if (res.confirm) {
          // 直接跳转到身份选择页面
          const userInfoStr = encodeURIComponent(JSON.stringify(this.data.userInfo));
          wx.navigateTo({
            url: `/pages/register/role-select?userInfo=${userInfoStr}`
          });
        }
      }
    });
  },

  // 返回上一页
  goBack: function() {
    wx.navigateBack();
  }
});