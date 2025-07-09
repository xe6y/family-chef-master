<template>
  <view class="ingredients-page">
    <!-- 顶部统计 -->
    <view class="stats-section">
      <view class="stat-item">
        <text class="stat-number">{{ totalIngredients }}</text>
        <text class="stat-label">总食材</text>
      </view>
      <view class="stat-item">
        <text class="stat-number">{{ lowStockCount }}</text>
        <text class="stat-label">库存不足</text>
      </view>
      <view class="stat-item">
        <text class="stat-number">{{ expiringCount }}</text>
        <text class="stat-label">即将过期</text>
      </view>
    </view>

    <!-- 功能按钮 -->
    <view class="action-buttons">
      <u-button type="primary" @click="addIngredient">添加食材</u-button>
      <u-button type="info" @click="generateShoppingList">生成采购清单</u-button>
    </view>

    <!-- 分类标签 -->
    <view class="category-tabs">
      <u-tabs v-model="activeCategory" :list="categoryList" />
    </view>

    <!-- 食材列表 -->
    <view class="ingredients-list">
      <view
        class="ingredient-item"
        v-for="ingredient in filteredIngredients"
        :key="ingredient.id"
        @click="editIngredient(ingredient)"
      >
        <view class="ingredient-info">
          <text class="ingredient-name">{{ ingredient.name }}</text>
          <text class="ingredient-category">{{ ingredient.category }}</text>
          <view class="ingredient-details">
            <text class="stock">库存：{{ ingredient.stock }}{{ ingredient.unit }}</text>
            <text class="location">位置：{{ ingredient.location }}</text>
          </view>
          <view class="ingredient-meta">
            <text class="expiry" :class="{ 'expiring': ingredient.isExpiring }">
              保质期：{{ ingredient.expiryDate }}
            </text>
            <text class="price">价格：¥{{ ingredient.price }}</text>
          </view>
        </view>
        <view class="ingredient-actions">
          <u-button
            type="warning"
            size="mini"
            @click.stop="adjustStock(ingredient)"
          >
            调整库存
          </u-button>
          <u-button
            type="error"
            size="mini"
            @click.stop="deleteIngredient(ingredient.id)"
          >
            删除
          </u-button>
        </view>
      </view>
    </view>

    <!-- 添加食材弹窗 -->
    <u-popup v-model="showAddPopup" mode="bottom" height="80%">
      <view class="add-popup">
        <view class="popup-header">
          <text class="popup-title">添加食材</text>
          <u-icon name="close" @click="showAddPopup = false" />
        </view>
        
        <view class="add-form">
          <view class="form-item">
            <text class="label">食材名称</text>
            <u-input v-model="newIngredient.name" placeholder="请输入食材名称" />
          </view>
          
          <view class="form-item">
            <text class="label">分类</text>
            <u-picker
              v-model="newIngredient.category"
              :columns="categoryOptions"
              placeholder="选择分类"
            />
          </view>
          
          <view class="form-item">
            <text class="label">库存数量</text>
            <u-input
              v-model="newIngredient.stock"
              type="number"
              placeholder="请输入数量"
            />
          </view>
          
          <view class="form-item">
            <text class="label">单位</text>
            <u-picker
              v-model="newIngredient.unit"
              :columns="unitOptions"
              placeholder="选择单位"
            />
          </view>
          
          <view class="form-item">
            <text class="label">存放位置</text>
            <u-input v-model="newIngredient.location" placeholder="如：冰箱、橱柜" />
          </view>
          
          <view class="form-item">
            <text class="label">保质期</text>
            <u-datetime-picker
              v-model="newIngredient.expiryDate"
              mode="date"
              placeholder="选择保质期"
            />
          </view>
          
          <view class="form-item">
            <text class="label">价格</text>
            <u-input
              v-model="newIngredient.price"
              type="number"
              placeholder="请输入价格"
            />
          </view>
        </view>
        
        <view class="popup-actions">
          <u-button type="info" @click="showAddPopup = false">取消</u-button>
          <u-button type="primary" @click="confirmAdd">确认添加</u-button>
        </view>
      </view>
    </u-popup>

    <!-- 调整库存弹窗 -->
    <u-popup v-model="showStockPopup" mode="bottom" height="50%">
      <view class="stock-popup">
        <view class="popup-header">
          <text class="popup-title">调整库存</text>
          <u-icon name="close" @click="showStockPopup = false" />
        </view>
        
        <view class="stock-form">
          <view class="current-stock">
            <text>当前库存：{{ selectedIngredient?.stock }}{{ selectedIngredient?.unit }}</text>
          </view>
          
          <view class="form-item">
            <text class="label">调整数量</text>
            <u-input
              v-model="stockAdjustment"
              type="number"
              placeholder="正数为增加，负数为减少"
            />
          </view>
        </view>
        
        <view class="popup-actions">
          <u-button type="info" @click="showStockPopup = false">取消</u-button>
          <u-button type="primary" @click="confirmStockAdjustment">确认调整</u-button>
        </view>
      </view>
    </u-popup>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import dayjs from 'dayjs'

