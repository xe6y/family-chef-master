// services/family.js
const { get, post, put, del } = require('../utils/request');

// 家庭服务
const familyService = {
  // 创建家庭
  createFamily: (familyData) => {
    return post('/families', familyData);
  },

  // 获取家庭信息
  getFamily: (familyId) => {
    return get(`/families/${familyId}`);
  },

  // 更新家庭信息
  updateFamily: (familyId, familyData) => {
    return put(`/families/${familyId}`, familyData);
  },

  // 删除家庭
  deleteFamily: (familyId) => {
    return del(`/families/${familyId}`);
  },

  // 获取家庭成员
  getFamilyMembers: (familyId) => {
    return get(`/families/${familyId}/members`);
  },

  // 添加家庭成员
  addFamilyMember: (familyId, memberData) => {
    return post(`/families/${familyId}/members`, memberData);
  },

  // 移除家庭成员
  removeFamilyMember: (familyId, memberId) => {
    return del(`/families/${familyId}/members/${memberId}`);
  },

  // 更新成员角色
  updateMemberRole: (familyId, memberId, role) => {
    return put(`/families/${familyId}/members/${memberId}/role`, { role });
  },

  // 加入家庭
  joinFamily: (inviteCode) => {
    return post('/families/join', { invite_code: inviteCode });
  }
};

module.exports = familyService;