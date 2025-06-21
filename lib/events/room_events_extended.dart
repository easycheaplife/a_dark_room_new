import '../core/state_manager.dart';
import '../core/notifications.dart';
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
        'title': () {
          final localization = Localization();
          return localization.translate('events.noises_inside.title');
        }(),
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final wood = _sm.get('stores.wood', true) ?? 0;
          return fire > 0 && wood > 0;
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('events.noises_inside.text1'),
                localization.translate('events.noises_inside.text2')
              ];
            }(),
            'notification': () {
              final localization = Localization();
              return localization.translate('events.noises_inside.notification');
            }(),
            'buttons': {
              'investigate': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.investigate');
                }(),
                'nextScene': {'0.5': 'scales', '0.8': 'teeth', '1.0': 'cloth'}
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
          'scales': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('events.noises_inside.wood_missing'),
                localization.translate('events.noises_inside.scales_found')
              ];
            }(),
            'onLoad': () {
              final numWood = _sm.get('stores.wood', true) ?? 0;
              final lostWood = (numWood * 0.1).floor().clamp(1, numWood);
              final gainedScales = (lostWood / 5).floor().clamp(1, 999);
              _sm.add('stores.wood', -lostWood);
              _sm.add('stores.scales', gainedScales);
            },
            'buttons': {
              'leave': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.leave');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'teeth': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('events.noises_inside.wood_missing'),
                localization.translate('events.noises_inside.teeth_found')
              ];
            }(),
            'onLoad': () {
              final numWood = _sm.get('stores.wood', true) ?? 0;
              final lostWood = (numWood * 0.1).floor().clamp(1, numWood);
              final gainedTeeth = (lostWood / 5).floor().clamp(1, 999);
              _sm.add('stores.wood', -lostWood);
              _sm.add('stores.teeth', gainedTeeth);
            },
            'buttons': {
              'leave': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.leave');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'cloth': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('events.noises_inside.wood_missing'),
                localization.translate('events.noises_inside.cloth_found')
              ];
            }(),
            'onLoad': () {
              final numWood = _sm.get('stores.wood', true) ?? 0;
              final lostWood = (numWood * 0.1).floor().clamp(1, numWood);
              final gainedCloth = (lostWood / 5).floor().clamp(1, 999);
              _sm.add('stores.wood', -lostWood);
              _sm.add('stores.cloth', gainedCloth);
            },
            'buttons': {
              'leave': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.leave');
                }(),
                'nextScene': 'end'
              }
            }
          }
        }
      };

  /// 乞丐事件
  static Map<String, dynamic> get beggar => {
        'title': '乞丐',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final fur = _sm.get('stores.fur', true) ?? 0;
          return fire > 0 && fur > 0;
        },
        'scenes': {
          'start': {
            'text': ['一个乞丐到达。', '请求一些多余的毛皮来在夜晚保暖。'],
            'notification': '一个乞丐到达',
            'buttons': {
              '50furs': {
                'text': '给50',
                'cost': {'fur': 50},
                'nextScene': {'0.5': 'scales', '0.8': 'teeth', '1.0': 'cloth'}
              },
              '100furs': {
                'text': '给100',
                'cost': {'fur': 100},
                'nextScene': {'0.5': 'teeth', '0.8': 'scales', '1.0': 'cloth'}
              },
              'deny': {'text': '拒绝他', 'nextScene': 'end'}
            }
          },
          'scales': {
            'reward': {'scales': 20},
            'text': ['乞丐表达了他的感谢。', '留下了一堆小鳞片。'],
            'buttons': {
              'leave': {'text': '告别', 'nextScene': 'end'}
            }
          },
          'teeth': {
            'reward': {'teeth': 20},
            'text': ['乞丐表达了他的感谢。', '留下了一堆小牙齿。'],
            'buttons': {
              'leave': {'text': '告别', 'nextScene': 'end'}
            }
          },
          'cloth': {
            'reward': {'cloth': 20},
            'text': ['乞丐表达了他的感谢。', '留下了一些布料碎片。'],
            'buttons': {
              'leave': {'text': '告别', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 可疑建造者事件
  static Map<String, dynamic> get shadyBuilder => {
        'title': '可疑建造者',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final huts = _sm.get('game.buildings.hut', true) ?? 0;
          return fire > 0 && huts >= 5 && huts < 20;
        },
        'scenes': {
          'start': {
            'text': ['一个可疑的建造者路过', '说他可以用更少的木材为你建造一间小屋'],
            'notification': '一个可疑的建造者路过',
            'buttons': {
              'build': {
                'text': '300木材',
                'cost': {'wood': 300},
                'nextScene': {'0.6': 'steal', '1.0': 'build'}
              },
              'deny': {'text': '告别', 'nextScene': 'end'}
            }
          },
          'steal': {
            'text': ['可疑的建造者带着你的木材跑了'],
            'notification': '可疑的建造者带着你的木材跑了',
            'buttons': {
              'end': {'text': '回家', 'nextScene': 'end'}
            }
          },
          'build': {
            'text': ['可疑的建造者建造了一间小屋'],
            'notification': '可疑的建造者建造了一间小屋',
            'onLoad': () {
              final huts = _sm.get('game.buildings.hut', true) ?? 0;
              if (huts < 20) {
                _sm.set('game.buildings.hut', huts + 1);
              }
            },
            'buttons': {
              'end': {'text': '回家', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 神秘流浪者-木材版事件
  static Map<String, dynamic> get mysteriousWandererWood => {
        'title': '神秘流浪者',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final wood = _sm.get('stores.wood', true) ?? 0;
          return fire > 0 && wood > 0;
        },
        'scenes': {
          'start': {
            'text': () {
              final localization = Localization();
              return [
                localization.translate('events.mysterious_wanderer_wood.text1'),
                localization.translate('events.mysterious_wanderer_wood.text2')
              ];
            }(),
            'notification': () {
              final localization = Localization();
              return localization.translate('events.mysterious_wanderer_wood.notification');
            }(),
            'buttons': {
              'wood100': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.give_100');
                }(),
                'cost': {'wood': 100},
                'nextScene': 'wood100'
              },
              'wood500': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.give_500');
                }(),
                'cost': {'wood': 500},
                'nextScene': 'wood500'
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
          'wood100': {
            'text': () {
              final localization = Localization();
              return [localization.translate('events.mysterious_wanderer_wood.leave_text')];
            }(),
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
              'leave': {
                'text': () {
                  final localization = Localization();
                  return localization.translate('ui.buttons.farewell');
                }(),
                'nextScene': 'end'
              }
            }
          },
          'wood500': {
            'text': () {
              final localization = Localization();
              return [localization.translate('events.mysterious_wanderer_wood.leave_text')];
            }(),
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
              'leave': {'text': '告别', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 神秘流浪者-毛皮版事件
  static Map<String, dynamic> get mysteriousWandererFur => {
        'title': '神秘流浪者',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final fur = _sm.get('stores.fur', true) ?? 0;
          return fire > 0 && fur > 0;
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
              return localization.translate('events.mysterious_wanderer_fur.notification');
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
              return [localization.translate('events.mysterious_wanderer_fur.leave_text')];
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
              return [localization.translate('events.mysterious_wanderer_fur.leave_text')];
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
        'title': '侦察兵',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final worldUnlocked =
              _sm.get('features.location.world', true) ?? false;
          return fire > 0 && worldUnlocked;
        },
        'scenes': {
          'start': {
            'text': ['侦察兵说她到过各个地方。', '愿意谈论这些，但要付出代价。'],
            'notification': '一个侦察兵过夜',
            'buttons': {
              'buyMap': {
                'text': '购买地图',
                'cost': {'fur': 200, 'scales': 10},
                'available': () {
                  // 检查是否已经看过所有地图
                  final world = World.instance;
                  return !world.seenAll;
                },
                'notification': '地图揭示了世界的一部分',
                'onChoose': () {
                  // 应用地图效果
                  final world = World.instance;
                  world.applyMap();
                  Logger.info('🗺️ 地图已购买并应用');
                }
              },
              'learn': {
                'text': '学习侦察',
                'cost': {'fur': 1000, 'scales': 50, 'teeth': 20},
                'available': () {
                  final hasScoutPerk =
                      _sm.get('character.perks.scout', true) ?? false;
                  return !hasScoutPerk;
                },
                'onChoose': () {
                  _sm.set('character.perks.scout', true);
                  Logger.info('🎯 学会了侦察技能');
                }
              },
              'leave': {'text': '告别', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 大师事件
  static Map<String, dynamic> get master => {
        'title': '大师',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final worldUnlocked =
              _sm.get('features.location.world', true) ?? false;
          return fire > 0 && worldUnlocked;
        },
        'scenes': {
          'start': {
            'text': ['一个老流浪者到达。', '他温暖地微笑着，请求在夜里住宿。'],
            'notification': '一个老流浪者到达',
            'buttons': {
              'agree': {
                'text': '同意',
                'cost': {'cured meat': 100, 'fur': 100, 'torch': 1},
                'nextScene': 'agree'
              },
              'deny': {'text': '拒绝他', 'nextScene': 'end'}
            }
          },
          'agree': {
            'text': ['作为交换，流浪者提供他的智慧。'],
            'buttons': {
              'evasion': {
                'text': '闪避',
                'available': () {
                  final hasEvasivePerk =
                      _sm.get('character.perks.evasive', true) ?? false;
                  return !hasEvasivePerk;
                },
                'onChoose': () {
                  _sm.set('character.perks.evasive', true);
                  Logger.info('🏃 学会了闪避技能');
                },
                'nextScene': 'end'
              },
              'precision': {
                'text': '精准',
                'available': () {
                  final hasPrecisePerk =
                      _sm.get('character.perks.precise', true) ?? false;
                  return !hasPrecisePerk;
                },
                'onChoose': () {
                  _sm.set('character.perks.precise', true);
                  Logger.info('🎯 学会了精准技能');
                },
                'nextScene': 'end'
              },
              'force': {
                'text': '力量',
                'available': () {
                  final hasBarbarianPerk =
                      _sm.get('character.perks.barbarian', true) ?? false;
                  return !hasBarbarianPerk;
                },
                'onChoose': () {
                  _sm.set('character.perks.barbarian', true);
                  Logger.info('💪 学会了野蛮人技能');
                },
                'nextScene': 'end'
              },
              'boxing': {
                'text': '拳击',
                'available': () {
                  final hasBoxerPerk =
                      _sm.get('character.perks.boxer', true) ?? false;
                  return !hasBoxerPerk;
                },
                'onChoose': () {
                  _sm.set('character.perks.boxer', true);
                  Logger.info('👊 学会了拳击手技能');
                },
                'nextScene': 'end'
              },
              'nothing': {'text': '什么都不要', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 病人事件
  static Map<String, dynamic> get sickMan => {
        'title': '病人',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final medicine = _sm.get('stores.medicine', true) ?? 0;
          return fire > 0 && medicine > 0;
        },
        'scenes': {
          'start': {
            'text': ['一个男人蹒跚着走来，咳嗽不止。', '他恳求要药品。'],
            'notification': '一个病人蹒跚着走来',
            'buttons': {
              'help': {
                'text': '给1个药品',
                'cost': {'medicine': 1},
                'notification': '那人急切地吞下了药品',
                'nextScene': {
                  '0.1': 'alloy',
                  '0.3': 'cells',
                  '0.5': 'scales',
                  '1.0': 'nothing'
                }
              },
              'ignore': {'text': '叫他离开', 'nextScene': 'end'}
            }
          },
          'alloy': {
            'text': ['那人很感激。', '他留下了一个奖励。', '一些他在旅行中捡到的奇怪金属。'],
            'reward': {'alien alloy': 1},
            'buttons': {
              'bye': {'text': '告别', 'nextScene': 'end'}
            }
          },
          'cells': {
            'text': ['那人很感激。', '他留下了一个奖励。', '一些他在旅行中捡到的奇怪发光盒子。'],
            'reward': {'energy cell': 3},
            'buttons': {
              'bye': {'text': '告别', 'nextScene': 'end'}
            }
          },
          'scales': {
            'text': ['那人很感激。', '他留下了一个奖励。', '他只有一些鳞片。'],
            'reward': {'scales': 5},
            'buttons': {
              'bye': {'text': '告别', 'nextScene': 'end'}
            }
          },
          'nothing': {
            'text': ['那人表达了感谢，然后蹒跚着离开了。'],
            'buttons': {
              'bye': {'text': '告别', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 武术大师事件
  static Map<String, dynamic> get martialMaster => {
        'title': '武术大师',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final hasBoxer = _sm.get('character.perks.boxer', true) ?? false;
          final population = _sm.get('game.population', true) ?? 0;
          return fire > 0 && hasBoxer && population >= 50;
        },
        'scenes': {
          'start': {
            'text': ['一个神秘的武术大师来到村庄。', '他看到你已经掌握了基础拳击技巧。', '"我可以教你更高深的武艺，"他说。'],
            'notification': '一个武术大师到达',
            'buttons': {
              'learn': {
                'text': '学习武艺',
                'cost': {'cured meat': 200, 'fur': 200},
                'nextScene': 'learn'
              },
              'decline': {'text': '谢绝', 'nextScene': 'end'}
            }
          },
          'learn': {
            'text': ['大师传授了他的武艺。'],
            'buttons': {
              'martial_artist': {
                'text': '武术家',
                'available': () {
                  final hasMartialArtist =
                      _sm.get('character.perks.martial artist', true) ?? false;
                  return !hasMartialArtist;
                },
                'onChoose': () {
                  _sm.set('character.perks.martial artist', true);
                  Logger.info('🥋 学会了武术家技能');
                },
                'nextScene': 'end'
              },
              'unarmed_master': {
                'text': '徒手大师',
                'available': () {
                  final hasMartialArtist =
                      _sm.get('character.perks.martial artist', true) ?? false;
                  final hasUnarmedMaster =
                      _sm.get('character.perks.unarmed master', true) ?? false;
                  return hasMartialArtist && !hasUnarmedMaster;
                },
                'onChoose': () {
                  _sm.set('character.perks.unarmed master', true);
                  Logger.info('🥊 学会了徒手大师技能');
                },
                'nextScene': 'end'
              },
              'nothing': {'text': '什么都不学', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 沙漠向导事件
  static Map<String, dynamic> get desertGuide => {
        'title': '沙漠向导',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final worldUnlocked =
              _sm.get('features.location.world', true) ?? false;
          final water = _sm.get('stores.water', true) ?? 0;
          return fire > 0 && worldUnlocked && water >= 100;
        },
        'scenes': {
          'start': {
            'text': [
              '一个经验丰富的沙漠向导来到村庄。',
              '他的皮肤被太阳晒得黝黑，眼神深邃。',
              '"我可以教你在荒野中生存的技巧，"他说。'
            ],
            'notification': '一个沙漠向导到达',
            'buttons': {
              'learn': {
                'text': '学习生存技巧',
                'cost': {'water': 100, 'cured meat': 50},
                'nextScene': 'learn'
              },
              'decline': {'text': '谢绝', 'nextScene': 'end'}
            }
          },
          'learn': {
            'text': ['向导传授了他的生存智慧。'],
            'buttons': {
              'slow_metabolism': {
                'text': '缓慢新陈代谢',
                'available': () {
                  final hasSlowMetabolism =
                      _sm.get('character.perks.slow metabolism', true) ?? false;
                  return !hasSlowMetabolism;
                },
                'onChoose': () {
                  _sm.set('character.perks.slow metabolism', true);
                  Logger.info('🐌 学会了缓慢新陈代谢技能');
                },
                'nextScene': 'end'
              },
              'desert_rat': {
                'text': '沙漠鼠',
                'available': () {
                  final hasDesertRat =
                      _sm.get('character.perks.desert rat', true) ?? false;
                  return !hasDesertRat;
                },
                'onChoose': () {
                  _sm.set('character.perks.desert rat', true);
                  Logger.info('🐭 学会了沙漠鼠技能');
                },
                'nextScene': 'end'
              },
              'stealthy': {
                'text': '潜行',
                'available': () {
                  final hasStealthy =
                      _sm.get('character.perks.stealthy', true) ?? false;
                  return !hasStealthy;
                },
                'onChoose': () {
                  _sm.set('character.perks.stealthy', true);
                  Logger.info('👤 学会了潜行技能');
                },
                'nextScene': 'end'
              },
              'nothing': {'text': '什么都不学', 'nextScene': 'end'}
            }
          }
        }
      };
}
