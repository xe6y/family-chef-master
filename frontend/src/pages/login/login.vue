<template>
  <view class="login">
    <!-- 背景装饰 -->
    <view class="bg-decoration">
      <view class="circle circle-1"></view>
      <view class="circle circle-2"></view>
      <view class="circle circle-3"></view>
    </view>

    <!-- 主要内容 -->
    <view class="login-content">
      <!-- Logo区域 -->
      <view class="logo-section">
        <image class="logo" src="/static/images/logo.png" mode="aspectFit" />
        <text class="app-name">家庭厨师</text>
        <text class="app-slogan">让每个家庭都能享受美食的乐趣</text>
      </view>

      <!-- 登录按钮区域 -->
      <view class="login-section">
        <view class="login-tips">
          <text class="tips-text">使用微信账号快速登录</text>
        </view>
        
        <button 
          class="wechat-login-btn" 
          @click="handleWechatLogin"
          :loading="loading"
          :disabled="loading"
        >
          <image class="wechat-icon" src="/static/images/wechat-icon.png" mode="aspectFit" />
          <text class="btn-text">{{ loading ? '登录中...' : '微信登录' }}</text>
        </button>

        <view class="privacy-tips">
          <text class="privacy-text">登录即表示同意</text>
          <text class="privacy-link" @click="showPrivacyPolicy">《用户协议和隐私政策》</text>
        </view>
      </view>

      <!-- 功能介绍 -->
      <view class="features-section">
        <view class="feature-item">
          <view class="feature-icon">👨‍👩‍👧‍👦</view>
          <text class="feature-text">家庭管理</text>
        </view>
        <view class="feature-item">
          <view class="feature-icon">🍽️</view>
          <text class="feature-text">智能点餐</text>
        </view>
        <view class="feature-item">
          <view class="feature-icon">📖</view>
          <text class="feature-text">菜谱分享</text>
        </view>
        <view class="feature-item">
          <view class="feature-icon">📸</view>
          <text class="feature-text">美好回忆</text>
        </view>
      </view>
    </view>
  </view>
</template>

<script>
import { mapActions, mapGetters } from 'vuex'

export default {
  name: 'Login',
  data() {
    return {
      loading: false
    }
  },
  computed: {
    ...mapGetters(['isLoggedIn'])
  },
  onLoad() {
    // 如果已经登录，直接跳转到首页
    if (this.isLoggedIn) {
      uni.reLaunch({
        url: '/pages/index/index'
      })
    }
  },
  methods: {
    ...mapActions(['login']),

    async handleWechatLogin() {
      if (this.loading) return
      
      this.loading = true
      
      try {
        // 获取微信登录code
        const loginResult = await this.getWechatCode()
        
        if (loginResult.code) {
          // 调用后端登录接口
          await this.login(loginResult.code)
          
          // 登录成功，跳转到首页
          uni.reLaunch({
            url: '/pages/index/index'
          })
          
          uni.showToast({
            title: '登录成功',
            icon: 'success'
          })
        } else {
          throw new Error('获取微信授权失败')
        }
      } catch (error) {
        console.error('登录失败:', error)
        
        uni.showToast({
          title: error.message || '登录失败，请重试',
          icon: 'none'
        })
      } finally {
        this.loading = false
      }
    },

    // 获取微信登录code
    getWechatCode() {
      return new Promise((resolve, reject) => {
        uni.login({
          provider: 'weixin',
          success: (res) => {
            resolve(res)
          },
          fail: (error) => {
            reject(error)
          }
        })
      })
    },

    // 显示隐私政策
    showPrivacyPolicy() {
      uni.navigateTo({
        url: '/pages/privacy/privacy'
      })
    }
  }
}
</script>

<style lang="scss" scoped>
.login {
  min-height: 100vh;
  background: linear-gradient(135deg, #FF6B6B 0%, #FF8E8E 100%);
  position: relative;
  overflow: hidden;
}

.bg-decoration {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  pointer-events: none;
  
  .circle {
    position: absolute;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.1);
    
    &.circle-1 {
      width: 200rpx;
      height: 200rpx;
      top: 10%;
      right: -50rpx;
    }
    
    &.circle-2 {
      width: 150rpx;
      height: 150rpx;
      top: 30%;
      left: -30rpx;
    }
    
    &.circle-3 {
      width: 100rpx;
      height: 100rpx;
      bottom: 20%;
      right: 20%;
    }
  }
}

.login-content {
  position: relative;
  z-index: 1;
  padding: 100rpx 60rpx;
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.logo-section {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  margin-bottom: 80rpx;
  
  .logo {
    width: 120rpx;
    height: 120rpx;
    margin-bottom: 30rpx;
  }
  
  .app-name {
    font-size: 48rpx;
    font-weight: bold;
    color: white;
    margin-bottom: 20rpx;
  }
  
  .app-slogan {
    font-size: 28rpx;
    color: rgba(255, 255, 255, 0.8);
    text-align: center;
    line-height: 1.5;
  }
}

.login-section {
  margin-bottom: 80rpx;
  
  .login-tips {
    text-align: center;
    margin-bottom: 40rpx;
    
    .tips-text {
      font-size: 28rpx;
      color: rgba(255, 255, 255, 0.9);
    }
  }
  
  .wechat-login-btn {
    width: 100%;
    height: 88rpx;
    background: #07C160;
    border: none;
    border-radius: 44rpx;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 30rpx;
    box-shadow: 0 8rpx 24rpx rgba(7, 193, 96, 0.3);
    
    &:active {
      transform: translateY(2rpx);
      box-shadow: 0 4rpx 12rpx rgba(7, 193, 96, 0.3);
    }
    
    .wechat-icon {
      width: 40rpx;
      height: 40rpx;
      margin-right: 16rpx;
    }
    
    .btn-text {
      font-size: 32rpx;
      color: white;
      font-weight: 500;
    }
  }
  
  .privacy-tips {
    text-align: center;
    
    .privacy-text {
      font-size: 24rpx;
      color: rgba(255, 255, 255, 0.7);
    }
    
    .privacy-link {
      font-size: 24rpx;
      color: white;
      text-decoration: underline;
    }
  }
}

.features-section {
  display: flex;
  justify-content: space-around;
  
  .feature-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    
    .feature-icon {
      font-size: 48rpx;
      margin-bottom: 16rpx;
    }
    
    .feature-text {
      font-size: 24rpx;
      color: rgba(255, 255, 255, 0.8);
    }
  }
}

// 响应式设计
@media (max-height: 600px) {
  .login-content {
    padding: 60rpx 60rpx;
  }
  
  .logo-section {
    margin-bottom: 40rpx;
  }
  
  .login-section {
    margin-bottom: 40rpx;
  }
}
</style> 