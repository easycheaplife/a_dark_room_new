import '../core/state_manager.dart';
import '../core/logger.dart';
import '../core/localization.dart';
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
        ...landmarkEvents,
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

  /// 地标事件 (特殊地点)
  static List<Map<String, dynamic>> get landmarkEvents => [
        swamp,
      ];

  /// 松鼠事件
  static Map<String, dynamic> get squirrel => {
        'title': () {
          final localization = Localization();
          return localization.translate('world_events.squirrel.title');
        }(),
        'isAvailable': () => _world.getDistance() <= 10,
        'scenes': {
          'start': {
            'combat': true,
            'enemy': () {
              final localization = Localization();
              return localization.translate('world_events.squirrel.enemy');
            }(),
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
        'title': () {
          final localization = Localization();
          return localization.translate('world_events.rabbit.title');
        }(),
        'isAvailable': () => _world.getDistance() <= 10,
        'scenes': {
          'start': {
            'combat': true,
            'enemy': () {
              final localization = Localization();
              return localization.translate('world_events.rabbit.enemy');
            }(),
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
        'title': () {
          final localization = Localization();
          return localization.translate('world_events.fox.title');
        }(),
        'isAvailable': () => _world.getDistance() <= 10,
        'scenes': {
          'start': {
            'combat': true,
            'enemy': () {
              final localization = Localization();
              return localization.translate('world_events.fox.enemy');
            }(),
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
        'title': () {
          final localization = Localization();
          return localization.translate('world_events.wolf.title');
        }(),
        'isAvailable': () => _world.getDistance() <= 10,
        'scenes': {
          'start': {
            'combat': true,
            'enemy': () {
              final localization = Localization();
              return localization.translate('world_events.wolf.enemy');
            }(),
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
        'title': () {
          final localization = Localization();
          return localization.translate('world_events.bandit.title');
        }(),
        'isAvailable': () => _world.getDistance() <= 10,
        'scenes': {
          'start': {
            'combat': true,
            'enemy': () {
              final localization = Localization();
              return localization.translate('world_events.bandit.enemy');
            }(),
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
        'title': () {
          final localization = Localization();
          return localization.translate('world_events.bear.title');
        }(),
        'isAvailable': () =>
            _world.getDistance() > 10 && _world.getDistance() <= 20,
        'scenes': {
          'start': {
            'combat': true,
            'enemy': () {
              final localization = Localization();
              return localization.translate('world_events.bear.enemy');
            }(),
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
        'title': () {
          final localization = Localization();
          return localization.translate('world_events.wildcat.title');
        }(),
        'isAvailable': () =>
            _world.getDistance() > 10 && _world.getDistance() <= 20,
        'scenes': {
          'start': {
            'combat': true,
            'enemy': () {
              final localization = Localization();
              return localization.translate('world_events.wildcat.enemy');
            }(),
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
        'title': () {
          final localization = Localization();
          return localization.translate('world_events.bandit_group.title');
        }(),
        'isAvailable': () =>
            _world.getDistance() > 10 && _world.getDistance() <= 20,
        'scenes': {
          'start': {
            'combat': true,
            'enemy': () {
              final localization = Localization();
              return localization.translate('world_events.bandit_group.enemy');
            }(),
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
        'title': () {
          final localization = Localization();
          return localization.translate('world_events.scavenger.title');
        }(),
        'isAvailable': () =>
            _world.getDistance() > 10 && _world.getDistance() <= 20,
        'scenes': {
          'start': {
            'combat': true,
            'enemy': () {
              final localization = Localization();
              return localization.translate('world_events.scavenger.enemy');
            }(),
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
        'title': () {
          final localization = Localization();
          return localization.translate('world_events.madman.title');
        }(),
        'isAvailable': () =>
            _world.getDistance() > 10 && _world.getDistance() <= 20,
        'scenes': {
          'start': {
            'combat': true,
            'enemy': () {
              final localization = Localization();
              return localization.translate('world_events.madman.enemy');
            }(),
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
        'title': () {
          final localization = Localization();
          return localization.translate('world_events.beast.title');
        }(),
        'isAvailable': () => _world.getDistance() > 20,
        'scenes': {
          'start': {
            'combat': true,
            'enemy': () {
              final localization = Localization();
              return localization.translate('world_events.beast.enemy');
            }(),
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
        'title': () {
          final localization = Localization();
          return localization.translate('world_events.soldiers.title');
        }(),
        'isAvailable': () => _world.getDistance() > 20,
        'scenes': {
          'start': {
            'combat': true,
            'enemy': () {
              final localization = Localization();
              return localization.translate('world_events.soldiers.enemy');
            }(),
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
        'title': () {
          final localization = Localization();
          return localization.translate('world_events.alien.title');
        }(),
        'isAvailable': () => _world.getDistance() > 20,
        'scenes': {
          'start': {
            'combat': true,
            'enemy': () {
              final localization = Localization();
              return localization.translate('world_events.alien.enemy');
            }(),
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
        'title': () {
          final localization = Localization();
          return localization.translate('world_events.mutant.title');
        }(),
        'isAvailable': () => _world.getDistance() > 20,
        'scenes': {
          'start': {
            'combat': true,
            'enemy': () {
              final localization = Localization();
              return localization.translate('world_events.mutant.enemy');
            }(),
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
        'title': () {
          final localization = Localization();
          return localization.translate('world_events.warband.title');
        }(),
        'isAvailable': () => _world.getDistance() > 20,
        'scenes': {
          'start': {
            'combat': true,
            'enemy': () {
              final localization = Localization();
              return localization.translate('world_events.warband.enemy');
            }(),
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

  /// 沼泽地标事件
  static Map<String, dynamic> get swamp => {
        'title': () {
          final localization = Localization();
          return localization.translate('world_events.swamp.title');
        }(),
        'isAvailable': () => true, // 地标事件总是可用
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('world_events.swamp.text1'),
                localization.translate('world_events.swamp.text2'),
                localization.translate('world_events.swamp.text3')
              ];
            }(),
            'buttons': {
              'investigate': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.investigate');
                }(),
                'nextScene': 'investigate'
              },
              'leave': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.leave');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'investigate': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('world_events.swamp.investigate_text1'),
                localization.translate('world_events.swamp.investigate_text2')
              ];
            }(),
            'onLoad': () {
              // 获得美食家技能
              if (!_sm.hasPerk('gastronome')) {
                _sm.addPerk('gastronome');
                Logger.info('🍽️ Learned gastronome skill');
              }
            },
            'buttons': {
              'continue': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.continue');
                }(),
                'nextScene': 'end'
              }
            }
          }
        }
      };
}
