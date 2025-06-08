import 'package:flutter/material.dart';
import '../core/state_manager.dart';
import 'events.dart';
import 'world.dart';

/// 场景事件模块 - 处理特定时间发生的事件
/// 包括前哨站、沼泽、洞穴、城镇等特殊场景
class Setpieces extends ChangeNotifier {
  static final Setpieces _instance = Setpieces._internal();

  factory Setpieces() {
    return _instance;
  }

  static Setpieces get instance => _instance;

  Setpieces._internal();

  // 模块名称
  final String name = "场景事件";

  /// 场景事件配置
  static const Map<String, Map<String, dynamic>> setpieces = {
    // 友好前哨站
    'outpost': {
      'title': '前哨站',
      'scenes': {
        'start': {
          'text': ['荒野中的安全之地。'],
          'notification': '荒野中的安全之地。',
          'loot': {
            'cured meat': {'min': 5, 'max': 10, 'chance': 1.0}
          },
          'onLoad': 'useOutpost',
          'buttons': {
            'leave': {'text': '离开', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'end': {
          'text': ['离开了前哨站，回到了荒野中。'],
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'finish'}
          }
        }
      },
      'audio': 'landmark_friendly_outpost'
    },

    // 阴暗沼泽
    'swamp': {
      'title': '阴暗沼泽',
      'scenes': {
        'start': {
          'text': ['腐烂的芦苇从沼泽地里长出来。', '一只孤独的青蛙静静地坐在泥泞中。'],
          'notification': '沼泽在停滞的空气中腐烂。',
          'buttons': {
            'enter': {
              'text': '进入',
              'nextScene': {'1': 'cabin'}
            },
            'leave': {'text': '离开', 'nextScene': 'end'}
          }
        },
        'cabin': {
          'text': ['沼泽深处有一间长满苔藓的小屋。', '一个老流浪者坐在里面，似乎在恍惚中。'],
          'buttons': {
            'talk': {
              'cost': {'charm': 1},
              'text': '交谈',
              'nextScene': {'1': 'talk'}
            },
            'leave': {'text': '离开', 'nextScene': 'end'}
          }
        },
        'talk': {
          'text': [
            '流浪者接过护身符，慢慢点头。',
            '他说起曾经带领伟大的舰队前往新世界。',
            '为了满足流浪者的饥饿而进行的不可理解的破坏。',
            '他在这里的时间，现在，是他的忏悔。'
          ],
          'onLoad': 'addGastronomePerk',
          'buttons': {
            'leave': {'text': '离开', 'nextScene': 'end'}
          }
        }
      },
      'audio': 'landmark_swamp'
    },

    // 潮湿洞穴
    'cave': {
      'title': '潮湿洞穴',
      'scenes': {
        'start': {
          'text': ['洞穴的入口又宽又黑。', '看不清里面有什么。'],
          'notification': '这里的大地裂开了，仿佛承受着古老的伤口',
          'buttons': {
            'enter': {
              'text': '进入',
              'cost': {'torch': 1},
              'nextScene': {'0.3': 'a1', '0.6': 'a2', '1': 'a3'}
            },
            'leave': {'text': '离开', 'nextScene': 'end'}
          }
        },
        'a1': {
          'combat': true,
          'enemy': 'beast',
          'chara': 'R',
          'damage': 1,
          'hit': 0.8,
          'attackDelay': 1,
          'health': 5,
          'notification': '一只受惊的野兽保卫着它的家',
          'loot': {
            'fur': {'min': 1, 'max': 10, 'chance': 1.0},
            'teeth': {'min': 1, 'max': 5, 'chance': 0.8}
          },
          'buttons': {
            'continue': {
              'text': '继续',
              'cooldown': 1,
              'nextScene': {'0.5': 'b1', '1': 'b2'}
            },
            'leave': {'text': '离开洞穴', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'a2': {
          'text': ['洞穴在几英尺处变窄。', '墙壁潮湿，长满苔藓'],
          'buttons': {
            'continue': {
              'text': '挤过去',
              'nextScene': {'0.5': 'b2', '1': 'b3'}
            },
            'leave': {'text': '离开洞穴', 'nextScene': 'end'}
          }
        },
        'a3': {
          'text': ['一个旧营地的遗迹就在洞穴里面。', '床铺，撕裂和发黑，躺在一层薄薄的灰尘下面。'],
          'loot': {
            'cured meat': {'min': 1, 'max': 5, 'chance': 1.0},
            'torch': {'min': 1, 'max': 5, 'chance': 0.5},
            'leather': {'min': 1, 'max': 5, 'chance': 0.3}
          },
          'buttons': {
            'continue': {
              'text': '继续',
              'cooldown': 1,
              'nextScene': {'0.5': 'b3', '1': 'b4'}
            },
            'leave': {'text': '离开洞穴', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'b1': {
          'text': ['一个流浪者的尸体躺在一个小洞穴里。', '腐烂已经开始了，有些部分不见了。', '不知道是什么把它留在这里的。'],
          'loot': {
            'cloth': {'min': 5, 'max': 10, 'chance': 1.0},
            'leather': {'min': 5, 'max': 10, 'chance': 0.8},
            'cured meat': {'min': 1, 'max': 5, 'chance': 0.5}
          },
          'buttons': {
            'continue': {
              'text': '继续',
              'cooldown': 1,
              'nextScene': {'1': 'c1'}
            },
            'leave': {'text': '离开洞穴', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'b2': {
          'text': ['洞穴深处一片漆黑。', '火把的光芒在潮湿的墙壁上跳舞。'],
          'buttons': {
            'continue': {
              'text': '继续',
              'cost': {'torch': 1},
              'nextScene': {'1': 'c1'}
            },
            'leave': {'text': '离开洞穴', 'nextScene': 'end'}
          }
        },
        'b3': {
          'text': ['洞穴分叉了。', '左边的通道很窄，右边的通道更宽。'],
          'buttons': {
            'continue': {
              'text': '继续',
              'cooldown': 1,
              'nextScene': {'1': 'c2'}
            },
            'leave': {'text': '离开洞穴', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'b4': {
          'combat': true,
          'enemy': 'cave lizard',
          'chara': 'R',
          'damage': 3,
          'hit': 0.8,
          'attackDelay': 2,
          'health': 6,
          'notification': '一只洞穴蜥蜴攻击',
          'loot': {
            'scales': {'min': 1, 'max': 3, 'chance': 1.0},
            'teeth': {'min': 1, 'max': 2, 'chance': 0.5}
          },
          'buttons': {
            'continue': {
              'text': '继续',
              'cooldown': 1,
              'nextScene': {'1': 'c2'}
            },
            'leave': {'text': '离开洞穴', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'c1': {
          'text': ['洞穴在这里变得更深。', '空气变得更加潮湿和寒冷。'],
          'buttons': {
            'continue': {
              'text': '继续',
              'cooldown': 1,
              'nextScene': {'0.5': 'end1', '1': 'end2'}
            },
            'leave': {'text': '离开洞穴', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'c2': {
          'text': ['洞穴的尽头就在前方。', '微弱的光线从裂缝中透进来。'],
          'buttons': {
            'continue': {
              'text': '继续',
              'cooldown': 1,
              'nextScene': {'0.7': 'end2', '1': 'end3'}
            },
            'leave': {'text': '离开洞穴', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'end1': {
          'text': ['一个大型动物的巢穴位于洞穴的后面。'],
          'onLoad': 'clearDungeon',
          'loot': {
            'meat': {'min': 5, 'max': 10, 'chance': 1.0},
            'fur': {'min': 5, 'max': 10, 'chance': 1.0},
            'scales': {'min': 5, 'max': 10, 'chance': 1.0},
            'teeth': {'min': 5, 'max': 10, 'chance': 1.0},
            'cloth': {'min': 5, 'max': 10, 'chance': 0.5}
          },
          'buttons': {
            'leave': {'text': '离开洞穴', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'end2': {
          'text': ['一个小的补给缓存隐藏在洞穴的后面。'],
          'onLoad': 'clearDungeon',
          'loot': {
            'cloth': {'min': 5, 'max': 10, 'chance': 1.0},
            'leather': {'min': 5, 'max': 10, 'chance': 1.0},
            'iron': {'min': 5, 'max': 10, 'chance': 1.0},
            'cured meat': {'min': 5, 'max': 10, 'chance': 1.0},
            'steel': {'min': 5, 'max': 10, 'chance': 0.5},
            'bolas': {'min': 1, 'max': 3, 'chance': 0.3},
            'medicine': {'min': 1, 'max': 4, 'chance': 0.15}
          },
          'buttons': {
            'leave': {'text': '离开洞穴', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'end3': {
          'text': ['一个旧箱子被楔在岩石后面，覆盖着厚厚的灰尘层。'],
          'onLoad': 'clearDungeon',
          'loot': {
            'steel sword': {'min': 1, 'max': 1, 'chance': 1.0},
            'bolas': {'min': 1, 'max': 3, 'chance': 0.5},
            'medicine': {'min': 1, 'max': 3, 'chance': 0.3}
          },
          'buttons': {
            'leave': {'text': '离开洞穴', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'end': {
          'text': ['离开了洞穴，回到了荒野中。'],
          'onLoad': 'markVisited',
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'finish'}
          }
        }
      },
      'audio': 'landmark_cave'
    },

    // 废弃城镇
    'town': {
      'title': '废弃城镇',
      'scenes': {
        'start': {
          'text': ['前方是一个小郊区，空房子被烧焦和剥落。', '破碎的路灯矗立着，生锈。光明很久没有照耀过这个地方了。'],
          'notification': '城镇被遗弃，居民早已死去',
          'buttons': {
            'enter': {
              'text': '探索',
              'nextScene': {'0.3': 'a1', '0.7': 'a3', '1': 'a2'}
            },
            'leave': {'text': '离开', 'nextScene': 'end'}
          }
        },
        'a1': {
          'text': ['学校的窗户没有破碎的地方，都被烟灰熏黑了。', '双扇门在风中不停地吱吱作响。'],
          'buttons': {
            'enter': {
              'text': '进入',
              'nextScene': {'0.5': 'b1', '1': 'b2'},
              'cost': {'torch': 1}
            },
            'leave': {'text': '离开城镇', 'nextScene': 'end'}
          }
        },
        'a2': {
          'combat': true,
          'enemy': 'thug',
          'chara': 'E',
          'damage': 4,
          'hit': 0.8,
          'attackDelay': 2,
          'health': 30,
          'loot': {
            'cloth': {'min': 5, 'max': 10, 'chance': 0.8},
            'leather': {'min': 5, 'max': 10, 'chance': 0.8},
            'cured meat': {'min': 1, 'max': 5, 'chance': 0.5}
          },
          'notification': '在街上遭到伏击。',
          'buttons': {
            'continue': {
              'text': '继续',
              'cooldown': 1,
              'nextScene': {'0.5': 'b3', '1': 'b4'}
            },
            'leave': {'text': '离开城镇', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'a3': {
          'text': ['一座废弃的商店，门窗都被木板封住了。'],
          'loot': {
            'cured meat': {'min': 1, 'max': 3, 'chance': 0.8},
            'cloth': {'min': 2, 'max': 5, 'chance': 0.6}
          },
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'end'},
            'leave': {'text': '离开城镇', 'nextScene': 'end'}
          }
        },
        'b1': {
          'text': ['学校里空荡荡的，只有灰尘和破碎的桌椅。'],
          'loot': {
            'cloth': {'min': 3, 'max': 8, 'chance': 1.0},
            'cured meat': {'min': 1, 'max': 2, 'chance': 0.3}
          },
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'end'},
            'leave': {'text': '离开城镇', 'nextScene': 'end'}
          }
        },
        'b2': {
          'text': ['在学校的角落里发现了一些有用的物品。'],
          'loot': {
            'medicine': {'min': 1, 'max': 2, 'chance': 0.5},
            'cloth': {'min': 5, 'max': 10, 'chance': 1.0}
          },
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'end'},
            'leave': {'text': '离开城镇', 'nextScene': 'end'}
          }
        },
        'b3': {
          'text': ['街道上散落着各种废弃物品。'],
          'loot': {
            'iron': {'min': 2, 'max': 5, 'chance': 0.7},
            'leather': {'min': 1, 'max': 3, 'chance': 0.5}
          },
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'end'},
            'leave': {'text': '离开城镇', 'nextScene': 'end'}
          }
        },
        'b4': {
          'text': ['在一栋房子里发现了一个小储藏室。'],
          'loot': {
            'cured meat': {'min': 3, 'max': 8, 'chance': 1.0},
            'medicine': {'min': 1, 'max': 3, 'chance': 0.4},
            'steel': {'min': 1, 'max': 2, 'chance': 0.2}
          },
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'end'},
            'leave': {'text': '离开城镇', 'nextScene': 'end'}
          }
        },
        'end': {
          'text': ['离开了废弃的城镇，回到了荒野中。'],
          'onLoad': 'markVisited',
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'finish'}
          }
        }
      },
      'audio': 'landmark_town'
    }
  };

  /// 启动场景事件
  void startSetpiece(String setpieceName) {
    final setpiece = setpieces[setpieceName];
    if (setpiece == null) return;

    // 创建事件并启动
    final event = {
      'title': setpiece['title'],
      'scenes': setpiece['scenes'],
      'audio': setpiece['audio'],
    };

    Events().startEvent(event);
    notifyListeners();
  }

  /// 使用前哨站
  void useOutpost() {
    World().useOutpost();
    notifyListeners();
  }

  /// 添加美食家技能
  void addGastronomePerk() {
    final sm = StateManager();
    sm.set('character.perks.gastronome', true);
    World().markVisited(World().curPos[0], World().curPos[1]);
    notifyListeners();
  }

  /// 清除地牢
  void clearDungeon() {
    World().clearDungeon();
    notifyListeners();
  }

  /// 标记当前位置为已访问
  void markVisited() {
    World().markVisited(World().curPos[0], World().curPos[1]);
    notifyListeners();
  }

  /// 获取可用的场景事件
  List<String> getAvailableSetpieces() {
    return setpieces.keys.toList();
  }

  /// 获取场景事件信息
  Map<String, dynamic>? getSetpieceInfo(String setpieceName) {
    return setpieces[setpieceName];
  }

  /// 检查场景事件是否可用
  bool isSetpieceAvailable(String setpieceName) {
    return setpieces.containsKey(setpieceName);
  }

  /// 获取场景事件状态
  Map<String, dynamic> getSetpiecesStatus() {
    return {
      'availableSetpieces': getAvailableSetpieces(),
      'totalSetpieces': setpieces.length,
    };
  }
}
