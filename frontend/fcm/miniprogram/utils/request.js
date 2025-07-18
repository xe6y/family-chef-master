// utils/request.js
const BASE_URL = 'https://api.example.com/api/v1';
const TOKEN_KEY = 'token';

// 获取存储的token
const getToken = () => {
  return wx.getStorageSync(TOKEN_KEY) || '';
};

// 设置token
const setToken = (token) => {
  wx.setStorageSync(TOKEN_KEY, token);
};

// 清除token
const clearToken = () => {
  wx.removeStorageSync(TOKEN_KEY);
};

// 请求拦截器
const request = (options) => {
  return new Promise((resolve, reject) => {
    // 构造请求参数
    const requestOptions = {
      url: BASE_URL + options.url,
      method: options.method || 'GET',
      data: options.data,
      header: {
        'Content-Type': 'application/json',
        ...options.header
      },
      success: (res) => {
        // 请求成功，处理响应
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(res.data);
        } else if (res.statusCode === 401) {
          // 未授权，清除token并跳转到登录页
          clearToken();
          wx.navigateTo({
            url: '/pages/login/login'
          });
          reject(new Error('未授权，请重新登录'));
        } else {
          // 其他错误
          reject(new Error(res.data.message || '请求失败'));
        }
      },
      fail: (err) => {
        // 请求失败
        reject(err);
      }
    };

    // 添加token到请求头
    const token = getToken();
    if (token) {
      requestOptions.header.Authorization = `Bearer ${token}`;
    }

    // 发送请求
    wx.request(requestOptions);
  });
};

// 封装GET请求
const get = (url, data = {}, options = {}) => {
  return request({
    url,
    method: 'GET',
    data,
    ...options
  });
};

// 封装POST请求
const post = (url, data = {}, options = {}) => {
  return request({
    url,
    method: 'POST',
    data,
    ...options
  });
};

// 封装PUT请求
const put = (url, data = {}, options = {}) => {
  return request({
    url,
    method: 'PUT',
    data,
    ...options
  });
};

// 封装DELETE请求
const del = (url, data = {}, options = {}) => {
  return request({
    url,
    method: 'DELETE',
    data,
    ...options
  });
};

module.exports = {
  request,
  get,
  post,
  put,
  del,
  getToken,
  setToken,
  clearToken
};