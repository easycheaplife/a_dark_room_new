import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/logger.dart';
import '../core/localization.dart';
import 'outside_events_extended.dart';

/// 外部事件定义
class OutsideEvents {
  static final StateManager _sm = StateManager();

  /// 获取所有外部事件
  static List<Map<String, dynamic>> get events => [
        convoy,
        raiders,
        beast,
        trader,
        refugees,
        scout,
        ruinedTrap,
        fire,
        OutsideEventsExtended.sickness,
        OutsideEventsExtended.plague,
        OutsideEventsExtended.beastAttack,
        OutsideEventsExtended.militaryRaid,
      ];

  /// 商队事件
  static Map<String, dynamic> get convoy => {
        'title': () {
          final localization = Localization();
          return localization.translate('outside_events.convoy.title');
        }(),
        'isAvailable': () {
          final tradingPost = _sm.get('game.buildings.trading post', true) ?? 0;
          return tradingPost > 0; // 需要贸易站
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.convoy.text1'),
                localization.translate('outside_events.convoy.text2'),
                localization.translate('outside_events.convoy.text3')
              ];
            }(),
            'buttons': {
              'trade': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.trade');
                }(),
                'nextScene': 'trade'
              },
              'attack': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('outside_events.convoy.attack');
                }(),
                'nextScene': 'attack'
              },
              'ignore': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.ignore');
                }(),
                'nextScene': 'ignore'
              }
            }
          },
          'trade': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.convoy.trade_text1'),
                localization.translate('outside_events.convoy.trade_text2')
              ];
            }(),
            'cost': {'fur': 100, 'meat': 50},
            'reward': {'bullets': 20, 'medicine': 3, 'steel': 10},
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
          'attack': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.convoy.attack_text1'),
                localization.translate('outside_events.convoy.attack_text2')
              ];
            }(),
            'nextScene': 'combat'
          },
          'ignore': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.convoy.ignore_text1'),
                localization.translate('outside_events.convoy.ignore_text2')
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
          'combat': {
            'combat': true,
            'enemy': () {
              final localization = Localization();
              return localization.translate('outside_events.convoy.enemy');
            }(),
            'health': 30,
            'damage': 4,
            'hit': 0.7,
            'attackDelay': 2.5,
            'loot': {
              'bullets': [10, 30],
              'medicine': [1, 5],
              'steel': [5, 15],
              'scales': [0, 3]
            }
          }
        }
      };

  /// 袭击者事件
  static Map<String, dynamic> get raiders => {
        'title': () {
          final localization = Localization();
          return localization.translate('outside_events.raiders.title');
        }(),
        'isAvailable': () {
          final population = _sm.get('game.population', true) ?? 0;
          return population >= 10; // 需要一定人口才会吸引袭击者
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.raiders.text1'),
                localization.translate('outside_events.raiders.text2'),
                localization.translate('outside_events.raiders.text3')
              ];
            }(),
            'buttons': {
              'fight': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.fight');
                }(),
                'nextScene': 'combat'
              }
            }
          },
          'combat': {
            'combat': true,
            'enemy': () {
              final localization = Localization();
              return localization.translate('outside_events.raiders.enemy');
            }(),
            'health': 25,
            'damage': 5,
            'hit': 0.8,
            'attackDelay': 2.0,
            'loot': {
              'iron': [5, 15],
              'leather': [3, 8],
              'bullets': [0, 10],
              'scales': [1, 3]
            }
          }
        }
      };

  /// 野兽事件
  static Map<String, dynamic> get beast => {
        'title': () {
          final localization = Localization();
          return localization.translate('outside_events.beast.title');
        }(),
        'isAvailable': () {
          final lodge = _sm.get('game.buildings.lodge', true) ?? 0;
          return lodge > 0; // 需要狩猎小屋
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.beast.text1'),
                localization.translate('outside_events.beast.text2'),
                localization.translate('outside_events.beast.text3')
              ];
            }(),
            'buttons': {
              'fight': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.fight');
                }(),
                'nextScene': 'combat'
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
          'combat': {
            'combat': true,
            'enemy': () {
              final localization = Localization();
              return localization.translate('outside_events.beast.enemy');
            }(),
            'health': 35,
            'damage': 6,
            'hit': 0.75,
            'attackDelay': 3.0,
            'loot': {
              'meat': [20, 40],
              'fur': [10, 20],
              'teeth': [2, 5],
              'scales': [1, 2]
            }
          },
          'hide': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.beast.hide_text1'),
                localization.translate('outside_events.beast.hide_text2'),
                localization.translate('outside_events.beast.hide_text3')
              ];
            }(),
            'cost': {'wood': 100, 'fur': 20},
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

  /// 商人事件
  static Map<String, dynamic> get trader => {
        'title': () {
          final localization = Localization();
          return localization.translate('outside_events.trader.title');
        }(),
        'isAvailable': () {
          final tradingPost = _sm.get('game.buildings.trading post', true) ?? 0;
          return tradingPost > 0; // 需要贸易站
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.trader.text1'),
                localization.translate('outside_events.trader.text2'),
                localization.translate('outside_events.trader.text3')
              ];
            }(),
            'buttons': {
              'buyMedicine': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('outside_events.trader.buy_medicine');
                }(),
                'cost': {'scales': 10},
                'nextScene': 'buyMedicine'
              },
              'buyWeapon': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('outside_events.trader.buy_weapon');
                }(),
                'cost': {'scales': 15, 'teeth': 5},
                'nextScene': 'buyWeapon'
              },
              'decline': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('outside_events.trader.decline_buy');
                }(),
                'nextScene': 'decline'
              }
            }
          },
          'buyMedicine': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.trader.buy_medicine_text1'),
                localization.translate('outside_events.trader.buy_medicine_text2')
              ];
            }(),
            'reward': {'medicine': 5},
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
          'buyWeapon': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.trader.buy_weapon_text1'),
                localization.translate('outside_events.trader.buy_weapon_text2')
              ];
            }(),
            'reward': {'steel sword': 1},
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
          'decline': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.trader.decline_text1'),
                localization.translate('outside_events.trader.decline_text2')
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
          }
        }
      };

  /// 难民事件
  static Map<String, dynamic> get refugees => {
        'title': () {
          final localization = Localization();
          return localization.translate('outside_events.refugees.title');
        }(),
        'isAvailable': () {
          final huts = _sm.get('game.buildings.hut', true) ?? 0;
          final population = _sm.get('game.population', true) ?? 0;
          final maxPop = huts * 4;
          return huts >= 5 && population < maxPop; // 需要足够的小屋和空余人口空间
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.refugees.text1'),
                localization.translate('outside_events.refugees.text2'),
                localization.translate('outside_events.refugees.text3')
              ];
            }(),
            'buttons': {
              'accept': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('outside_events.refugees.accept');
                }(),
                'cost': {'meat': 50, 'fur': 20},
                'nextScene': 'accept'
              },
              'refuse': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('outside_events.refugees.refuse');
                }(),
                'nextScene': 'refuse'
              }
            }
          },
          'accept': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.refugees.accept_text1'),
                localization.translate('outside_events.refugees.accept_text2')
              ];
            }(),
            'onLoad': () {
              final currentPop = _sm.get('game.population', true) ?? 0;
              _sm.set('game.population', currentPop + 3);
              Logger.info('👥 Population increased by 3');
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
          'refuse': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.refugees.refuse_text1'),
                localization.translate('outside_events.refugees.refuse_text2')
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
          }
        }
      };

  /// 侦察兵事件
  static Map<String, dynamic> get scout => {
        'title': () {
          final localization = Localization();
          return localization.translate('outside_events.scout_report.title');
        }(),
        'isAvailable': () {
          final armoury = _sm.get('game.buildings.armoury', true) ?? 0;
          return armoury > 0; // 需要军械库
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.scout_report.text1'),
                localization.translate('outside_events.scout_report.text2'),
                localization.translate('outside_events.scout_report.text3')
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
              'ignore': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.ignore');
                }(),
                'nextScene': 'ignore'
              }
            }
          },
          'investigate': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.scout_report.investigate_text1'),
                localization.translate('outside_events.scout_report.investigate_text2')
              ];
            }(),
            'reward': {'bullets': 30, 'medicine': 2, 'energy cell': 1},
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
          'ignore': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.scout_report.ignore_text1'),
                localization.translate('outside_events.scout_report.ignore_text2')
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
          }
        }
      };

  /// 被毁的陷阱事件
  static Map<String, dynamic> get ruinedTrap => {
        'title': () {
          final localization = Localization();
          return localization.translate('outside_events.ruined_trap.title');
        }(),
        'isAvailable': () {
          final traps = _sm.get('game.buildings.trap', true) ?? 0;
          return traps > 0;
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.ruined_trap.text1'),
                localization.translate('outside_events.ruined_trap.text2')
              ];
            }(),
            'notification': () {
              final localization = Localization();
              return localization.translate('outside_events.ruined_trap.notification');
            }(),
            'onLoad': () {
              // 减少一个陷阱
              final traps = _sm.get('game.buildings.trap', true) ?? 0;
              if (traps > 0) {
                _sm.set('game.buildings.trap', traps - 1);
              }
            },
            'buttons': {
              'track': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('outside_events.ruined_trap.track');
                }(),
                'available': () {
                  final hasScoutPerk =
                      _sm.get('character.perks.scout', true) ?? false;
                  return hasScoutPerk;
                },
                'nextScene': {'0.7': 'catch', '1.0': 'lose'} // 侦察技能提高成功率到70%
              },
              'ignore': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.ignore');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'catch': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.ruined_trap.catch_text1'),
                localization.translate('outside_events.ruined_trap.catch_text2')
              ];
            }(),
            'reward': {'fur': 200, 'meat': 200, 'teeth': 5},
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
                localization.translate('outside_events.ruined_trap.lose_text1'),
                localization.translate('outside_events.ruined_trap.lose_text2')
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
          }
        }
      };

  /// 火灾事件
  static Map<String, dynamic> get fire => {
        'title': () {
          final localization = Localization();
          return localization.translate('outside_events.fire.title');
        }(),
        'isAvailable': () {
          final huts = _sm.get('game.buildings.hut', true) ?? 0;
          return huts > 0;
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('outside_events.fire.text1'),
                localization.translate('outside_events.fire.text2')
              ];
            }(),
            'notification': () {
              final localization = Localization();
              return localization.translate('outside_events.fire.notification');
            }(),
            'onLoad': () {
              // 减少小屋和村民
              final huts = _sm.get('game.buildings.hut', true) ?? 0;
              final population = _sm.get('game.population', true) ?? 0;

              if (huts > 0) {
                final lostHuts =
                    (huts * 0.1).floor().clamp(1, 3); // 10%的小屋，最少1个最多3个
                final newHuts = (huts - lostHuts).clamp(0, huts);
                _sm.set('game.buildings.hut', newHuts);

                // 每个小屋损失对应村民
                final lostPop = lostHuts * 4;
                final newPop = (population - lostPop).clamp(0, population);
                _sm.set('game.population', newPop);

                Logger.info('🔥 Fire damage: $lostHuts huts, $lostPop villagers');
              }
            },
            'buttons': {
              'mourn': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('outside_events.fire.mourn');
                }(),
                'nextScene': 'end'
              }
            }
          }
        }
      };
}
