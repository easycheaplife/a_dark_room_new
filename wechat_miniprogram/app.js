// A Dark Room 微信小程序入口文件
const envConfig = require('./config/env.js');

App({
  onLaunch: function () {
    console.log('A Dark Room 小程序启动');

    // 检查更新
    this.checkForUpdate();

    // 初始化全局数据
    this.initGlobalData();
  },

  onShow: function (options) {
    console.log('小程序显示', options);
  },

  onHide: function () {
    console.log('小程序隐藏');
  },

  onError: function (msg) {
    console.error('小程序错误:', msg);
  },

  // 检查小程序更新
  checkForUpdate: function() {
    if (wx.canIUse('getUpdateManager')) {
      const updateManager = wx.getUpdateManager();

      updateManager.onCheckForUpdate(function (res) {
        console.log('检查更新结果:', res.hasUpdate);
      });

      updateManager.onUpdateReady(function () {
        wx.showModal({
          title: '更新提示',
          content: '新版本已经准备好，是否重启应用？',
          success: function (res) {
            if (res.confirm) {
              updateManager.applyUpdate();
            }
          }
        });
      });

      updateManager.onUpdateFailed(function () {
        console.error('新版本下载失败');
      });
    }
  },

  // 初始化全局数据
  initGlobalData: function() {
    console.log('当前环境配置:', envConfig.environment);
    console.log('H5页面地址:', envConfig.h5Url);

    this.globalData = {
      // H5页面地址（从环境配置读取）
      h5Url: envConfig.h5Url,

      // 环境配置
      envConfig: envConfig,

      // 游戏数据
      gameData: null,

      // 用户设置
      userSettings: {
        language: 'zh',
        audioEnabled: true
      },

      // 小程序信息
      systemInfo: null
    };

    // 获取系统信息
    wx.getSystemInfo({
      success: (res) => {
        this.globalData.systemInfo = res;
        console.log('系统信息:', res);
      }
    });

    // 加载本地存储的游戏数据
    this.loadGameData();
  },

  // 加载游戏数据
  loadGameData: function() {
    try {
      const gameData = wx.getStorageSync('gameData');
      if (gameData) {
        this.globalData.gameData = gameData;
        console.log('加载游戏数据成功');
      }
    } catch (e) {
      console.error('加载游戏数据失败:', e);
    }
  },

  // 保存游戏数据
  saveGameData: function(data) {
    try {
      this.globalData.gameData = data;
      wx.setStorageSync('gameData', data);
      console.log('保存游戏数据成功');
      return true;
    } catch (e) {
      console.error('保存游戏数据失败:', e);
      return false;
    }
  },

  globalData: {}
});