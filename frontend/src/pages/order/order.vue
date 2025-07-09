<template>
  <view class="order-page">
    <!-- 顶部搜索 -->
    <view class="search-section">
      <u-search
        v-model="searchKeyword"
        placeholder="搜索菜品"
        :show-action="false"
        @search="searchDishes"
      />
    </view>

    <!-- 筛选标签 -->
    <view class="filter-section">
      <scroll-view class="filter-scroll" scroll-x>
        <view class="filter-tags">
          <u-tag
            v-for="tag in filterTags"
            :key="tag.id"
            :text="tag.name"
            :type="tag.selected ? 'primary' : 'info'"
            size="mini"
            @click="toggleFilter(tag)"
          />
        </view>
      </scroll-view>
    </view>

    <!-- 菜品列表 -->
    <view class="dish-list">
      <view
        class="dish-item"
        v-for="dish in filteredDishes"
        :key="dish.id"
        @click="selectDish(dish)"
      >
        <image class="dish-image" :src="dish.image" mode="aspectFill" />
        <view class="dish-content">
          <view class="dish-header">
            <text class="dish-name">{{ dish.name }}</text>
            <view class="dish-badge" v-if="dish.isSpecialty">
              <u-tag text="拿手菜" type="warning" size="mini" />
            </view>
          </view>
          <text class="dish-chef">大厨：{{ dish.chef }}</text>
          <view class="dish-tags">
            <u-tag
              v-for="tag in dish.tags"
              :key="tag"
              :text="tag"
              size="mini"
              type="info"
            />
          </view>
          <view class="dish-actions">
            <u-button
              type="primary"
              size="mini"
              @click.stop="orderDish(dish)"
            >
              点菜
            </u-button>
            <u-button
              type="info"
              size="mini"
              @click.stop="viewDetail(dish)"
            >
              详情
            </u-button>
          </view>
        </view>
      </view>
    </view>

    <!-- 点菜弹窗 -->
    <u-popup v-model="showOrderPopup" mode="bottom" height="60%">
      <view class="order-popup">
        <view class="popup-header">
          <text class="popup-title">点菜详情</text>
          <u-icon name="close" @click="showOrderPopup = false" />
        </view>
        
        <view class="selected-dish">
          <image :src="selectedDish?.image" mode="aspectFill" />
          <view class="dish-info">
            <text class="dish-name">{{ selectedDish?.name }}</text>
            <text class="dish-chef">{{ selectedDish?.chef }}</text>
          </view>
        </view>

        <view class="order-form">
          <view class="form-item">
            <text class="label">选择大厨</text>
            <u-radio-group v-model="selectedChef">
              <u-radio
                v-for="chef in availableChefs"
                :key="chef.id"
                :name="chef.id"
                :label="chef.name"
              />
            </u-radio-group>
          </view>

          <view class="form-item">
            <text class="label">备注</text>
            <u-textarea
              v-model="orderRemark"
              placeholder="有什么特殊要求吗？"
              :maxlength="200"
            />
          </view>

          <view class="form-item">
            <text class="label">期望时间</text>
            <u-datetime-picker
              v-model="expectedTime"
              mode="time"
              placeholder="选择期望时间"
            />
          </view>
        </view>

        <view class="popup-actions">
          <u-button type="info" @click="showOrderPopup = false">取消</u-button>
          <u-button type="primary" @click="submitOrder">确认点菜</u-button>
        </view>
      </view>
    </u-popup>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'

// 搜索关键词
const searchKeyword = ref('')

// 筛选标签
const filterTags = ref([
  { id: 1, name: '全部', selected: true },
  { id: 2, name: '家常菜', selected: false },
  { id: 3, name: '川菜', selected: false },
  { id: 4, name: '粤菜', selected: false },
  { id: 5, name: '素食', selected: false },
  { id: 6, name: '海鲜', selected: false },
  { id: 7, name: '拿手菜', selected: false }
])

// 菜品列表
const dishes = ref([
  {
    id: 1,
    name: '红烧肉',
    chef: '张妈妈',
    image: '/static/image/dish1.jpg',
    tags: ['家常菜', '肉类'],
    isSpecialty: true,
    category: '家常菜'
  },
  {
    id: 2,
    name: '清蒸鱼',
    chef: '李爸爸',
    image: '/static/image/dish2.jpg',
    tags: ['海鲜', '清淡'],
    isSpecialty: false,
    category: '海鲜'
  },
  {
    id: 3,
    name: '麻婆豆腐',
    chef: '王奶奶',
    image: '/static/image/dish3.jpg',
    tags: ['川菜', '素食'],
    isSpecialty: true,
    category: '川菜'
  },
  {
    id: 4,
    name: '白切鸡',
    chef: '陈爷爷',
    image: '/static/image/dish4.jpg',
    tags: ['粤菜', '禽类'],
    isSpecialty: false,
    category: '粤菜'
  }
])

// 可用大厨
const availableChefs = ref([
  { id: 1, name: '张妈妈', specialty: '家常菜' },
  { id: 2, name: '李爸爸', specialty: '海鲜' },
  { id: 3, name: '王奶奶', specialty: '川菜' },
  { id: 4, name: '陈爷爷', specialty: '粤菜' }
])

// 弹窗控制
const showOrderPopup = ref(false)
const selectedDish = ref<any>(null)
const selectedChef = ref('')
const orderRemark = ref('')
const expectedTime = ref('')

