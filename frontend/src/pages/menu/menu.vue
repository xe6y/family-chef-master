<template>
  <view class="menu-page">
    <!-- 顶部标签页 -->
    <u-tabs v-model="activeTab" :list="tabList" />
    
    <!-- 今日菜单 -->
    <view v-if="activeTab === 0" class="tab-content">
      <view class="menu-header">
        <text class="date">{{ todayDate }}</text>
        <u-button type="primary" size="mini" @click="addToMenu">添加菜品</u-button>
      </view>
      
      <view class="menu-list">
        <view class="menu-item" v-for="item in todayMenu" :key="item.id">
          <image class="dish-image" :src="item.image" mode="aspectFill" />
          <view class="dish-info">
            <text class="dish-name">{{ item.name }}</text>
            <text class="dish-chef">大厨：{{ item.chef }}</text>
            <view class="dish-tags">
              <u-tag v-for="tag in item.tags" :key="tag" :text="tag" size="mini" />
            </view>
          </view>
          <view class="dish-actions">
            <u-button type="warning" size="mini" @click="removeFromMenu(item.id)">移除</u-button>
            <u-button type="info" size="mini" @click="editDish(item)">编辑</u-button>
          </view>
        </view>
      </view>
    </view>
    
    <!-- 私家菜谱 -->
    <view v-if="activeTab === 1" class="tab-content">
      <view class="recipe-header">
        <u-button type="primary" @click="createRecipe">创建私家菜</u-button>
      </view>
      
      <view class="recipe-list">
        <view class="recipe-item" v-for="recipe in privateRecipes" :key="recipe.id" @click="viewRecipe(recipe)">
          <image class="recipe-image" :src="recipe.image" mode="aspectFill" />
          <view class="recipe-info">
            <text class="recipe-name">{{ recipe.name }}</text>
            <text class="recipe-desc">{{ recipe.description }}</text>
            <view class="recipe-meta">
              <text class="cook-count">制作{{ recipe.cookCount }}次</text>
              <text class="last-cook">上次：{{ recipe.lastCookDate }}</text>
            </view>
            <view class="recipe-tags">
              <u-tag v-for="tag in recipe.tags" :key="tag" :text="tag" size="mini" />
            </view>
          </view>
          <view class="recipe-actions">
            <u-button type="primary" size="mini" @click.stop="cookToday(recipe)">今天做</u-button>
            <u-button type="info" size="mini" @click.stop="shareRecipe(recipe)">分享</u-button>
          </view>
        </view>
      </view>
    </view>
    
    <!-- 菜谱库 -->
    <view v-if="activeTab === 2" class="tab-content">
      <view class="library-search">
        <u-search
          v-model="searchKeyword"
          placeholder="搜索菜谱"
          :show-action="false"
          @search="searchRecipes"
        />
      </view>
      
      <view class="library-filters">
        <scroll-view class="filter-scroll" scroll-x>
          <view class="filter-tags">
            <u-tag
              v-for="tag in libraryFilters"
              :key="tag.id"
              :text="tag.name"
              :type="tag.selected ? 'primary' : 'info'"
              size="mini"
              @click="toggleLibraryFilter(tag)"
            />
          </view>
        </scroll-view>
      </view>
      
      <view class="library-list">
        <view class="library-item" v-for="recipe in filteredLibrary" :key="recipe.id" @click="viewLibraryRecipe(recipe)">
          <image class="recipe-image" :src="recipe.image" mode="aspectFill" />
          <view class="recipe-info">
            <text class="recipe-name">{{ recipe.name }}</text>
            <text class="recipe-author">作者：{{ recipe.author }}</text>
            <view class="recipe-stats">
              <text class="rating">评分：{{ recipe.rating }}</text>
              <text class="cook-count">制作{{ recipe.cookCount }}次</text>
            </view>
            <view class="recipe-tags">
              <u-tag v-for="tag in recipe.tags" :key="tag" :text="tag" size="mini" />
            </view>
          </view>
          <view class="recipe-actions">
            <u-button type="primary" size="mini" @click.stop="addToPrivate(recipe)">收藏</u-button>
            <u-button type="info" size="mini" @click.stop="addRecipeToMenu(recipe)">加入菜单</u-button>
          </view>
        </view>
      </view>
    </view>
    
    <!-- 添加菜品弹窗 -->
    <u-popup v-model="showAddPopup" mode="bottom" height="70%">
      <view class="add-popup">
        <view class="popup-header">
          <text class="popup-title">添加菜品</text>
          <u-icon name="close" @click="showAddPopup = false" />
        </view>
        
        <view class="add-form">
          <view class="form-item">
            <text class="label">选择菜品</text>
            <u-radio-group v-model="selectedRecipeId">
              <u-radio
                v-for="recipe in availableRecipes"
                :key="recipe.id"
                :name="recipe.id"
                :label="recipe.name"
              />
            </u-radio-group>
          </view>
          
          <view class="form-item">
            <text class="label">选择大厨</text>
            <u-radio-group v-model="selectedChefId">
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
              v-model="addRemark"
              placeholder="有什么特殊要求吗？"
              :maxlength="200"
            />
          </view>
        </view>
        
        <view class="popup-actions">
          <u-button type="info" @click="showAddPopup = false">取消</u-button>
          <u-button type="primary" @click="confirmAdd">确认添加</u-button>
        </view>
      </view>
    </u-popup>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import dayjs from 'dayjs'

