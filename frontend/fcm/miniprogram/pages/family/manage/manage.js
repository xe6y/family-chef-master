// pages/family/manage/manage.js
const familyService = require('../../../services/family');

Page({
  data: {
    family: {},
    isOwner: false,
    loading: false
  },

  onLoad: function(options) {
    this.loadFamilyDetail();
  },

  // 加载家庭详情
  loadFamilyDetail: function() {
    this.setData({ loading: true });
    
    // 获取当前家庭ID，这里假设为1
    const familyId = 1;
    
    familyService.getFamilyDetail(familyId)
      .then(res => {
        this.setData({
          family: res,
          isOwner: res.isOwner
        });
      })
      .catch(err => {
        wx.showToast({
          title: '加载失败，请重试',
          icon: 'none'
        });
      })
      .finally(() => {
        this.setData({ loading: false });
      });
  },

  // 页面导航
  navigateTo: function(e) {
    const url = e.currentTarget.dataset.url;
    wx.navigateTo({ url });
  },

  // 显示邀请码
  showInviteCode: function() {
    this.setData({ loading: true });
    
    familyService.createInvitation(this.data.family.id, 1)
      .then(res => {
        wx.showModal({
          title: '邀请码',
          content: `邀请码: ${res.code}\n有效期至: ${new Date(res.expireAt).toLocaleString()}`,
          showCancel: false,
          confirmText: '复制',
          success: (result) => {
            if (result.confirm) {
              wx.setClipboardData({
                data: res.code,
                success: () => {
                  wx.showToast({
                    title: '已复制到剪贴板',
                    icon: 'success'
                  });
                }
              });
            }
          }
        });
      })
      .catch(err => {
        wx.showToast({
          title: '生成邀请码失败',
          icon: 'none'
        });
      })
      .finally(() => {
        this.setData({ loading: false });
      });
  },

  // 退出家庭
  leaveFamily: function() {
    wx.showModal({
      title: '确认退出',
      content: '确定要退出该家庭吗？',
      success: (res) => {
        if (res.confirm) {
          wx.showToast({
            title: '退出成功',
            icon: 'success'
          });
          
          setTimeout(() => {
            wx.switchTab({
              url: '/pages/index/index'
            });
          }, 1500);
        }
      }
    });
  },

  // 解散家庭
  dissolveFamily: function() {
    wx.showModal({
      title: '确认解散',
      content: '解散家庭后，所有数据将被删除且无法恢复，确定要解散吗？',
      success: (res) => {
        if (res.confirm) {
          wx.showModal({
            title: '二次确认',
            content: '真的确定要解散家庭吗？',
            success: (res) => {
              if (res.confirm) {
                wx.showToast({
                  title: '解散成功',
                  icon: 'success'
                });
                
                setTimeout(() => {
                  wx.switchTab({
                    url: '/pages/index/index'
                  });
                }, 1500);
              }
            }
          });
        }
      }
    });
  }
});