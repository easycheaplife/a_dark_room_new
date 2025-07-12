// A Dark Room 游戏页面
const app = getApp();

Page({
  data: {
    h5Url: '',
    loading: true,
    error: false,
    errorMessage: ''
  },

  onLoad: function (options) {
    console.log('游戏页面加载', options);

    // 设置页面标题
    wx.setNavigationBarTitle({
      title: 'A Dark Room'
    });

    // 构建H5 URL
    this.buildH5Url();

    // 设置加载超时
    this.loadingTimeout = setTimeout(() => {
      if (this.data.loading) {
        console.warn('页面加载超时');
        this.setData({
          error: true,
          errorMessage: '页面加载超时，请检查网络连接或重试',
          loading: false
        });
      }
    }, 15000); // 15秒超时
  },

  onShow: function () {
    console.log('游戏页面显示');
  },

  onHide: function () {
    console.log('游戏页面隐藏');
  },

  onUnload: function () {
    console.log('游戏页面卸载');

    // 清除加载超时定时器
    if (this.loadingTimeout) {
      clearTimeout(this.loadingTimeout);
      this.loadingTimeout = null;
    }
  },

  // 构建H5页面URL
  buildH5Url: function() {
    try {
      let baseUrl = app.globalData.h5Url;

      // 构建URL参数（兼容微信小程序环境）
      const params = [];
      params.push('from=miniprogram');
      params.push('timestamp=' + Date.now().toString());
      params.push('platform=' + (app.globalData.systemInfo?.platform || 'unknown'));

      // 如果有游戏数据，添加到URL参数中
      if (app.globalData.gameData) {
        try {
          const gameDataStr = JSON.stringify(app.globalData.gameData);
          params.push('gameData=' + encodeURIComponent(gameDataStr));
        } catch (e) {
          console.error('序列化游戏数据失败:', e);
        }
      }

      const finalUrl = baseUrl + '?' + params.join('&');
      console.log('构建的H5 URL:', finalUrl);

      this.setData({
        h5Url: finalUrl,
        loading: false
      });

      // 清除加载超时定时器
      if (this.loadingTimeout) {
        clearTimeout(this.loadingTimeout);
        this.loadingTimeout = null;
      }

    } catch (e) {
      console.error('构建H5 URL失败:', e);
      this.setData({
        error: true,
        errorMessage: '页面加载失败，请重试',
        loading: false
      });
    }
  },

  // 接收H5页面发送的消息
  onH5Message: function(e) {
    console.log('收到H5消息:', e.detail.data);

    const messages = e.detail.data;
    if (!Array.isArray(messages) || messages.length === 0) {
      return;
    }

    // 处理每个消息
    messages.forEach(message => {
      this.handleH5Message(message);
    });
  },

  // web-view加载错误处理
  onH5Error: function(e) {
    console.error('web-view加载错误:', e);

    let errorMessage = 'H5页面加载失败';
    if (e.detail && e.detail.errMsg) {
      const errMsg = e.detail.errMsg;
      if (errMsg.includes('invalid url')) {
        errorMessage = 'URL格式错误或协议不支持';
      } else if (errMsg.includes('domain not in domain list')) {
        errorMessage = '域名未在白名单中，请在开发者工具中开启"不校验合法域名"选项';
      } else if (errMsg.includes('ssl handshake error')) {
        errorMessage = 'SSL证书问题，请检查HTTPS配置';
      } else if (errMsg.includes('ERR_CONNECTION_REFUSED')) {
        errorMessage = '服务器拒绝连接，请检查服务器状态';
      } else {
        errorMessage = '加载失败: ' + errMsg;
      }
    }

    this.setData({
      error: true,
      errorMessage: errorMessage,
      loading: false
    });

    // 清除加载超时定时器
    if (this.loadingTimeout) {
      clearTimeout(this.loadingTimeout);
      this.loadingTimeout = null;
    }
  },

  // 处理单个H5消息
  handleH5Message: function(message) {
    if (!message || !message.type) {
      console.warn('无效的H5消息:', message);
      return;
    }

    console.log('处理H5消息:', message.type, message);

    switch (message.type) {
      case 'saveGame':
        this.handleSaveGame(message.gameData);
        break;

      case 'loadGame':
        this.handleLoadGame();
        break;

      case 'shareGame':
        this.handleShareGame(message.shareData);
        break;

      case 'exitGame':
        this.handleExitGame();
        break;

      case 'showToast':
        this.handleShowToast(message.text, message.icon);
        break;

      default:
        console.warn('未知的H5消息类型:', message.type);
    }
  },

  // 处理保存游戏数据
  handleSaveGame: function(gameData) {
    if (!gameData) {
      console.warn('游戏数据为空');
      return;
    }

    const success = app.saveGameData(gameData);
    if (success) {
      console.log('游戏数据保存成功');
      // 可以显示保存成功的提示
      wx.showToast({
        title: '游戏已保存',
        icon: 'success',
        duration: 1500
      });
    } else {
      console.error('游戏数据保存失败');
      wx.showToast({
        title: '保存失败',
        icon: 'error',
        duration: 1500
      });
    }
  },

  // 处理加载游戏数据请求
  handleLoadGame: function() {
    // 这里可以向H5页面发送游戏数据
    // 但由于web-view的限制，通常通过URL参数传递
    console.log('H5请求加载游戏数据');
  },

  // 处理分享游戏
  handleShareGame: function(shareData) {
    console.log('分享游戏:', shareData);
    // 这里可以实现分享功能
  },

  // 处理退出游戏
  handleExitGame: function() {
    wx.showModal({
      title: '确认退出',
      content: '确定要退出游戏吗？',
      success: (res) => {
        if (res.confirm) {
          wx.navigateBack();
        }
      }
    });
  },

  // 处理显示提示
  handleShowToast: function(text, icon = 'none') {
    wx.showToast({
      title: text || '操作完成',
      icon: icon,
      duration: 2000
    });
  },

  // 重新加载页面
  onRetry: function() {
    this.setData({
      loading: true,
      error: false,
      errorMessage: ''
    });

    this.buildH5Url();
  },

  // 测试不同URL
  onTestUrl: function() {
    const testUrls = [
      'https://www.baidu.com',
      'https://m.baidu.com',
      'https://www.qq.com',
      app.globalData.h5Url
    ];

    wx.showActionSheet({
      itemList: [
        '测试百度(www.baidu.com)',
        '测试百度手机版(m.baidu.com)',
        '测试腾讯(www.qq.com)',
        '测试游戏URL'
      ],
      success: (res) => {
        const selectedUrl = testUrls[res.tapIndex];
        console.log('测试URL:', selectedUrl);

        this.setData({
          h5Url: selectedUrl,
          loading: true,
          error: false,
          errorMessage: ''
        });

        // 设置新的超时定时器
        if (this.loadingTimeout) {
          clearTimeout(this.loadingTimeout);
        }
        this.loadingTimeout = setTimeout(() => {
          if (this.data.loading) {
            this.setData({
              error: true,
              errorMessage: '页面加载超时: ' + selectedUrl,
              loading: false
            });
          }
        }, 15000);
      }
    });
  },

  // 页面分享
  onShareAppMessage: function () {
    return {
      title: 'A Dark Room - 黑暗房间',
      desc: '一个引人入胜的文字冒险游戏',
      path: '/pages/game/game'
    };
  }
});