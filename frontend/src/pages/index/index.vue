<template>
  <view class="index">
    <!-- 顶部欢迎区域 -->
    <view class="welcome-section">
      <view class="welcome-text">
        <text class="greeting">{{ greeting }}</text>
        <text class="username">{{ user?.nickname || '亲爱的家人' }}</text>
      </view>
      <view class="family-info" v-if="family">
        <text class="family-name">{{ family.name }}</text>
        <text class="member-count">{{ family.members?.length || 0 }}位成员</text>
      </view>
    </view>

    <!-- 快捷功能区域 -->
    <view class="quick-actions">
      <view class="action-grid">
        <view class="action-item" @click="navigateTo('/pages/order/create')">
          <view class="action-icon order-icon">🍽️</view>
          <text class="action-text">点餐</text>
        </view>
        <view class="action-item" @click="navigateTo('/pages/recipe/list')">
          <view class="action-icon recipe-icon">📖</view>
          <text class="action-text">菜谱</text>
        </view>
        <view class="action-item" @click="navigateTo('/pages/ingredient/list')">
          <view class="action-icon ingredient-icon">🥬</view>
          <text class="action-text">食材</text>
        </view>
        <view class="action-item" @click="navigateTo('/pages/memory/list')">
          <view class="action-icon memory-icon">📸</view>
          <text class="action-text">回忆</text>
        </view>
      </view>
    </view>

    <!-- 今日推荐 -->
    <view class="today-recommend" v-if="todayRecipes.length > 0">
      <view class="section-title">
        <text class="title-text">今日推荐</text>
        <text class="more-text" @click="navigateTo('/pages/recipe/list')">更多</text>
      </view>
      <scroll-view class="recipe-scroll" scroll-x="true">
        <view class="recipe-list">
          <view 
            class="recipe-item" 
            v-for="recipe in todayRecipes" 
            :key="recipe.id"
            @click="navigateToRecipe(recipe.id)"
          >
            <image class="recipe-image" :src="recipe.image || '/static/images/default-recipe.png'" mode="aspectFill" />
            <view class="recipe-info">
              <text class="recipe-name">{{ recipe.name }}</text>
              <text class="recipe-desc">{{ recipe.description }}</text>
            </view>
          </view>
        </view>
      </scroll-view>
    </view>

    <!-- 最近订单 -->
    <view class="recent-orders" v-if="recentOrders.length > 0">
      <view class="section-title">
        <text class="title-text">最近订单</text>
        <text class="more-text" @click="navigateTo('/pages/order/list')">更多</text>
      </view>
      <view class="order-list">
        <view 
          class="order-item" 
          v-for="order in recentOrders" 
          :key="order.id"
          @click="navigateToOrder(order.id)"
        >
          <view class="order-info">
            <text class="order-no">订单号：{{ order.orderNo }}</text>
            <text class="order-status" :class="getStatusClass(order.status)">
              {{ getStatusText(order.status) }}
            </text>
          </view>
          <view class="order-items">
            <text class="item-text">{{ order.items?.length || 0 }}道菜品</text>
          </view>
          <view class="order-time">
            <text class="time-text">{{ formatTime(order.createdAt) }}</text>
          </view>
        </view>
      </view>
    </view>

    <!-- 家庭动态 -->
    <view class="family-activities" v-if="familyActivities.length > 0">
      <view class="section-title">
        <text class="title-text">家庭动态</text>
      </view>
      <view class="activity-list">
        <view 
          class="activity-item" 
          v-for="activity in familyActivities" 
          :key="activity.id"
        >
          <image class="activity-avatar" :src="activity.user?.avatar || '/static/images/default-avatar.png'" mode="aspectFill" />
          <view class="activity-content">
            <text class="activity-text">{{ activity.content }}</text>
            <text class="activity-time">{{ formatTime(activity.createdAt) }}</text>
          </view>
        </view>
      </view>
    </view>
  </view>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import dayjs from 'dayjs'

