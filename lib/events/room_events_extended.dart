import '../core/state_manager.dart';
import '../core/logger.dart';
import '../core/localization.dart';
import '../modules/world.dart';
import 'dart:math';
import 'dart:async';

/// 扩展房间事件定义
class RoomEventsExtended {
  static final StateManager _sm = StateManager();

  /// 里面的声音事件
  static Map<String, dynamic> get noisesInside => {
        'title': 'events.room_events.noises_inside.title',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final wood = _sm.get('stores.wood', true) ?? 0;
          return wood > 0;
        },
        'scenes': {
          'start': {
            'text': [
              'events.room_events.noises_inside.text1',
              'events.room_events.noises_inside.text2'
            ],
            'notification': 'events.room_events.noises_inside.notification',
            'buttons': {
              'investigate': {
                'text': 'ui.buttons.investigate',
                'nextScene': {'0.5': 'scales', '0.8': 'teeth', '1.0': 'cloth'}
              },
              'ignore': {'text': 'ui.buttons.ignore', 'nextScene': 'end'}
            }
          },
          'scales': {
            'text': [
              'events.room_events.noises_inside.wood_missing',
              'events.room_events.noises_inside.scales_found'
            ],
            'onLoad': () {
              final numWood = _sm.get('stores.wood', true) ?? 0;
              final lostWood = (numWood * 0.1).floor().clamp(1, numWood);
              final gainedScales = (lostWood / 5).floor().clamp(1, 999);
              _sm.add('stores.wood', -lostWood);
              _sm.add('stores.scales', gainedScales);
            },
            'buttons': {
              'leave': {'text': 'ui.buttons.leave', 'nextScene': 'end'}
            }
          },
          'teeth': {
            'text': [
              'events.room_events.noises_inside.wood_missing',
              'events.room_events.noises_inside.teeth_found'
            ],
            'onLoad': () {
              final numWood = _sm.get('stores.wood', true) ?? 0;
              final lostWood = (numWood * 0.1).floor().clamp(1, numWood);
              final gainedTeeth = (lostWood / 5).floor().clamp(1, 999);
              _sm.add('stores.wood', -lostWood);
              _sm.add('stores.teeth', gainedTeeth);
            },
            'buttons': {
              'leave': {'text': 'ui.buttons.leave', 'nextScene': 'end'}
            }
          },
          'cloth': {
            'text': [
              'events.room_events.noises_inside.wood_missing',
              'events.room_events.noises_inside.cloth_found'
            ],
            'onLoad': () {
              final numWood = _sm.get('stores.wood', true) ?? 0;
              final lostWood = (numWood * 0.1).floor().clamp(1, numWood);
              final gainedCloth = (lostWood / 5).floor().clamp(1, 999);
              _sm.add('stores.wood', -lostWood);
              _sm.add('stores.cloth', gainedCloth);
            },
            'buttons': {
              'leave': {'text': 'ui.buttons.leave', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 乞丐事件
  static Map<String, dynamic> get beggar => {
        'title': 'events.room_events.beggar.title',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final fur = _sm.get('stores.fur', true) ?? 0;
          return fur > 0;
        },
        'scenes': {
          'start': {
            'text': [
              'events.room_events.beggar.text1',
              'events.room_events.beggar.text2'
            ],
            'notification': 'events.room_events.beggar.notification',
            'buttons': {
              '50furs': {
                'text': 'ui.buttons.give_50',
                'cost': {'fur': 50},
                'nextScene': {'0.5': 'scales', '0.8': 'teeth', '1.0': 'cloth'}
              },
              '100furs': {
                'text': 'ui.buttons.give_100',
                'cost': {'fur': 100},
                'nextScene': {'0.5': 'teeth', '0.8': 'scales', '1.0': 'cloth'}
              },
              'deny': {'text': 'ui.buttons.deny', 'nextScene': 'end'}
            }
          },
          'scales': {
            'reward': {'scales': 20},
            'text': [
              'events.room_events.beggar.scales_text1',
              'events.room_events.beggar.scales_text2'
            ],
            'buttons': {
              'leave': {'text': 'ui.buttons.farewell', 'nextScene': 'end'}
            }
          },
          'teeth': {
            'reward': {'teeth': 20},
            'text': [
              'events.room_events.beggar.teeth_text1',
              'events.room_events.beggar.teeth_text2'
            ],
            'buttons': {
              'leave': {'text': 'ui.buttons.farewell', 'nextScene': 'end'}
            }
          },
          'cloth': {
            'reward': {'cloth': 20},
            'text': [
              'events.room_events.beggar.cloth_text1',
              'events.room_events.beggar.cloth_text2'
            ],
            'buttons': {
              'leave': {'text': 'ui.buttons.farewell', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 可疑建造者事件
  static Map<String, dynamic> get shadyBuilder => {
        'title': () {
          final localization = Localization();
          return localization
              .translate('events.room_events.shady_builder.title');
        }(),
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final huts = _sm.get('game.buildings.hut', true) ?? 0;
          return huts >= 5 && huts < 20;
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization
                    .translate('events.room_events.shady_builder.text1'),
                localization.translate('events.room_events.shady_builder.text2')
              ];
            }(),
            'notification': () {
              final localization = Localization();
              return localization
                  .translate('events.room_events.shady_builder.notification');
            }(),
            'buttons': {
              'build': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.wood_300');
                }(),
                'cost': {'wood': 300},
                'nextScene': {'0.6': 'steal', '1.0': 'build'}
              },
              'deny': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.farewell');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'steal': {
            'text': () {
              final localization = Localization();
              return [
                localization
                    .translate('events.room_events.shady_builder.steal_text')
              ];
            }(),
            'notification': () {
              final localization = Localization();
              return localization.translate(
                  'events.room_events.shady_builder.steal_notification');
            }(),
            'buttons': {
              'end': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.go_home');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'build': {
            'text': () {
              final localization = Localization();
              return [
                localization
                    .translate('events.room_events.shady_builder.build_text')
              ];
            }(),
            'notification': () {
              final localization = Localization();
              return localization.translate(
                  'events.room_events.shady_builder.build_notification');
            }(),
            'onLoad': () {
              final huts = _sm.get('game.buildings.hut', true) ?? 0;
              if (huts < 20) {
                _sm.set('game.buildings.hut', huts + 1);
              }
            },
            'buttons': {
              'end': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.go_home');
                }(),
                'nextScene': 'end'
              }
            }
          }
        }
      };

  /// 神秘流浪者-木材版事件
  static Map<String, dynamic> get mysteriousWandererWood => {
        'title': 'events.mysterious_wanderer_wood.title',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final wood = _sm.get('stores.wood', true) ?? 0;
          return wood > 0;
        },
        'scenes': {
          'start': {
            'text': [
              'events.mysterious_wanderer_wood.text1',
              'events.mysterious_wanderer_wood.text2'
            ],
            'notification': 'events.mysterious_wanderer_wood.notification',
            'buttons': {
              'wood100': {
                'text': 'ui.buttons.give_100',
                'cost': {'wood': 100},
                'nextScene': 'wood100'
              },
              'wood500': {
                'text': 'ui.buttons.give_500',
                'cost': {'wood': 500},
                'nextScene': 'wood500'
              },
              'deny': {'text': 'ui.buttons.deny', 'nextScene': 'end'}
            }
          },
          'wood100': {
            'text': ['events.mysterious_wanderer_wood.leave_text'],
            'onLoad': () {
              // 50%概率在60秒后返回300木材
              if (Random().nextDouble() < 0.5) {
                // 使用延迟奖励机制
                Timer(Duration(seconds: 60), () {
                  _sm.add('stores.wood', 300);
                  // 通知系统暂时用Logger代替
                  Logger.info('📢 神秘流浪者返回了，车上堆满了木材。');
                  Logger.info('🎁 神秘流浪者返回奖励: 300木材');
                });
                Logger.info('⏰ 神秘流浪者将在60秒后返回');
              }
            },
            'buttons': {
              'leave': {'text': 'ui.buttons.farewell', 'nextScene': 'end'}
            }
          },
          'wood500': {
            'text': ['events.mysterious_wanderer_wood.leave_text'],
            'onLoad': () {
              // 30%概率在60秒后返回1500木材
              if (Random().nextDouble() < 0.3) {
                // 使用延迟奖励机制
                Timer(Duration(seconds: 60), () {
                  _sm.add('stores.wood', 1500);
                  Logger.info('📢 神秘流浪者返回了，车上堆满了木材。');
                  Logger.info('🎁 神秘流浪者返回奖励: 1500木材');
                });
                Logger.info('⏰ 神秘流浪者将在60秒后返回');
              }
            },
            'buttons': {
              'leave': {'text': 'ui.buttons.farewell', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 神秘流浪者-毛皮版事件
  static Map<String, dynamic> get mysteriousWandererFur => {
        'title': 'events.mysterious_wanderer_fur.title',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final fur = _sm.get('stores.fur', true) ?? 0;
          return fur > 0;
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('events.mysterious_wanderer_fur.text1'),
                localization.translate('events.mysterious_wanderer_fur.text2')
              ];
            }(),
            'notification': () {
              final localization = Localization();
              return localization
                  .translate('events.mysterious_wanderer_fur.notification');
            }(),
            'buttons': {
              'fur100': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.give_100');
                }(),
                'cost': {'fur': 100},
                'nextScene': 'fur100'
              },
              'fur500': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.give_500');
                }(),
                'cost': {'fur': 500},
                'nextScene': 'fur500'
              },
              'deny': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.deny');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'fur100': {
            'text': () {
              final localization = Localization();
              return [
                localization
                    .translate('events.mysterious_wanderer_fur.leave_text')
              ];
            }(),
            'onLoad': () {
              // 50%概率在60秒后返回300毛皮
              if (Random().nextDouble() < 0.5) {
                Timer(Duration(seconds: 60), () {
                  _sm.add('stores.fur', 300);
                  Logger.info('📢 神秘流浪者返回了，车上堆满了毛皮。');
                  Logger.info('🎁 神秘流浪者返回奖励: 300毛皮');
                });
                Logger.info('⏰ 神秘流浪者将在60秒后返回');
              }
            },
            'buttons': {
              'leave': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.farewell');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'fur500': {
            'text': () {
              final localization = Localization();
              return [
                localization
                    .translate('events.mysterious_wanderer_fur.leave_text')
              ];
            }(),
            'onLoad': () {
              // 30%概率在60秒后返回1500毛皮
              if (Random().nextDouble() < 0.3) {
                Timer(Duration(seconds: 60), () {
                  _sm.add('stores.fur', 1500);
                  Logger.info('📢 神秘流浪者返回了，车上堆满了毛皮。');
                  Logger.info('🎁 神秘流浪者返回奖励: 1500毛皮');
                });
                Logger.info('⏰ 神秘流浪者将在60秒后返回');
              }
            },
            'buttons': {
              'leave': {'text': '告别', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 侦察兵事件
  static Map<String, dynamic> get scout => {
        'title': () {
          final localization = Localization();
          return localization.translate('events.room_events.scout.title');
        }(),
        'isAvailable': () {
          // 原游戏条件：Engine.activeModule == Room && $SM.get('features.location.world')
          // 只需要世界功能解锁即可，不需要火焰条件
          final worldUnlocked =
              _sm.get('features.location.world', true) ?? false;
          return worldUnlocked;
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('events.room_events.scout.text1'),
                localization.translate('events.room_events.scout.text2')
              ];
            }(),
            'notification': () {
              final localization = Localization();
              return localization
                  .translate('events.room_events.scout.notification');
            }(),
            'buttons': {
              'buyMap': {
                'text': () {
                  final localization = Localization();
                  return localization
                      .translate('events.room_events.scout.buy_map');
                }(),
                'cost': {'fur': 200, 'scales': 10},
                'available': () {
                  // 检查是否已经看过所有地图
                  final world = World.instance;
                  return !world.seenAll;
                },
                'notification': () {
                  final localization = Localization();
                  return localization
                      .translate('events.room_events.scout.map_notification');
                }(),
                'onChoose': () {
                  // 应用地图效果
                  final world = World.instance;
                  world.applyMap();
                  Logger.info('🗺️ Map purchased and applied');
                }
              },
              'learn': {
                'text': () {
                  final localization = Localization();
                  return localization
                      .translate('events.room_events.scout.learn_scouting');
                }(),
                'cost': {'fur': 1000, 'scales': 50, 'teeth': 20},
                'available': () {
                  final hasScoutPerk =
                      _sm.get('character.perks.scout', true) ?? false;
                  return !hasScoutPerk;
                },
                'onChoose': () {
                  _sm.set('character.perks.scout', true);
                  Logger.info('🎯 Learned scouting skill');
                }
              },
              'leave': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.farewell');
                }(),
                'nextScene': 'end'
              }
            }
          }
        }
      };