// 标签页
const activeTab = ref(0)
const tabList = ref([
  { name: '今日菜单' },
  { name: '私家菜谱' },
  { name: '菜谱库' }
])

// 今日日期
const todayDate = computed(() => {
  return dayjs().format('YYYY年MM月DD日')
})

// 今日菜单
const todayMenu = ref([
  {
    id: 1,
    name: '红烧肉',
    chef: '张妈妈',
    image: '/static/image/dish1.jpg',
    tags: ['家常菜', '肉类'],
    remark: '少放盐'
  },
  {
    id: 2,
    name: '清蒸鱼',
    chef: '李爸爸',
    image: '/static/image/dish2.jpg',
    tags: ['海鲜', '清淡'],
    remark: ''
  }
])

// 私家菜谱
const privateRecipes = ref([
  {
    id: 1,
    name: '张妈妈红烧肉',
    description: '改良版红烧肉，肥而不腻',
    image: '/static/image/dish1.jpg',
    tags: ['家常菜', '肉类'],
    cookCount: 15,
    lastCookDate: '2024-01-15',
    ingredients: [
      { name: '五花肉', amount: '500g', unit: '克' },
      { name: '生抽', amount: '2', unit: '勺' },
      { name: '老抽', amount: '1', unit: '勺' }
    ],
    steps: [
      '五花肉切块',
      '锅中放油烧热',
      '放入肉块翻炒'
    ]
  }
])

// 菜谱库
const searchKeyword = ref('')
const libraryFilters = ref([
  { id: 1, name: '全部', selected: true },
  { id: 2, name: '家常菜', selected: false },
  { id: 3, name: '川菜', selected: false },
  { id: 4, name: '粤菜', selected: false },
  { id: 5, name: '素食', selected: false }
])

const recipeLibrary = ref([
  {
    id: 1,
    name: '经典红烧肉',
    author: '美食达人',
    image: '/static/image/dish1.jpg',
    tags: ['家常菜', '肉类'],
    rating: 4.8,
    cookCount: 1250,
    category: '家常菜'
  },
  {
    id: 2,
    name: '清蒸鲈鱼',
    author: '海鲜专家',
    image: '/static/image/dish2.jpg',
    tags: ['海鲜', '清淡'],
    rating: 4.6,
    cookCount: 890,
    category: '海鲜'
  }
])

// 筛选后的菜谱库
const filteredLibrary = computed(() => {
  let result = recipeLibrary.value

  // 关键词搜索
  if (searchKeyword.value) {
    result = result.filter(recipe => 
      recipe.name.includes(searchKeyword.value) ||
      recipe.author.includes(searchKeyword.value) ||
      recipe.tags.some(tag => tag.includes(searchKeyword.value))
    )
  }

  // 标签筛选
  const selectedTags = libraryFilters.value.filter(tag => tag.selected)
  if (selectedTags.length > 0 && !selectedTags.find(tag => tag.name === '全部')) {
    result = result.filter(recipe => {
      return selectedTags.some(tag => recipe.category === tag.name || recipe.tags.includes(tag.name))
    })
  }

  return result
})

