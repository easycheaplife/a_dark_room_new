// A Dark Room 微信小程序环境配置示例
// 复制此文件为 env.js 并修改为实际的配置值

const ENV_CONFIG = {
  // 开发环境配置
  development: {
    // H5页面地址 - 开发环境
    h5Url: 'https://dev.your-domain.com/a-dark-room',

    // API配置
    apiBaseUrl: 'https://dev-api.your-domain.com',

    // 调试配置
    debug: true,
    logLevel: 'debug',

    // 微信小程序配置
    appId: 'your-dev-appid',

    // 其他开发环境配置
    enableMock: true,
    showDebugInfo: true
  },

  // 测试环境配置
  staging: {
    // H5页面地址 - 测试环境
    h5Url: 'https://staging.your-domain.com/a-dark-room',

    // API配置
    apiBaseUrl: 'https://staging-api.your-domain.com',

    // 调试配置
    debug: true,
    logLevel: 'info',

    // 微信小程序配置
    appId: 'your-staging-appid',

    // 其他测试环境配置
    enableMock: false,
    showDebugInfo: true
  },

  // 生产环境配置
  production: {
    // H5页面地址 - 生产环境
    h5Url: 'https://your-domain.com/a-dark-room',

    // API配置
    apiBaseUrl: 'https://api.your-domain.com',

    // 调试配置
    debug: false,
    logLevel: 'error',

    // 微信小程序配置
    appId: 'your-production-appid',

    // 其他生产环境配置
    enableMock: false,
    showDebugInfo: false
  }
};

// 当前环境 - 可以通过构建脚本或手动修改
// 可选值: 'development', 'staging', 'production'
// 注意：微信小程序不支持process.env，使用固定值
const CURRENT_ENV = 'development';

// 导出当前环境的配置
const currentConfig = ENV_CONFIG[CURRENT_ENV];

// 添加环境标识
currentConfig.environment = CURRENT_ENV;
currentConfig.buildTime = new Date().toISOString();

module.exports = currentConfig;