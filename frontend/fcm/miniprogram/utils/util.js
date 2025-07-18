// utils/util.js

/**
 * 格式化时间
 * @param {Date} date 日期对象
 * @param {String} format 格式字符串，如 'YYYY-MM-DD HH:mm:ss'
 * @return {String} 格式化后的时间字符串
 */
const formatTime = (date, format = 'YYYY-MM-DD HH:mm:ss') => {
  if (!date) return '';
  
  const year = date.getFullYear();
  const month = date.getMonth() + 1;
  const day = date.getDate();
  const hour = date.getHours();
  const minute = date.getMinutes();
  const second = date.getSeconds();

  const formatNumber = n => {
    n = n.toString();
    return n[1] ? n : `0${n}`;
  };

  return format
    .replace('YYYY', year)
    .replace('MM', formatNumber(month))
    .replace('DD', formatNumber(day))
    .replace('HH', formatNumber(hour))
    .replace('mm', formatNumber(minute))
    .replace('ss', formatNumber(second));
};

/**
 * 生成随机字符串
 * @param {Number} length 字符串长度
 * @return {String} 随机字符串
 */
const randomString = (length = 8) => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
};

/**
 * 深拷贝对象
 * @param {Object} obj 要拷贝的对象
 * @return {Object} 拷贝后的对象
 */
const deepClone = (obj) => {
  if (obj === null || typeof obj !== 'object') {
    return obj;
  }
  
  if (obj instanceof Date) {
    return new Date(obj.getTime());
  }
  
  if (obj instanceof Array) {
    return obj.map(item => deepClone(item));
  }
  
  if (obj instanceof Object) {
    const copy = {};
    Object.keys(obj).forEach(key => {
      copy[key] = deepClone(obj[key]);
    });
    return copy;
  }
  
  return obj;
};

/**
 * 防抖函数
 * @param {Function} func 要执行的函数
 * @param {Number} wait 等待时间
 * @return {Function} 防抖后的函数
 */
const debounce = (func, wait = 300) => {
  let timeout;
  return function() {
    const context = this;
    const args = arguments;
    clearTimeout(timeout);
    timeout = setTimeout(() => {
      func.apply(context, args);
    }, wait);
  };
};

/**
 * 节流函数
 * @param {Function} func 要执行的函数
 * @param {Number} wait 等待时间
 * @return {Function} 节流后的函数
 */
const throttle = (func, wait = 300) => {
  let timeout = null;
  let previous = 0;
  
  return function() {
    const context = this;
    const args = arguments;
    const now = Date.now();
    
    if (now - previous > wait) {
      if (timeout) {
        clearTimeout(timeout);
        timeout = null;
      }
      func.apply(context, args);
      previous = now;
    } else if (!timeout) {
      timeout = setTimeout(() => {
        previous = Date.now();
        timeout = null;
        func.apply(context, args);
      }, wait - (now - previous));
    }
  };
};

/**
 * 获取文件扩展名
 * @param {String} filename 文件名
 * @return {String} 文件扩展名
 */
const getFileExt = (filename) => {
  if (!filename) return '';
  return filename.substring(filename.lastIndexOf('.') + 1).toLowerCase();
};

/**
 * 格式化文件大小
 * @param {Number} size 文件大小（字节）
 * @return {String} 格式化后的文件大小
 */
const formatFileSize = (size) => {
  if (size < 1024) {
    return size + 'B';
  } else if (size < 1024 * 1024) {
    return (size / 1024).toFixed(2) + 'KB';
  } else if (size < 1024 * 1024 * 1024) {
    return (size / (1024 * 1024)).toFixed(2) + 'MB';
  } else {
    return (size / (1024 * 1024 * 1024)).toFixed(2) + 'GB';
  }
};

/**
 * 获取当前日期的问候语
 * @return {String} 问候语
 */
const getGreeting = () => {
  const hour = new Date().getHours();
  if (hour < 6) {
    return '凌晨好';
  } else if (hour < 9) {
    return '早上好';
  } else if (hour < 12) {
    return '上午好';
  } else if (hour < 14) {
    return '中午好';
  } else if (hour < 17) {
    return '下午好';
  } else if (hour < 19) {
    return '傍晚好';
  } else {
    return '晚上好';
  }
};

/**
 * 检查对象是否为空
 * @param {Object} obj 要检查的对象
 * @return {Boolean} 是否为空
 */
const isEmpty = (obj) => {
  if (obj === null || obj === undefined) {
    return true;
  }
  
  if (typeof obj === 'string') {
    return obj.trim() === '';
  }
  
  if (Array.isArray(obj)) {
    return obj.length === 0;
  }
  
  if (typeof obj === 'object') {
    return Object.keys(obj).length === 0;
  }
  
  return false;
};

module.exports = {
  formatTime,
  randomString,
  deepClone,
  debounce,
  throttle,
  getFileExt,
  formatFileSize,
  getGreeting,
  isEmpty
};