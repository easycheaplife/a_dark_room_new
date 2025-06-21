import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/logger.dart';
import '../core/localization.dart';
import 'dart:math';

/// 扩展外部事件定义
class OutsideEventsExtended {
  static final StateManager _sm = StateManager();

  /// 疾病事件
  static Map<String, dynamic> get sickness => {
        'title': () {
          final localization = Localization();
          return localization.translate('outside_events_extended.sickness.title');
        }(),
        'isAvailable': () {
          final population = _sm.get('game.population', true) ?? 0;
          return population > 10;
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events_extended.sickness.text1'),
                localization.translate('outside_events_extended.sickness.text2')
              ];
            }(),
            'notification': () {
              final localization = Localization();
              return localization.translate('outside_events_extended.sickness.notification');
            }(),
            'buttons': {
              'medicine': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('outside_events_extended.sickness.use_medicine');
                }(),
                'cost': {'medicine': 5},
                'nextScene': 'cured'
              },
              'wait': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.wait');
                }(),
                'nextScene': 'wait'
              }
            }
          },
          'cured': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events_extended.sickness.cured_text1'),
                localization.translate('outside_events_extended.sickness.cured_text2')
              ];
            }(),
            'buttons': {
              'continue': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.continue');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'wait': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events_extended.sickness.wait_text1'),
                localization.translate('outside_events_extended.sickness.wait_text2')
              ];
            }(),
            'onLoad': () {
              final population = _sm.get('game.population', true) ?? 0;
              final lostPop = (population * 0.1).floor().clamp(1, 10);
              final newPop = (population - lostPop).clamp(0, population);
              _sm.set('game.population', newPop);
              Logger.info('🦠 Sickness loss: $lostPop villagers');
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

  /// 瘟疫事件
  static Map<String, dynamic> get plague => {
        'title': () {
          final localization = Localization();
          return localization.translate('outside_events_extended.plague.title');
        }(),
        'isAvailable': () {
          final population = _sm.get('game.population', true) ?? 0;
          return population > 50;
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events_extended.plague.text1'),
                localization.translate('outside_events_extended.plague.text2')
              ];
            }(),
            'notification': () {
              final localization = Localization();
              return localization.translate('outside_events_extended.plague.notification');
            }(),
            'buttons': {
              'buyMedicine': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('outside_events_extended.plague.buy_medicine');
                }(),
                'cost': {'scales': 50},
                'reward': {'medicine': 10},
                'nextScene': 'buyMedicine'
              },
              'useMedicine': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('outside_events_extended.plague.use_medicine');
                }(),
                'cost': {'medicine': 15},
                'nextScene': 'useMedicine'
              },
              'wait': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.wait');
                }(),
                'nextScene': 'wait'
              }
            }
          },
          'buyMedicine': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events_extended.plague.buy_text1'),
                localization.translate('outside_events_extended.plague.buy_text2')
              ];
            }(),
            'buttons': {
              'useMedicine': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('outside_events_extended.plague.use_medicine');
                }(),
                'cost': {'medicine': 15},
                'nextScene': 'useMedicine'
              },
              'wait': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.wait');
                }(),
                'nextScene': 'wait'
              }
            }
          },
          'useMedicine': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events_extended.plague.use_text1'),
                localization.translate('outside_events_extended.plague.use_text2')
              ];
            }(),
            'onLoad': () {
              final population = _sm.get('game.population', true) ?? 0;
              final lostPop = (population * 0.05).floor().clamp(1, 5);
              final newPop = (population - lostPop).clamp(0, population);
              _sm.set('game.population', newPop);
              Logger.info('💊 Plague loss (treated): $lostPop villagers');
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
          },
          'wait': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events_extended.plague.wait_text1'),
                localization.translate('outside_events_extended.plague.wait_text2')
              ];
            }(),
            'onLoad': () {
              final population = _sm.get('game.population', true) ?? 0;
              final lostPop = (population * 0.3).floor().clamp(5, 20);
              final newPop = (population - lostPop).clamp(0, population);
              _sm.set('game.population', newPop);
              Logger.info('☠️ Plague loss (untreated): $lostPop villagers');
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

  /// 野兽袭击事件
  static Map<String, dynamic> get beastAttack => {
        'title': () {
          final localization = Localization();
          return localization.translate('outside_events_extended.beast_attack.title');
        }(),
        'isAvailable': () {
          final population = _sm.get('game.population', true) ?? 0;
          return population > 0;
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events_extended.beast_attack.text1'),
                localization.translate('outside_events_extended.beast_attack.text2')
              ];
            }(),
            'notification': () {
              final localization = Localization();
              return localization.translate('outside_events_extended.beast_attack.notification');
            }(),
            'buttons': {
              'fight': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.fight');
                }(),
                'nextScene': {'0.6': 'win', '1.0': 'lose'}
              },
              'hide': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.hide');
                }(),
                'nextScene': 'hide'
              }
            }
          },
          'win': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events_extended.beast_attack.win_text1'),
                localization.translate('outside_events_extended.beast_attack.win_text2')
              ];
            }(),
            'reward': {'fur': 100, 'meat': 100, 'teeth': 10},
            'buttons': {
              'continue': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.continue');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'lose': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events_extended.beast_attack.lose_text1'),
                localization.translate('outside_events_extended.beast_attack.lose_text2')
              ];
            }(),
            'onLoad': () {
              final population = _sm.get('game.population', true) ?? 0;
              final lostPop = Random().nextInt(5) + 3; // 3-7个村民
              final newPop = (population - lostPop).clamp(0, population);
              _sm.set('game.population', newPop);
              Logger.info('🐺 Beast attack loss: $lostPop villagers');
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
          },
          'hide': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events_extended.beast_attack.hide_text1'),
                localization.translate('outside_events_extended.beast_attack.hide_text2')
              ];
            }(),
            'onLoad': () {
              final huts = _sm.get('game.buildings.hut', true) ?? 0;
              if (huts > 0) {
                final lostHuts = Random().nextInt(2) + 1; // 1-2个小屋
                final newHuts = (huts - lostHuts).clamp(0, huts);
                _sm.set('game.buildings.hut', newHuts);
                Logger.info('🏠 Beast destruction: $lostHuts huts');
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

  /// 军事突袭事件
  static Map<String, dynamic> get militaryRaid => {
        'title': () {
          final localization = Localization();
          return localization.translate('outside_events_extended.military_raid.title');
        }(),
        'isAvailable': () {
          final population = _sm.get('game.population', true) ?? 0;
          final cityCleared = _sm.get('game.cityCleared', true) ?? false;
          return population > 100 && !cityCleared;
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events_extended.military_raid.text1'),
                localization.translate('outside_events_extended.military_raid.text2')
              ];
            }(),
            'notification': () {
              final localization = Localization();
              return localization.translate('outside_events_extended.military_raid.notification');
            }(),
            'buttons': {
              'fight': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.fight');
                }(),
                'nextScene': {'0.3': 'win', '1.0': 'lose'}
              },
              'surrender': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('outside_events_extended.military_raid.surrender');
                }(),
                'nextScene': 'surrender'
              }
            }
          },
          'win': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events_extended.military_raid.win_text1'),
                localization.translate('outside_events_extended.military_raid.win_text2')
              ];
            }(),
            'reward': {'rifle': 5, 'bullets': 100, 'steel': 50},
            'buttons': {
              'continue': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.continue');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'lose': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events_extended.military_raid.lose_text1'),
                localization.translate('outside_events_extended.military_raid.lose_text2')
              ];
            }(),
            'onLoad': () {
              final population = _sm.get('game.population', true) ?? 0;
              final lostPop = (population * 0.5).floor().clamp(10, 50);
              final newPop = (population - lostPop).clamp(0, population);
              _sm.set('game.population', newPop);
              Logger.info('⚔️ Military raid loss: $lostPop villagers');
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
          },
          'surrender': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events_extended.military_raid.surrender_text1'),
                localization.translate('outside_events_extended.military_raid.surrender_text2')
              ];
            }(),
            'onLoad': () {
              // 失去大部分资源
              final resources = ['wood', 'fur', 'meat', 'iron', 'steel'];
              for (final resource in resources) {
                final amount = _sm.get('stores.$resource', true) ?? 0;
                final lost = (amount * 0.7).floor();
                _sm.add('stores.$resource', -lost);
              }
              Logger.info('💰 Military raid loss: 70% of resources');
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