// 弹窗控制
const showAddPopup = ref(false)
const selectedRecipeId = ref('')
const selectedChefId = ref('')
const addRemark = ref('')

// 可用菜谱和大厨
const availableRecipes = ref([
  { id: 1, name: '红烧肉' },
  { id: 2, name: '清蒸鱼' },
  { id: 3, name: '麻婆豆腐' }
])

const availableChefs = ref([
  { id: 1, name: '张妈妈' },
  { id: 2, name: '李爸爸' },
  { id: 3, name: '王奶奶' }
])

// 添加菜品到菜单
const addToMenu = () => {
  showAddPopup.value = true
}

// 确认添加
const confirmAdd = () => {
  if (!selectedRecipeId.value || !selectedChefId.value) {
    uni.showToast({
      title: '请选择菜品和大厨',
      icon: 'none'
    })
    return
  }

  const recipe = availableRecipes.value.find(r => r.id === parseInt(selectedRecipeId.value))
  const chef = availableChefs.value.find(c => c.id === parseInt(selectedChefId.value))

  const newDish = {
    id: Date.now(),
    name: recipe?.name || '',
    chef: chef?.name || '',
    image: '/static/image/dish1.jpg',
    tags: ['家常菜'],
    remark: addRemark.value
  }

  todayMenu.value.push(newDish)
  showAddPopup.value = false
  resetAddForm()

  uni.showToast({
    title: '添加成功',
    icon: 'success'
  })
}

// 重置添加表单
const resetAddForm = () => {
  selectedRecipeId.value = ''
  selectedChefId.value = ''
  addRemark.value = ''
}

// 从菜单移除
const removeFromMenu = (id: number) => {
  todayMenu.value = todayMenu.value.filter(item => item.id !== id)
  uni.showToast({
    title: '移除成功',
    icon: 'success'
  })
}

// 编辑菜品
const editDish = (dish: any) => {
  uni.navigateTo({
    url: `/pages/order/dish-edit?id=${dish.id}`
  })
}

// 创建私家菜
const createRecipe = () => {
  uni.navigateTo({
    url: '/pages/order/recipe-create'
  })
}

// 查看私家菜
const viewRecipe = (recipe: any) => {
  uni.navigateTo({
    url: `/pages/order/recipe-detail?id=${recipe.id}`
  })
}

// 今天做
const cookToday = (recipe: any) => {
  const newDish = {
    id: Date.now(),
    name: recipe.name,
    chef: '我',
    image: recipe.image,
    tags: recipe.tags,
    remark: ''
  }
  todayMenu.value.push(newDish)
  
  uni.showToast({
    title: '已加入今日菜单',
    icon: 'success'
  })
}

// 分享菜谱
const shareRecipe = (recipe: any) => {
  uni.share({
    provider: 'weixin',
    scene: 'WXSceneSession',
    type: 0,
    href: `https://example.com/recipe/${recipe.id}`,
    title: recipe.name,
    summary: recipe.description,
    imageUrl: recipe.image
  })
}

// 搜索菜谱
const searchRecipes = () => {
  // TODO: 实现搜索逻辑
}

// 切换菜谱库筛选
const toggleLibraryFilter = (tag: any) => {
  if (tag.name === '全部') {
    libraryFilters.value.forEach(t => t.selected = t.id === tag.id)
  } else {
    const allTag = libraryFilters.value.find(t => t.name === '全部')
    if (allTag) allTag.selected = false
    tag.selected = !tag.selected
  }
}

// 查看菜谱库菜谱
const viewLibraryRecipe = (recipe: any) => {
  uni.navigateTo({
    url: `/pages/order/library-detail?id=${recipe.id}`
  })
}

