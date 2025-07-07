<template>
	<view class="order-container">
		<view class="header">
			<text class="title">点餐</text>
			<text class="subtitle">选择您喜欢的菜品</text>
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
		
		<view class="dish-list">
			<view class="dish-item" v-for="dish in filteredDishes" :key="dish.id">
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
					<view class="quantity-control">
						<button class="qty-btn" @click="decreaseQuantity(dish)" :disabled="getQuantity(dish) === 0">-</button>
						<text class="qty-text">{{ getQuantity(dish) }}</text>
						<button class="qty-btn" @click="increaseQuantity(dish)">+</button>
					</view>
				</view>
			</view>
		</view>
		
		<view class="order-summary" v-if="totalQuantity > 0">
			<view class="summary-content">
				<view class="summary-info">
					<text class="summary-text">已选 {{ totalQuantity }} 道菜</text>
					<text class="summary-price">¥{{ totalPrice }}</text>
				</view>
				<button class="submit-btn" @click="submitOrder">提交订单</button>
			</view>
		</view>
		
		<view class="empty-state" v-if="filteredDishes.length === 0">
			<text class="empty-icon">🍽️</text>
			<text class="empty-text">暂无菜品</text>
		</view>
	</view>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

// 响应式数据
const activeCategory = ref('all')
const orderItems = ref([])

const categories = ref([
	{ label: '全部', value: 'all' },
	{ label: '热菜', value: 'hot' },
	{ label: '凉菜', value: 'cold' },
	{ label: '汤类', value: 'soup' },
	{ label: '主食', value: 'staple' }
])

const dishes = ref([
	{
		id: 1,
		name: '红烧肉',
		description: '肥而不腻，入口即化',
		image: '/static/images/dishes/hongshao.png',
		chef: '妈妈',
		price: 25,
		category: 'hot'
	},
	{
		id: 2,
		name: '糖醋里脊',
		description: '酸甜可口，外酥内嫩',
		image: '/static/images/dishes/tangcu.png',
		chef: '爸爸',
		price: 28,
		category: 'hot'
	},
	{
		id: 3,
		name: '凉拌黄瓜',
		description: '清爽开胃，脆嫩爽口',
		image: '/static/images/dishes/cucumber.png',
		chef: '小明',
		price: 8,
		category: 'cold'
	},
	{
		id: 4,
		name: '番茄蛋汤',
		description: '酸甜开胃，营养美味',
		image: '/static/images/dishes/soup.png',
		chef: '小红',
		price: 12,
		category: 'soup'
	},
	{
		id: 5,
		name: '白米饭',
		description: '香软可口，粒粒分明',
		image: '/static/images/dishes/rice.png',
		chef: '妈妈',
		price: 3,
		category: 'staple'
	},
	{
		id: 6,
		name: '清炒时蔬',
		description: '新鲜蔬菜，清淡爽口',
		image: '/static/images/dishes/vegetables.png',
		chef: '小明',
		price: 15,
		category: 'hot'
	}
])

// 计算属性
const filteredDishes = computed(() => {
	if (activeCategory.value === 'all') {
		return dishes.value
	}
	return dishes.value.filter(dish => dish.category === activeCategory.value)
})

const totalQuantity = computed(() => {
	return orderItems.value.reduce((total, item) => total + item.quantity, 0)
})

const totalPrice = computed(() => {
	return orderItems.value.reduce((total, item) => total + (item.price * item.quantity), 0)
})

// 方法
const switchCategory = (category) => {
	activeCategory.value = category
}

const getQuantity = (dish) => {
	const item = orderItems.value.find(item => item.id === dish.id)
	return item ? item.quantity : 0
}

const increaseQuantity = (dish) => {
	const existingItem = orderItems.value.find(item => item.id === dish.id)
	if (existingItem) {
		existingItem.quantity++
	} else {
		orderItems.value.push({
			id: dish.id,
			name: dish.name,
			price: dish.price,
			quantity: 1
		})
	}
}

const decreaseQuantity = (dish) => {
	const existingItem = orderItems.value.find(item => item.id === dish.id)
	if (existingItem) {
		if (existingItem.quantity > 1) {
			existingItem.quantity--
		} else {
			orderItems.value = orderItems.value.filter(item => item.id !== dish.id)
		}
	}
}

const submitOrder = () => {
	if (totalQuantity.value === 0) {
		uni.showToast({
			title: '请选择菜品',
			icon: 'none'
		})
		return
	}
	
	uni.showModal({
		title: '确认订单',
		content: `共${totalQuantity.value}道菜，总价¥${totalPrice.value}，确认提交吗？`,
		success: (res) => {
			if (res.confirm) {
				// 这里可以调用API提交订单
				uni.showToast({
					title: '订单提交成功',
					icon: 'success'
				})
				// 清空购物车
				orderItems.value = []
			}
		}
	})
}

// 生命周期
onMounted(() => {
	console.log('点餐页面加载完成')
})
</script>

<style scoped>
.order-container {
	padding: 20rpx;
	background-color: #f5f5f5;
	min-height: 100vh;
	padding-bottom: 120rpx;
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

.subtitle {
	font-size: 26rpx;
	color: #666;
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

.dish-list {
	display: flex;
	flex-direction: column;
	gap: 20rpx;
}

.dish-item {
	background: white;
	border-radius: 20rpx;
	padding: 30rpx;
	display: flex;
	align-items: center;
	box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.1);
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

.quantity-control {
	display: flex;
	align-items: center;
	background: #f8f9fa;
	border-radius: 25rpx;
	padding: 5rpx;
}

.qty-btn {
	width: 50rpx;
	height: 50rpx;
	border-radius: 25rpx;
	background: white;
	border: 1rpx solid #ddd;
	color: #333;
	font-size: 24rpx;
	display: flex;
	align-items: center;
	justify-content: center;
}

.qty-btn:disabled {
	color: #ccc;
	background: #f5f5f5;
}

.qty-text {
	width: 60rpx;
	text-align: center;
	font-size: 26rpx;
	color: #333;
	font-weight: bold;
}

.order-summary {
	position: fixed;
	bottom: 0;
	left: 0;
	right: 0;
	background: white;
	padding: 30rpx;
	box-shadow: 0 -4rpx 16rpx rgba(0, 0, 0, 0.1);
	z-index: 999;
}

.summary-content {
	display: flex;
	justify-content: space-between;
	align-items: center;
}

.summary-info {
	display: flex;
	flex-direction: column;
}

.summary-text {
	font-size: 26rpx;
	color: #666;
	margin-bottom: 5rpx;
}

.summary-price {
	font-size: 32rpx;
	font-weight: bold;
	color: #ff6b6b;
}

.submit-btn {
	background: #ff6b6b;
	color: white;
	padding: 20rpx 40rpx;
	border-radius: 25rpx;
	font-size: 28rpx;
	border: none;
}

.empty-state {
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	padding: 100rpx 0;
}

.empty-icon {
	font-size: 100rpx;
	margin-bottom: 30rpx;
}

.empty-text {
	font-size: 28rpx;
	color: #999;
}
</style> 