// 筛选后的菜品
const filteredDishes = computed(() => {
  let result = dishes.value

  // 关键词搜索
  if (searchKeyword.value) {
    result = result.filter(dish => 
      dish.name.includes(searchKeyword.value) ||
      dish.chef.includes(searchKeyword.value) ||
      dish.tags.some(tag => tag.includes(searchKeyword.value))
    )
  }

  // 标签筛选
  const selectedTags = filterTags.value.filter(tag => tag.selected)
  if (selectedTags.length > 0 && !selectedTags.find(tag => tag.name === '全部')) {
    result = result.filter(dish => {
      return selectedTags.some(tag => {
        if (tag.name === '拿手菜') {
          return dish.isSpecialty
        }
        return dish.category === tag.name || dish.tags.includes(tag.name)
      })
    })
  }

  return result
})

// 搜索菜品
const searchDishes = () => {
  // TODO: 实现搜索逻辑
}

// 切换筛选标签
const toggleFilter = (tag: any) => {
  if (tag.name === '全部') {
    filterTags.value.forEach(t => t.selected = t.id === tag.id)
  } else {
    const allTag = filterTags.value.find(t => t.name === '全部')
    if (allTag) allTag.selected = false
    tag.selected = !tag.selected
  }
}

// 选择菜品
const selectDish = (dish: any) => {
  selectedDish.value = dish
  showOrderPopup.value = true
}

// 点菜
const orderDish = (dish: any) => {
  selectedDish.value = dish
  showOrderPopup.value = true
}

// 查看详情
const viewDetail = (dish: any) => {
  uni.navigateTo({
    url: `/pages/order/dish-detail?id=${dish.id}`
  })
}

// 提交点菜
const submitOrder = () => {
  if (!selectedChef.value) {
    uni.showToast({
      title: '请选择大厨',
      icon: 'none'
    })
    return
  }

  const orderData = {
    dishId: selectedDish.value.id,
    dishName: selectedDish.value.name,
    chefId: selectedChef.value,
    chefName: availableChefs.value.find(c => c.id === parseInt(selectedChef.value))?.name,
    remark: orderRemark.value,
    expectedTime: expectedTime.value,
    orderTime: new Date().toISOString()
  }

  // TODO: 调用API提交点菜
  console.log('提交点菜:', orderData)

  uni.showToast({
    title: '点菜成功',
    icon: 'success'
  })

  showOrderPopup.value = false
  resetForm()
}

// 重置表单
const resetForm = () => {
  selectedDish.value = null
  selectedChef.value = ''
  orderRemark.value = ''
  expectedTime.value = ''
}

// 页面加载
onMounted(() => {
  // 获取菜品列表
  getDishes()
  // 获取可用大厨
  getAvailableChefs()
})

// 获取菜品列表
const getDishes = () => {
  // TODO: 调用API获取菜品列表
}

// 获取可用大厨
const getAvailableChefs = () => {
  // TODO: 调用API获取可用大厨
}
</script>

<style lang="scss" scoped>
.order-page {
  min-height: 100vh;
  background-color: #f8f9fa;
}

.search-section {
  padding: 20rpx;
  background: white;
}

.filter-section {
  background: white;
  border-bottom: 1rpx solid #e9ecef;
}

.filter-scroll {
  white-space: nowrap;
  padding: 20rpx;
}

.filter-tags {
  display: flex;
  gap: 16rpx;
}

.dish-list {
  padding: 20rpx;
}

.dish-item {
  display: flex;
  background: white;
  border-radius: 16rpx;
  margin-bottom: 20rpx;
  overflow: hidden;
  box-shadow: 0 2rpx 8rpx rgba(0, 0, 0, 0.1);
}

.dish-image {
  width: 200rpx;
  height: 200rpx;
  flex-shrink: 0;
}

.dish-content {
  flex: 1;
  padding: 20rpx;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.dish-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.dish-name {
  font-size: 32rpx;
  font-weight: bold;
  color: #212529;
}

.dish-chef {
  font-size: 24rpx;
  color: #6c757d;
  margin: 8rpx 0;
}

.dish-tags {
  display: flex;
  gap: 8rpx;
  margin-bottom: 16rpx;
}

.dish-actions {
  display: flex;
  gap: 16rpx;
}

.order-popup {
  padding: 30rpx;
}

.popup-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30rpx;
  
  .popup-title {
    font-size: 36rpx;
    font-weight: bold;
  }
}

.selected-dish {
  display: flex;
  align-items: center;
  padding: 20rpx;
  background: #f8f9fa;
  border-radius: 12rpx;
  margin-bottom: 30rpx;
  
  image {
    width: 120rpx;
    height: 120rpx;
    border-radius: 8rpx;
    margin-right: 20rpx;
  }
  
  .dish-info {
    .dish-name {
      font-size: 28rpx;
      font-weight: bold;
      display: block;
    }
    
    .dish-chef {
      font-size: 24rpx;
      color: #6c757d;
      margin-top: 8rpx;
    }
  }
}

.order-form {
  .form-item {
    margin-bottom: 30rpx;
    
    .label {
      font-size: 28rpx;
      font-weight: bold;
      color: #212529;
      display: block;
      margin-bottom: 16rpx;
    }
  }
}

.popup-actions {
  display: flex;
  gap: 20rpx;
  margin-top: 40rpx;
}
</style> 