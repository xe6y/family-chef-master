<template>
	<view class="profile-container">
		<!-- 用户信息卡片 -->
		<view class="user-header">
			<view class="user-info">
				<image class="user-avatar" :src="userInfo.avatar" mode="aspectFill"></image>
				<view class="user-details">
					<text class="user-name">{{ userInfo.name }}</text>
					<text class="user-role">{{ userInfo.role }}</text>
					<text class="user-id">ID: {{ userInfo.id }}</text>
				</view>
			</view>
			<button class="edit-btn" @click="editProfile">编辑</button>
		</view>

		<!-- 统计信息 -->
		<view class="stats-section">
			<view class="stats-card">
				<view class="stats-item">
					<text class="stats-number">{{ stats.orderCount }}</text>
					<text class="stats-label">总订单</text>
				</view>
				<view class="stats-item">
					<text class="stats-number">{{ stats.favoriteCount }}</text>
					<text class="stats-label">收藏菜谱</text>
				</view>
				<view class="stats-item">
					<text class="stats-number">{{ stats.points }}</text>
					<text class="stats-label">积分</text>
				</view>
			</view>
		</view>

		<!-- 功能菜单 -->
		<view class="menu-section">
			<view class="menu-group">
				<view class="menu-item" @click="navigateTo('/pages/order/history')">
					<view class="menu-icon">📋</view>
					<text class="menu-text">订单历史</text>
					<text class="menu-arrow">></text>
				</view>
				<view class="menu-item" @click="navigateTo('/pages/recipe/favorites')">
					<view class="menu-icon">❤️</view>
					<text class="menu-text">我的收藏</text>
					<text class="menu-arrow">></text>
				</view>
				<view class="menu-item" @click="navigateTo('/pages/family/family')">
					<view class="menu-icon">👨‍👩‍👧‍👦</view>
					<text class="menu-text">家庭管理</text>
					<text class="menu-arrow">></text>
				</view>
			</view>

			<view class="menu-group">
				<view class="menu-item" @click="navigateTo('/pages/settings/settings')">
					<view class="menu-icon">⚙️</view>
					<text class="menu-text">设置</text>
					<text class="menu-arrow">></text>
				</view>
				<view class="menu-item" @click="navigateTo('/pages/help/help')">
					<view class="menu-icon">❓</view>
					<text class="menu-text">帮助与反馈</text>
					<text class="menu-arrow">></text>
				</view>
				<view class="menu-item" @click="navigateTo('/pages/about/about')">
					<view class="menu-icon">ℹ️</view>
					<text class="menu-text">关于我们</text>
					<text class="menu-arrow">></text>
				</view>
			</view>
		</view>

		<!-- 退出登录 -->
		<view class="logout-section">
			<button class="logout-btn" @click="logout">退出登录</button>
		</view>
	</view>
</template>

<script setup>
import { ref, onMounted } from 'vue'

// 响应式数据
const userInfo = ref({
	id: '10086',
	name: '小明',
	role: '家庭成员',
	avatar: '/static/images/avatar3.png'
})

const stats = ref({
	orderCount: 25,
	favoriteCount: 12,
	points: 1580
})

// 方法
const editProfile = () => {
	uni.navigateTo({
		url: '/pages/profile/edit'
	})
}

const navigateTo = (url) => {
	uni.navigateTo({
		url: url
	})
}

const logout = () => {
	uni.showModal({
		title: '确认退出',
		content: '确定要退出登录吗？',
		success: (res) => {
			if (res.confirm) {
				// 清除用户数据
				uni.clearStorageSync()
				uni.showToast({
					title: '已退出登录',
					icon: 'success'
				})
				// 跳转到登录页
				setTimeout(() => {
					uni.reLaunch({
						url: '/pages/login/login'
					})
				}, 1500)
			}
		}
	})
}

// 生命周期
onMounted(() => {
	console.log('个人中心页面加载完成')
	// 获取用户信息
	loadUserInfo()
})

const loadUserInfo = () => {
	// 这里可以从本地存储或API获取用户信息
	const storedUserInfo = uni.getStorageSync('userInfo')
	if (storedUserInfo) {
		userInfo.value = { ...userInfo.value, ...storedUserInfo }
	}
}
</script>

<style scoped>
.profile-container {
	padding: 20rpx;
	background-color: #f5f5f5;
	min-height: 100vh;
}

.user-header {
	background: white;
	border-radius: 20rpx;
	padding: 40rpx;
	margin-bottom: 30rpx;
	display: flex;
	justify-content: space-between;
	align-items: center;
	box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.1);
}

.user-info {
	display: flex;
	align-items: center;
}

.user-avatar {
	width: 120rpx;
	height: 120rpx;
	border-radius: 60rpx;
	margin-right: 30rpx;
	border: 4rpx solid #f0f0f0;
}

.user-details {
	display: flex;
	flex-direction: column;
}

.user-name {
	font-size: 36rpx;
	font-weight: bold;
	color: #333;
	margin-bottom: 10rpx;
}

.user-role {
	font-size: 26rpx;
	color: #666;
	margin-bottom: 8rpx;
}

.user-id {
	font-size: 24rpx;
	color: #999;
}

.edit-btn {
	background: #ff6b6b;
	color: white;
	padding: 15rpx 30rpx;
	border-radius: 25rpx;
	font-size: 26rpx;
	border: none;
}

.stats-section {
	margin-bottom: 30rpx;
}

.stats-card {
	background: white;
	border-radius: 20rpx;
	padding: 40rpx;
	display: flex;
	justify-content: space-around;
	box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.1);
}

.stats-item {
	display: flex;
	flex-direction: column;
	align-items: center;
}

.stats-number {
	font-size: 48rpx;
	font-weight: bold;
	color: #ff6b6b;
	margin-bottom: 10rpx;
}

.stats-label {
	font-size: 24rpx;
	color: #666;
}

.menu-section {
	margin-bottom: 30rpx;
}

.menu-group {
	background: white;
	border-radius: 20rpx;
	margin-bottom: 20rpx;
	box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.1);
	overflow: hidden;
}

.menu-item {
	display: flex;
	align-items: center;
	padding: 30rpx;
	border-bottom: 1rpx solid #f0f0f0;
	transition: background-color 0.3s ease;
}

.menu-item:last-child {
	border-bottom: none;
}

.menu-item:active {
	background-color: #f8f9fa;
}

.menu-icon {
	font-size: 40rpx;
	margin-right: 20rpx;
}

.menu-text {
	flex: 1;
	font-size: 30rpx;
	color: #333;
}

.menu-arrow {
	font-size: 24rpx;
	color: #ccc;
}

.logout-section {
	margin-bottom: 30rpx;
}

.logout-btn {
	width: 100%;
	background: #ff4757;
	color: white;
	padding: 30rpx;
	border-radius: 20rpx;
	font-size: 32rpx;
	border: none;
	box-shadow: 0 4rpx 16rpx rgba(255, 71, 87, 0.3);
}
</style> 