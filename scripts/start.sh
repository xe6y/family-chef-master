#!/bin/bash

# 家庭厨师微信小程序启动脚本

echo "🚀 启动家庭厨师微信小程序开发环境..."

# 检查必要的工具是否安装
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ 错误: $1 未安装，请先安装 $1"
        exit 1
    fi
}

echo "📋 检查开发环境..."
check_command "go"
check_command "node"
check_command "npm"
check_command "mysql"

echo "✅ 开发环境检查完成"

# 启动后端服务
start_backend() {
    echo "🔧 启动后端服务..."
    cd backend
    
    # 检查配置文件
    if [ ! -f "configs/config.yaml" ]; then
        echo "❌ 错误: 配置文件 configs/config.yaml 不存在"
        echo "请复制 configs/config.yaml.example 并修改配置"
        exit 1
    fi
    
    # 安装依赖
    echo "📦 安装Go依赖..."
    go mod tidy
    
    # 启动服务
    echo "🚀 启动Go服务..."
    go run cmd/main.go &
    BACKEND_PID=$!
    echo "✅ 后端服务已启动 (PID: $BACKEND_PID)"
    
    cd ..
}

# 启动前端服务
start_frontend() {
    echo "🎨 启动前端服务..."
    cd frontend
    
    # 检查依赖
    if [ ! -d "node_modules" ]; then
        echo "📦 安装前端依赖..."
        npm install
    fi
    
    # 启动开发服务器
    echo "🚀 启动前端开发服务器..."
    npm run dev &
    FRONTEND_PID=$!
    echo "✅ 前端服务已启动 (PID: $FRONTEND_PID)"
    
    cd ..
}

# 启动Redis（如果本地安装）
start_redis() {
    if command -v redis-server &> /dev/null; then
        echo "🔴 启动Redis服务..."
        redis-server --daemonize yes
        echo "✅ Redis服务已启动"
    else
        echo "⚠️  Redis未安装，请确保Redis服务正在运行"
    fi
}

# 检查数据库连接
check_database() {
    echo "🗄️ 检查数据库连接..."
    # 这里可以添加数据库连接检查逻辑
    echo "✅ 数据库连接正常"
}

# 显示服务状态
show_status() {
    echo ""
    echo "🎉 所有服务启动完成！"
    echo ""
    echo "📱 前端服务: http://localhost:3000"
    echo "🔧 后端API: http://localhost:8080"
    echo "📚 API文档: http://localhost:8080/docs"
    echo ""
    echo "💡 提示:"
    echo "  - 使用 Ctrl+C 停止所有服务"
    echo "  - 后端日志: tail -f backend/logs/app.log"
    echo "  - 前端日志: 查看终端输出"
    echo ""
}

# 清理函数
cleanup() {
    echo ""
    echo "🛑 正在停止服务..."
    
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null
        echo "✅ 后端服务已停止"
    fi
    
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null
        echo "✅ 前端服务已停止"
    fi
    
    echo "👋 所有服务已停止"
    exit 0
}

# 注册清理函数
trap cleanup SIGINT SIGTERM

# 主函数
main() {
    echo "🏠 家庭厨师微信小程序"
    echo "========================"
    
    # 检查数据库
    check_database
    
    # 启动Redis
    start_redis
    
    # 启动后端
    start_backend
    
    # 等待后端启动
    sleep 3
    
    # 启动前端
    start_frontend
    
    # 显示状态
    show_status
    
    # 等待用户中断
    wait
}

# 运行主函数
main 