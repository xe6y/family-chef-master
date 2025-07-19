// services/user.js
const { get, post, put, del } = require('../utils/request');

// 用户服务
const userService = {
  // 创建用户
  createUser: (userData) => {
    return post('/users', userData);
  },

  // 获取用户信息
  getUser: (userId) => {
    return get(`/users/${userId}`);
  },

  // 根据OpenID获取用户
  getUserByOpenID: (openID) => {
    return get('/users/openid', { openid: openID });
  },

  // 更新用户信息
  updateUser: (userId, userData) => {
    return put(`/users/${userId}`, userData);
  },

  // 更新用户基本信息
  updateUserProfile: (userId, profileData) => {
    return put(`/users/${userId}/profile`, profileData);
  },

  // 获取用户列表
  listUsers: (page = 1, pageSize = 10) => {
    return get('/users', { page, page_size: pageSize });
  },

  // 搜索用户
  searchUsers: (keyword, page = 1, pageSize = 10) => {
    return get('/users/search', { keyword, page, page_size: pageSize });
  },

  // 获取用户统计
  getUserStats: () => {
    return get('/users/stats');
  },

  // 删除用户
  deleteUser: (userId) => {
    return del(`/users/${userId}`);
  }
};

module.exports = userService; 