// 分类标签
const activeCategory = ref(0)
const categoryList = ref([
  { name: '全部' },
  { name: '蔬菜' },
  { name: '肉类' },
  { name: '海鲜' },
  { name: '调味料' },
  { name: '主食' }
])

// 分类选项
const categoryOptions = ref([
  '蔬菜',
  '肉类',
  '海鲜',
  '调味料',
  '主食',
  '水果',
  '其他'
])

// 单位选项
const unitOptions = ref([
  '克',
  '千克',
  '个',
  '包',
  '瓶',
  '袋',
  '盒'
])

// 食材列表
const ingredients = ref([
  {
    id: 1,
    name: '土豆',
    category: '蔬菜',
    stock: 2.5,
    unit: '千克',
    location: '冰箱',
    expiryDate: '2024-02-15',
    price: 8.5,
    isExpiring: false
  },
  {
    id: 2,
    name: '猪肉',
    category: '肉类',
    stock: 1.2,
    unit: '千克',
    location: '冰箱',
    expiryDate: '2024-01-20',
    price: 25.0,
    isExpiring: true
  },
  {
    id: 3,
    name: '生抽',
    category: '调味料',
    stock: 1,
    unit: '瓶',
    location: '橱柜',
    expiryDate: '2024-12-31',
    price: 15.0,
    isExpiring: false
  }
])

// 统计数据
const totalIngredients = computed(() => ingredients.value.length)

const lowStockCount = computed(() => {
  return ingredients.value.filter(item => {
    const threshold = getLowStockThreshold(item.category)
    return item.stock < threshold
  }).length
})

const expiringCount = computed(() => {
  const today = dayjs()
  const weekLater = today.add(7, 'day')
  return ingredients.value.filter(item => {
    const expiry = dayjs(item.expiryDate)
    return expiry.isBefore(weekLater) && expiry.isAfter(today)
  }).length
})

// 筛选后的食材
const filteredIngredients = computed(() => {
  if (activeCategory.value === 0) {
    return ingredients.value
  }
  const category = categoryList.value[activeCategory.value].name
  return ingredients.value.filter(item => item.category === category)
})

// 弹窗控制
const showAddPopup = ref(false)
const showStockPopup = ref(false)
const selectedIngredient = ref<any>(null)
const stockAdjustment = ref('')

// 新食材数据
const newIngredient = ref({
  name: '',
  category: '',
  stock: '',
  unit: '',
  location: '',
  expiryDate: '',
  price: ''
})

// 获取库存不足阈值
const getLowStockThreshold = (category: string) => {
  const thresholds: Record<string, number> = {
    '蔬菜': 1,
    '肉类': 0.5,
    '海鲜': 0.5,
    '调味料': 0.5,
    '主食': 1,
    '水果': 1,
    '其他': 1
  }
  return thresholds[category] || 1
}

// 添加食材
const addIngredient = () => {
  showAddPopup.value = true
}

// 确认添加
const confirmAdd = () => {
  if (!newIngredient.value.name || !newIngredient.value.category) {
    uni.showToast({
      title: '请填写必要信息',
      icon: 'none'
    })
    return
  }

  const ingredient = {
    id: Date.now(),
    name: newIngredient.value.name,
    category: newIngredient.value.category,
    stock: parseFloat(newIngredient.value.stock) || 0,
    unit: newIngredient.value.unit || '个',
    location: newIngredient.value.location || '未指定',
    expiryDate: newIngredient.value.expiryDate || '',
    price: parseFloat(newIngredient.value.price) || 0,
    isExpiring: false
  }

  // 检查是否即将过期
  if (ingredient.expiryDate) {
    const expiry = dayjs(ingredient.expiryDate)
    const weekLater = dayjs().add(7, 'day')
    ingredient.isExpiring = expiry.isBefore(weekLater) && expiry.isAfter(dayjs())
  }

  ingredients.value.push(ingredient)
  showAddPopup.value = false
  resetNewIngredient()

  uni.showToast({
    title: '添加成功',
    icon: 'success'
  })
}

// 重置新食材表单
const resetNewIngredient = () => {
  newIngredient.value = {
    name: '',
    category: '',
    stock: '',
    unit: '',
    location: '',
    expiryDate: '',
    price: ''
  }
}

