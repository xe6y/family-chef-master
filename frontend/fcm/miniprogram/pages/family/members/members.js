// pages/family/members/members.js
const familyService = require('../../../services/family');

Page({
  data: {
    members: [],
    searchKeyword: '',
    loading: false,
    isOwner: false
  },

  onLoad: function(options) {
    this.loadMembers();
  },

  // 加载家庭成员
  loadMembers: function() {
    this.setData({ loading: true });
    
    // 获取当前家庭ID，这里假设为1
    const familyId = 1;
    
    familyService.getFamilyMembers(familyId)
      .then(res => {
        this.setData({
          members: res.data,
          // 假设当前用户是一家之主
          isOwner: true
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

  // 搜索输入
  onSearchInput: function(e) {
    this.setData({
      searchKeyword: e.detail.value
    });
  },

  // 执行搜索
  onSearch: function() {
    // 简单的前端搜索，实际项目中可能需要调用API
    const keyword = this.data.searchKeyword.toLowerCase();
    
    familyService.getFamilyMembers(1)
      .then(res => {
        if (keyword) {
          const filteredMembers = res.data.filter(member => 
            member.nickname.toLowerCase().includes(keyword) || 
            member.roleName.toLowerCase().includes(keyword)
          );
          this.setData({ members: filteredMembers });
        } else {
          this.setData({ members: res.data });
        }
      });
  },

  // 清除搜索
  clearSearch: function() {
    this.setData({
      searchKeyword: ''
    });
    this.loadMembers();
  },

  // 显示成员操作菜单
  showMemberActions: function(e) {
    const member = e.currentTarget.dataset.member;
    
    // 如果不是一家之主，或者点击的是自己，不显示操作菜单
    if (!this.data.isOwner || member.role === 'owner') {
      return;
    }
    
    wx.showActionSheet({
      itemList: ['设为主厨', '设为美食家', '设为洗碗工', '设为普通成员', '移出家庭'],
      success: (res) => {
        let role = '';
        switch (res.tapIndex) {
          case 0:
            role = 'chef';
            break;
          case 1:
            role = 'foodie';
            break;
          case 2:
            role = 'cleaner';
            break;
          case 3:
            role = 'member';
            break;
          case 4:
            this.removeMember(member);
            return;
        }
        
        if (role) {
          this.updateMemberRole(member, role);
        }
      }
    });
  },

  // 更新成员角色
  updateMemberRole: function(member, role) {
    this.setData({ loading: true });
    
    familyService.updateMemberRole(member.id, role)
      .then(res => {
        wx.showToast({
          title: '更新成功',
          icon: 'success'
        });
        
        // 重新加载成员列表
        this.loadMembers();
      })
      .catch(err => {
        wx.showToast({
          title: '更新失败，请重试',
          icon: 'none'
        });
      })
      .finally(() => {
        this.setData({ loading: false });
      });
  },

  // 移出成员
  removeMember: function(member) {
    wx.showModal({
      title: '确认移出',
      content: `确定要将 ${member.nickname} 移出家庭吗？`,
      success: (res) => {
        if (res.confirm) {
          wx.showToast({
            title: '移出成功',
            icon: 'success'
          });
          
          // 模拟移出成功，重新加载成员列表
          this.loadMembers();
        }
      }
    });
  },

  // 邀请成员
  inviteMember: function() {
    wx.navigateTo({
      url: '/pages/family/invite/invite'
    });
  }
});