// config/api.js

// 环境配置
const ENV = {
  development: {
    BASE_URL: 'http://localhost:8080/api/v1',
    UPLOAD_URL: 'http://localhost:8080/api/v1/upload'
  },
  production: {
    BASE_URL: 'https://your-production-domain.com/api/v1',
    UPLOAD_URL: 'https://your-production-domain.com/api/v1/upload'
  }
};

// 当前环境（可以通过构建工具或环境变量设置）
const CURRENT_ENV = 'development';

// 导出配置
module.exports = {
  BASE_URL: ENV[CURRENT_ENV].BASE_URL,
  UPLOAD_URL: ENV[CURRENT_ENV].UPLOAD_URL,
  
  // API端点
  ENDPOINTS: {
    // 用户相关
    USERS: '/users',
    USER_BY_OPENID: '/users/openid',
    USER_PROFILE: '/users/:id/profile',
    USER_STATS: '/users/stats',
    
    // 家庭相关
    FAMILIES: '/families',
    FAMILY_MEMBERS: '/families/:id/members',
    
    // 菜谱相关
    MENUS_PUBLIC: '/menus/public',
    MENUS_FAMILY: '/menus/family',
    MENUS_SEARCH: '/menus/search',
    MENUS_CATEGORY: '/menus/category',
    
    // 订单相关
    ORDERS: '/orders',
    ORDER_STATUS: '/orders/:id/status',
    ORDER_CANCEL: '/orders/:id/cancel',
    ORDER_COMPLETE: '/orders/:id/complete',
    ORDER_STATS: '/orders/stats',
    
    // 食材相关
    INGREDIENTS: '/ingredients',
    INGREDIENTS_SEARCH: '/ingredients/search',
    INGREDIENTS_CATEGORY: '/ingredients/category',
    INGREDIENTS_STOCK: '/ingredients/:id/stock',
    INGREDIENTS_STATS: '/ingredients/stats'
  },
  
  // 请求配置
  REQUEST_CONFIG: {
    TIMEOUT: 10000, // 10秒超时
    RETRY_TIMES: 3, // 重试次数
    RETRY_DELAY: 1000 // 重试延迟（毫秒）
  },
  
  // 错误码
  ERROR_CODES: {
    SUCCESS: 200,
    BAD_REQUEST: 400,
    UNAUTHORIZED: 401,
    FORBIDDEN: 403,
    NOT_FOUND: 404,
    INTERNAL_ERROR: 500
  }
}; 