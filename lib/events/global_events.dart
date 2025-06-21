import '../core/state_manager.dart';
import '../core/localization.dart';
import '../core/notifications.dart';

/// 全局事件定义
class GlobalEvents {
  static final StateManager _sm = StateManager();

  /// 获取所有全局事件
  static List<Map<String, dynamic>> get events => [
        mysteriousStranger,
        nomadicTribe,
        sickMan,
        scavenger,
        beggar,
        thief,
      ];

  /// 神秘陌生人事件
  static Map<String, dynamic> get mysteriousStranger {
    final localization = Localization();
    return {
      'title': localization.translate('events.mysterious_wanderer_event.title'),
      'isAvailable': () {
        final fire = _sm.get('game.fire.value', true) ?? 0;
        final wood = _sm.get('stores.wood', true) ?? 0;
        return fire > 0 && wood > 0; // 需要有火和木材
      },
      'scenes': {
        'start': {
          'text': [
            localization.translate('events.mysterious_wanderer_event.start_text1'),
            localization.translate('events.mysterious_wanderer_event.start_text2'),
            localization.translate('events.mysterious_wanderer_event.start_text3')
          ],
          'buttons': {
            'talk': {'text': localization.translate('ui.buttons.talk'), 'nextScene': 'talk'},
            'ignore': {'text': localization.translate('ui.buttons.ignore'), 'nextScene': 'ignore'}
          }
        },
        'talk': {
          'text': [
            localization.translate('events.mysterious_wanderer_event.talk_text1'),
            localization.translate('events.mysterious_wanderer_event.talk_text2')
          ],
          'reward': {'wood': 100, 'fur': 10, 'meat': 5},
          'buttons': {
            'thank': {'text': localization.translate('ui.buttons.thank'), 'nextScene': 'end'}
          }
        },
        'ignore': {
          'text': [
            localization.translate('events.mysterious_wanderer_event.ignore_text1'),
            localization.translate('events.mysterious_wanderer_event.ignore_text2'),
            localization.translate('events.mysterious_wanderer_event.ignore_text3')
          ],
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        }
      }
    };
  }

  /// 游牧部落事件
  static Map<String, dynamic> get nomadicTribe {
    final localization = Localization();
    return {
      'title': localization.translate('events.global_events.nomadic_tribe.title'),
      'isAvailable': () {
        final huts = _sm.get('game.buildings.hut', true) ?? 0;
        return huts >= 3; // 需要至少3个小屋
      },
      'scenes': {
        'start': {
          'text': [
            localization.translate('events.global_events.nomadic_tribe.text1'),
            localization.translate('events.global_events.nomadic_tribe.text2')
          ],
          'buttons': {
            'trade': {
              'text': localization.translate('ui.buttons.trade'),
              'cost': {'fur': 50},
              'nextScene': 'trade'
            },
            'decline': {'text': localization.translate('ui.buttons.decline'), 'nextScene': 'decline'}
          }
        },
        'trade': {
          'text': [
            localization.translate('events.global_events.nomadic_tribe.trade_text1'),
            localization.translate('events.global_events.nomadic_tribe.trade_text2')
          ],
          'reward': {'scales': 5, 'teeth': 10, 'cloth': 3},
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        },
        'decline': {
          'text': [
            localization.translate('events.global_events.nomadic_tribe.decline_text1'),
            localization.translate('events.global_events.nomadic_tribe.decline_text2')
          ],
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        }
      }
    };
  }

  /// 病人事件
  static Map<String, dynamic> get sickMan {
    final localization = Localization();
    return {
      'title': localization.translate('events.sick_man_event.title'),
      'isAvailable': () {
        final medicine = _sm.get('stores.medicine', true) ?? 0;
        return medicine > 0; // 需要有药品
      },
      'scenes': {
        'start': {
          'text': [
            localization.translate('events.sick_man_event.start_text1'),
            localization.translate('events.sick_man_event.start_text2'),
            localization.translate('events.sick_man_event.start_text3')
          ],
          'buttons': {
            'help': {
              'text': localization.translate('ui.buttons.help_him'),
              'cost': {'medicine': 1},
              'nextScene': 'help'
            },
            'turnAway': {'text': localization.translate('ui.buttons.turn_away'), 'nextScene': 'turnAway'}
          }
        },
        'help': {
          'text': [
            localization.translate('events.sick_man_event.help_text1'),
            localization.translate('events.sick_man_event.help_text2'),
            localization.translate('events.sick_man_event.help_text3')
          ],
          'reward': {'scales': 3, 'teeth': 5},
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        },
        'turnAway': {
          'text': [
            localization.translate('events.sick_man_event.turn_away_text1'),
            localization.translate('events.sick_man_event.turn_away_text2'),
            localization.translate('events.sick_man_event.turn_away_text3')
          ],
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        }
      }
    };
  }

