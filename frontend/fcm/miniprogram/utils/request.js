// utils/request.js
const config = require('../config/api');

const BASE_URL = config.BASE_URL;
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
      timeout: config.REQUEST_CONFIG.TIMEOUT,
      success: (res) => {
        console.log('API响应:', res);
        // 请求成功，处理响应
        if (res.statusCode >= 200 && res.statusCode < 300) {
          // 检查后端返回的数据格式
          if (res.data && res.data.code === config.ERROR_CODES.SUCCESS) {
            console.log('API成功，返回数据:', res.data.data);
            resolve(res.data.data);
          } else {
            // 后端返回错误
            const errorMsg = res.data.message || '请求失败';
            console.error('API错误:', errorMsg, res.data);
            wx.showToast({
              title: errorMsg,
              icon: 'none'
            });
            reject(new Error(errorMsg));
          }
        } else if (res.statusCode === config.ERROR_CODES.UNAUTHORIZED) {
          // 未授权，清除token并跳转到登录页
          clearToken();
          wx.showToast({
            title: '登录已过期，请重新登录',
            icon: 'none'
          });
          setTimeout(() => {
            wx.navigateTo({
              url: '/pages/login/login'
            });
          }, 1500);
          reject(new Error('未授权，请重新登录'));
        } else {
          // 其他错误
          const errorMsg = res.data.message || '请求失败';
          wx.showToast({
            title: errorMsg,
            icon: 'none'
          });
          reject(new Error(errorMsg));
        }
      },
      fail: (err) => {
        // 请求失败
        console.error('请求失败:', err);
        wx.showToast({
          title: '网络请求失败',
          icon: 'none'
        });
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

// 文件上传
const uploadFile = (filePath, options = {}) => {
  return new Promise((resolve, reject) => {
    const token = getToken();
    const uploadOptions = {
      url: config.UPLOAD_URL,
      filePath: filePath,
      name: 'file',
      header: {
        'Authorization': token ? `Bearer ${token}` : ''
      },
      success: (res) => {
        if (res.statusCode === 200) {
          const data = JSON.parse(res.data);
          if (data.code === config.ERROR_CODES.SUCCESS) {
            resolve(data.data);
          } else {
            reject(new Error(data.message || '上传失败'));
          }
        } else {
          reject(new Error('上传失败'));
        }
      },
      fail: (err) => {
        reject(err);
      },
      ...options
    };

    wx.uploadFile(uploadOptions);
  });
};

module.exports = {
  request,
  get,
  post,
  put,
  del,
  uploadFile,
  getToken,
  setToken,
  clearToken
};