// services/menu.js
const { get, post, put, del } = require('../utils/request');

// 菜谱服务
const menuService = {
  // 获取公共菜谱
  getPublicMenus: (page = 1, pageSize = 10) => {
    return get('/menus/public', { page, page_size: pageSize });
  },

  // 获取家庭菜谱
  getFamilyMenus: (familyId, page = 1, pageSize = 10) => {
    return get('/menus/family', { family_id: familyId, page, page_size: pageSize });
  },

  // 获取菜谱详情
  getMenuDetail: (menuId) => {
    return get(`/menus/${menuId}`);
  },

  // 创建菜谱
  createMenu: (menuData) => {
    return post('/menus', menuData);
  },

  // 更新菜谱
  updateMenu: (menuId, menuData) => {
    return put(`/menus/${menuId}`, menuData);
  },

  // 删除菜谱
  deleteMenu: (menuId) => {
    return del(`/menus/${menuId}`);
  },

  // 搜索菜谱
  searchMenus: (keyword, page = 1, pageSize = 10) => {
    return get('/menus/search', { keyword, page, page_size: pageSize });
  },

  // 按分类获取菜谱
  getMenusByCategory: (category, page = 1, pageSize = 10) => {
    return get('/menus/category', { category, page, page_size: pageSize });
  }
};

module.exports = menuService; 