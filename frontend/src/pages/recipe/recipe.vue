<template>
	<view class="recipe-container">
		<view class="header">
			<text class="title">菜谱库</text>
			<view class="search-box">
				<input class="search-input" placeholder="搜索菜谱..." v-model="searchKeyword" @input="onSearch" />
			</view>
		</view>
		
		<view class="category-tabs">
			<view 
				class="tab-item" 
				:class="{ active: activeCategory === category.value }"
				v-for="category in categories" 
				:key="category.value"
				@click="switchCategory(category.value)"
			>
				<text class="tab-text">{{ category.label }}</text>
			</view>
		</view>
		
		<view class="recipe-list">
			<view class="recipe-item" v-for="recipe in filteredRecipes" :key="recipe.id" @click="viewRecipe(recipe)">
				<image class="recipe-image" :src="recipe.image" mode="aspectFill"></image>
				<view class="recipe-info">
					<text class="recipe-name">{{ recipe.name }}</text>
					<text class="recipe-desc">{{ recipe.description }}</text>
					<view class="recipe-meta">
						<view class="meta-item">
							<text class="meta-icon">👨‍🍳</text>
							<text class="meta-text">{{ recipe.chef }}</text>
						</view>
						<view class="meta-item">
							<text class="meta-icon">⭐</text>
							<text class="meta-text">{{ recipe.rating }}</text>
						</view>
						<view class="meta-item">
							<text class="meta-icon">⏱️</text>
							<text class="meta-text">{{ recipe.cookTime }}分钟</text>
						</view>
					</view>
					<view class="recipe-tags">
						<text class="tag" v-for="tag in recipe.tags" :key="tag">{{ tag }}</text>
					</view>
				</view>
			</view>
		</view>
		
		<view class="floating-btn" @click="addRecipe">
			<text class="btn-icon">+</text>
		</view>
	</view>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

// 响应式数据
const searchKeyword = ref('')
const activeCategory = ref('all')

const categories = ref([
	{ label: '全部', value: 'all' },
	{ label: '川菜', value: 'sichuan' },
	{ label: '粤菜', value: 'cantonese' },
	{ label: '湘菜', value: 'hunan' },
	{ label: '家常菜', value: 'home' },
	{ label: '汤类', value: 'soup' }
])

const recipes = ref([
	{
		id: 1,
		name: '红烧肉',
		description: '肥而不腻，入口即化的经典红烧肉',
		image: '/static/images/dishes/hongshao.png',
		chef: '妈妈',
		rating: 4.9,
		cookTime: 60,
		category: 'home',
		tags: ['家常菜', '肉类', '经典']
	},
	{
		id: 2,
		name: '麻婆豆腐',
		description: '麻辣鲜香，下饭神器',
		image: '/static/images/dishes/mapo.png',
		chef: '爸爸',
		rating: 4.7,
		cookTime: 30,
		category: 'sichuan',
		tags: ['川菜', '豆腐', '麻辣']
	},
	{
		id: 3,
		name: '白切鸡',
		description: '皮爽肉嫩，清淡鲜美',
		image: '/static/images/dishes/white-chicken.png',
		chef: '妈妈',
		rating: 4.8,
		cookTime: 45,
		category: 'cantonese',
		tags: ['粤菜', '鸡肉', '清淡']
	},
	{
		id: 4,
		name: '剁椒鱼头',
		description: '鲜辣开胃，鱼肉鲜嫩',
		image: '/static/images/dishes/fish-head.png',
		chef: '爸爸',
		rating: 4.6,
		cookTime: 40,
		category: 'hunan',
		tags: ['湘菜', '鱼类', '辣味']
	},
	{
		id: 5,
		name: '番茄蛋汤',
		description: '酸甜开胃，营养美味',
		image: '/static/images/dishes/soup.png',
		chef: '小明',
		rating: 4.5,
		cookTime: 15,
		category: 'soup',
		tags: ['汤类', '鸡蛋', '开胃']
	},
	{
		id: 6,
		name: '糖醋里脊',
		description: '酸甜可口，外酥内嫩',
		image: '/static/images/dishes/tangcu.png',
		chef: '爸爸',
		rating: 4.7,
		cookTime: 35,
		category: 'home',
		tags: ['家常菜', '猪肉', '酸甜']
	}
])

