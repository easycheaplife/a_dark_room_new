import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/logger.dart';
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
        RoomEventsExtended.sickMan,
        straycat,
        wounded,
        stranger,
      ];

  /// 守火人事件
  static Map<String, dynamic> get firekeeper => {
        'title': '守火人',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final builderLevel = _sm.get('game.builder.level', true) ?? -1;
          return fire > 0 && builderLevel < 0; // 有火但还没有建造者
        },
        'scenes': {
          'start': {
            'text': ['火光在黑暗中摇曳。', '一个身影从阴影中走出。', '建造者已经到来。'],
            'notification': '建造者已经到来',
            'onLoad': () {
              // 解锁建造者
              _sm.set('game.builder.level', 0);
              Logger.info('🔨 建造者已解锁');
            },
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 建造者升级事件
  static Map<String, dynamic> get builder => {
        'title': '建造者',
        'isAvailable': () {
          final builderLevel = _sm.get('game.builder.level', true) ?? -1;
          final temperature = _sm.get('game.temperature.value', true) ?? 0;
          return builderLevel >= 0 &&
              builderLevel < 4 &&
              temperature >= 2; // 建造者存在且温度适宜
        },
        'scenes': {
          'start': {
            'text': ['建造者看起来更加熟练了。', '他开始制作更复杂的工具。'],
            'notification': '建造者技能提升',
            'onLoad': () {
              final currentLevel = _sm.get('game.builder.level', true) ?? 0;
              if (currentLevel < 4) {
                _sm.set('game.builder.level', currentLevel + 1);
                Logger.info('🔨 建造者等级提升到: ${currentLevel + 1}');
              }
            },
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 流浪猫事件
  static Map<String, dynamic> get straycat => {
        'title': '流浪猫',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final meat = _sm.get('stores.meat', true) ?? 0;
          return fire > 0 && meat >= 10; // 需要火和一些肉
        },
        'scenes': {
          'start': {
            'text': ['一只瘦弱的猫咪走向火堆。', '它看起来很饿，用期待的眼神看着你。', '也许它闻到了肉的味道。'],
            'buttons': {
              'feed': {
                'text': '喂食',
                'cost': {'meat': 10},
                'nextScene': 'feed'
              },
              'ignore': {'text': '忽视', 'nextScene': 'ignore'}
            }
          },
          'feed': {
            'text': ['猫咪感激地吃着你给的肉。', '它满足地蜷缩在火堆旁。', '从此以后，它成为了你忠实的伙伴。'],
            'reward': {'charm': 1},
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          },
          'ignore': {
            'text': ['猫咪失望地离开了。', '它消失在黑暗中，再也没有回来。'],
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 受伤的人事件
  static Map<String, dynamic> get wounded => {
        'title': '受伤的人',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final cloth = _sm.get('stores.cloth', true) ?? 0;
          return fire > 0 && cloth >= 5; // 需要火和布料
        },
        'scenes': {
          'start': {
            'text': ['一个受伤的人拖着沉重的脚步走向火堆。', '他的手臂在流血，需要包扎。', '"请帮帮我..."他虚弱地说道。'],
            'buttons': {
              'help': {
                'text': '帮助他',
                'cost': {'cloth': 5},
                'nextScene': 'help'
              },
              'refuse': {'text': '拒绝帮助', 'nextScene': 'refuse'}
            }
          },
          'help': {
            'text': ['你用布料为他包扎伤口。', '他感激地看着你。', '"谢谢你救了我的命。这是我仅有的，请收下。"'],
            'reward': {'scales': 2, 'teeth': 3},
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          },
          'refuse': {
            'text': ['你选择不帮助这个受伤的人。', '他失望地离开了，血迹斑斑。', '你感到良心不安。'],
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 陌生人事件
  static Map<String, dynamic> get stranger => {
        'title': '陌生人',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final wood = _sm.get('stores.wood', true) ?? 0;
          return fire > 0 && wood >= 200; // 需要火和大量木材
        },
        'scenes': {
          'start': {
            'text': [
              '一个陌生人出现在火堆旁。',
              '他穿着厚重的斗篷，看不清面容。',
              '"我需要一些木材来修理我的工具，"他说，"我可以给你一些回报。"'
            ],
            'buttons': {
              'trade': {
                'text': '交易',
                'cost': {'wood': 200},
                'nextScene': 'trade'
              },
              'decline': {'text': '拒绝', 'nextScene': 'decline'}
            }
          },
          'trade': {
            'text': ['陌生人接过木材，从斗篷下取出一些物品。', '"这些应该对你有用，"他说着消失在黑暗中。'],
            'reward': {'iron': 10, 'leather': 5, 'fur': 15},
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          },
          'decline': {
            'text': ['陌生人点点头，没有说什么。', '他转身离开，消失在夜色中。'],
            'buttons': {
              'continue': {'text': '继续', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 游牧商人事件
  static Map<String, dynamic> get nomad => {
        'title': '游牧商人',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final fur = _sm.get('stores.fur', true) ?? 0;
          return fire > 0 && fur > 0; // 需要火和毛皮
        },
        'scenes': {
          'start': {
            'text': [
              '一个游牧商人拖着简陋的行囊走进视野，身上绑着粗糙的麻绳制成的袋子。',
              '不愿说出他来自何方，但显然他不会久留。'
            ],
            'notification': '一个游牧商人到达，想要交易',
            'buttons': {
              'buyScales': {
                'text': '购买鳞片',
                'cost': {'fur': 100},
                'reward': {'scales': 1}
              },
              'buyTeeth': {
                'text': '购买牙齿',
                'cost': {'fur': 200},
                'reward': {'teeth': 1}
              },
              'buyBait': {
                'text': '购买诱饵',
                'cost': {'fur': 5},
                'reward': {'bait': 1},
                'notification': '有了诱饵，陷阱会更有效。'
              },
              'buyCompass': {
                'text': '购买指南针',
                'cost': {'fur': 300, 'scales': 15, 'teeth': 5},
                'reward': {'compass': 1},
                'available': () => (_sm.get('stores.compass', true) ?? 0) < 1,
                'notification': '这个旧指南针有些凹痕和灰尘，但看起来还能用。'
              },
              'goodbye': {'text': '告别', 'nextScene': 'end'}
            }
          }
        }
      };

  /// 外面的声音事件
  static Map<String, dynamic> get noisesOutside => {
        'title': '声音',
        'isAvailable': () {
          final fire = _sm.get('game.fire.value', true) ?? 0;
          final wood = _sm.get('stores.wood', true) ?? 0;
          return fire > 0 && wood > 0;
        },
        'scenes': {
          'start': {
            'text': ['透过墙壁，可以听到窸窸窣窣的声音。', '不知道它们在做什么。'],
            'notification': '透过墙壁可以听到奇怪的声音',
            'buttons': {
              'investigate': {
                'text': '调查',
                'nextScene': {'0.3': 'stuff', '1.0': 'nothing'}
              },
              'ignore': {'text': '忽视它们', 'nextScene': 'end'}
            }
          },
          'nothing': {
            'text': ['模糊的形状在移动，就在视线之外。', '声音停止了。'],
            'buttons': {
              'backinside': {'text': '回到屋内', 'nextScene': 'end'}
            }
          },
          'stuff': {
            'reward': {'wood': 100, 'fur': 10},
            'text': ['门槛外放着一捆木棍，用粗糙的毛皮包着。', '夜晚很安静。'],
            'buttons': {
              'backinside': {'text': '回到屋内', 'nextScene': 'end'}
            }
          }
        }
      };
}