export default {
  name: 'Index',
  data() {
    return {
      todayRecipes: [],
      recentOrders: [],
      familyActivities: []
    }
  },
  computed: {
    ...mapGetters(['user', 'family', 'isLoggedIn']),
    
    greeting() {
      const hour = new Date().getHours()
      if (hour < 6) return '夜深了'
      if (hour < 9) return '早上好'
      if (hour < 12) return '上午好'
      if (hour < 14) return '中午好'
      if (hour < 18) return '下午好'
      if (hour < 22) return '晚上好'
      return '夜深了'
    }
  },
  onLoad() {
    this.initPage()
  },
  onShow() {
    // 检查登录状态
    if (!this.isLoggedIn) {
      uni.reLaunch({
        url: '/pages/login/login'
      })
      return
    }
    
    // 刷新数据
    this.loadPageData()
  },
  methods: {
    ...mapActions(['initApp']),
    
    async initPage() {
      try {
        // 初始化应用
        await this.initApp()
        
        // 加载页面数据
        this.loadPageData()
      } catch (error) {
        console.error('初始化页面失败:', error)
      }
    },
    
    async loadPageData() {
      // 这里可以调用API获取首页数据
      // 暂时使用模拟数据
      this.loadTodayRecipes()
      this.loadRecentOrders()
      this.loadFamilyActivities()
    },
    
    loadTodayRecipes() {
      // 模拟今日推荐菜谱
      this.todayRecipes = [
        {
          id: 1,
          name: '红烧肉',
          description: '经典家常菜，肥而不腻',
          image: '/static/images/recipe1.jpg'
        },
        {
          id: 2,
          name: '清炒时蔬',
          description: '营养健康，简单易做',
          image: '/static/images/recipe2.jpg'
        }
      ]
    },
    
    loadRecentOrders() {
      // 模拟最近订单
      this.recentOrders = [
        {
          id: 1,
          orderNo: 'FC20231201001',
          status: 3,
          items: [{}, {}],
          createdAt: new Date()
        }
      ]
    },
    
    loadFamilyActivities() {
      // 模拟家庭动态
      this.familyActivities = [
        {
          id: 1,
          content: '妈妈添加了新菜谱：红烧肉',
          user: { avatar: '/static/images/avatar1.jpg' },
          createdAt: new Date()
        }
      ]
    },
    
    navigateTo(url) {
      uni.navigateTo({ url })
    },
    
    navigateToRecipe(id) {
      uni.navigateTo({
        url: `/pages/recipe/detail?id=${id}`
      })
    },
    
    navigateToOrder(id) {
      uni.navigateTo({
        url: `/pages/order/detail?id=${id}`
      })
    },
    
    getStatusClass(status) {
      const statusMap = {
        0: 'status-pending',
        1: 'status-confirmed',
        2: 'status-cooking',
        3: 'status-completed',
        4: 'status-cancelled'
      }
      return statusMap[status] || 'status-pending'
    },
    
    getStatusText(status) {
      const statusMap = {
        0: '待确认',
        1: '已确认',
        2: '制作中',
        3: '已完成',
        4: '已取消'
      }
      return statusMap[status] || '待确认'
    },
    
    formatTime(time) {
      return dayjs(time).format('MM-DD HH:mm')
    }
  }
}
</script>

<style lang="scss" scoped>
.index {
  min-height: 100vh;
  background-color: #f8f8f8;
  padding-bottom: 20rpx;
}

