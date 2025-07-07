// Web音频配置脚本
// 专门处理Flutter Web音频在远程部署环境下的兼容性问题

console.log('🎵 Loading audio configuration...');

// 检查音频支持
function checkAudioSupport() {
  const audio = new Audio();
  const canPlayFlac = audio.canPlayType('audio/flac');
  const canPlayOgg = audio.canPlayType('audio/ogg');
  const canPlayMp3 = audio.canPlayType('audio/mpeg');
  
  console.log('🎵 Audio format support:');
  console.log('  FLAC:', canPlayFlac);
  console.log('  OGG:', canPlayOgg);
  console.log('  MP3:', canPlayMp3);
  
  return { flac: canPlayFlac !== '', ogg: canPlayOgg !== '', mp3: canPlayMp3 !== '' };
}

// 预处理Web音频环境
function initWebAudio() {
  console.log('🎵 Initializing web audio environment...');
  
  // 检查AudioContext支持
  const AudioContext = window.AudioContext || window.webkitAudioContext;
  if (!AudioContext) {
    console.warn('⚠️ AudioContext not supported');
    return false;
  }
  
  // 创建全局音频上下文
  if (!window.globalAudioContext) {
    try {
      window.globalAudioContext = new AudioContext();
      console.log('🎵 Global AudioContext created');
    } catch (e) {
      console.error('❌ Failed to create AudioContext:', e);
      return false;
    }
  }
  
  return true;
}

// 解锁音频上下文
function unlockAudioContext() {
  if (!window.globalAudioContext) return;
  
  if (window.globalAudioContext.state === 'suspended') {
    console.log('🔓 Attempting to unlock audio context...');
    window.globalAudioContext.resume().then(() => {
      console.log('🔓 Audio context unlocked successfully');
    }).catch(e => {
      console.error('❌ Failed to unlock audio context:', e);
    });
  }
}

// 用户交互处理
function handleUserInteraction() {
  console.log('👆 User interaction detected');
  unlockAudioContext();
  
  // 移除事件监听器，避免重复触发
  document.removeEventListener('click', handleUserInteraction);
  document.removeEventListener('touchstart', handleUserInteraction);
  document.removeEventListener('keydown', handleUserInteraction);
}

// 初始化音频环境
function initAudioEnvironment() {
  console.log('🎵 Setting up audio environment...');
  
  // 检查音频支持
  const audioSupport = checkAudioSupport();
  
  // 初始化Web音频
  const audioInitialized = initWebAudio();
  
  if (audioInitialized) {
    // 添加用户交互监听器
    document.addEventListener('click', handleUserInteraction, { once: true });
    document.addEventListener('touchstart', handleUserInteraction, { once: true });
    document.addEventListener('keydown', handleUserInteraction, { once: true });
    
    console.log('🎵 Audio environment setup complete');
  } else {
    console.warn('⚠️ Audio environment setup failed');
  }
  
  return { audioSupport, audioInitialized };
}

// 页面加载完成后初始化
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initAudioEnvironment);
} else {
  initAudioEnvironment();
}

// 暴露给Flutter使用的全局函数
window.checkAudioSupport = checkAudioSupport;
window.initWebAudio = initWebAudio;
window.unlockAudioContext = unlockAudioContext;

console.log('🎵 Audio configuration loaded');
