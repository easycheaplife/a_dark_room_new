import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/logger.dart';
import '../core/localization.dart';
import 'room_events_extended.dart';

/// 房间事件定义
class RoomEvents {
  static final StateManager _sm = StateManager();

  /// 获取所有房间事件
  static List<Map<String, dynamic>> get events => [
        firekeeper,
        builder,
        nomad,
        noisesOutside,
        RoomEventsExtended.noisesInside,
        RoomEventsExtended.beggar,
        RoomEventsExtended.shadyBuilder,
        RoomEventsExtended.mysteriousWandererWood,
        RoomEventsExtended.mysteriousWandererFur,
        RoomEventsExtended.scout,
        RoomEventsExtended.master,
        RoomEventsExtended.martialMaster,
        RoomEventsExtended.desertGuide,
        RoomEventsExtended.sickMan,
        straycat,
        wounded,
        stranger,
      ];

  /// 守火人事件
  static Map<String, dynamic> get firekeeper {
    final localization = Localization();
    return {
      'title': localization.translate('events.room_events.firekeeper.title'),
      'isAvailable': () {
        final fire = _sm.get('game.fire.value', true) ?? 0;
        final builderLevel = _sm.get('game.builder.level', true) ?? -1;
        return fire > 0 && builderLevel < 0; // 有火但还没有建造者
      },
      'scenes': {
        'start': {
          'text': [
            localization.translate('events.room_events.firekeeper.text1'),
            localization.translate('events.room_events.firekeeper.text2'),
            localization.translate('events.room_events.firekeeper.text3')
          ],
          'notification': localization.translate('events.room_events.firekeeper.notification'),
          'onLoad': () {
            // 解锁建造者
            _sm.set('game.builder.level', 0);
            Logger.info('🔨 Builder unlocked');
          },
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        }
      }
    };
  }

  /// 建造者升级事件
  static Map<String, dynamic> get builder {
    final localization = Localization();
    return {
      'title': localization.translate('events.room_events.builder.title'),
      'isAvailable': () {
        final builderLevel = _sm.get('game.builder.level', true) ?? -1;
        final temperature = _sm.get('game.temperature.value', true) ?? 0;
        return builderLevel >= 0 &&
            builderLevel < 4 &&
            temperature >= 2; // 建造者存在且温度适宜
      },
      'scenes': {
        'start': {
          'text': [
            localization.translate('events.room_events.builder.text1'),
            localization.translate('events.room_events.builder.text2')
          ],
          'notification': localization.translate('events.room_events.builder.notification'),
          'onLoad': () {
            final currentLevel = _sm.get('game.builder.level', true) ?? 0;
            if (currentLevel < 4) {
              _sm.set('game.builder.level', currentLevel + 1);
              Logger.info('🔨 Builder level increased to: ${currentLevel + 1}');
            }
          },
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        }
      }
    };
  }

  /// 流浪猫事件
  static Map<String, dynamic> get straycat {
    final localization = Localization();
    return {
      'title': localization.translate('events.room_events.straycat.title'),
      'isAvailable': () {
        final fire = _sm.get('game.fire.value', true) ?? 0;
        final meat = _sm.get('stores.meat', true) ?? 0;
        return fire > 0 && meat >= 10; // 需要火和一些肉
      },
      'scenes': {
        'start': {
          'text': [
            localization.translate('events.room_events.straycat.text1'),
            localization.translate('events.room_events.straycat.text2'),
            localization.translate('events.room_events.straycat.text3')
          ],
          'buttons': {
            'feed': {
              'text': localization.translate('ui.buttons.feed'),
              'cost': {'meat': 10},
              'nextScene': 'feed'
            },
            'ignore': {'text': localization.translate('ui.buttons.ignore'), 'nextScene': 'ignore'}
          }
        },
        'feed': {
          'text': [
            localization.translate('events.room_events.straycat.feed_text1'),
            localization.translate('events.room_events.straycat.feed_text2'),
            localization.translate('events.room_events.straycat.feed_text3')
          ],
          'reward': {'charm': 1},
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        },
        'ignore': {
          'text': [
            localization.translate('events.room_events.straycat.ignore_text1'),
            localization.translate('events.room_events.straycat.ignore_text2')
          ],
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        }
      }
    };
  }

  /// 受伤的人事件
  static Map<String, dynamic> get wounded {
    final localization = Localization();
    return {
      'title': localization.translate('events.room_events.wounded.title'),
      'isAvailable': () {
        final fire = _sm.get('game.fire.value', true) ?? 0;
        final cloth = _sm.get('stores.cloth', true) ?? 0;
        return fire > 0 && cloth >= 5; // 需要火和布料
      },
      'scenes': {
        'start': {
          'text': [
            localization.translate('events.room_events.wounded.text1'),
            localization.translate('events.room_events.wounded.text2'),
            localization.translate('events.room_events.wounded.text3')
          ],
          'buttons': {
            'help': {
              'text': localization.translate('ui.buttons.help'),
              'cost': {'cloth': 5},
              'nextScene': 'help'
            },
            'refuse': {'text': localization.translate('ui.buttons.refuse'), 'nextScene': 'refuse'}
          }
        },
        'help': {
          'text': [
            localization.translate('events.room_events.wounded.help_text1'),
            localization.translate('events.room_events.wounded.help_text2'),
            localization.translate('events.room_events.wounded.help_text3')
          ],
          'reward': {'scales': 2, 'teeth': 3},
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        },
        'refuse': {
          'text': [
            localization.translate('events.room_events.wounded.refuse_text1'),
            localization.translate('events.room_events.wounded.refuse_text2'),
            localization.translate('events.room_events.wounded.refuse_text3')
          ],
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        }
      }
    };
  }

