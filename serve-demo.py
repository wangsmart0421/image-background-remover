#!/usr/bin/env python3
"""
简单的HTTP服务器，用于展示背景去除工具的演示页面
"""

import http.server
import socketserver
import webbrowser
import os
import sys

PORT = 3000
DEMO_FILE = "frontend/public/index.html"

class DemoHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # 重定向到演示页面
        if self.path == "/":
            self.path = "/" + DEMO_FILE
        
        # 检查文件是否存在
        file_path = "." + self.path
        if not os.path.exists(file_path):
            # 如果请求的是根目录，返回演示页面
            if self.path == "/":
                self.path = "/" + DEMO_FILE
                file_path = "." + self.path
            else:
                # 返回404
                self.send_error(404, "File not found")
                return
        
        # 设置正确的MIME类型
        if file_path.endswith(".html"):
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            
            with open(file_path, "rb") as f:
                self.wfile.write(f.read())
        else:
            # 对于其他文件，使用父类的方法
            return super().do_GET()
    
    def log_message(self, format, *args):
        # 简化日志输出
        print(f"[HTTP] {self.address_string()} - {format % args}")

def main():
    # 检查演示文件是否存在
    if not os.path.exists(DEMO_FILE):
        print(f"错误: 演示文件 {DEMO_FILE} 不存在")
        print("正在创建演示文件...")
        
        # 确保目录存在
        os.makedirs(os.path.dirname(DEMO_FILE), exist_ok=True)
        
        # 这里应该创建演示文件，但我们已经在上面的代码中创建了
        print("请先运行前面的代码创建演示文件")
        return
    
    print("=" * 60)
    print("🚀 图片背景去除工具 - 本地演示")
    print("=" * 60)
    print(f"📁 项目目录: {os.getcwd()}")
    print(f"🌐 演示文件: {DEMO_FILE}")
    print(f"🔗 本地地址: http://localhost:{PORT}")
    print(f"🔗 网络地址: http://{get_ip_address()}:{PORT}")
    print("-" * 60)
    print("📋 功能演示:")
    print("  • 响应式设计，支持手机和电脑")
    print("  • 拖拽上传区域（模拟）")
    print("  • 处理选项选择")
    print("  • 进度条动画")
    print("  • 前后对比展示")
    print("  • 下载选项")
    print("-" * 60)
    
    # 尝试打开浏览器
    try:
        webbrowser.open(f"http://localhost:{PORT}")
        print("🌐 正在浏览器中打开演示页面...")
    except:
        print("⚠️  无法自动打开浏览器，请手动访问上面的地址")
    
    print("🔄 服务器运行中... 按 Ctrl+C 停止")
    print("=" * 60)
    
    # 启动服务器
    os.chdir(".")  # 设置工作目录
    
    with socketserver.TCPServer(("", PORT), DemoHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n👋 服务器已停止")
            httpd.server_close()

def get_ip_address():
    """获取本地IP地址"""
    import socket
    try:
        # 创建一个UDP套接字
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        # 连接到一个外部地址（不需要实际连接）
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"

if __name__ == "__main__":
    # 确保在项目根目录
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    main()