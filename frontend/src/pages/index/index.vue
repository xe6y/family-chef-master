<template>
	<view class="content">
		<view class="header">
			<text class="title">家庭厨师</text>
			<text class="subtitle">让每个家庭都能享受美食</text>
		</view>
		
		<view class="feature-grid">
			<view class="feature-item" @click="navigateTo('/pages/family/family')">
				<view class="feature-icon">👨‍👩‍👧‍👦</view>
				<text class="feature-title">我的家庭</text>
				<text class="feature-desc">管理家庭成员</text>
			</view>
			
			<view class="feature-item" @click="navigateTo('/pages/menu/menu')">
				<view class="feature-icon">🍽️</view>
				<text class="feature-title">今日菜单</text>
				<text class="feature-desc">查看今日菜品</text>
			</view>
			
			<view class="feature-item" @click="navigateTo('/pages/recipe/recipe')">
				<view class="feature-icon">📖</view>
				<text class="feature-title">菜谱库</text>
				<text class="feature-desc">浏览美味菜谱</text>
			</view>
			
			<view class="feature-item" @click="navigateTo('/pages/order/order')">
				<view class="feature-icon">🛒</view>
				<text class="feature-title">点餐</text>
				<text class="feature-desc">在线点餐服务</text>
			</view>
		</view>
		
		<view class="quick-actions">
			<button class="action-btn primary" @click="navigateTo('/pages/order/order')">
				开始点餐
			</button>
			<button class="action-btn secondary" @click="navigateTo('/pages/recipe/recipe')">
				浏览菜谱
			</button>
		</view>
	</view>
</template>

<script setup>
import { ref, onMounted } from 'vue'

// 响应式数据
const userInfo = ref({
	name: '用户',
	avatar: '/static/avatar.png'
})

// 方法
const navigateTo = (url) => {
	uni.navigateTo({
		url: url
	})
}

// 生命周期
onMounted(() => {
	console.log('首页加载完成')
})
</script>

<style scoped>
.content {
	padding: 40rpx;
	background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
	min-height: 100vh;
}

.header {
	text-align: center;
	margin-bottom: 60rpx;
}

.title {
	font-size: 48rpx;
	font-weight: bold;
	color: #ffffff;
	display: block;
	margin-bottom: 20rpx;
}

.subtitle {
	font-size: 28rpx;
	color: rgba(255, 255, 255, 0.8);
	display: block;
}

.feature-grid {
	display: grid;
	grid-template-columns: 1fr 1fr;
	gap: 30rpx;
	margin-bottom: 60rpx;
}

.feature-item {
	background: rgba(255, 255, 255, 0.95);
	border-radius: 20rpx;
	padding: 40rpx 30rpx;
	text-align: center;
	box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
	transition: transform 0.3s ease;
}

.feature-item:active {
	transform: scale(0.95);
}

.feature-icon {
	font-size: 60rpx;
	margin-bottom: 20rpx;
}

.feature-title {
	font-size: 32rpx;
	font-weight: bold;
	color: #333;
	display: block;
	margin-bottom: 10rpx;
}

.feature-desc {
	font-size: 24rpx;
	color: #666;
	display: block;
}

.quick-actions {
	display: flex;
	flex-direction: column;
	gap: 20rpx;
}

.action-btn {
	padding: 30rpx;
	border-radius: 15rpx;
	font-size: 32rpx;
	font-weight: bold;
	border: none;
	transition: all 0.3s ease;
}

.action-btn.primary {
	background: #ff6b6b;
	color: white;
}

.action-btn.primary:active {
	background: #ff5252;
}

.action-btn.secondary {
	background: rgba(255, 255, 255, 0.9);
	color: #333;
}

.action-btn.secondary:active {
	background: rgba(255, 255, 255, 0.8);
}
</style> 