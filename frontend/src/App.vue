<script>
export default {
  onLaunch: function() {
    console.log('App Launch')
    
    // 检查更新
    this.checkUpdate()
    
    // 初始化应用
    this.initApp()
  },
  
  onShow: function() {
    console.log('App Show')
  },
  
  onHide: function() {
    console.log('App Hide')
  },
  
  methods: {
    // 检查应用更新
    checkUpdate() {
      // #ifdef MP-WEIXIN
      if (uni.canIUse('getUpdateManager')) {
        const updateManager = uni.getUpdateManager()
        
        updateManager.onCheckForUpdate((res) => {
          if (res.hasUpdate) {
            updateManager.onUpdateReady(() => {
              uni.showModal({
                title: '更新提示',
                content: '新版本已经准备好，是否重启应用？',
                success: (res) => {
                  if (res.confirm) {
                    updateManager.applyUpdate()
                  }
                }
              })
            })
            
            updateManager.onUpdateFailed(() => {
              uni.showModal({
                title: '更新失败',
                content: '新版本下载失败，请检查网络后重试',
                showCancel: false
              })
            })
          }
        })
      }
      // #endif
    },
    
    // 初始化应用
    async initApp() {
      try {
        // 初始化Vuex状态
        await this.$store.dispatch('initApp')
      } catch (error) {
        console.error('初始化应用失败:', error)
      }
    }
  }
}
</script>

<style lang="scss">
/* 全局样式 */
page {
  background-color: #f8f8f8;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', 'Helvetica Neue', Helvetica, Arial, sans-serif;
}

/* 通用样式类 */
.container {
  padding: 20rpx;
}

.card {
  background: white;
  border-radius: 16rpx;
  padding: 30rpx;
  margin-bottom: 20rpx;
  box-shadow: 0 2rpx 8rpx rgba(0, 0, 0, 0.1);
}

.flex {
  display: flex;
}

.flex-center {
  display: flex;
  align-items: center;
  justify-content: center;
}

.flex-between {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.flex-column {
  display: flex;
  flex-direction: column;
}

.text-center {
  text-align: center;
}

.text-primary {
  color: #FF6B6B;
}

.text-secondary {
  color: #666;
}

.text-muted {
  color: #999;
}

.font-bold {
  font-weight: bold;
}

.font-large {
  font-size: 32rpx;
}

.font-medium {
  font-size: 28rpx;
}

.font-small {
  font-size: 24rpx;
}

.margin-top {
  margin-top: 20rpx;
}

.margin-bottom {
  margin-bottom: 20rpx;
}

.padding {
  padding: 20rpx;
}

/* 按钮样式 */
.btn {
  height: 88rpx;
  border-radius: 44rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32rpx;
  font-weight: 500;
  border: none;
  
  &.btn-primary {
    background: #FF6B6B;
    color: white;
  }
  
  &.btn-secondary {
    background: #f0f0f0;
    color: #333;
  }
  
  &.btn-outline {
    background: transparent;
    color: #FF6B6B;
    border: 2rpx solid #FF6B6B;
  }
  
  &.btn-small {
    height: 60rpx;
    font-size: 24rpx;
    border-radius: 30rpx;
  }
  
  &.btn-large {
    height: 100rpx;
    font-size: 36rpx;
    border-radius: 50rpx;
  }
}

/* 输入框样式 */
.input {
  width: 100%;
  height: 88rpx;
  border: 2rpx solid #e0e0e0;
  border-radius: 12rpx;
  padding: 0 24rpx;
  font-size: 28rpx;
  background: white;
  
  &:focus {
    border-color: #FF6B6B;
  }
}

/* 标签样式 */
.tag {
  display: inline-block;
  padding: 8rpx 16rpx;
  border-radius: 20rpx;
  font-size: 24rpx;
  
  &.tag-primary {
    background: #FF6B6B;
    color: white;
  }
  
  &.tag-success {
    background: #4ECDC4;
    color: white;
  }
  
  &.tag-warning {
    background: #FFD93D;
    color: #333;
  }
  
  &.tag-danger {
    background: #FF6B6B;
    color: white;
  }
}

/* 加载状态 */
.loading {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40rpx;
  color: #999;
}

.empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80rpx 40rpx;
  color: #999;
  
  .empty-icon {
    font-size: 80rpx;
    margin-bottom: 20rpx;
  }
  
  .empty-text {
    font-size: 28rpx;
  }
}

/* 动画效果 */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.slide-up-enter-active,
.slide-up-leave-active {
  transition: transform 0.3s ease;
}

.slide-up-enter-from,
.slide-up-leave-to {
  transform: translateY(100%);
}

/* 响应式设计 */
@media (max-width: 750rpx) {
  .container {
    padding: 16rpx;
  }
  
  .card {
    padding: 24rpx;
  }
  
  .font-large {
    font-size: 28rpx;
  }
  
  .font-medium {
    font-size: 24rpx;
  }
  
  .font-small {
    font-size: 20rpx;
  }
}
</style> 