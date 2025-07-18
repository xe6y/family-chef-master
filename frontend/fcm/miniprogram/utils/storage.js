// utils/storage.js

/**
 * 存储数据
 * @param {String} key 键名
 * @param {Any} value 值
 */
const set = (key, value) => {
  try {
    wx.setStorageSync(key, value);
  } catch (e) {
    console.error('存储数据失败:', e);
  }
};

/**
 * 获取数据
 * @param {String} key 键名
 * @param {Any} defaultValue 默认值
 * @return {Any} 存储的值或默认值
 */
const get = (key, defaultValue = null) => {
  try {
    const value = wx.getStorageSync(key);
    return value || defaultValue;
  } catch (e) {
    console.error('获取数据失败:', e);
    return defaultValue;
  }
};

/**
 * 移除数据
 * @param {String} key 键名
 */
const remove = (key) => {
  try {
    wx.removeStorageSync(key);
  } catch (e) {
    console.error('移除数据失败:', e);
  }
};

/**
 * 清除所有数据
 */
const clear = () => {
  try {
    wx.clearStorageSync();
  } catch (e) {
    console.error('清除数据失败:', e);
  }
};

/**
 * 获取所有数据的信息
 * @return {Object} 存储信息
 */
const info = () => {
  try {
    return wx.getStorageInfoSync();
  } catch (e) {
    console.error('获取存储信息失败:', e);
    return { keys: [], currentSize: 0, limitSize: 0 };
  }
};

/**
 * 存储对象数据
 * @param {String} key 键名
 * @param {Object} obj 对象
 */
const setObject = (key, obj) => {
  try {
    const jsonString = JSON.stringify(obj);
    wx.setStorageSync(key, jsonString);
  } catch (e) {
    console.error('存储对象数据失败:', e);
  }
};

/**
 * 获取对象数据
 * @param {String} key 键名
 * @param {Object} defaultValue 默认值
 * @return {Object} 存储的对象或默认值
 */
const getObject = (key, defaultValue = {}) => {
  try {
    const jsonString = wx.getStorageSync(key);
    if (!jsonString) return defaultValue;
    return JSON.parse(jsonString);
  } catch (e) {
    console.error('获取对象数据失败:', e);
    return defaultValue;
  }
};

module.exports = {
  set,
  get,
  remove,
  clear,
  info,
  setObject,
  getObject
};