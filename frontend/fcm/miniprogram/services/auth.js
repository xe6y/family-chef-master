// services/auth.js
const { post, setToken } = require('../utils/request');

// 微信登录
const login = (data) => {
  // 模拟登录，实际项目中应该调用后端API
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      const result = {
        token: 'mock_token_' + Math.random().toString(36).substr(2, 9),
        userInfo: {
          id: 1,
          nickName: data.userInfo.nickName,
          avatarUrl: data.userInfo.avatarUrl,
          gender: data.userInfo.gender,
          hasFamily: true
        }
      };
      
      // 存储token
      setToken(result.token);
      
      resolve(result);
    }, 500);
  });
  
  // 实际API调用
  // return post('/auth/login', data).then(res => {
  //   if (res.token) {
  //     setToken(res.token);
  //   }
  //   return res;
  // });
};

// 退出登录
const logout = () => {
  // 模拟退出登录
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve(true);
    }, 300);
  });
  
  // 实际API调用
  // return post('/auth/logout').then(res => {
  //   clearToken();
  //   return res;
  // });
};

module.exports = {
  login,
  logout
};