import 'package:flutter/foundation.dart';
import '../core/logger.dart';
import 'web_utils.dart';


/// 分享管理器
/// 处理游戏内的分享功能，包括微信分享、成就分享等
class ShareManager {
  static bool _initialized = false;
  
  /// 初始化分享管理器
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      if (kIsWeb && WebUtils.isWeChatBrowser()) {
        await _initializeWeChatShare();
      }
      
      _initialized = true;
      Logger.info('ShareManager initialized');
    } catch (e) {
      Logger.error('ShareManager.initialize error: $e');
    }
  }

  /// 初始化微信分享
  static Future<void> _initializeWeChatShare() async {
    try {
      // 配置默认分享内容
      await updateShareContent();
    } catch (e) {
      Logger.error('_initializeWeChatShare error: $e');
    }
  }

  /// 更新分享内容
  static Future<void> updateShareContent({
    String? title,
    String? desc,
    String? link,
    String? imgUrl,
  }) async {
    if (!kIsWeb || !WebUtils.isWeChatBrowser()) return;
    
    try {
      final shareConfig = {
        'title': title ?? 'A Dark Room - 黑暗房间',
        'desc': desc ?? '一个引人入胜的文字冒险游戏，快来体验吧！',
        'link': link ?? WebUtils.getCurrentUrl(),
        'imgUrl': imgUrl ?? '${WebUtils.getCurrentUrl().split('?')[0]}/icons/Icon-512.png',
      };
      
      WebUtils.configWeChatShare(
        title: shareConfig['title']!,
        desc: shareConfig['desc']!,
        link: shareConfig['link'],
        imgUrl: shareConfig['imgUrl'],
      );
      
      Logger.info('Share content updated: $shareConfig');
    } catch (e) {
      Logger.error('updateShareContent error: $e');
    }
  }

  /// 分享游戏进度
  static Future<void> shareProgress({
    required int day,
    required String currentLocation,
    required Map<String, int> resources,
  }) async {
    if (!kIsWeb || !WebUtils.isWeChatBrowser()) return;
    
    try {
      final resourceText = _formatResources(resources);
      final title = 'A Dark Room - 第$day天的冒险';
      final desc = '我在《黑暗房间》中已经生存了$day天！当前位置：$currentLocation。$resourceText 快来一起冒险吧！';
      
      await updateShareContent(
        title: title,
        desc: desc,
      );
      
      Logger.info('Progress shared: Day $day, Location: $currentLocation');
    } catch (e) {
      Logger.error('shareProgress error: $e');
    }
  }

  /// 分享成就
  static Future<void> shareAchievement({
    required String achievementName,
    required String achievementDesc,
  }) async {
    if (!kIsWeb || !WebUtils.isWeChatBrowser()) return;
    
    try {
      final title = 'A Dark Room - 成就解锁！';
      final desc = '我在《黑暗房间》中解锁了成就：$achievementName！$achievementDesc 快来挑战吧！';
      
      await updateShareContent(
        title: title,
        desc: desc,
      );
      
      Logger.info('Achievement shared: $achievementName');
    } catch (e) {
      Logger.error('shareAchievement error: $e');
    }
  }

  /// 分享探索发现
  static Future<void> shareDiscovery({
    required String locationName,
    required String discoveryDesc,
  }) async {
    if (!kIsWeb || !WebUtils.isWeChatBrowser()) return;
    
    try {
      final title = 'A Dark Room - 新发现！';
      final desc = '我在《黑暗房间》中发现了$locationName！$discoveryDesc 这个世界充满了神秘，快来探索吧！';
      
      await updateShareContent(
        title: title,
        desc: desc,
      );
      
      Logger.info('Discovery shared: $locationName');
    } catch (e) {
      Logger.error('shareDiscovery error: $e');
    }
  }

  /// 分享战斗胜利
  static Future<void> shareCombatVictory({
    required String enemyName,
    required Map<String, int> loot,
  }) async {
    if (!kIsWeb || !WebUtils.isWeChatBrowser()) return;
    
    try {
      final lootText = _formatResources(loot);
      final title = 'A Dark Room - 战斗胜利！';
      final desc = '我在《黑暗房间》中击败了$enemyName！获得了：$lootText 危险与机遇并存，快来体验吧！';
      
      await updateShareContent(
        title: title,
        desc: desc,
      );
      
      Logger.info('Combat victory shared: $enemyName');
    } catch (e) {
      Logger.error('shareCombatVictory error: $e');
    }
  }

  /// 分享游戏完成
  static Future<void> shareGameCompletion({
    required int totalDays,
    required String endingType,
  }) async {
    if (!kIsWeb || !WebUtils.isWeChatBrowser()) return;
    
    try {
      final title = 'A Dark Room - 游戏完成！';
      final desc = '我完成了《黑暗房间》的冒险！总共生存了$totalDays天，获得了"$endingType"结局。这是一段难忘的旅程，推荐给所有喜欢冒险的朋友！';
      
      await updateShareContent(
        title: title,
        desc: desc,
      );
      
      Logger.info('Game completion shared: $totalDays days, $endingType ending');
    } catch (e) {
      Logger.error('shareGameCompletion error: $e');
    }
  }

  /// 分享邀请好友
  static Future<void> shareInvitation() async {
    if (!kIsWeb || !WebUtils.isWeChatBrowser()) return;
    
    try {
      final title = 'A Dark Room - 邀请你来冒险！';
      final desc = '我在玩一个超棒的文字冒险游戏《黑暗房间》！从一个小火堆开始，建造村庄，探索世界，体验完整的生存冒险。快来一起玩吧！';
      
      await updateShareContent(
        title: title,
        desc: desc,
      );
      
      Logger.info('Invitation shared');
    } catch (e) {
      Logger.error('shareInvitation error: $e');
    }
  }

  /// 格式化资源信息
  static String _formatResources(Map<String, int> resources) {
    if (resources.isEmpty) return '';
    
    final resourceList = <String>[];
    resources.forEach((key, value) {
      if (value > 0) {
        resourceList.add('$key: $value');
      }
    });
    
    if (resourceList.isEmpty) return '';
    
    if (resourceList.length <= 3) {
      return resourceList.join('、');
    } else {
      return '${resourceList.take(3).join('、')}等${resourceList.length}种资源';
    }
  }

  /// 获取当前游戏状态用于分享
  static Map<String, dynamic> getCurrentGameState() {
    // 这里应该从游戏状态管理器获取当前状态
    // 为了演示，返回模拟数据
    return {
      'day': 1,
      'location': '小黑屋',
      'resources': {
        '木材': 10,
        '毛皮': 5,
        '肉': 3,
      },
    };
  }

  /// 检查分享功能是否可用
  static bool isShareAvailable() {
    return kIsWeb && WebUtils.isWeChatBrowser();
  }

  /// 获取分享管理器状态
  static Map<String, dynamic> getStatus() {
    return {
      'initialized': _initialized,
      'platform': kIsWeb ? 'web' : 'native',
      'wechatAvailable': kIsWeb ? WebUtils.isWeChatBrowser() : false,
      'shareAvailable': isShareAvailable(),
    };
  }

  /// 重置分享内容为默认
  static Future<void> resetToDefault() async {
    await updateShareContent();
  }

  /// 测试分享功能
  static Future<void> testShare() async {
    if (!isShareAvailable()) {
      Logger.info('Share not available');
      return;
    }
    
    try {
      await shareInvitation();
      Logger.info('Test share completed');
    } catch (e) {
      Logger.error('testShare error: $e');
    }
  }
}