// 编辑食材
const editIngredient = (ingredient: any) => {
  uni.navigateTo({
    url: `/pages/order/ingredient-edit?id=${ingredient.id}`
  })
}

// 调整库存
const adjustStock = (ingredient: any) => {
  selectedIngredient.value = ingredient
  stockAdjustment.value = ''
  showStockPopup.value = true
}

// 确认库存调整
const confirmStockAdjustment = () => {
  if (!stockAdjustment.value) {
    uni.showToast({
      title: '请输入调整数量',
      icon: 'none'
    })
    return
  }

  const adjustment = parseFloat(stockAdjustment.value)
  if (selectedIngredient.value) {
    selectedIngredient.value.stock += adjustment
    if (selectedIngredient.value.stock < 0) {
      selectedIngredient.value.stock = 0
    }
  }

  showStockPopup.value = false
  stockAdjustment.value = ''

  uni.showToast({
    title: '调整成功',
    icon: 'success'
  })
}

// 删除食材
const deleteIngredient = (id: number) => {
  uni.showModal({
    title: '确认删除',
    content: '确定要删除这个食材吗？',
    success: (res) => {
      if (res.confirm) {
        ingredients.value = ingredients.value.filter(item => item.id !== id)
        uni.showToast({
          title: '删除成功',
          icon: 'success'
        })
      }
    }
  })
}

// 生成采购清单
const generateShoppingList = () => {
  const lowStockItems = ingredients.value.filter(item => {
    const threshold = getLowStockThreshold(item.category)
    return item.stock < threshold
  })

  const shoppingList = lowStockItems.map(item => ({
    name: item.name,
    category: item.category,
    suggestedAmount: getLowStockThreshold(item.category) - item.stock,
    unit: item.unit,
    estimatedPrice: item.price
  }))

  // 跳转到采购清单页面
  uni.navigateTo({
    url: '/pages/order/shopping-list',
    success: () => {
      // 传递采购清单数据
      uni.$emit('shoppingList', shoppingList)
    }
  })
}

// 页面加载
onMounted(() => {
  getIngredients()
})

// 获取食材列表
const getIngredients = () => {
  // TODO: 调用API获取食材列表
}
</script>

<style lang="scss" scoped>
.ingredients-page {
  min-height: 100vh;
  background-color: #f8f9fa;
  padding-bottom: 20rpx;
}

.stats-section {
  display: flex;
  justify-content: space-around;
  padding: 30rpx 20rpx;
  background: white;
  margin-bottom: 20rpx;
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  
  .stat-number {
    font-size: 36rpx;
    font-weight: bold;
    color: #5685FF;
  }
  
  .stat-label {
    font-size: 24rpx;
    color: #6c757d;
    margin-top: 8rpx;
  }
}

.action-buttons {
  display: flex;
  gap: 20rpx;
  padding: 20rpx;
  background: white;
  margin-bottom: 20rpx;
}

.category-tabs {
  background: white;
  margin-bottom: 20rpx;
}

.ingredients-list {
  padding: 0 20rpx;
}

.ingredient-item {
  display: flex;
  background: white;
  border-radius: 16rpx;
  margin-bottom: 20rpx;
  overflow: hidden;
  box-shadow: 0 2rpx 8rpx rgba(0, 0, 0, 0.1);
}

.ingredient-info {
  flex: 1;
  padding: 20rpx;
  
  .ingredient-name {
    font-size: 32rpx;
    font-weight: bold;
    color: #212529;
    display: block;
  }
  
  .ingredient-category {
    font-size: 24rpx;
    color: #5685FF;
    margin: 8rpx 0;
    display: block;
  }
  
  .ingredient-details {
    display: flex;
    justify-content: space-between;
    margin: 12rpx 0;
    
    .stock,
    .location {
      font-size: 24rpx;
      color: #6c757d;
    }
  }
  
  .ingredient-meta {
    display: flex;
    justify-content: space-between;
    margin-top: 12rpx;
    
    .expiry {
      font-size: 22rpx;
      color: #868e96;
      
      &.expiring {
        color: #dc3545;
        font-weight: bold;
      }
    }
    
    .price {
      font-size: 22rpx;
      color: #28a745;
      font-weight: bold;
    }
  }
}

.ingredient-actions {
  display: flex;
  flex-direction: column;
  gap: 8rpx;
  padding: 20rpx;
  justify-content: center;
}

.add-popup,
.stock-popup {
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

.add-form {
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

.stock-form {
  .current-stock {
    text-align: center;
    padding: 20rpx;
    background: #f8f9fa;
    border-radius: 12rpx;
    margin-bottom: 30rpx;
    
    text {
      font-size: 28rpx;
      color: #212529;
    }
  }
  
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