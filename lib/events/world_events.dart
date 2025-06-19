import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/logger.dart';
import '../modules/world.dart';

/// 世界地图事件定义
class WorldEvents {
  static final StateManager _sm = StateManager();
  static final World _world = World();

  /// 获取所有世界事件
  static List<Map<String, dynamic>> get events => [
    ...tier1Events,
    ...tier2Events,
    ...tier3Events,
  ];

  /// 第一层事件 (距离 0-10)
  static List<Map<String, dynamic>> get tier1Events => [
    squirrel,
    rabbit,
    fox,
    wolf,
    bandit,
  ];

  /// 第二层事件 (距离 10-20)
  static List<Map<String, dynamic>> get tier2Events => [
    bear,
    wildcat,
    banditGroup,
    scavenger,
    madman,
  ];

  /// 第三层事件 (距离 20+)
  static List<Map<String, dynamic>> get tier3Events => [
    beast,
    soldiers,
    alien,
    mutant,
    warband,
  ];

  /// 松鼠事件
  static Map<String, dynamic> get squirrel => {
    'title': '松鼠',
    'isAvailable': () => _world.getDistance() <= 10,
    'scenes': {
      'start': {
        'combat': true,
        'enemy': '松鼠',
        'health': 3,
        'damage': 1,
        'hit': 0.5,
        'attackDelay': 1.5,
        'loot': {
          'meat': [1, 2],
          'fur': [0, 1]
        }
      }
    }
  };

  /// 兔子事件
  static Map<String, dynamic> get rabbit => {
    'title': '兔子',
    'isAvailable': () => _world.getDistance() <= 10,
    'scenes': {
      'start': {
        'combat': true,
        'enemy': '兔子',
        'health': 5,
        'damage': 1,
        'hit': 0.4,
        'attackDelay': 2.0,
        'loot': {
          'meat': [2, 4],
          'fur': [1, 2]
        }
      }
    }
  };

  /// 狐狸事件
  static Map<String, dynamic> get fox => {
    'title': '狐狸',
    'isAvailable': () => _world.getDistance() <= 10,
    'scenes': {
      'start': {
        'combat': true,
        'enemy': '狐狸',
        'health': 8,
        'damage': 2,
        'hit': 0.6,
        'attackDelay': 2.0,
        'loot': {
          'meat': [3, 5],
          'fur': [2, 3],
          'teeth': [0, 1]
        }
      }
    }
  };

  /// 狼事件
  static Map<String, dynamic> get wolf => {
    'title': '狼',
    'isAvailable': () => _world.getDistance() <= 10,
    'scenes': {
      'start': {
        'combat': true,
        'enemy': '狼',
        'health': 12,
        'damage': 3,
        'hit': 0.7,
        'attackDelay': 2.5,
        'loot': {
          'meat': [5, 8],
          'fur': [3, 5],
          'teeth': [1, 2]
        }
      }
    }
  };

  /// 土匪事件
  static Map<String, dynamic> get bandit => {
    'title': '土匪',
    'isAvailable': () => _world.getDistance() <= 10,
    'scenes': {
      'start': {
        'combat': true,
        'enemy': '土匪',
        'health': 15,
        'damage': 4,
        'hit': 0.6,
        'attackDelay': 3.0,
        'loot': {
          'leather': [2, 4],
          'cloth': [1, 3],
          'bullets': [0, 5],
          'scales': [0, 1]
        }
      }
    }
  };

  /// 熊事件
  static Map<String, dynamic> get bear => {
    'title': '熊',
    'isAvailable': () => _world.getDistance() > 10 && _world.getDistance() <= 20,
    'scenes': {
      'start': {
        'combat': true,
        'enemy': '熊',
        'health': 25,
        'damage': 6,
        'hit': 0.7,
        'attackDelay': 3.5,
        'loot': {
          'meat': [15, 25],
          'fur': [8, 12],
          'teeth': [2, 4],
          'scales': [1, 2]
        }
      }
    }
  };

  /// 野猫事件
  static Map<String, dynamic> get wildcat => {
    'title': '野猫',
    'isAvailable': () => _world.getDistance() > 10 && _world.getDistance() <= 20,
    'scenes': {
      'start': {
        'combat': true,
        'enemy': '野猫',
        'health': 18,
        'damage': 5,
        'hit': 0.8,
        'attackDelay': 2.0,
        'loot': {
          'meat': [8, 12],
          'fur': [5, 8],
          'teeth': [2, 3],
          'scales': [0, 1]
        }
      }
    }
  };

