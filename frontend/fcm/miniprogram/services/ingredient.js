// services/ingredient.js
const { get, post, put, del } = require('../utils/request');

// 食材服务
const ingredientService = {
  // 获取食材列表
  listIngredients: (page = 1, pageSize = 10) => {
    return get('/ingredients', { page, page_size: pageSize });
  },

  // 获取食材详情
  getIngredient: (ingredientId) => {
    return get(`/ingredients/${ingredientId}`);
  },

  // 创建食材
  createIngredient: (ingredientData) => {
    return post('/ingredients', ingredientData);
  },

  // 更新食材
  updateIngredient: (ingredientId, ingredientData) => {
    return put(`/ingredients/${ingredientId}`, ingredientData);
  },

  // 删除食材
  deleteIngredient: (ingredientId) => {
    return del(`/ingredients/${ingredientId}`);
  },

  // 搜索食材
  searchIngredients: (keyword, page = 1, pageSize = 10) => {
    return get('/ingredients/search', { keyword, page, page_size: pageSize });
  },

  // 按分类获取食材
  getIngredientsByCategory: (category, page = 1, pageSize = 10) => {
    return get('/ingredients/category', { category, page, page_size: pageSize });
  },

  // 更新库存
  updateStock: (ingredientId, stock) => {
    return put(`/ingredients/${ingredientId}/stock`, { stock });
  },

  // 获取食材统计
  getIngredientStats: () => {
    return get('/ingredients/stats');
  }
};

module.exports = ingredientService; 