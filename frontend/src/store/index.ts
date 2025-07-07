import { createStore } from 'vuex'

interface User {
  id: number
  nickname: string
  avatar: string
  phone?: string
  email?: string
}

interface Family {
  id: number
  name: string
  description: string
  avatar: string
  ownerId: number
  members: FamilyMember[]
}

interface FamilyMember {
  id: number
  userId: number
  role: string
  nickname: string
  status: number
  user: User
}

interface AppState {
  user: User | null
  family: Family | null
  token: string | null
  loading: boolean
}

const store = createStore<AppState>({
  state: {
    user: null,
    family: null,
    token: null,
    loading: false
  },

  mutations: {
    SET_USER(state, user: User) {
      state.user = user
    },
    SET_FAMILY(state, family: Family) {
      state.family = family
    },
    SET_TOKEN(state, token: string) {
      state.token = token
    },
    SET_LOADING(state, loading: boolean) {
      state.loading = loading
    },
    CLEAR_USER_DATA(state) {
      state.user = null
      state.family = null
      state.token = null
    }
  },

  actions: {
    // 登录
    async login({ commit }, code: string) {
      try {
        commit('SET_LOADING', true)
        const { login } = await import('@/api')
        const response = await login(code)
        
        const { user, token } = response.data
        commit('SET_USER', user)
        commit('SET_TOKEN', token)
        
        // 保存到本地存储
        uni.setStorageSync('user', user)
        uni.setStorageSync('token', token)
        
        return response
      } catch (error) {
        throw error
      } finally {
        commit('SET_LOADING', false)
      }
    },

    // 获取用户信息
    async getUserInfo({ commit }) {
      try {
        commit('SET_LOADING', true)
        const { getUserInfo } = await import('@/api')
        const response = await getUserInfo()
        
        commit('SET_USER', response.data)
        uni.setStorageSync('user', response.data)
        
        return response
      } catch (error) {
        throw error
      } finally {
        commit('SET_LOADING', false)
      }
    },

    // 获取家庭信息
    async getFamilyInfo({ commit }) {
      try {
        commit('SET_LOADING', true)
        const { getFamilyInfo } = await import('@/api')
        const response = await getFamilyInfo()
        
        commit('SET_FAMILY', response.data)
        uni.setStorageSync('family', response.data)
        
        return response
      } catch (error) {
        throw error
      } finally {
        commit('SET_LOADING', false)
      }
    },

    // 初始化应用
    async initApp({ commit, dispatch }) {
      try {
        // 从本地存储恢复数据
        const token = uni.getStorageSync('token')
        const user = uni.getStorageSync('user')
        const family = uni.getStorageSync('family')
        
        if (token) {
          commit('SET_TOKEN', token)
        }
        
        if (user) {
          commit('SET_USER', user)
        }
        
        if (family) {
          commit('SET_FAMILY', family)
        }
        
        // 如果有token，尝试获取最新数据
        if (token) {
          await Promise.all([
            dispatch('getUserInfo'),
            dispatch('getFamilyInfo')
          ])
        }
      } catch (error) {
        console.error('初始化应用失败:', error)
        // 清除无效数据
        commit('CLEAR_USER_DATA')
        uni.clearStorageSync()
      }
    },

    // 退出登录
    logout({ commit }) {
      commit('CLEAR_USER_DATA')
      uni.clearStorageSync()
      uni.reLaunch({
        url: '/pages/login/login'
      })
    }
  },

  getters: {
    // 是否已登录
    isLoggedIn: state => !!state.token,
    
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

export default store 