import React, { useState, useCallback } from 'react';
import { useDropzone } from 'react-dropzone';
import { Upload, X, Check, AlertCircle } from 'lucide-react';
import apiService from '../utils/api';

interface ImageUploaderProps {
  onImageUpload: (imageData: string) => void;
  onProcessingStart: () => void;
  onProcessingComplete: (result: any) => void;
  onError: (error: string) => void;
}

const ImageUploader: React.FC<ImageUploaderProps> = ({
  onImageUpload,
  onProcessingStart,
  onProcessingComplete,
  onError,
}) => {
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string>('');
  const [isProcessing, setIsProcessing] = useState(false);
  const [progress, setProgress] = useState(0);
  const [options, setOptions] = useState({
    size: 'auto' as 'auto' | 'preview' | 'small' | 'regular' | 'medium' | 'hd' | '4k',
    format: 'png' as 'png' | 'jpg' | 'zip',
    crop: false,
  });

  const onDrop = useCallback(async (acceptedFiles: File[]) => {
    const file = acceptedFiles[0];
    if (!file) return;

    // 验证文件
    const validation = apiService.validateImageFile(file);
    if (!validation.valid) {
      onError(validation.error!);
      return;
    }

    setSelectedFile(file);
    
    // 创建预览
    const reader = new FileReader();
    reader.onload = () => {
      const result = reader.result as string;
      setPreviewUrl(result);
      onImageUpload(result);
    };
    reader.readAsDataURL(file);
  }, [onImageUpload, onError]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'image/jpeg': ['.jpg', '.jpeg'],
      'image/png': ['.png'],
      'image/webp': ['.webp'],
    },
    maxFiles: 1,
    maxSize: 10 * 1024 * 1024, // 10MB
  });

  const handleRemoveImage = () => {
    setSelectedFile(null);
    setPreviewUrl('');
    setProgress(0);
  };

  const handleProcessImage = async () => {
    if (!selectedFile || !previewUrl) {
      onError('Please select an image first');
      return;
    }

    setIsProcessing(true);
    onProcessingStart();
    setProgress(10);

    try {
      // 模拟进度
      const progressInterval = setInterval(() => {
        setProgress(prev => {
          if (prev >= 90) {
            clearInterval(progressInterval);
            return 90;
          }
          return prev + 10;
        });
      }, 300);

      // 实际处理
      const result = await apiService.removeBackground(previewUrl, options);
      
      clearInterval(progressInterval);
      setProgress(100);
      
      setTimeout(() => {
        setIsProcessing(false);
        onProcessingComplete(result);
      }, 500);

    } catch (error: any) {
      setIsProcessing(false);
      setProgress(0);
      onError(error.message || 'Failed to process image');
    }
  };

  const handleOptionChange = (key: keyof typeof options, value: any) => {
    setOptions(prev => ({ ...prev, [key]: value }));
  };

  const formatOptions = [
    { value: 'png', label: 'PNG (透明背景)' },
    { value: 'jpg', label: 'JPG (白色背景)' },
    { value: 'zip', label: 'ZIP (包含遮罩)' },
  ];

  const sizeOptions = [
    { value: 'auto', label: '自动 (原始尺寸)' },
    { value: 'preview', label: '预览 (小尺寸)' },
    { value: 'small', label: '小 (450px)' },
    { value: 'regular', label: '常规 (1024px)' },
    { value: 'medium', label: '中 (1920px)' },
    { value: 'hd', label: '高清 (1920x1080)' },
    { value: '4k', label: '4K (3840x2160)' },
  ];

  return (
    <div className="space-y-6">
      {/* 上传区域 */}
      {!selectedFile ? (
        <div
          {...getRootProps()}
          className={`border-3 border-dashed rounded-2xl p-12 text-center cursor-pointer transition-all duration-300 ${
            isDragActive
              ? 'border-blue-500 bg-blue-50 scale-105'
              : 'border-gray-300 hover:border-blue-400 hover:bg-gray-50'
          }`}
        >
          <input {...getInputProps()} />
          <Upload className="w-16 h-16 mx-auto mb-4 text-gray-400" />
          <h3 className="text-2xl font-semibold text-gray-800 mb-2">
            {isDragActive ? 'Drop the image here' : 'Drag & drop your image'}
          </h3>
          <p className="text-gray-600 mb-6">
            Supports JPG, PNG, WebP up to 10MB
          </p>
          <button className="bg-blue-600 text-white font-semibold py-3 px-8 rounded-full hover:bg-blue-700 transition-colors">
            Browse Files
          </button>
          <p className="text-sm text-gray-500 mt-4">
            Or click to select from your computer
          </p>
        </div>
      ) : (
        <div className="relative">
          {/* 图片预览 */}
          <div className="border-2 border-gray-200 rounded-2xl overflow-hidden">
            <img
              src={previewUrl}
              alt="Preview"
              className="w-full h-64 object-contain bg-gray-100"
            />
          </div>
          
          {/* 移除按钮 */}
          <button
            onClick={handleRemoveImage}
            className="absolute top-4 right-4 bg-red-500 text-white p-2 rounded-full hover:bg-red-600 transition-colors"
            disabled={isProcessing}
          >
            <X className="w-5 h-5" />
          </button>
          
          {/* 文件信息 */}
          <div className="mt-4 p-4 bg-gray-50 rounded-xl">
            <div className="flex items-center justify-between">
              <div>
                <h4 className="font-semibold text-gray-800">{selectedFile.name}</h4>
                <p className="text-sm text-gray-600">
                  {(selectedFile.size / 1024 / 1024).toFixed(2)} MB • {selectedFile.type}
                </p>
              </div>
              <Check className="w-6 h-6 text-green-500" />
            </div>
          </div>
        </div>
      )}

      {/* 处理选项 */}
      {selectedFile && (
        <div className="bg-white border border-gray-200 rounded-2xl p-6">
          <h3 className="text-xl font-semibold text-gray-800 mb-4">
            Processing Options
          </h3>
          
          <div className="space-y-6">
            {/* 输出格式 */}
            <div>
              <label className="block text-gray-700 mb-3 font-medium">
                Output Format
              </label>
              <div className="grid grid-cols-3 gap-3">
                {formatOptions.map((option) => (
                  <button
                    key={option.value}
                    onClick={() => handleOptionChange('format', option.value)}
                    className={`py-3 px-4 rounded-lg border transition-all ${
                      options.format === option.value
                        ? 'border-blue-500 bg-blue-50 text-blue-700'
                        : 'border-gray-300 hover:border-gray-400 hover:bg-gray-50'
                    }`}
                  >
                    {option.label}
                  </button>
                ))}
              </div>
            </div>

            {/* 图片尺寸 */}
            <div>
              <label className="block text-gray-700 mb-3 font-medium">
                Image Size
              </label>
              <select
                value={options.size}
                onChange={(e) => handleOptionChange('size', e.target.value)}
                className="w-full p-3 border border-gray-300 rounded-lg bg-white focus:border-blue-500 focus:ring-2 focus:ring-blue-200 outline-none"
              >
                {sizeOptions.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
            </div>

            {/* 裁剪选项 */}
            <div className="flex items-center">
              <input
                type="checkbox"
                id="crop"
                checked={options.crop}
                onChange={(e) => handleOptionChange('crop', e.target.checked)}
                className="w-5 h-5 text-blue-600 rounded focus:ring-blue-500"
              />
              <label htmlFor="crop" className="ml-3 text-gray-700">
                Auto-crop to subject
              </label>
              <span className="ml-2 text-sm text-gray-500">
                (Crop image tightly around the subject)
              </span>
            </div>
          </div>

          {/* 处理按钮 */}
          <button
            onClick={handleProcessImage}
            disabled={isProcessing}
            className={`w-full mt-6 py-4 rounded-lg font-semibold transition-all ${
              isProcessing
                ? 'bg-blue-400 cursor-not-allowed'
                : 'bg-blue-600 hover:bg-blue-700 hover:shadow-lg'
            } text-white flex items-center justify-center`}
          >
            {isProcessing ? (
              <>
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-3"></div>
                Processing... {progress}%
              </>
            ) : (
              <>
                <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
                Remove Background Now
              </>
            )}
          </button>

          {/* 进度条 */}
          {isProcessing && (
            <div className="mt-4">
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div
                  className="bg-green-600 h-2 rounded-full transition-all duration-300"
                  style={{ width: `${progress}%` }}
                ></div>
              </div>
              <div className="flex justify-between text-sm text-gray-600 mt-2">
                <span>Uploading...</span>
                <span>{progress}%</span>
              </div>
            </div>
          )}
        </div>
      )}

      {/* 提示信息 */}
      {!selectedFile && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-2xl p-6">
          <div className="flex items-start">
            <AlertCircle className="w-6 h-6 text-yellow-600 mr-3 flex-shrink-0" />
            <div>
              <h4 className="font-semibold text-yellow-800 mb-2">Tips for best results</h4>
              <ul className="text-yellow-700 space-y-1">
                <li>• Use high-contrast images for better detection</li>
                <li>• Ensure the subject is clearly visible</li>
                <li>• Avoid complex backgrounds with similar colors</li>
                <li>• For best quality, use PNG format</li>
              </ul>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ImageUploader;