.welcome-section {
  background: linear-gradient(135deg, #FF6B6B 0%, #FF8E8E 100%);
  padding: 40rpx 30rpx;
  color: white;
  
  .welcome-text {
    margin-bottom: 20rpx;
    
    .greeting {
      font-size: 32rpx;
      margin-right: 10rpx;
    }
    
    .username {
      font-size: 36rpx;
      font-weight: bold;
    }
  }
  
  .family-info {
    .family-name {
      font-size: 28rpx;
      margin-right: 20rpx;
    }
    
    .member-count {
      font-size: 24rpx;
      opacity: 0.8;
    }
  }
}

.quick-actions {
  background: white;
  margin: 20rpx;
  border-radius: 16rpx;
  padding: 30rpx;
  
  .action-grid {
    display: flex;
    justify-content: space-around;
    
    .action-item {
      display: flex;
      flex-direction: column;
      align-items: center;
      
      .action-icon {
        width: 80rpx;
        height: 80rpx;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 40rpx;
        margin-bottom: 16rpx;
        
        &.order-icon {
          background: linear-gradient(135deg, #FF6B6B, #FF8E8E);
        }
        
        &.recipe-icon {
          background: linear-gradient(135deg, #4ECDC4, #44A08D);
        }
        
        &.ingredient-icon {
          background: linear-gradient(135deg, #45B7D1, #96C93D);
        }
        
        &.memory-icon {
          background: linear-gradient(135deg, #A8E6CF, #DCEDC8);
        }
      }
      
      .action-text {
        font-size: 24rpx;
        color: #333;
      }
    }
  }
}

.section-title {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20rpx;
  
  .title-text {
    font-size: 32rpx;
    font-weight: bold;
    color: #333;
  }
  
  .more-text {
    font-size: 24rpx;
    color: #FF6B6B;
  }
}

.today-recommend {
  background: white;
  margin: 20rpx;
  border-radius: 16rpx;
  padding: 30rpx;
  
  .recipe-scroll {
    white-space: nowrap;
    
    .recipe-list {
      display: flex;
      
      .recipe-item {
        width: 300rpx;
        margin-right: 20rpx;
        border-radius: 12rpx;
        overflow: hidden;
        background: #f8f8f8;
        
        .recipe-image {
          width: 100%;
          height: 200rpx;
        }
        
        .recipe-info {
          padding: 20rpx;
          
          .recipe-name {
            font-size: 28rpx;
            font-weight: bold;
            color: #333;
            display: block;
            margin-bottom: 8rpx;
          }
          
          .recipe-desc {
            font-size: 24rpx;
            color: #666;
            display: block;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
          }
        }
      }
    }
  }
}

.recent-orders {
  background: white;
  margin: 20rpx;
  border-radius: 16rpx;
  padding: 30rpx;
  
  .order-list {
    .order-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 20rpx 0;
      border-bottom: 1rpx solid #f0f0f0;
      
      &:last-child {
        border-bottom: none;
      }
      
      .order-info {
        flex: 1;
        
        .order-no {
          font-size: 28rpx;
          color: #333;
          display: block;
          margin-bottom: 8rpx;
        }
        
        .order-status {
          font-size: 24rpx;
          padding: 4rpx 12rpx;
          border-radius: 20rpx;
          
          &.status-pending {
            background: #FFF3CD;
            color: #856404;
          }
          
          &.status-confirmed {
            background: #D1ECF1;
            color: #0C5460;
          }
          
          &.status-cooking {
            background: #D4EDDA;
            color: #155724;
          }
          
          &.status-completed {
            background: #D1E7DD;
            color: #0F5132;
          }
          
          &.status-cancelled {
            background: #F8D7DA;
            color: #721C24;
          }
        }
      }
      
      .order-items {
        margin: 0 20rpx;
        
        .item-text {
          font-size: 24rpx;
          color: #666;
        }
      }
      
      .order-time {
        .time-text {
          font-size: 24rpx;
          color: #999;
        }
      }
    }
  }
}

.family-activities {
  background: white;
  margin: 20rpx;
  border-radius: 16rpx;
  padding: 30rpx;
  
  .activity-list {
    .activity-item {
      display: flex;
      align-items: flex-start;
      padding: 20rpx 0;
      border-bottom: 1rpx solid #f0f0f0;
      
      &:last-child {
        border-bottom: none;
      }
      
      .activity-avatar {
        width: 60rpx;
        height: 60rpx;
        border-radius: 50%;
        margin-right: 20rpx;
      }
      
      .activity-content {
        flex: 1;
        
        .activity-text {
          font-size: 28rpx;
          color: #333;
          display: block;
          margin-bottom: 8rpx;
        }
        
        .activity-time {
          font-size: 24rpx;
          color: #999;
        }
      }
    }
  }
}
</style> 