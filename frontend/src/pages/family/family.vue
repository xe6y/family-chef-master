<template>
	<view class="family-container">
		<view class="header">
			<text class="title">我的家庭</text>
			<button class="add-btn" @click="showAddMember">添加成员</button>
		</view>
		
		<view class="family-info">
			<view class="family-card">
				<view class="family-avatar">🏠</view>
				<view class="family-details">
					<text class="family-name">{{ familyInfo.name }}</text>
					<text class="family-desc">{{ familyInfo.description }}</text>
					<text class="member-count">{{ familyMembers.length }}位成员</text>
				</view>
			</view>
		</view>
		
		<view class="members-section">
			<view class="section-header">
				<text class="section-title">家庭成员</text>
			</view>
			
			<view class="members-list">
				<view class="member-item" v-for="member in familyMembers" :key="member.id">
					<image class="member-avatar" :src="member.avatar" mode="aspectFill"></image>
					<view class="member-info">
						<text class="member-name">{{ member.name }}</text>
						<text class="member-role">{{ member.role }}</text>
						<text class="member-status" :class="member.status">{{ member.statusText }}</text>
					</view>
					<view class="member-actions">
						<button class="action-btn" @click="editMember(member)">编辑</button>
						<button class="action-btn delete" @click="removeMember(member)">移除</button>
					</view>
				</view>
			</view>
		</view>
		
		<view class="family-stats">
			<view class="stats-card">
				<view class="stats-item">
					<text class="stats-number">{{ stats.totalMembers }}</text>
					<text class="stats-label">总成员</text>
				</view>
				<view class="stats-item">
					<text class="stats-number">{{ stats.activeMembers }}</text>
					<text class="stats-label">在线成员</text>
				</view>
				<view class="stats-item">
					<text class="stats-number">{{ stats.todayOrders }}</text>
					<text class="stats-label">今日订单</text>
				</view>
			</view>
		</view>
	</view>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

// 响应式数据
const familyInfo = ref({
	name: '温馨之家',
	description: '一个充满爱的家庭'
})

const familyMembers = ref([
	{
		id: 1,
		name: '爸爸',
		role: '家长',
		avatar: '/static/images/avatar1.png',
		status: 'online',
		statusText: '在线'
	},
	{
		id: 2,
		name: '妈妈',
		role: '主厨',
		avatar: '/static/images/avatar2.png',
		status: 'online',
		statusText: '在线'
	},
	{
		id: 3,
		name: '小明',
		role: '成员',
		avatar: '/static/images/avatar3.png',
		status: 'offline',
		statusText: '离线'
	},
	{
		id: 4,
		name: '小红',
		role: '成员',
		avatar: '/static/images/avatar4.png',
		status: 'online',
		statusText: '在线'
	}
])

// 计算属性
const stats = computed(() => {
	return {
		totalMembers: familyMembers.value.length,
		activeMembers: familyMembers.value.filter(m => m.status === 'online').length,
		todayOrders: 8
	}
})

// 方法
const showAddMember = () => {
	uni.showToast({
		title: '添加成员功能开发中',
		icon: 'none'
	})
}

const editMember = (member) => {
	uni.showToast({
		title: `编辑${member.name}的信息`,
		icon: 'none'
	})
}

const removeMember = (member) => {
	uni.showModal({
		title: '确认移除',
		content: `确定要移除${member.name}吗？`,
		success: (res) => {
			if (res.confirm) {
				familyMembers.value = familyMembers.value.filter(m => m.id !== member.id)
				uni.showToast({
					title: '移除成功',
					icon: 'success'
				})
			}
		}
	})
}

// 生命周期
onMounted(() => {
	console.log('家庭管理页面加载完成')
})
</script>

<style scoped>
.family-container {
	padding: 20rpx;
	background-color: #f5f5f5;
	min-height: 100vh;
}

.header {
	display: flex;
	justify-content: space-between;
	align-items: center;
	margin-bottom: 30rpx;
}

.title {
	font-size: 36rpx;
	font-weight: bold;
	color: #333;
}

.add-btn {
	background: #ff6b6b;
	color: white;
	padding: 15rpx 30rpx;
	border-radius: 25rpx;
	font-size: 28rpx;
	border: none;
}

.family-info {
	margin-bottom: 30rpx;
}

.family-card {
	background: white;
	border-radius: 20rpx;
	padding: 30rpx;
	display: flex;
	align-items: center;
	box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.1);
}

.family-avatar {
	font-size: 80rpx;
	margin-right: 30rpx;
}

.family-details {
	flex: 1;
}

.family-name {
	font-size: 32rpx;
	font-weight: bold;
	color: #333;
	display: block;
	margin-bottom: 10rpx;
}

.family-desc {
	font-size: 26rpx;
	color: #666;
	display: block;
	margin-bottom: 10rpx;
}

.member-count {
	font-size: 24rpx;
	color: #999;
}

.members-section {
	background: white;
	border-radius: 20rpx;
	padding: 30rpx;
	margin-bottom: 30rpx;
	box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.1);
}

.section-header {
	margin-bottom: 30rpx;
}

.section-title {
	font-size: 32rpx;
	font-weight: bold;
	color: #333;
}

.members-list {
	display: flex;
	flex-direction: column;
	gap: 20rpx;
}

.member-item {
	display: flex;
	align-items: center;
	padding: 20rpx;
	background: #f8f9fa;
	border-radius: 16rpx;
}

.member-avatar {
	width: 80rpx;
	height: 80rpx;
	border-radius: 40rpx;
	margin-right: 20rpx;
}

.member-info {
	flex: 1;
}

.member-name {
	font-size: 30rpx;
	font-weight: bold;
	color: #333;
	display: block;
	margin-bottom: 8rpx;
}

.member-role {
	font-size: 24rpx;
	color: #666;
	display: block;
	margin-bottom: 8rpx;
}

.member-status {
	font-size: 22rpx;
	padding: 4rpx 12rpx;
	border-radius: 12rpx;
}

.member-status.online {
	background: #e8f5e8;
	color: #4caf50;
}

.member-status.offline {
	background: #f5f5f5;
	color: #999;
}

.member-actions {
	display: flex;
	gap: 10rpx;
}

.action-btn {
	padding: 10rpx 20rpx;
	border-radius: 15rpx;
	font-size: 24rpx;
	border: 1rpx solid #ddd;
	background: white;
	color: #333;
}

.action-btn.delete {
	border-color: #ff6b6b;
	color: #ff6b6b;
}

.family-stats {
	margin-bottom: 30rpx;
}

.stats-card {
	background: white;
	border-radius: 20rpx;
	padding: 30rpx;
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
</style> 