  /// 土匪团伙事件
  static Map<String, dynamic> get banditGroup => {
    'title': '土匪团伙',
    'isAvailable': () => _world.getDistance() > 10 && _world.getDistance() <= 20,
    'scenes': {
      'start': {
        'combat': true,
        'enemy': '土匪团伙',
        'health': 30,
        'damage': 5,
        'hit': 0.7,
        'attackDelay': 2.5,
        'loot': {
          'leather': [5, 10],
          'cloth': [3, 6],
          'bullets': [5, 15],
          'scales': [1, 3],
          'iron': [0, 5]
        }
      }
    }
  };

  /// 拾荒者事件
  static Map<String, dynamic> get scavenger => {
    'title': '拾荒者',
    'isAvailable': () => _world.getDistance() > 10 && _world.getDistance() <= 20,
    'scenes': {
      'start': {
        'combat': true,
        'enemy': '拾荒者',
        'health': 20,
        'damage': 4,
        'hit': 0.6,
        'attackDelay': 3.0,
        'loot': {
          'iron': [3, 8],
          'steel': [0, 3],
          'cloth': [2, 5],
          'medicine': [0, 1]
        }
      }
    }
  };

  /// 疯子事件
  static Map<String, dynamic> get madman => {
    'title': '疯子',
    'isAvailable': () => _world.getDistance() > 10 && _world.getDistance() <= 20,
    'scenes': {
      'start': {
        'combat': true,
        'enemy': '疯子',
        'health': 22,
        'damage': 7,
        'hit': 0.5,
        'attackDelay': 1.5,
        'loot': {
          'medicine': [1, 2],
          'cloth': [2, 4],
          'scales': [1, 2]
        }
      }
    }
  };

  /// 野兽事件
  static Map<String, dynamic> get beast => {
    'title': '野兽',
    'isAvailable': () => _world.getDistance() > 20,
    'scenes': {
      'start': {
        'combat': true,
        'enemy': '野兽',
        'health': 40,
        'damage': 8,
        'hit': 0.8,
        'attackDelay': 3.0,
        'loot': {
          'meat': [20, 35],
          'fur': [10, 18],
          'teeth': [3, 6],
          'scales': [2, 4]
        }
      }
    }
  };

  /// 士兵事件
  static Map<String, dynamic> get soldiers => {
    'title': '士兵',
    'isAvailable': () => _world.getDistance() > 20,
    'scenes': {
      'start': {
        'combat': true,
        'enemy': '士兵',
        'health': 35,
        'damage': 6,
        'hit': 0.8,
        'attackDelay': 2.0,
        'ranged': true,
        'loot': {
          'bullets': [10, 25],
          'medicine': [1, 3],
          'steel': [3, 8],
          'rifle': [0, 1]
        }
      }
    }
  };

  /// 外星人事件
  static Map<String, dynamic> get alien => {
    'title': '外星人',
    'isAvailable': () => _world.getDistance() > 20,
    'scenes': {
      'start': {
        'combat': true,
        'enemy': '外星人',
        'health': 45,
        'damage': 10,
        'hit': 0.7,
        'attackDelay': 2.5,
        'ranged': true,
        'loot': {
          'alien alloy': [1, 3],
          'energy cell': [1, 2],
          'scales': [2, 5]
        }
      }
    }
  };

  /// 变异体事件
  static Map<String, dynamic> get mutant => {
    'title': '变异体',
    'isAvailable': () => _world.getDistance() > 20,
    'scenes': {
      'start': {
        'combat': true,
        'enemy': '变异体',
        'health': 50,
        'damage': 9,
        'hit': 0.6,
        'attackDelay': 2.8,
        'loot': {
          'meat': [15, 30],
          'scales': [3, 6],
          'teeth': [2, 5],
          'medicine': [0, 2]
        }
      }
    }
  };

  /// 战团事件
  static Map<String, dynamic> get warband => {
    'title': '战团',
    'isAvailable': () => _world.getDistance() > 20,
    'scenes': {
      'start': {
        'combat': true,
        'enemy': '战团',
        'health': 60,
        'damage': 7,
        'hit': 0.8,
        'attackDelay': 2.0,
        'loot': {
          'bullets': [15, 30],
          'steel': [5, 12],
          'medicine': [2, 4],
          'scales': [2, 5],
          'laser rifle': [0, 1]
        }
      }
    }
  };
}