  /// 大师事件
  static Map<String, dynamic> get master => {
        'title': () {
          final localization = Localization();
          return localization.translate('events.room_events.master.title');
        }(),
        'isAvailable': () {
          final worldUnlocked =
              _sm.get('features.location.world', true) ?? false;
          Logger.info('🧙 宗师事件检查 - 世界已解锁: $worldUnlocked');
          return worldUnlocked; // 与原游戏一致，只需要世界已解锁
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('events.room_events.master.text1'),
                localization.translate('events.room_events.master.text2')
              ];
            }(),
            'notification': () {
              final localization = Localization();
              return localization
                  .translate('events.room_events.master.notification');
            }(),
            'buttons': {
              'agree': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.agree');
                }(),
                'cost': {'cured meat': 100, 'fur': 100, 'torch': 1},
                'nextScene': 'agree'
              },
              'deny': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.deny');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'agree': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('events.room_events.master.agree_text')
              ];
            }(),
            'buttons': {
              'evasion': {
                'text': () {
                  final localization = Localization();
                  return localization
                      .translate('events.room_events.master.evasion');
                }(),
                'available': () {
                  final hasEvasivePerk =
                      _sm.get('character.perks.evasive', true) ?? false;
                  return !hasEvasivePerk;
                },
                'onChoose': () {
                  _sm.set('character.perks.evasive', true);
                  Logger.info('🏃 Learned evasion skill');
                },
                'nextScene': 'end'
              },
              'precision': {
                'text': () {
                  final localization = Localization();
                  return localization
                      .translate('events.room_events.master.precision');
                }(),
                'available': () {
                  final hasPrecisePerk =
                      _sm.get('character.perks.precise', true) ?? false;
                  return !hasPrecisePerk;
                },
                'onChoose': () {
                  _sm.set('character.perks.precise', true);
                  Logger.info('🎯 Learned precision skill');
                },
                'nextScene': 'end'
              },
              'force': {
                'text': () {
                  final localization = Localization();
                  return localization
                      .translate('events.room_events.master.force');
                }(),
                'available': () {
                  final hasBarbarianPerk =
                      _sm.get('character.perks.barbarian', true) ?? false;
                  return !hasBarbarianPerk;
                },
                'onChoose': () {
                  _sm.set('character.perks.barbarian', true);
                  Logger.info('💪 Learned barbarian skill');
                },
                'nextScene': 'end'
              },
              'boxing': {
                'text': () {
                  final localization = Localization();
                  return localization
                      .translate('events.room_events.master.boxing');
                }(),
                'available': () {
                  final hasBoxerPerk =
                      _sm.get('character.perks.boxer', true) ?? false;
                  return !hasBoxerPerk;
                },
                'onChoose': () {
                  _sm.set('character.perks.boxer', true);
                  Logger.info('👊 Learned boxing skill');
                },
                'nextScene': 'end'
              },
              'nothing': {
                'text': () {
                  final localization = Localization();
                  return localization
                      .translate('events.room_events.master.nothing');
                }(),
                'nextScene': 'end'
              }
            }
          }
        }
      };

  /// 病人事件
  static Map<String, dynamic> get sickMan => {
        'title': () {
          final localization = Localization();
          return localization.translate('events.room_events.sick_man.title');
        }(),
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final medicine = _sm.get('stores.medicine', true) ?? 0;
          return medicine > 0;
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('events.room_events.sick_man.text1'),
                localization.translate('events.room_events.sick_man.text2')
              ];
            }(),
            'notification': () {
              final localization = Localization();
              return localization
                  .translate('events.room_events.sick_man.notification');
            }(),
            'buttons': {
              'help': {
                'text': () {
                  final localization = Localization();
                  return localization
                      .translate('events.room_events.sick_man.help');
                }(),
                'cost': {'medicine': 1},
                'notification': () {
                  final localization = Localization();
                  return localization.translate(
                      'events.room_events.sick_man.help_notification');
                }(),
                'nextScene': {
                  '0.1': 'alloy',
                  '0.3': 'cells',
                  '0.5': 'scales',
                  '1.0': 'nothing'
                }
              },
              'ignore': {
                'text': () {
                  final localization = Localization();
                  return localization
                      .translate('events.room_events.sick_man.ignore');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'alloy': {
            'text': () {
              final localization = Localization();
              return [
                localization
                    .translate('events.room_events.sick_man.alloy_text1'),
                localization
                    .translate('events.room_events.sick_man.alloy_text2'),
                localization
                    .translate('events.room_events.sick_man.alloy_text3')
              ];
            }(),
            'reward': {'alien alloy': 1},
            'buttons': {
              'bye': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.farewell');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'cells': {
            'text': () {
              final localization = Localization();
              return [
                localization
                    .translate('events.room_events.sick_man.cells_text1'),
                localization
                    .translate('events.room_events.sick_man.cells_text2'),
                localization
                    .translate('events.room_events.sick_man.cells_text3')
              ];
            }(),
            'reward': {'energy cell': 3},
            'buttons': {
              'bye': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.farewell');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'scales': {
            'text': () {
              final localization = Localization();
              return [
                localization
                    .translate('events.room_events.sick_man.scales_text1'),
                localization
                    .translate('events.room_events.sick_man.scales_text2'),
                localization
                    .translate('events.room_events.sick_man.scales_text3')
              ];
            }(),
            'reward': {'scales': 5},
            'buttons': {
              'bye': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.farewell');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'nothing': {
            'text': () {
              final localization = Localization();
              return [
                localization
                    .translate('events.room_events.sick_man.nothing_text')
              ];
            }(),
            'buttons': {
              'bye': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.farewell');
                }(),
                'nextScene': 'end'
              }
            }
          }
        }
      };

  /// 武术大师事件
  static Map<String, dynamic> get martialMaster => {
        'title': () {
          final localization = Localization();
          return localization
              .translate('events.room_events.martial_master.title');
        }(),
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final hasBoxer = _sm.get('character.perks.boxer', true) ?? false;
          final population = _sm.get('game.population', true) ?? 0;
          return hasBoxer && population >= 50;
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization
                    .translate('events.room_events.martial_master.text1'),
                localization
                    .translate('events.room_events.martial_master.text2'),
                localization
                    .translate('events.room_events.martial_master.text3')
              ];
            }(),
            'notification': () {
              final localization = Localization();
              return localization
                  .translate('events.room_events.martial_master.notification');
            }(),
            'buttons': {
              'learn': {
                'text': () {
                  final localization = Localization();
                  return localization
                      .translate('events.room_events.martial_master.learn');
                }(),
                'cost': {'cured meat': 200, 'fur': 200},
                'nextScene': 'learn'
              },
              'decline': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.decline');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'learn': {
            'text': () {
              final localization = Localization();
              return [
                localization
                    .translate('events.room_events.martial_master.learn_text')
              ];
            }(),
            'buttons': {
              'martial_artist': {
                'text': () {
                  final localization = Localization();
                  return localization.translate(
                      'events.room_events.martial_master.martial_artist');
                }(),
                'available': () {
                  final hasMartialArtist =
                      _sm.get('character.perks.martial artist', true) ?? false;
                  return !hasMartialArtist;
                },
                'onChoose': () {
                  _sm.set('character.perks.martial artist', true);
                  Logger.info('🥋 Learned martial artist skill');
                },
                'nextScene': 'end'
              },
              'unarmed_master': {
                'text': () {
                  final localization = Localization();
                  return localization.translate(
                      'events.room_events.martial_master.unarmed_master');
                }(),
                'available': () {
                  final hasMartialArtist =
                      _sm.get('character.perks.martial artist', true) ?? false;
                  final hasUnarmedMaster =
                      _sm.get('character.perks.unarmed master', true) ?? false;
                  return hasMartialArtist && !hasUnarmedMaster;
                },
                'onChoose': () {
                  _sm.set('character.perks.unarmed master', true);
                  Logger.info('🥊 Learned unarmed master skill');
                },
                'nextScene': 'end'
              },
              'nothing': {
                'text': () {
                  final localization = Localization();
                  return localization
                      .translate('events.room_events.martial_master.nothing');
                }(),
                'nextScene': 'end'
              }
            }
          }
        }
      };

  /// 沙漠向导事件
  static Map<String, dynamic> get desertGuide => {
        'title': () {
          final localization = Localization();
          return localization
              .translate('events.room_events.desert_guide.title');
        }(),
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final worldUnlocked =
              _sm.get('features.location.world', true) ?? false;
          final water = _sm.get('stores.water', true) ?? 0;
          return worldUnlocked && water >= 100;
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('events.room_events.desert_guide.text1'),
                localization.translate('events.room_events.desert_guide.text2'),
                localization.translate('events.room_events.desert_guide.text3')
              ];
            }(),
            'notification': () {
              final localization = Localization();
              return localization
                  .translate('events.room_events.desert_guide.notification');
            }(),
            'buttons': {
              'learn': {
                'text': () {
                  final localization = Localization();
                  return localization
                      .translate('events.room_events.desert_guide.learn');
                }(),
                'cost': {'water': 100, 'cured meat': 50},
                'nextScene': 'learn'
              },
              'decline': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.decline');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'learn': {
            'text': () {
              final localization = Localization();
              return [
                localization
                    .translate('events.room_events.desert_guide.learn_text')
              ];
            }(),
            'buttons': {
              'slow_metabolism': {
                'text': () {
                  final localization = Localization();
                  return localization.translate(
                      'events.room_events.desert_guide.slow_metabolism');
                }(),
                'available': () {
                  final hasSlowMetabolism =
                      _sm.get('character.perks.slow metabolism', true) ?? false;
                  return !hasSlowMetabolism;
                },
                'onChoose': () {
                  _sm.set('character.perks.slow metabolism', true);
                  Logger.info('🐌 Learned slow metabolism skill');
                },
                'nextScene': 'end'
              },
              'desert_rat': {
                'text': () {
                  final localization = Localization();
                  return localization
                      .translate('events.room_events.desert_guide.desert_rat');
                }(),
                'available': () {
                  final hasDesertRat =
                      _sm.get('character.perks.desert rat', true) ?? false;
                  return !hasDesertRat;
                },
                'onChoose': () {
                  _sm.set('character.perks.desert rat', true);
                  Logger.info('🐭 Learned desert rat skill');
                },
                'nextScene': 'end'
              },
              'stealthy': {
                'text': () {
                  final localization = Localization();
                  return localization
                      .translate('events.room_events.desert_guide.stealthy');
                }(),
                'available': () {
                  final hasStealthy =
                      _sm.get('character.perks.stealthy', true) ?? false;
                  return !hasStealthy;
                },
                'onChoose': () {
                  _sm.set('character.perks.stealthy', true);
                  Logger.info('👤 Learned stealthy skill');
                },
                'nextScene': 'end'
              },
              'nothing': {
                'text': () {
                  final localization = Localization();
                  return localization
                      .translate('events.room_events.desert_guide.nothing');
                }(),
                'nextScene': 'end'
              }
            }
          }
        }
      };
}