// 添加到私家菜谱
const addToPrivate = (recipe: any) => {
  const newRecipe = {
    id: Date.now(),
    name: recipe.name,
    description: `来自菜谱库：${recipe.name}`,
    image: recipe.image,
    tags: recipe.tags,
    cookCount: 0,
    lastCookDate: '从未制作',
    ingredients: [],
    steps: []
  }
  
  privateRecipes.value.push(newRecipe)
  
  uni.showToast({
    title: '收藏成功',
    icon: 'success'
  })
}

// 添加菜谱到菜单
const addRecipeToMenu = (recipe: any) => {
  const newDish = {
    id: Date.now(),
    name: recipe.name,
    chef: '我',
    image: recipe.image,
    tags: recipe.tags,
    remark: ''
  }
  todayMenu.value.push(newDish)
  
  uni.showToast({
    title: '已加入今日菜单',
    icon: 'success'
  })
}

// 页面加载
onMounted(() => {
  getTodayMenu()
  getPrivateRecipes()
  getRecipeLibrary()
})

// 获取今日菜单
const getTodayMenu = () => {
  // TODO: 调用API获取今日菜单
}

// 获取私家菜谱
const getPrivateRecipes = () => {
  // TODO: 调用API获取私家菜谱
}

// 获取菜谱库
const getRecipeLibrary = () => {
  // TODO: 调用API获取菜谱库
}
</script>