  /// 陌生人事件
  static Map<String, dynamic> get stranger {
    final localization = Localization();
    return {
      'title': localization.translate('events.room_events.stranger.title'),
      'isAvailable': () {
        final fire = _sm.get('game.fire.value', true) ?? 0;
        final wood = _sm.get('stores.wood', true) ?? 0;
        return fire > 0 && wood >= 200; // 需要火和大量木材
      },
      'scenes': {
        'start': {
          'text': [
            localization.translate('events.room_events.stranger.text1'),
            localization.translate('events.room_events.stranger.text2'),
            localization.translate('events.room_events.stranger.text3')
          ],
          'buttons': {
            'trade': {
              'text': localization.translate('ui.buttons.trade'),
              'cost': {'wood': 200},
              'nextScene': 'trade'
            },
            'decline': {'text': localization.translate('ui.buttons.decline'), 'nextScene': 'decline'}
          }
        },
        'trade': {
          'text': [
            localization.translate('events.room_events.stranger.trade_text1'),
            localization.translate('events.room_events.stranger.trade_text2')
          ],
          'reward': {'iron': 10, 'leather': 5, 'fur': 15},
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        },
        'decline': {
          'text': [
            localization.translate('events.room_events.stranger.decline_text1'),
            localization.translate('events.room_events.stranger.decline_text2')
          ],
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        }
      }
    };
  }

  /// 游牧商人事件
  static Map<String, dynamic> get nomad {
    final localization = Localization();
    return {
      'title': localization.translate('events.room_events.nomad.title'),
      'isAvailable': () {
        final fire = _sm.get('game.fire.value', true) ?? 0;
        final fur = _sm.get('stores.fur', true) ?? 0;
        return fire > 0 && fur > 0; // 需要火和毛皮
      },
      'scenes': {
        'start': {
          'text': [
            localization.translate('events.room_events.nomad.text1'),
            localization.translate('events.room_events.nomad.text2')
          ],
          'notification': localization.translate('events.room_events.nomad.notification'),
          'buttons': {
            'buyScales': {
              'text': localization.translate('ui.buttons.buy_scales'),
              'cost': {'fur': 100},
              'reward': {'scales': 1}
            },
            'buyTeeth': {
              'text': localization.translate('ui.buttons.buy_teeth'),
              'cost': {'fur': 200},
              'reward': {'teeth': 1}
            },
            'buyBait': {
              'text': localization.translate('ui.buttons.buy_bait'),
              'cost': {'fur': 5},
              'reward': {'bait': 1},
              'notification': localization.translate('events.room_events.nomad.bait_notification')
            },
            'buyCompass': {
              'text': localization.translate('ui.buttons.buy_compass'),
              'cost': {'fur': 300, 'scales': 15, 'teeth': 5},
              'reward': {'compass': 1},
              'available': () => (_sm.get('stores.compass', true) ?? 0) < 1,
              'notification': localization.translate('events.room_events.nomad.compass_notification')
            },
            'goodbye': {'text': localization.translate('ui.buttons.goodbye'), 'nextScene': 'end'}
          }
        }
      }
    };
  }

  /// 外面的声音事件
  static Map<String, dynamic> get noisesOutside {
    final localization = Localization();
    return {
      'title': localization.translate('events.room_events.noises_outside.title'),
      'isAvailable': () {
        final fire = _sm.get('game.fire.value', true) ?? 0;
        final wood = _sm.get('stores.wood', true) ?? 0;
        return fire > 0 && wood > 0;
      },
      'scenes': {
        'start': {
          'text': [
            localization.translate('events.room_events.noises_outside.text1'),
            localization.translate('events.room_events.noises_outside.text2')
          ],
          'notification': localization.translate('events.room_events.noises_outside.notification'),
          'buttons': {
            'investigate': {
              'text': localization.translate('ui.buttons.investigate'),
              'nextScene': {'0.3': 'stuff', '1.0': 'nothing'}
            },
            'ignore': {'text': localization.translate('ui.buttons.ignore'), 'nextScene': 'end'}
          }
        },
        'nothing': {
          'text': [
            localization.translate('events.room_events.noises_outside.nothing_text1'),
            localization.translate('events.room_events.noises_outside.nothing_text2')
          ],
          'buttons': {
            'backinside': {'text': localization.translate('ui.buttons.back_inside'), 'nextScene': 'end'}
          }
        },
        'stuff': {
          'reward': {'wood': 100, 'fur': 10},
          'text': [
            localization.translate('events.room_events.noises_outside.stuff_text1'),
            localization.translate('events.room_events.noises_outside.stuff_text2')
          ],
          'buttons': {
            'backinside': {'text': localization.translate('ui.buttons.back_inside'), 'nextScene': 'end'}
          }
        }
      }
    };
  }
}
