#!/bin/bash

# 图片背景去除工具 - 本地演示启动脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================================${NC}"
echo -e "${GREEN}🚀 图片背景去除工具 - 本地演示${NC}"
echo -e "${BLUE}==================================================${NC}"

# 检查必要文件
check_files() {
    echo -e "${YELLOW}检查必要文件...${NC}"
    
    local missing_files=()
    
    # 检查演示页面
    if [ ! -f "frontend/public/index.html" ]; then
        missing_files+=("frontend/public/index.html")
    fi
    
    # 检查API模拟服务器
    if [ ! -f "test-worker.js" ]; then
        missing_files+=("test-worker.js")
    fi
    
    # 检查Python服务器脚本
    if [ ! -f "serve-demo.py" ]; then
        missing_files+=("serve-demo.py")
    fi
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        echo -e "${RED}错误: 缺少以下文件:${NC}"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        echo -e "\n请先运行前面的代码创建这些文件。"
        exit 1
    fi
    
    echo -e "${GREEN}✓ 所有必要文件都存在${NC}"
}

# 安装必要依赖
install_deps() {
    echo -e "${YELLOW}检查Node.js依赖...${NC}"
    
    if ! command -v node &> /dev/null; then
        echo -e "${RED}错误: Node.js未安装${NC}"
        echo "请先安装Node.js: https://nodejs.org/"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Node.js已安装 ($(node --version))${NC}"
    
    # 检查Python
    if ! command -v python3 &> /dev/null; then
        echo -e "${YELLOW}警告: Python3未安装，部分功能可能受限${NC}"
    else
        echo -e "${GREEN}✓ Python3已安装 ($(python3 --version))${NC}"
    fi
}

# 显示信息
show_info() {
    echo -e "${BLUE}--------------------------------------------------${NC}"
    echo -e "${GREEN}📋 演示信息${NC}"
    echo -e "${BLUE}--------------------------------------------------${NC}"
    echo -e "🌐 ${YELLOW}前端演示${NC}"
    echo -e "   地址: ${GREEN}http://localhost:3000${NC}"
    echo -e "   文件: frontend/public/index.html"
    echo ""
    echo -e "🔧 ${YELLOW}API模拟服务器${NC}"
    echo -e "   地址: ${GREEN}http://localhost:8787${NC}"
    echo -e "   文件: test-worker.js"
    echo ""
    echo -e "📁 ${YELLOW}项目结构${NC}"
    echo -e "   bg-remover-cf/"
    echo -e "   ├── frontend/           # 前端代码"
    echo -e "   ├── worker/             # Cloudflare Worker代码"
    echo -e "   ├── deploy.sh           # 部署脚本"
    echo -e "   └── README.md           # 项目文档"
    echo -e "${BLUE}--------------------------------------------------${NC}"
}

# 启动服务
start_services() {
    echo -e "${YELLOW}启动服务...${NC}"
    
    # 获取本地IP
    local_ip=$(hostname -I | awk '{print $1}')
    if [ -z "$local_ip" ]; then
        local_ip="127.0.0.1"
    fi
    
    # 在后台启动API服务器
    echo -e "启动API模拟服务器 (端口 8787)..."
    node test-worker.js > api-server.log 2>&1 &
    API_PID=$!
    echo -e "${GREEN}✓ API服务器已启动 (PID: $API_PID)${NC}"
    
    # 等待API服务器启动
    sleep 2
    
    # 在后台启动Python HTTP服务器
    echo -e "启动前端演示服务器 (端口 3000)..."
    python3 serve-demo.py > web-server.log 2>&1 &
    WEB_PID=$!
    echo -e "${GREEN}✓ 前端服务器已启动 (PID: $WEB_PID)${NC}"
    
    echo -e "${BLUE}--------------------------------------------------${NC}"
    echo -e "${GREEN}🎉 所有服务已启动！${NC}"
    echo ""
    echo -e "📱 ${YELLOW}访问方式:${NC}"
    echo -e "   1. 本地访问: ${GREEN}http://localhost:3000${NC}"
    echo -e "   2. 网络访问: ${GREEN}http://${local_ip}:3000${NC}"
    echo ""
    echo -e "🔧 ${YELLOW}API测试:${NC}"
    echo -e "   健康检查: ${GREEN}curl http://localhost:8787/health${NC}"
    echo -e "   API信息: ${GREEN}curl http://localhost:8787/info${NC}"
    echo ""
    echo -e "📝 ${YELLOW}日志文件:${NC}"
    echo -e "   API服务器: api-server.log"
    echo -e "   前端服务器: web-server.log"
    echo ""
    echo -e "🛑 ${YELLOW}停止服务:${NC}"
    echo -e "   按 ${RED}Ctrl+C${NC} 停止所有服务"
    echo -e "${BLUE}--------------------------------------------------${NC}"
    
    # 等待用户中断
    wait_for_interrupt
}

# 等待中断
wait_for_interrupt() {
    echo -e "${YELLOW}服务运行中... 按 Ctrl+C 停止${NC}"
    
    # 设置陷阱
    trap cleanup INT TERM
    
    # 等待
    while true; do
        sleep 1
    done
}

# 清理函数
cleanup() {
    echo -e "\n${YELLOW}正在停止服务...${NC}"
    
    # 停止API服务器
    if [ ! -z "$API_PID" ]; then
        kill $API_PID 2>/dev/null && echo -e "${GREEN}✓ API服务器已停止${NC}" || true
    fi
    
    # 停止Web服务器
    if [ ! -z "$WEB_PID" ]; then
        kill $WEB_PID 2>/dev/null && echo -e "${GREEN}✓ 前端服务器已停止${NC}" || true
    fi
    
    echo -e "${GREEN}👋 所有服务已停止${NC}"
    exit 0
}

# 主函数
main() {
    check_files
    install_deps
    show_info
    start_services
}

# 运行主函数
main