<style lang="scss" scoped>
.menu-page {
  min-height: 100vh;
  background: linear-gradient(180deg, #fff5f7 0%, #fff 50%, #fef7f8 100%);
  position: relative;
}

.menu-page::before {
  content: '';
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: 
    radial-gradient(circle at 20% 80%, rgba(255, 154, 158, 0.1) 0%, transparent 50%),
    radial-gradient(circle at 80% 20%, rgba(254, 207, 239, 0.1) 0%, transparent 50%),
    radial-gradient(circle at 40% 40%, rgba(255, 107, 157, 0.05) 0%, transparent 50%);
  pointer-events: none;
  z-index: -1;
}

.tab-content {
  padding: 20rpx;
  position: relative;
  z-index: 1;
}

.menu-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20rpx;
  padding: 24rpx;
  background: linear-gradient(135deg, #fff 0%, #fef7f8 100%);
  border-radius: 20rpx;
  border: 1rpx solid rgba(255, 154, 158, 0.1);
  box-shadow: 0 4rpx 16rpx rgba(255, 154, 158, 0.1);
  
  .date {
    font-size: 32rpx;
    font-weight: bold;
    background: linear-gradient(135deg, #ff6b9d, #ff9a9e);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }
}

.menu-list {
  .menu-item {
    display: flex;
    background: linear-gradient(135deg, #fff 0%, #fef7f8 100%);
    border-radius: 20rpx;
    margin-bottom: 20rpx;
    overflow: hidden;
    box-shadow: 0 8rpx 32rpx rgba(255, 154, 158, 0.1);
    border: 1rpx solid rgba(255, 154, 158, 0.08);
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    
    &:active {
      transform: scale(0.98) translateY(2rpx);
      box-shadow: 0 4rpx 16rpx rgba(255, 154, 158, 0.2);
    }
    
    .dish-image {
      width: 160rpx;
      height: 160rpx;
      flex-shrink: 0;
    }
    
    .dish-info {
      flex: 1;
      padding: 20rpx;
      
      .dish-name {
        font-size: 28rpx;
        font-weight: bold;
        color: #ff6b9d;
        display: block;
      }
      
      .dish-chef {
        font-size: 24rpx;
        color: #ff9a9e;
        margin: 8rpx 0;
        display: block;
      }
      
      .dish-tags {
        display: flex;
        gap: 8rpx;
      }
    }
    
    .dish-actions {
      display: flex;
      flex-direction: column;
      gap: 8rpx;
      padding: 20rpx;
      justify-content: center;
    }
  }
}

.recipe-header {
  margin-bottom: 20rpx;
  padding: 24rpx;
  background: linear-gradient(135deg, #fff 0%, #fef7f8 100%);
  border-radius: 20rpx;
  border: 1rpx solid rgba(255, 154, 158, 0.1);
  box-shadow: 0 4rpx 16rpx rgba(255, 154, 158, 0.1);
}

.recipe-list {
  .recipe-item {
    background: linear-gradient(135deg, #fff 0%, #fef7f8 100%);
    border-radius: 20rpx;
    margin-bottom: 20rpx;
    overflow: hidden;
    box-shadow: 0 8rpx 32rpx rgba(255, 154, 158, 0.1);
    border: 1rpx solid rgba(255, 154, 158, 0.08);
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    
    &:active {
      transform: scale(0.98) translateY(2rpx);
      box-shadow: 0 4rpx 16rpx rgba(255, 154, 158, 0.2);
    }
    
    .recipe-image {
      width: 100%;
      height: 300rpx;
    }
    
    .recipe-info {
      padding: 20rpx;
      
      .recipe-name {
        font-size: 32rpx;
        font-weight: bold;
        color: #ff6b9d;
        display: block;
      }
      
      .recipe-desc {
        font-size: 24rpx;
        color: #ff9a9e;
        margin: 8rpx 0;
        display: block;
      }
      
      .recipe-meta {
        display: flex;
        justify-content: space-between;
        margin: 12rpx 0;
        
        .cook-count,
        .last-cook {
          font-size: 22rpx;
          color: #ff9a9e;
          opacity: 0.8;
        }
      }
      
      .recipe-tags {
        display: flex;
        gap: 8rpx;
      }
    }
    
    .recipe-actions {
      display: flex;
      gap: 16rpx;
      padding: 20rpx;
      border-top: 1rpx solid rgba(255, 154, 158, 0.1);
      background: rgba(255, 154, 158, 0.02);
    }
  }
}

.library-search {
  margin-bottom: 20rpx;
  padding: 20rpx;
  background: linear-gradient(135deg, #fff 0%, #fef7f8 100%);
  border-radius: 20rpx;
  border: 1rpx solid rgba(255, 154, 158, 0.1);
  box-shadow: 0 4rpx 16rpx rgba(255, 154, 158, 0.1);
}

.library-filters {
  margin-bottom: 20rpx;
  padding: 20rpx;
  background: linear-gradient(135deg, #fff 0%, #fef7f8 100%);
  border-radius: 20rpx;
  border: 1rpx solid rgba(255, 154, 158, 0.1);
  box-shadow: 0 4rpx 16rpx rgba(255, 154, 158, 0.1);
}

.filter-scroll {
  white-space: nowrap;
}

.filter-tags {
  display: flex;
  gap: 16rpx;
}

.library-list {
  .library-item {
    background: linear-gradient(135deg, #fff 0%, #fef7f8 100%);
    border-radius: 20rpx;
    margin-bottom: 20rpx;
    overflow: hidden;
    box-shadow: 0 8rpx 32rpx rgba(255, 154, 158, 0.1);
    border: 1rpx solid rgba(255, 154, 158, 0.08);
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    
    &:active {
      transform: scale(0.98) translateY(2rpx);
      box-shadow: 0 4rpx 16rpx rgba(255, 154, 158, 0.2);
    }
    
    .recipe-image {
      width: 100%;
      height: 200rpx;
    }
    
    .recipe-info {
      padding: 20rpx;
      
      .recipe-name {
        font-size: 28rpx;
        font-weight: bold;
        color: #ff6b9d;
        display: block;
      }
      
      .recipe-author {
        font-size: 24rpx;
        color: #ff9a9e;
        margin: 8rpx 0;
        display: block;
      }
      
      .recipe-stats {
        display: flex;
        justify-content: space-between;
        margin: 12rpx 0;
        
        .rating,
        .cook-count {
          font-size: 22rpx;
          color: #ff9a9e;
          opacity: 0.8;
        }
      }
      
      .recipe-tags {
        display: flex;
        gap: 8rpx;
      }
    }
    
    .recipe-actions {
      display: flex;
      gap: 16rpx;
      padding: 20rpx;
      border-top: 1rpx solid rgba(255, 154, 158, 0.1);
      background: rgba(255, 154, 158, 0.02);
    }
  }
}

.add-popup {
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

.popup-actions {
  display: flex;
  gap: 20rpx;
  margin-top: 40rpx;
}
</style> 