// A Dark Room 存储管理工具
class StorageManager {

  // 保存游戏数据
  static saveGameData(data) {
    try {
      wx.setStorageSync('gameData', data);
      wx.setStorageSync('gameDataTimestamp', Date.now());
      console.log('游戏数据保存成功');
      return true;
    } catch (e) {
      console.error('保存游戏数据失败:', e);
      return false;
    }
  }

  // 加载游戏数据
  static loadGameData() {
    try {
      const data = wx.getStorageSync('gameData');
      const timestamp = wx.getStorageSync('gameDataTimestamp');

      if (data) {
        console.log('游戏数据加载成功, 时间戳:', timestamp);
        return {
          data: data,
          timestamp: timestamp
        };
      }

      return null;
    } catch (e) {
      console.error('加载游戏数据失败:', e);
      return null;
    }
  }

  // 清除游戏数据
  static clearGameData() {
    try {
      wx.removeStorageSync('gameData');
      wx.removeStorageSync('gameDataTimestamp');
      console.log('游戏数据清除成功');
      return true;
    } catch (e) {
      console.error('清除游戏数据失败:', e);
      return false;
    }
  }

  // 保存用户设置
  static saveUserSettings(settings) {
    try {
      wx.setStorageSync('userSettings', settings);
      console.log('用户设置保存成功');
      return true;
    } catch (e) {
      console.error('保存用户设置失败:', e);
      return false;
    }
  }

  // 加载用户设置
  static loadUserSettings() {
    try {
      const settings = wx.getStorageSync('userSettings');
      return settings || {
        language: 'zh',
        audioEnabled: true,
        vibrationEnabled: true
      };
    } catch (e) {
      console.error('加载用户设置失败:', e);
      return {
        language: 'zh',
        audioEnabled: true,
        vibrationEnabled: true
      };
    }
  }

  // 获取存储信息
  static getStorageInfo() {
    try {
      const info = wx.getStorageInfoSync();
      console.log('存储信息:', info);
      return info;
    } catch (e) {
      console.error('获取存储信息失败:', e);
      return null;
    }
  }

  // 备份游戏数据
  static backupGameData() {
    try {
      const gameData = this.loadGameData();
      if (gameData) {
        const backupKey = `gameDataBackup_${Date.now()}`;
        wx.setStorageSync(backupKey, gameData);

        // 只保留最近的3个备份
        this.cleanupBackups();

        console.log('游戏数据备份成功:', backupKey);
        return backupKey;
      }
      return null;
    } catch (e) {
      console.error('备份游戏数据失败:', e);
      return null;
    }
  }

  // 清理旧备份
  static cleanupBackups() {
    try {
      const info = wx.getStorageInfoSync();
      const backupKeys = info.keys.filter(key => key.startsWith('gameDataBackup_'));

      // 按时间戳排序，保留最新的3个
      backupKeys.sort((a, b) => {
        const timeA = parseInt(a.split('_')[1]);
        const timeB = parseInt(b.split('_')[1]);
        return timeB - timeA;
      });

      // 删除多余的备份
      for (let i = 3; i < backupKeys.length; i++) {
        wx.removeStorageSync(backupKeys[i]);
        console.log('删除旧备份:', backupKeys[i]);
      }
    } catch (e) {
      console.error('清理备份失败:', e);
    }
  }

  // 恢复游戏数据
  static restoreGameData(backupKey) {
    try {
      const backupData = wx.getStorageSync(backupKey);
      if (backupData) {
        this.saveGameData(backupData.data);
        console.log('游戏数据恢复成功');
        return true;
      }
      return false;
    } catch (e) {
      console.error('恢复游戏数据失败:', e);
      return false;
    }
  }
}

module.exports = StorageManager;