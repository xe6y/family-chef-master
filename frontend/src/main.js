import { createSSRApp } from 'vue'
import App from './App.vue'
import store from './store'

export function createApp() {
  const app = createSSRApp(App)
  
  // 挂载Vuex
  app.use(store)
  
  // 全局混入
  app.mixin({
    onLoad() {
      // 页面加载时的通用逻辑
      console.log('页面加载:', this.$options.name)
    },
    
    onShow() {
      // 页面显示时的通用逻辑
      console.log('页面显示:', this.$options.name)
    }
  })
  
  // 全局错误处理
  app.config.errorHandler = (err, vm, info) => {
    console.error('全局错误:', err, info)
    
    // 显示错误提示
    uni.showToast({
      title: '系统错误，请重试',
      icon: 'none'
    })
  }
  
  return {
    app
  }
} 