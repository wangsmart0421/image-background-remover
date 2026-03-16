import axios from 'axios';

// API 配置
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8787';

// 创建 axios 实例
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000, // 30秒超时
  headers: {
    'Content-Type': 'application/json',
  },
});

// 响应拦截器
api.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error);
    
    if (error.response) {
      // 服务器返回错误
      const { status, data } = error.response;
      
      switch (status) {
        case 400:
          throw new Error(data.error || 'Invalid request');
        case 413:
          throw new Error(data.error || 'File too large');
        case 429:
          throw new Error('Too many requests. Please try again later.');
        case 500:
          throw new Error(data.error || 'Server error. Please try again.');
        case 502:
        case 503:
        case 504:
          throw new Error('Service temporarily unavailable. Please try again.');
        default:
          throw new Error(data.error || `Error ${status}: ${data.message || 'Unknown error'}`);
      }
    } else if (error.request) {
      // 请求发送但无响应
      throw new Error('Network error. Please check your connection.');
    } else {
      // 请求配置错误
      throw new Error(error.message || 'Request configuration error');
    }
  }
);

// API 函数
export const apiService = {
  // 健康检查
  async healthCheck() {
    const response = await api.get('/health');
    return response.data;
  },

  // 获取 API 信息
  async getApiInfo() {
    const response = await api.get('/info');
    return response.data;
  },

  // 去除背景
  async removeBackground(imageData: string, options: {
    size?: 'auto' | 'preview' | 'small' | 'regular' | 'medium' | 'hd' | '4k';
    format?: 'png' | 'jpg' | 'zip';
    crop?: boolean;
  } = {}) {
    const payload = {
      image: imageData,
      size: options.size || 'auto',
      format: options.format || 'png',
      crop: options.crop || false,
    };

    const response = await api.post('/api/remove-bg', payload);
    return response.data;
  },

  // 批量处理（占位）
  async batchRemoveBackground(images: string[]) {
    const response = await api.post('/api/batch-remove-bg', { images });
    return response.data;
  },

  // 图片转 Base64
  async fileToBase64(file: File): Promise<string> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => {
        if (typeof reader.result === 'string') {
          resolve(reader.result);
        } else {
          reject(new Error('Failed to convert file to base64'));
        }
      };
      reader.onerror = () => reject(new Error('File reading error'));
      reader.readAsDataURL(file);
    });
  },

  // 验证图片文件
  validateImageFile(file: File): { valid: boolean; error?: string } {
    // 检查文件类型
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (!allowedTypes.includes(file.type)) {
      return {
        valid: false,
        error: `Unsupported file type: ${file.type}. Please upload JPEG, PNG, or WebP.`,
      };
    }

    // 检查文件大小（默认10MB）
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (file.size > maxSize) {
      return {
        valid: false,
        error: `File too large: ${(file.size / 1024 / 1024).toFixed(2)}MB. Maximum size is 10MB.`,
      };
    }

    return { valid: true };
  },

  // 下载图片
  downloadImage(base64Data: string, filename: string = 'background-removed.png') {
    const link = document.createElement('a');
    link.href = base64Data;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  },

  // 复制到剪贴板
  async copyToClipboard(base64Data: string): Promise<boolean> {
    try {
      // 如果是图片，需要先转换为 Blob
      const response = await fetch(base64Data);
      const blob = await response.blob();
      
      await navigator.clipboard.write([
        new ClipboardItem({
          [blob.type]: blob,
        }),
      ]);
      return true;
    } catch (error) {
      console.error('Failed to copy to clipboard:', error);
      
      // 备用方案：复制图片URL
      try {
        await navigator.clipboard.writeText(base64Data);
        return true;
      } catch (fallbackError) {
        console.error('Fallback copy also failed:', fallbackError);
        return false;
      }
    }
  },
};

export default apiService;