// A Dark Room 小程序与H5通信桥接工具
const StorageManager = require('./storage.js');

class BridgeManager {

  // 处理来自H5的消息
  static handleH5Message(message, page) {
    if (!message || !message.type) {
      console.warn('无效的H5消息:', message);
      return;
    }

    console.log('处理H5消息:', message.type, message);

    switch (message.type) {
      case 'saveGame':
        return this.handleSaveGame(message.gameData, page);

      case 'loadGame':
        return this.handleLoadGame(page);

      case 'shareGame':
        return this.handleShareGame(message.shareData, page);

      case 'exitGame':
        return this.handleExitGame(page);

      case 'showToast':
        return this.handleShowToast(message.text, message.icon, page);

      case 'vibrate':
        return this.handleVibrate(message.type, page);

      case 'setTitle':
        return this.handleSetTitle(message.title, page);

      case 'getUserInfo':
        return this.handleGetUserInfo(page);

      default:
        console.warn('未知的H5消息类型:', message.type);
        return false;
    }
  }

  // 处理保存游戏数据
  static handleSaveGame(gameData, page) {
    if (!gameData) {
      console.warn('游戏数据为空');
      return false;
    }

    // 先备份当前数据
    StorageManager.backupGameData();

    // 保存新数据
    const success = StorageManager.saveGameData(gameData);

    if (success) {
      console.log('游戏数据保存成功');
      wx.showToast({
        title: '游戏已保存',
        icon: 'success',
        duration: 1500
      });

      // 更新全局数据
      const app = getApp();
      app.globalData.gameData = gameData;

      return true;
    } else {
      console.error('游戏数据保存失败');
      wx.showToast({
        title: '保存失败',
        icon: 'error',
        duration: 1500
      });
      return false;
    }
  }

  // 处理加载游戏数据请求
  static handleLoadGame(page) {
    const gameData = StorageManager.loadGameData();

    if (gameData) {
      console.log('返回游戏数据给H5');
      // 由于web-view限制，无法直接向H5发送消息
      // 通常通过重新加载页面并在URL中传递数据
      return gameData;
    } else {
      console.log('没有找到游戏数据');
      return null;
    }
  }

  // 处理分享游戏
  static handleShareGame(shareData, page) {
    console.log('分享游戏:', shareData);

    // 触发页面分享
    if (page && page.onShareAppMessage) {
      const shareInfo = page.onShareAppMessage();

      // 如果H5提供了自定义分享数据，使用它
      if (shareData) {
        shareInfo.title = shareData.title || shareInfo.title;
        shareInfo.desc = shareData.desc || shareInfo.desc;
        shareInfo.imageUrl = shareData.imageUrl || shareInfo.imageUrl;
      }

      return shareInfo;
    }

    return false;
  }

  // 处理退出游戏
  static handleExitGame(page) {
    wx.showModal({
      title: '确认退出',
      content: '确定要退出游戏吗？未保存的进度将会丢失。',
      confirmText: '退出',
      cancelText: '取消',
      success: (res) => {
        if (res.confirm) {
          // 可以在这里保存当前状态
          wx.navigateBack({
            fail: () => {
              // 如果无法返回，则退出小程序
              wx.exitMiniProgram();
            }
          });
        }
      }
    });

    return true;
  }

  // 处理显示提示
  static handleShowToast(text, icon = 'none', page) {
    const validIcons = ['success', 'error', 'loading', 'none'];
    const finalIcon = validIcons.includes(icon) ? icon : 'none';

    wx.showToast({
      title: text || '操作完成',
      icon: finalIcon,
      duration: 2000
    });

    return true;
  }

  // 处理震动
  static handleVibrate(type = 'short', page) {
    try {
      if (type === 'long') {
        wx.vibrateLong();
      } else {
        wx.vibrateShort();
      }
      return true;
    } catch (e) {
      console.error('震动失败:', e);
      return false;
    }
  }

  // 处理设置标题
  static handleSetTitle(title, page) {
    if (title) {
      wx.setNavigationBarTitle({
        title: title
      });
      return true;
    }
    return false;
  }

  // 处理获取用户信息
  static handleGetUserInfo(page) {
    return new Promise((resolve) => {
      wx.getUserInfo({
        success: (res) => {
          console.log('获取用户信息成功:', res);
          resolve(res.userInfo);
        },
        fail: (err) => {
          console.error('获取用户信息失败:', err);
          resolve(null);
        }
      });
    });
  }

  // 构建带参数的H5 URL
  static buildH5Url(baseUrl, extraParams = {}) {
    try {
      const app = getApp();
      const params = [];

      // 基础参数
      params.push('from=miniprogram');
      params.push('timestamp=' + Date.now().toString());
      params.push('platform=' + (app.globalData.systemInfo?.platform || 'unknown'));

      // 游戏数据
      if (app.globalData.gameData) {
        try {
          const gameDataStr = JSON.stringify(app.globalData.gameData);
          params.push('gameData=' + encodeURIComponent(gameDataStr));
        } catch (e) {
          console.error('序列化游戏数据失败:', e);
        }
      }

      // 用户设置
      const userSettings = StorageManager.loadUserSettings();
      params.push('settings=' + encodeURIComponent(JSON.stringify(userSettings)));

      // 额外参数
      Object.keys(extraParams).forEach(key => {
        params.push(key + '=' + extraParams[key]);
      });

      return baseUrl + '?' + params.join('&');
    } catch (e) {
      console.error('构建H5 URL失败:', e);
      return baseUrl;
    }
  }
}

module.exports = BridgeManager;