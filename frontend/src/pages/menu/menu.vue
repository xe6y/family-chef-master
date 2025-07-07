<template>
	<view class="menu-container">
		<view class="header">
			<text class="title">今日菜单</text>
			<text class="date">{{ currentDate }}</text>
		</view>
		
		<view class="menu-tabs">
			<view 
				class="tab-item" 
				:class="{ active: activeTab === tab.value }"
				v-for="tab in tabs" 
				:key="tab.value"
				@click="switchTab(tab.value)"
			>
				<text class="tab-text">{{ tab.label }}</text>
			</view>
		</view>
		
		<view class="menu-content">
			<view class="meal-section" v-for="meal in currentMeals" :key="meal.type">
				<view class="section-header">
					<text class="section-title">{{ meal.title }}</text>
					<text class="meal-time">{{ meal.time }}</text>
				</view>
				
				<view class="dish-list">
					<view class="dish-item" v-for="dish in meal.dishes" :key="dish.id">
						<image class="dish-image" :src="dish.image" mode="aspectFill"></image>
						<view class="dish-info">
							<text class="dish-name">{{ dish.name }}</text>
							<text class="dish-desc">{{ dish.description }}</text>
							<view class="dish-meta">
								<text class="chef-name">主厨: {{ dish.chef }}</text>
								<text class="dish-price">¥{{ dish.price }}</text>
							</view>
						</view>
						<view class="dish-actions">
							<button class="order-btn" @click="orderDish(dish)">点餐</button>
						</view>
					</view>
				</view>
			</view>
		</view>
		
		<view class="menu-summary">
			<view class="summary-card">
				<view class="summary-item">
					<text class="summary-label">今日菜品</text>
					<text class="summary-value">{{ totalDishes }}道</text>
				</view>
				<view class="summary-item">
					<text class="summary-label">已点餐</text>
					<text class="summary-value">{{ orderedDishes }}道</text>
				</view>
				<view class="summary-item">
					<text class="summary-label">总价</text>
					<text class="summary-value">¥{{ totalPrice }}</text>
				</view>
			</view>
		</view>
	</view>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

// 响应式数据
const activeTab = ref('today')

const tabs = ref([
	{ label: '今日菜单', value: 'today' },
	{ label: '明日菜单', value: 'tomorrow' },
	{ label: '本周菜单', value: 'week' }
])

const todayMeals = ref([
	{
		type: 'breakfast',
		title: '早餐',
		time: '07:00 - 09:00',
		dishes: [
			{
				id: 1,
				name: '皮蛋瘦肉粥',
				description: '香浓可口，营养丰富',
				image: '/static/images/dishes/porridge.png',
				chef: '妈妈',
				price: 8
			},
			{
				id: 2,
				name: '煎蛋三明治',
				description: '新鲜鸡蛋，松软面包',
				image: '/static/images/dishes/sandwich.png',
				chef: '爸爸',
				price: 6
			}
		]
	},
	{
		type: 'lunch',
		title: '午餐',
		time: '12:00 - 13:30',
		dishes: [
			{
				id: 3,
				name: '红烧肉',
				description: '肥而不腻，入口即化',
				image: '/static/images/dishes/hongshao.png',
				chef: '妈妈',
				price: 25
			},
			{
				id: 4,
				name: '清炒时蔬',
				description: '新鲜蔬菜，清淡爽口',
				image: '/static/images/dishes/vegetables.png',
				chef: '小明',
				price: 12
			},
			{
				id: 5,
				name: '番茄蛋汤',
				description: '酸甜开胃，营养美味',
				image: '/static/images/dishes/soup.png',
				chef: '小红',
				price: 8
			}
		]
	},
	{
		type: 'dinner',
		title: '晚餐',
		time: '18:00 - 19:30',
		dishes: [
			{
				id: 6,
				name: '糖醋里脊',
				description: '酸甜可口，外酥内嫩',
				image: '/static/images/dishes/tangcu.png',
				chef: '爸爸',
				price: 28
			},
			{
				id: 7,
				name: '蒜蓉西兰花',
				description: '清香爽脆，健康美味',
				image: '/static/images/dishes/broccoli.png',
				chef: '妈妈',
				price: 15
			}
		]
	}
])

