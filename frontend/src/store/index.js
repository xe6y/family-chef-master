import { createStore } from 'vuex'
import { login, getUserInfo, getFamilyInfo } from '@/api'

export default createStore({
  state: {
    // 用户信息
    user: null,
    // 家庭信息
    family: null,
    // 认证token
    token: '',
    // 是否已登录
    isLoggedIn: false,
    // 加载状态
    loading: false
  },

  mutations: {
    // 设置用户信息
    SET_USER(state, user) {
      state.user = user
      state.isLoggedIn = !!user
    },

    // 设置家庭信息
    SET_FAMILY(state, family) {
      state.family = family
    },

    // 设置token
    SET_TOKEN(state, token) {
      state.token = token
      if (token) {
        uni.setStorageSync('token', token)
      } else {
        uni.removeStorageSync('token')
      }
    },

    // 设置加载状态
    SET_LOADING(state, loading) {
      state.loading = loading
    },

    // 清除用户数据
    CLEAR_USER_DATA(state) {
      state.user = null
      state.family = null
      state.token = ''
      state.isLoggedIn = false
      uni.removeStorageSync('token')
      uni.removeStorageSync('userInfo')
    }
  },

  actions: {
    // 微信登录
    async login({ commit }, code) {
      try {
        commit('SET_LOADING', true)
        const data = await login(code)
        commit('SET_TOKEN', data.token)
        commit('SET_USER', data.user)
        uni.setStorageSync('userInfo', data.user)
        return data
      } catch (error) {
        console.error('登录失败:', error)
        throw error
      } finally {
        commit('SET_LOADING', false)
      }
    },

    // 获取用户信息
    async getUserInfo({ commit }) {
      try {
        const user = await getUserInfo()
        commit('SET_USER', user)
        uni.setStorageSync('userInfo', user)
        return user
      } catch (error) {
        console.error('获取用户信息失败:', error)
        throw error
      }
    },

    // 获取家庭信息
    async getFamilyInfo({ commit }) {
      try {
        const family = await getFamilyInfo()
        commit('SET_FAMILY', family)
        return family
      } catch (error) {
        console.error('获取家庭信息失败:', error)
        throw error
      }
    },

    // 初始化应用
    async initApp({ commit, dispatch }) {
      try {
        // 检查本地存储的token
        const token = uni.getStorageSync('token')
        if (token) {
          commit('SET_TOKEN', token)
          
          // 获取用户信息
          await dispatch('getUserInfo')
          
          // 获取家庭信息
          await dispatch('getFamilyInfo')
        }
      } catch (error) {
        console.error('初始化应用失败:', error)
        // 清除无效的token
        commit('CLEAR_USER_DATA')
      }
    },

    // 退出登录
    logout({ commit }) {
      commit('CLEAR_USER_DATA')
      uni.reLaunch({
        url: '/pages/login/login'
      })
    }
  },

  getters: {
    // 是否已登录
    isLoggedIn: state => state.isLoggedIn,
    
    // 用户信息
    user: state => state.user,
    
    // 家庭信息
    family: state => state.family,
    
    // 用户ID
    userId: state => state.user?.id,
    
    // 家庭ID
    familyId: state => state.family?.id,
    
    // 用户角色
    userRole: state => {
      if (!state.user || !state.family) return null
      const member = state.family.members?.find(m => m.userId === state.user.id)
      return member?.role || 'member'
    },
    
    // 是否是一家之主
    isOwner: state => {
      if (!state.user || !state.family) return false
      return state.family.ownerId === state.user.id
    },
    
    // 是否是主厨
    isChef: state => {
      const role = state.userRole
      return role === 'chef' || role === 'owner'
    },
    
    // 加载状态
    loading: state => state.loading
  }
}) 