// 计算属性
const filteredRecipes = computed(() => {
	let filtered = recipes.value
	
	// 按分类筛选
	if (activeCategory.value !== 'all') {
		filtered = filtered.filter(recipe => recipe.category === activeCategory.value)
	}
	
	// 按关键词搜索
	if (searchKeyword.value) {
		const keyword = searchKeyword.value.toLowerCase()
		filtered = filtered.filter(recipe => 
			recipe.name.toLowerCase().includes(keyword) ||
			recipe.description.toLowerCase().includes(keyword) ||
			recipe.tags.some(tag => tag.toLowerCase().includes(keyword))
		)
	}
	
	return filtered
})

// 方法
const switchCategory = (category) => {
	activeCategory.value = category
}

const onSearch = () => {
	// 搜索逻辑已在计算属性中处理
}

const viewRecipe = (recipe) => {
	uni.navigateTo({
		url: `/pages/recipe/detail?id=${recipe.id}`
	})
}

const addRecipe = () => {
	uni.showToast({
		title: '添加菜谱功能开发中',
		icon: 'none'
	})
}

// 生命周期
onMounted(() => {
	console.log('菜谱库页面加载完成')
})
</script>

<style scoped>
.recipe-container {
	padding: 20rpx;
	background-color: #f5f5f5;
	min-height: 100vh;
}

.header {
	margin-bottom: 30rpx;
}

.title {
	font-size: 36rpx;
	font-weight: bold;
	color: #333;
	display: block;
	margin-bottom: 20rpx;
}

.search-box {
	margin-bottom: 20rpx;
}

.search-input {
	width: 100%;
	height: 80rpx;
	background: white;
	border-radius: 40rpx;
	padding: 0 30rpx;
	font-size: 28rpx;
	box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.1);
}

.category-tabs {
	display: flex;
	background: white;
	border-radius: 20rpx;
	padding: 10rpx;
	margin-bottom: 30rpx;
	box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.1);
	overflow-x: auto;
}

.tab-item {
	flex-shrink: 0;
	padding: 20rpx 30rpx;
	border-radius: 15rpx;
	transition: all 0.3s ease;
	margin-right: 10rpx;
}

.tab-item:last-child {
	margin-right: 0;
}

.tab-item.active {
	background: #ff6b6b;
}

.tab-text {
	font-size: 26rpx;
	color: #333;
	font-weight: 500;
}

.tab-item.active .tab-text {
	color: white;
}

.recipe-list {
	display: flex;
	flex-direction: column;
	gap: 20rpx;
	margin-bottom: 120rpx;
}

.recipe-item {
	background: white;
	border-radius: 20rpx;
	overflow: hidden;
	box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.1);
	transition: transform 0.3s ease;
}

.recipe-item:active {
	transform: scale(0.98);
}

.recipe-image {
	width: 100%;
	height: 300rpx;
}

.recipe-info {
	padding: 30rpx;
}

.recipe-name {
	font-size: 32rpx;
	font-weight: bold;
	color: #333;
	display: block;
	margin-bottom: 10rpx;
}

.recipe-desc {
	font-size: 26rpx;
	color: #666;
	display: block;
	margin-bottom: 20rpx;
	line-height: 1.5;
}

.recipe-meta {
	display: flex;
	justify-content: space-between;
	margin-bottom: 20rpx;
}

.meta-item {
	display: flex;
	align-items: center;
}

.meta-icon {
	font-size: 24rpx;
	margin-right: 8rpx;
}

.meta-text {
	font-size: 24rpx;
	color: #666;
}

.recipe-tags {
	display: flex;
	flex-wrap: wrap;
	gap: 10rpx;
}

.tag {
	background: #f0f0f0;
	color: #666;
	padding: 8rpx 16rpx;
	border-radius: 20rpx;
	font-size: 22rpx;
}

.floating-btn {
	position: fixed;
	bottom: 40rpx;
	right: 40rpx;
	width: 120rpx;
	height: 120rpx;
	background: #ff6b6b;
	border-radius: 60rpx;
	display: flex;
	align-items: center;
	justify-content: center;
	box-shadow: 0 8rpx 32rpx rgba(255, 107, 107, 0.4);
	z-index: 999;
}

.btn-icon {
	color: white;
	font-size: 48rpx;
	font-weight: bold;
}
</style> 