import 'package:flutter/material.dart';

/// 本地化模块 - 处理游戏的多语言支持
/// 包括所有可翻译字符串的定义和管理
class Localization extends ChangeNotifier {
  static final Localization _instance = Localization._internal();

  factory Localization() {
    return _instance;
  }

  static Localization get instance => _instance;

  Localization._internal();

  // 模块名称
  final String name = "本地化";

  // 当前语言
  String _currentLanguage = 'zh_CN';

  /// 获取当前语言
  String get currentLanguage => _currentLanguage;

  /// 设置当前语言
  void setLanguage(String language) {
    _currentLanguage = language;
    notifyListeners();
  }

  /// 翻译字符串映射表
  static const Map<String, Map<String, String>> _translations = {
    // 中文翻译
    'zh_CN': {
      // 基础资源
      'saved.': '已保存。',
      'wood': '木材',
      'teeth': '牙齿',
      'meat': '肉',
      'fur': '毛皮',
      'alien alloy': '外星合金',
      'bullets': '子弹',
      'charm': '护身符',
      'leather': '皮革',
      'iron': '铁',
      'steel': '钢',
      'coal': '煤',
      'sulphur': '硫磺',
      'energy cell': '能量电池',
      'torch': '火把',
      'medicine': '药物',
      'grenade': '手榴弹',
      'bolas': '流星锤',
      'bayonet': '刺刀',
      'bait': '诱饵',
      'cured meat': '熏肉',
      'scales': '鳞片',
      'compass': '指南针',
      'laser rifle': '激光步枪',
      'cloth': '布料',
      'baited trap': '设饵陷阱',

      // 职业
      'builder': '建造者',
      'hunter': '猎人',
      'trapper': '陷阱师',
      'tanner': '制革师',
      'charcutier': '肉类加工师',
      'iron miner': '铁矿工',
      'coal miner': '煤矿工',
      'sulphur miner': '硫磺矿工',
      'armourer': '军械师',
      'steelworker': '钢铁工',
      'gatherer': '采集者',

      // 建筑
      'iron mine': '铁矿',
      'coal mine': '煤矿',
      'sulphur mine': '硫磺矿',

      // 错误信息
      'not enough fur': '毛皮不足',
      'not enough wood': '木材不足',
      'not enough coal': '煤不足',
      'not enough iron': '铁不足',
      'not enough steel': '钢不足',
      'not enough sulphur': '硫磺不足',
      'not enough scales': '鳞片不足',
      'not enough cloth': '布料不足',
      'not enough teeth': '牙齿不足',
      'not enough leather': '皮革不足',
      'not enough meat': '肉不足',

      // 指南针方向
      'the compass points east': '指南针指向东方',
      'the compass points west': '指南针指向西方',
      'the compass points north': '指南针指向北方',
      'the compass points south': '指南针指向南方',
      'the compass points northeast': '指南针指向东北方',
      'the compass points northwest': '指南针指向西北方',
      'the compass points southeast': '指南针指向东南方',
      'the compass points southwest': '指南针指向西南方',

      // 敌人
      'thieves': '盗贼',

      // 游戏界面
      'A Dark Room': '黑暗房间',
      'light fire': '点火',
      'stoke fire': '添柴',
      'gather wood': '收集木材',
      'check traps': '检查陷阱',
      'build': '建造',
      'craft': '制作',
      'trade': '交易',
      'embark': '出发',
      'lift off': '起飞',
      'restart': '重新开始',

      // 房间描述
      'the fire is dead.': '火已熄灭。',
      'the fire is smoldering.': '火在闷烧。',
      'the fire is flickering.': '火在闪烁。',
      'the fire is burning.': '火在燃烧。',
      'the fire is roaring.': '火在熊熊燃烧。',

      // 建筑描述
      'trap': '陷阱',
      'cart': '货车',
      'hut': '小屋',
      'lodge': '小屋',
      'trading post': '贸易站',
      'tannery': '制革屋',
      'smokehouse': '熏肉房',
      'workshop': '工坊',
      'steelworks': '炼钢坊',
      'armoury': '军械库',

      // 状态描述
      'healthy': '健康',
      'tired': '疲惫',
      'hungry': '饥饿',
      'thirsty': '口渴',
      'cold': '寒冷',
      'warm': '温暖',

      // 动作描述
      'eat': '吃',
      'drink': '喝',
      'rest': '休息',
      'explore': '探索',
      'fight': '战斗',
      'flee': '逃跑',
      'take': '拿取',
      'leave': '离开',
      'wait': '等待',

      // 数量描述
      'none': '无',
      'few': '少量',
      'some': '一些',
      'many': '很多',
      'lots': '大量',
    },

    // 英文翻译（原文）
    'en_US': {
      'saved.': 'saved.',
      'wood': 'wood',
      'teeth': 'teeth',
      'meat': 'meat',
      'fur': 'fur',
      'alien alloy': 'alien alloy',
      'bullets': 'bullets',
      'charm': 'charm',
      'leather': 'leather',
      'iron': 'iron',
      'steel': 'steel',
      'coal': 'coal',
      'sulphur': 'sulphur',
      'energy cell': 'energy cell',
      'torch': 'torch',
      'medicine': 'medicine',
      'grenade': 'grenade',
      'bolas': 'bolas',
      'bayonet': 'bayonet',
      'bait': 'bait',
      'cured meat': 'cured meat',
      'scales': 'scales',
      'compass': 'compass',
      'laser rifle': 'laser rifle',
      'cloth': 'cloth',
      'baited trap': 'baited trap',
      'builder': 'builder',
      'hunter': 'hunter',
      'trapper': 'trapper',
      'tanner': 'tanner',
      'charcutier': 'charcutier',
      'iron miner': 'iron miner',
      'coal miner': 'coal miner',
      'sulphur miner': 'sulphur miner',
      'armourer': 'armourer',
      'steelworker': 'steelworker',
      'gatherer': 'gatherer',
      'iron mine': 'iron mine',
      'coal mine': 'coal mine',
      'sulphur mine': 'sulphur mine',
      'not enough fur': 'not enough fur',
      'not enough wood': 'not enough wood',
      'not enough coal': 'not enough coal',
      'not enough iron': 'not enough iron',
      'not enough steel': 'not enough steel',
      'not enough sulphur': 'not enough sulphur',
      'not enough scales': 'not enough scales',
      'not enough cloth': 'not enough cloth',
      'not enough teeth': 'not enough teeth',
      'not enough leather': 'not enough leather',
      'not enough meat': 'not enough meat',
      'the compass points east': 'the compass points east',
      'the compass points west': 'the compass points west',
      'the compass points north': 'the compass points north',
      'the compass points south': 'the compass points south',
      'the compass points northeast': 'the compass points northeast',
      'the compass points northwest': 'the compass points northwest',
      'the compass points southeast': 'the compass points southeast',
      'the compass points southwest': 'the compass points southwest',
      'thieves': 'thieves',
    },
  };

