import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/logger.dart';
import 'dart:math';

/// 扩展外部事件定义
class OutsideEventsExtended {
  static final StateManager _sm = StateManager();

  /// 疾病事件
  static Map<String, dynamic> get sickness => {
        'title': '疾病',
        'isAvailable': () {
          final population = _sm.get('game.population', true) ?? 0;
          return population > 10;
        },
        'scenes': {
          'start': {
            'text': ['疾病在村民中传播。', '他们需要药品。'],
            'notification': '疾病在村民中传播',
            'buttons': {
              'medicine': {
                'text': '使用药品',
                'cost': {'medicine': 5},
                'nextScene': 'cured'
              },
              'wait': {'text': '等待', 'nextScene': 'wait'}
            }
          },
          'cured': {
            'text': ['药品治愈了疾病。', '村民们康复了。'],
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          },
          'wait': {
            'text': ['疾病夺走了一些生命。', '村民们哀悼死者。'],
            'onLoad': () {
              final population = _sm.get('game.population', true) ?? 0;
              final lostPop = (population * 0.1).floor().clamp(1, 10);
              final newPop = (population - lostPop).clamp(0, population);
              _sm.set('game.population', newPop);
              Logger.info('🦠 疾病损失: $lostPop个村民');
            },
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 瘟疫事件
  static Map<String, dynamic> get plague => {
        'title': '瘟疫',
        'isAvailable': () {
          final population = _sm.get('game.population', true) ?? 0;
          return population > 50;
        },
        'scenes': {
          'start': {
            'text': ['一场可怕的瘟疫席卷村庄。', '死亡人数不断上升。'],
            'notification': '瘟疫席卷村庄',
            'buttons': {
              'buyMedicine': {
                'text': '购买药品',
                'cost': {'scales': 50},
                'reward': {'medicine': 10},
                'nextScene': 'buyMedicine'
              },
              'useMedicine': {
                'text': '使用药品',
                'cost': {'medicine': 15},
                'nextScene': 'useMedicine'
              },
              'wait': {'text': '等待', 'nextScene': 'wait'}
            }
          },
          'buyMedicine': {
            'text': ['商人们带来了药品。', '但瘟疫仍在蔓延。'],
            'buttons': {
              'useMedicine': {
                'text': '使用药品',
                'cost': {'medicine': 15},
                'nextScene': 'useMedicine'
              },
              'wait': {'text': '等待', 'nextScene': 'wait'}
            }
          },
          'useMedicine': {
            'text': ['药品减缓了瘟疫的传播。', '许多生命得到了拯救。'],
            'onLoad': () {
              final population = _sm.get('game.population', true) ?? 0;
              final lostPop = (population * 0.05).floor().clamp(1, 5);
              final newPop = (population - lostPop).clamp(0, population);
              _sm.set('game.population', newPop);
              Logger.info('💊 瘟疫损失(已治疗): $lostPop个村民');
            },
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          },
          'wait': {
            'text': ['瘟疫肆虐村庄。', '许多村民死去。'],
            'onLoad': () {
              final population = _sm.get('game.population', true) ?? 0;
              final lostPop = (population * 0.3).floor().clamp(5, 20);
              final newPop = (population - lostPop).clamp(0, population);
              _sm.set('game.population', newPop);
              Logger.info('☠️ 瘟疫损失(未治疗): $lostPop个村民');
            },
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 野兽袭击事件
  static Map<String, dynamic> get beastAttack => {
        'title': '野兽袭击',
        'isAvailable': () {
          final population = _sm.get('game.population', true) ?? 0;
          return population > 0;
        },
        'scenes': {
          'start': {
            'text': ['一群野兽袭击了村庄。', '村民们在战斗。'],
            'notification': '野兽袭击村庄',
            'buttons': {
              'fight': {
                'text': '战斗',
                'nextScene': {'0.6': 'win', '1.0': 'lose'}
              },
              'hide': {'text': '躲藏', 'nextScene': 'hide'}
            }
          },
          'win': {
            'text': ['村民们击退了野兽。', '战利品散落在地上。'],
            'reward': {'fur': 100, 'meat': 100, 'teeth': 10},
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          },
          'lose': {
            'text': ['野兽们造成了重大伤亡。', '村民们哀悼死者。'],
            'onLoad': () {
              final population = _sm.get('game.population', true) ?? 0;
              final lostPop = Random().nextInt(5) + 3; // 3-7个村民
              final newPop = (population - lostPop).clamp(0, population);
              _sm.set('game.population', newPop);
              Logger.info('🐺 野兽袭击损失: $lostPop个村民');
            },
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          },
          'hide': {
            'text': ['村民们躲在小屋里。', '野兽们破坏了一些建筑后离开了。'],
            'onLoad': () {
              final huts = _sm.get('game.buildings.hut', true) ?? 0;
              if (huts > 0) {
                final lostHuts = Random().nextInt(2) + 1; // 1-2个小屋
                final newHuts = (huts - lostHuts).clamp(0, huts);
                _sm.set('game.buildings.hut', newHuts);
                Logger.info('🏠 野兽破坏: $lostHuts个小屋');
              }
            },
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 军事突袭事件
  static Map<String, dynamic> get militaryRaid => {
        'title': '军事突袭',
        'isAvailable': () {
          final population = _sm.get('game.population', true) ?? 0;
          final cityCleared = _sm.get('game.cityCleared', true) ?? false;
          return population > 100 && !cityCleared;
        },
        'scenes': {
          'start': {
            'text': ['士兵们包围了村庄。', '他们要求投降。'],
            'notification': '士兵们包围了村庄',
            'buttons': {
              'fight': {
                'text': '战斗',
                'nextScene': {'0.3': 'win', '1.0': 'lose'}
              },
              'surrender': {'text': '投降', 'nextScene': 'surrender'}
            }
          },
          'win': {
            'text': ['村民们击退了士兵。', '缴获了他们的装备。'],
            'reward': {'rifle': 5, 'bullets': 100, 'steel': 50},
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          },
          'lose': {
            'text': ['士兵们占领了村庄。', '许多村民被杀或被俘。'],
            'onLoad': () {
              final population = _sm.get('game.population', true) ?? 0;
              final lostPop = (population * 0.5).floor().clamp(10, 50);
              final newPop = (population - lostPop).clamp(0, population);
              _sm.set('game.population', newPop);
              Logger.info('⚔️ 军事突袭损失: $lostPop个村民');
            },
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          },
          'surrender': {
            'text': ['士兵们占领了村庄。', '他们拿走了大部分资源。'],
            'onLoad': () {
              // 失去大部分资源
              final resources = ['wood', 'fur', 'meat', 'iron', 'steel'];
              for (final resource in resources) {
                final amount = _sm.get('stores.$resource', true) ?? 0;
                final lost = (amount * 0.7).floor();
                _sm.add('stores.$resource', -lost);
              }
              Logger.info('💰 军事突袭损失: 70%的资源');
            },
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          }
        }
      };
}
