// services/order.js
const { get, post, put, del } = require('../utils/request');

// 订单服务
const orderService = {
  // 创建订单
  createOrder: (orderData) => {
    return post('/orders', orderData);
  },

  // 获取订单列表
  getOrders: (page = 1, pageSize = 10, status = null) => {
    const params = { page, page_size: pageSize };
    if (status !== null) {
      params.status = status;
    }
    return get('/orders', params);
  },

  // 获取订单详情
  getOrderDetail: (orderId) => {
    return get(`/orders/${orderId}`);
  },

  // 更新订单状态
  updateOrderStatus: (orderId, status) => {
    return put(`/orders/${orderId}/status`, { status });
  },

  // 取消订单
  cancelOrder: (orderId) => {
    return put(`/orders/${orderId}/cancel`);
  },

  // 完成订单
  completeOrder: (orderId) => {
    return put(`/orders/${orderId}/complete`);
  },

  // 删除订单
  deleteOrder: (orderId) => {
    return del(`/orders/${orderId}`);
  },

  // 获取用户订单统计
  getOrderStats: () => {
    return get('/orders/stats');
  }
};

module.exports = orderService; 