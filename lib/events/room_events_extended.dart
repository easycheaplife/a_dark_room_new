import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/logger.dart';
import '../modules/world.dart';
import 'dart:math';
import 'dart:async';

/// 扩展房间事件定义
class RoomEventsExtended {
  static final StateManager _sm = StateManager();

  /// 里面的声音事件
  static Map<String, dynamic> get noisesInside => {
        'title': '声音',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final wood = _sm.get('stores.wood', true) ?? 0;
          return fire > 0 && wood > 0;
        },
        'scenes': {
          'start': {
            'text': ['从储藏室可以听到抓挠的声音。', '里面有什么东西。'],
            'notification': '储藏室里有什么东西',
            'buttons': {
              'investigate': {
                'text': '调查',
                'nextScene': {'0.5': 'scales', '0.8': 'teeth', '1.0': 'cloth'}
              },
              'ignore': {'text': '忽视它们', 'nextScene': 'end'}
            }
          },
          'scales': {
            'text': ['一些木材不见了。', '地上散落着小鳞片'],
            'onLoad': () {
              final numWood = _sm.get('stores.wood', true) ?? 0;
              final lostWood = (numWood * 0.1).floor().clamp(1, numWood);
              final gainedScales = (lostWood / 5).floor().clamp(1, 999);
              _sm.add('stores.wood', -lostWood);
              _sm.add('stores.scales', gainedScales);
            },
            'buttons': {
              'leave': {'text': '离开', 'nextScene': 'end'}
            }
          },
          'teeth': {
            'text': ['一些木材不见了。', '地上散落着小牙齿'],
            'onLoad': () {
              final numWood = _sm.get('stores.wood', true) ?? 0;
              final lostWood = (numWood * 0.1).floor().clamp(1, numWood);
              final gainedTeeth = (lostWood / 5).floor().clamp(1, 999);
              _sm.add('stores.wood', -lostWood);
              _sm.add('stores.teeth', gainedTeeth);
            },
            'buttons': {
              'leave': {'text': '离开', 'nextScene': 'end'}
            }
          },
          'cloth': {
            'text': ['一些木材不见了。', '地上散落着布料碎片'],
            'onLoad': () {
              final numWood = _sm.get('stores.wood', true) ?? 0;
              final lostWood = (numWood * 0.1).floor().clamp(1, numWood);
              final gainedCloth = (lostWood / 5).floor().clamp(1, 999);
              _sm.add('stores.wood', -lostWood);
              _sm.add('stores.cloth', gainedCloth);
            },
            'buttons': {
              'leave': {'text': '离开', 'nextScene': 'end'}
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
            'text': ['一个流浪者带着空车到达。说如果他带着木材离开，他会带着更多回来。', '建造者不确定他是否值得信任。'],
            'notification': '一个神秘的流浪者到达',
            'buttons': {
              'wood100': {
                'text': '给100',
                'cost': {'wood': 100},
                'nextScene': 'wood100'
              },
              'wood500': {
                'text': '给500',
                'cost': {'wood': 500},
                'nextScene': 'wood500'
              },
              'deny': {'text': '拒绝他', 'nextScene': 'end'}
            }
          },
          'wood100': {
            'text': ['流浪者离开了，车上装满了木材'],
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
              'leave': {'text': '告别', 'nextScene': 'end'}
            }
          },
          'wood500': {
            'text': ['流浪者离开了，车上装满了木材'],
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
            'text': ['一个流浪者带着空车到达。说如果她带着毛皮离开，她会带着更多回来。', '建造者不确定她是否值得信任。'],
            'notification': '一个神秘的流浪者到达',
            'buttons': {
              'fur100': {
                'text': '给100',
                'cost': {'fur': 100},
                'nextScene': 'fur100'
              },
              'fur500': {
                'text': '给500',
                'cost': {'fur': 500},
                'nextScene': 'fur500'
              },
              'deny': {'text': '拒绝她', 'nextScene': 'end'}
            }
          },
          'fur100': {
            'text': ['流浪者离开了，车上装满了毛皮'],
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
              'leave': {'text': '告别', 'nextScene': 'end'}
            }
          },
          'fur500': {
            'text': ['流浪者离开了，车上装满了毛皮'],
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
                  Logger.info('💪 学会了力量技能');
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
}
