import '../core/state_manager.dart';
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
  static Map<String, dynamic> get mysteriousStranger => {
        'title': '神秘流浪者',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final wood = _sm.get('stores.wood', true) ?? 0;
          return fire > 0 && wood > 0; // 需要有火和木材
        },
        'scenes': {
          'start': {
            'text': ['一个神秘的陌生人从黑暗中走来。', '他的眼中闪烁着奇异的光芒。', '"我有些东西可能对你有用。"他说道。'],
            'buttons': {
              'talk': {'text': '与他交谈', 'nextScene': 'talk'},
              'ignore': {'text': '忽视他', 'nextScene': 'ignore'}
            }
          },
          'talk': {
            'text': ['陌生人微笑着从袍子里取出一些物品。', '"这些可能在你的旅程中派上用场。"'],
            'reward': {'wood': 100, 'fur': 10, 'meat': 5},
            'buttons': {
              'thank': {'text': '感谢他', 'nextScene': 'end'}
            }
          },
          'ignore': {
            'text': ['你选择忽视这个陌生人。', '他摇摇头，消失在黑暗中。', '也许你错过了什么重要的东西。'],
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 游牧部落事件
  static Map<String, dynamic> get nomadicTribe => {
        'title': '游牧部落',
        'isAvailable': () {
          final huts = _sm.get('game.buildings.hut', true) ?? 0;
          return huts >= 3; // 需要至少3个小屋
        },
        'scenes': {
          'start': {
            'text': ['一个游牧部落在你的村庄附近扎营。', '他们看起来很友善，想要进行贸易。'],
            'buttons': {
              'trade': {
                'text': '与他们交易',
                'cost': {'fur': 50},
                'nextScene': 'trade'
              },
              'decline': {'text': '拒绝交易', 'nextScene': 'decline'}
            }
          },
          'trade': {
            'text': ['部落的首领很高兴与你交易。', '他们给了你一些珍贵的物品作为回报。'],
            'reward': {'scales': 5, 'teeth': 10, 'cloth': 3},
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          },
          'decline': {
            'text': ['部落的人们看起来有些失望。', '他们收拾行装，继续他们的旅程。'],
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 病人事件
  static Map<String, dynamic> get sickMan => {
        'title': '病人',
        'isAvailable': () {
          final medicine = _sm.get('stores.medicine', true) ?? 0;
          return medicine > 0; // 需要有药品
        },
        'scenes': {
          'start': {
            'text': [
              '一个生病的男人蹒跚着走向你的火堆。',
              '他看起来很虚弱，急需医疗帮助。',
              '"请帮帮我..."他虚弱地说道。'
            ],
            'buttons': {
              'help': {
                'text': '帮助他',
                'cost': {'medicine': 1},
                'nextScene': 'help'
              },
              'turnAway': {'text': '拒绝帮助', 'nextScene': 'turnAway'}
            }
          },
          'help': {
            'text': ['你给了他一些药品。', '他的脸色很快好转了。', '"谢谢你！"他感激地说，"让我给你一些回报。"'],
            'reward': {'scales': 3, 'teeth': 5},
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          },
          'turnAway': {
            'text': ['你选择不帮助这个病人。', '他失望地离开了。', '你感到有些内疚。'],
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 拾荒者事件
  static Map<String, dynamic> get scavenger => {
        'title': '拾荒者',
        'isAvailable': () {
          final wood = _sm.get('stores.wood', true) ?? 0;
          return wood >= 500; // 需要大量木材
        },
        'scenes': {
          'start': {
            'text': ['一个拾荒者带着一车废料来到你的村庄。', '"我有一些有用的东西，"他说，"但我需要木材来修理我的车。"'],
            'buttons': {
              'trade': {
                'text': '用木材交换',
                'cost': {'wood': 500},
                'nextScene': 'trade'
              },
              'refuse': {'text': '拒绝交易', 'nextScene': 'refuse'}
            }
          },
          'trade': {
            'text': ['拾荒者很高兴地接受了你的木材。', '他从车上卸下了一些有用的物品。'],
            'reward': {'iron': 20, 'coal': 10, 'steel': 5},
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          },
          'refuse': {
            'text': ['拾荒者耸耸肩，继续他的旅程。', '也许你错过了一个好机会。'],
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 乞丐事件
  static Map<String, dynamic> get beggar => {
        'title': '乞丐',
        'isAvailable': () {
          final meat = _sm.get('stores.meat', true) ?? 0;
          return meat >= 100; // 需要足够的肉
        },
        'scenes': {
          'start': {
            'text': ['一个饥饿的乞丐来到你的村庄。', '"我已经好几天没吃东西了，"他恳求道，"能给我一些食物吗？"'],
            'buttons': {
              'give': {
                'text': '给他食物',
                'cost': {'meat': 100},
                'nextScene': 'give'
              },
              'refuse': {'text': '拒绝给予', 'nextScene': 'refuse'}
            }
          },
          'give': {
            'text': ['乞丐感激地接受了食物。', '"愿神明保佑你的善良，"他说，"我没有什么可以回报的，但请接受这个。"'],
            'reward': {'charm': 1},
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          },
          'refuse': {
            'text': ['乞丐失望地离开了。', '你看着他消失在远方。'],
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 小偷事件
  static Map<String, dynamic> get thief => {
        'title': '小偷',
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
            'text': ['夜深人静时，你听到了可疑的声音。', '一个小偷正试图偷取你的物资！'],
            'buttons': {
              'chase': {'text': '追赶小偷', 'nextScene': 'chase'},
              'ignore': {'text': '假装没看见', 'nextScene': 'ignore'}
            }
          },
          'chase': {
            'text': ['你成功抓住了小偷。', '他恳求你的宽恕，并交出了偷来的东西。', '作为补偿，他还给了你一些额外的物品。'],
            'reward': {'fur': 20, 'leather': 10},
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          },
          'ignore': {
            'text': ['你选择忽视小偷。', '第二天早上，你发现一些物资不见了。'],
            'cost': {'wood': 50, 'fur': 10, 'meat': 20},
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          }
        }
      };
}