  /// 翻译函数
  String translate(String key, [List<dynamic>? args]) {
    final languageMap = _translations[_currentLanguage];
    if (languageMap == null) {
      return key; // 如果语言不存在，返回原始key
    }

    String translated = languageMap[key] ?? key;

    // 处理参数替换
    if (args != null && args.isNotEmpty) {
      for (int i = 0; i < args.length; i++) {
        translated = translated.replaceAll('{$i}', args[i].toString());
      }
    }

    return translated;
  }

  /// 获取支持的语言列表
  List<String> getSupportedLanguages() {
    return _translations.keys.toList();
  }

  /// 获取语言显示名称
  String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'zh_CN':
        return '中文';
      case 'en_US':
        return 'English';
      default:
        return languageCode;
    }
  }

  /// 检查是否支持某种语言
  bool isLanguageSupported(String languageCode) {
    return _translations.containsKey(languageCode);
  }

  /// 获取所有翻译键
  List<String> getAllTranslationKeys() {
    final keys = <String>{};
    for (final languageMap in _translations.values) {
      keys.addAll(languageMap.keys);
    }
    return keys.toList()..sort();
  }

  /// 获取缺失的翻译
  Map<String, List<String>> getMissingTranslations() {
    final allKeys = getAllTranslationKeys();
    final missing = <String, List<String>>{};

    for (final language in _translations.keys) {
      final languageMap = _translations[language]!;
      final missingKeys =
          allKeys.where((key) => !languageMap.containsKey(key)).toList();
      if (missingKeys.isNotEmpty) {
        missing[language] = missingKeys;
      }
    }

    return missing;
  }

  /// 重置为默认语言
  void resetToDefault() {
    setLanguage('zh_CN');
  }
}
