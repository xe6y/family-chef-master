// services/family.js
const { get, post, put } = require('../utils/request');

// 创建家庭
const createFamily = (data) => {
  // 模拟创建家庭
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      resolve({
        id: Math.floor(Math.random() * 1000) + 1,
        name: data.name,
        description: data.description,
        avatar: data.avatar,
        inviteCode: 'FAM' + Math.random().toString(36).substr(2, 6).toUpperCase()
      });
    }, 500);
  });
  
  // 实际API调用
  // return post('/family', data);
};

// 获取家庭列表
const getFamilyList = () => {
  // 模拟获取家庭列表
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        data: [
          {
            id: 1,
            name: '我的家庭',
            description: '这是我的第一个家庭',
            avatar: 'https://img.yzcdn.cn/vant/cat.jpeg',
            memberCount: 3,
            isOwner: true
          }
        ]
      });
    }, 300);
  });
  
  // 实际API调用
  // return get('/family');
};

// 获取家庭详情
const getFamilyDetail = (id) => {
  // 模拟获取家庭详情
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        id: id,
        name: '我的家庭',
        description: '这是我的第一个家庭',
        avatar: 'https://img.yzcdn.cn/vant/cat.jpeg',
        inviteCode: 'FAM123456',
        memberCount: 3,
        isOwner: true,
        createdAt: '2025-07-01'
      });
    }, 300);
  });
  
  // 实际API调用
  // return get(`/family/${id}`);
};

// 加入家庭
const joinFamily = (inviteCode) => {
  // 模拟加入家庭
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      if (inviteCode === 'FAM123456') {
        resolve({
          id: 1,
          name: '测试家庭',
          status: 0 // 0-待审核 1-已加入
        });
      } else {
        reject(new Error('邀请码无效'));
      }
    }, 500);
  });
  
  // 实际API调用
  // return post('/family/join', { inviteCode });
};

// 获取家庭成员
const getFamilyMembers = (familyId) => {
  // 模拟获取家庭成员
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        data: [
          {
            id: 1,
            userId: 1,
            nickname: '张三',
            avatar: 'https://img.yzcdn.cn/vant/cat.jpeg',
            role: 'owner',
            roleName: '一家之主',
            joinedAt: '2025-07-01'
          },
          {
            id: 2,
            userId: 2,
            nickname: '李四',
            avatar: 'https://img.yzcdn.cn/vant/cat.jpeg',
            role: 'chef',
            roleName: '主厨',
            joinedAt: '2025-07-02'
          },
          {
            id: 3,
            userId: 3,
            nickname: '王五',
            avatar: 'https://img.yzcdn.cn/vant/cat.jpeg',
            role: 'member',
            roleName: '家庭成员',
            joinedAt: '2025-07-03'
          }
        ]
      });
    }, 300);
  });
  
  // 实际API调用
  // return get(`/family/${familyId}/members`);
};

// 更新成员角色
const updateMemberRole = (memberId, role) => {
  // 模拟更新成员角色
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        success: true
      });
    }, 300);
  });
  
  // 实际API调用
  // return put(`/family/member/${memberId}/role`, { role });
};

// 创建邀请
const createInvitation = (familyId, type) => {
  // 模拟创建邀请
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        code: 'INV' + Math.random().toString(36).substr(2, 6).toUpperCase(),
        expireAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
      });
    }, 300);
  });
  
  // 实际API调用
  // return post('/family/invite', { familyId, type });
};

// 上传图片
const uploadImage = (filePath) => {
  // 模拟上传图片
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        url: filePath
      });
    }, 500);
  });
  
  // 实际API调用
  // return new Promise((resolve, reject) => {
  //   wx.uploadFile({
  //     url: 'https://api.example.com/api/v1/upload',
  //     filePath: filePath,
  //     name: 'file',
  //     header: {
  //       'Authorization': `Bearer ${wx.getStorageSync('token')}`
  //     },
  //     success: (res) => {
  //       if (res.statusCode === 200) {
  //         const data = JSON.parse(res.data);
  //         resolve(data);
  //       } else {
  //         reject(new Error('上传失败'));
  //       }
  //     },
  //     fail: (err) => {
  //       reject(err);
  //     }
  //   });
  // });
};

module.exports = {
  createFamily,
  getFamilyList,
  getFamilyDetail,
  joinFamily,
  getFamilyMembers,
  updateMemberRole,
  createInvitation,
  uploadImage
};