const orderedDishes = ref([])

// 计算属性
const currentDate = computed(() => {
	const date = new Date()
	return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`
})

const currentMeals = computed(() => {
	return todayMeals.value
})

const totalDishes = computed(() => {
	return currentMeals.value.reduce((total, meal) => total + meal.dishes.length, 0)
})

const totalPrice = computed(() => {
	return orderedDishes.value.reduce((total, dish) => total + dish.price, 0)
})

// 方法
const switchTab = (tab) => {
	activeTab.value = tab
}

const orderDish = (dish) => {
	const existingOrder = orderedDishes.value.find(item => item.id === dish.id)
	if (existingOrder) {
		uni.showToast({
			title: '已经点过这道菜了',
			icon: 'none'
		})
		return
	}
	
	orderedDishes.value.push(dish)
	uni.showToast({
		title: `已点餐: ${dish.name}`,
		icon: 'success'
	})
}

// 生命周期
onMounted(() => {
	console.log('菜单页面加载完成')
})
</script>

<style scoped>
.menu-container {
	padding: 20rpx;
	background-color: #f5f5f5;
	min-height: 100vh;
}

.header {
	text-align: center;
	margin-bottom: 30rpx;
}

.title {
	font-size: 36rpx;
	font-weight: bold;
	color: #333;
	display: block;
	margin-bottom: 10rpx;
}

.date {
	font-size: 26rpx;
	color: #666;
}

.menu-tabs {
	display: flex;
	background: white;
	border-radius: 20rpx;
	padding: 10rpx;
	margin-bottom: 30rpx;
	box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.1);
}

.tab-item {
	flex: 1;
	text-align: center;
	padding: 20rpx;
	border-radius: 15rpx;
	transition: all 0.3s ease;
}

.tab-item.active {
	background: #ff6b6b;
}

.tab-text {
	font-size: 28rpx;
	color: #333;
	font-weight: 500;
}

.tab-item.active .tab-text {
	color: white;
}

.menu-content {
	margin-bottom: 30rpx;
}

.meal-section {
	background: white;
	border-radius: 20rpx;
	padding: 30rpx;
	margin-bottom: 30rpx;
	box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.1);
}

.section-header {
	display: flex;
	justify-content: space-between;
	align-items: center;
	margin-bottom: 30rpx;
}

.section-title {
	font-size: 32rpx;
	font-weight: bold;
	color: #333;
}

.meal-time {
	font-size: 24rpx;
	color: #999;
}

.dish-list {
	display: flex;
	flex-direction: column;
	gap: 20rpx;
}

.dish-item {
	display: flex;
	align-items: center;
	padding: 20rpx;
	background: #f8f9fa;
	border-radius: 16rpx;
}

.dish-image {
	width: 120rpx;
	height: 120rpx;
	border-radius: 12rpx;
	margin-right: 20rpx;
}

.dish-info {
	flex: 1;
}

.dish-name {
	font-size: 30rpx;
	font-weight: bold;
	color: #333;
	display: block;
	margin-bottom: 8rpx;
}

.dish-desc {
	font-size: 24rpx;
	color: #666;
	display: block;
	margin-bottom: 12rpx;
}

.dish-meta {
	display: flex;
	justify-content: space-between;
	align-items: center;
}

.chef-name {
	font-size: 22rpx;
	color: #999;
}

.dish-price {
	font-size: 26rpx;
	color: #ff6b6b;
	font-weight: bold;
}

.dish-actions {
	margin-left: 20rpx;
}

.order-btn {
	background: #ff6b6b;
	color: white;
	padding: 15rpx 30rpx;
	border-radius: 25rpx;
	font-size: 26rpx;
	border: none;
}

.menu-summary {
	margin-bottom: 30rpx;
}

.summary-card {
	background: white;
	border-radius: 20rpx;
	padding: 30rpx;
	display: flex;
	justify-content: space-around;
	box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.1);
}

.summary-item {
	display: flex;
	flex-direction: column;
	align-items: center;
}

.summary-label {
	font-size: 24rpx;
	color: #666;
	margin-bottom: 10rpx;
}

.summary-value {
	font-size: 36rpx;
	font-weight: bold;
	color: #ff6b6b;
}
</style> 