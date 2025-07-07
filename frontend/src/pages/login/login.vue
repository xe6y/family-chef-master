<template>
  <view class="login-container">
    <view class="logo-section">
      <image class="logo" src="/static/images/logo.png" mode="aspectFit" />
      <text class="app-name">家庭厨师</text>
      <text class="app-desc">让每个家庭都能享受美食的乐趣</text>
    </view>
    
    <view class="login-section">
      <button 
        class="login-btn" 
        type="primary" 
        @click="handleLogin"
        :loading="loading"
      >
        微信授权登录
      </button>
      
      <view class="tips">
        <text class="tip-text">登录即表示同意</text>
        <text class="link-text" @click="showPrivacy">《用户协议和隐私政策》</text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useStore } from 'vuex'

const store = useStore()
const loading = ref(false)

const handleLogin = async () => {
  try {
    loading.value = true
    
    // 获取微信授权码
    const { code } = await uni.login({
      provider: 'weixin'
    })
    
    if (!code) {
      uni.showToast({
        title: '获取授权码失败',
        icon: 'none'
      })
      return
    }
    
    // 调用登录接口
    await store.dispatch('login', code)
    
    uni.showToast({
      title: '登录成功',
      icon: 'success'
    })
    
    // 跳转到首页
    uni.switchTab({
      url: '/pages/index/index'
    })
    
  } catch (error) {
    console.error('登录失败:', error)
    uni.showToast({
      title: '登录失败，请重试',
      icon: 'none'
    })
  } finally {
    loading.value = false
  }
}

const showPrivacy = () => {
  uni.showModal({
    title: '用户协议和隐私政策',
    content: '我们承诺保护您的隐私，不会泄露您的个人信息。',
    showCancel: false
  })
}
</script>

<style lang="scss" scoped>
.login-container {
  min-height: 100vh;
  background: linear-gradient(135deg, #FF6B6B 0%, #FF8E8E 100%);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40rpx;
}

.logo-section {
  text-align: center;
  margin-bottom: 80rpx;
  
  .logo {
    width: 200rpx;
    height: 200rpx;
    margin-bottom: 30rpx;
  }
  
  .app-name {
    display: block;
    font-size: 48rpx;
    font-weight: bold;
    color: white;
    margin-bottom: 20rpx;
  }
  
  .app-desc {
    display: block;
    font-size: 28rpx;
    color: rgba(255, 255, 255, 0.8);
  }
}

.login-section {
  width: 100%;
  max-width: 600rpx;
  
  .login-btn {
    width: 100%;
    height: 88rpx;
    background: white;
    color: #FF6B6B;
    border: none;
    border-radius: 44rpx;
    font-size: 32rpx;
    font-weight: bold;
    margin-bottom: 40rpx;
    
    &:active {
      background: rgba(255, 255, 255, 0.9);
    }
  }
  
  .tips {
    text-align: center;
    
    .tip-text {
      font-size: 24rpx;
      color: rgba(255, 255, 255, 0.8);
    }
    
    .link-text {
      font-size: 24rpx;
      color: white;
      text-decoration: underline;
    }
  }
}
</style> 