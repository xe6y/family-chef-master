import { defineStore } from "pinia";

export const useUserInfoStore = defineStore(
  "user",
  () => {
    // token
    const token = ref("");
    function setToken(str: string) {
      token.value = str;
    }

    // 用户信息
    const userInfo = ref({
      id: '',
      nickname: '家庭成员',
      avatar: '/static/image/avatar1.jpg',
      inviteCode: 'FAMILY123',
      role: 'member'
    });

    function setUserInfo(info: any) {
      userInfo.value = { ...userInfo.value, ...info };
    }

    // 清除用户信息
    function clearUserInfo() {
      token.value = "";
      userInfo.value = {
        id: '',
        nickname: '家庭成员',
        avatar: '/static/image/avatar1.jpg',
        inviteCode: 'FAMILY123',
        role: 'member'
      };
    }

    return {
      token,
      userInfo,
      setToken,
      setUserInfo,
      clearUserInfo,
    };
  },
  {
    persist: {
      storage: {
        setItem(key, value) {
          uni.setStorageSync(key, value);
        },
        getItem(key) {
          return uni.getStorageSync(key);
        },
      },
    },
  }
);