  /// 拾荒者事件
  static Map<String, dynamic> get scavenger {
    final localization = Localization();
    return {
      'title': localization.translate('events.global_events.scavenger.title'),
      'isAvailable': () {
        final wood = _sm.get('stores.wood', true) ?? 0;
        return wood >= 500; // 需要大量木材
      },
      'scenes': {
        'start': {
          'text': [
            localization.translate('events.global_events.scavenger.text1'),
            localization.translate('events.global_events.scavenger.text2')
          ],
          'buttons': {
            'trade': {
              'text': localization.translate('ui.buttons.trade'),
              'cost': {'wood': 500},
              'nextScene': 'trade'
            },
            'refuse': {'text': localization.translate('ui.buttons.refuse'), 'nextScene': 'refuse'}
          }
        },
        'trade': {
          'text': [
            localization.translate('events.global_events.scavenger.trade_text1'),
            localization.translate('events.global_events.scavenger.trade_text2')
          ],
          'reward': {'iron': 20, 'coal': 10, 'steel': 5},
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        },
        'refuse': {
          'text': [
            localization.translate('events.global_events.scavenger.refuse_text1'),
            localization.translate('events.global_events.scavenger.refuse_text2')
          ],
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        }
      }
    };
  }

  /// 乞丐事件
  static Map<String, dynamic> get beggar {
    final localization = Localization();
    return {
      'title': localization.translate('events.global_events.beggar_global.title'),
      'isAvailable': () {
        final meat = _sm.get('stores.meat', true) ?? 0;
        return meat >= 100; // 需要足够的肉
      },
      'scenes': {
        'start': {
          'text': [
            localization.translate('events.global_events.beggar_global.text1'),
            localization.translate('events.global_events.beggar_global.text2')
          ],
          'buttons': {
            'give': {
              'text': localization.translate('ui.buttons.give'),
              'cost': {'meat': 100},
              'nextScene': 'give'
            },
            'refuse': {'text': localization.translate('ui.buttons.refuse'), 'nextScene': 'refuse'}
          }
        },
        'give': {
          'text': [
            localization.translate('events.global_events.beggar_global.give_text1'),
            localization.translate('events.global_events.beggar_global.give_text2')
          ],
          'reward': {'charm': 1},
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        },
        'refuse': {
          'text': [
            localization.translate('events.global_events.beggar_global.refuse_text1'),
            localization.translate('events.global_events.beggar_global.refuse_text2')
          ],
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        }
      }
    };
  }

  /// 小偷事件
  static Map<String, dynamic> get thief {
    final localization = Localization();
    return {
      'title': localization.translate('events.global_events.thief.title'),
      'isAvailable': () {
        final stores = _sm.get('stores', true) ?? {};
        int totalValue = 0;
        for (final value in stores.values) {
          if (value is num) totalValue += value.toInt();
        }
        return totalValue > 1000; // 需要大量资源才会吸引小偷
      },
      'scenes': {
        'start': {
          'text': [
            localization.translate('events.global_events.thief.text1'),
            localization.translate('events.global_events.thief.text2')
          ],
          'buttons': {
            'chase': {'text': localization.translate('ui.buttons.chase'), 'nextScene': 'chase'},
            'ignore': {'text': localization.translate('ui.buttons.ignore'), 'nextScene': 'ignore'}
          }
        },
        'chase': {
          'text': [
            localization.translate('events.global_events.thief.chase_text1'),
            localization.translate('events.global_events.thief.chase_text2'),
            localization.translate('events.global_events.thief.chase_text3')
          ],
          'reward': {'fur': 20, 'leather': 10},
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        },
        'ignore': {
          'text': [
            localization.translate('events.global_events.thief.ignore_text1'),
            localization.translate('events.global_events.thief.ignore_text2')
          ],
          'cost': {'wood': 50, 'fur': 10, 'meat': 20},
          'buttons': {
            'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
          }
        }
      }
    };
  }
}
