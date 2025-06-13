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

    // 旧房子
    'house': {
      'title': '旧房子',
      'scenes': {
        'start': {
          'text': ['一座旧房子仍然矗立在这里，曾经白色的壁板已经发黄剥落。', '门敞开着。'],
          'notification': '旧房子的遗迹作为更简单时代的纪念碑矗立着',
          'buttons': {
            'enter': {
              'text': '进入',
              'nextScene': {
                '0.25': 'medicine',
                '0.75': 'supplies',
                '1': 'occupied'
              }
            },
            'leave': {'text': '离开', 'nextScene': 'end'}
          }
        },
        'supplies': {
          'text': ['房子已被遗弃，但尚未被搜刮。', '旧井里还有几滴水。'],
          'onLoad': 'replenishWater',
          'loot': {
            'cured meat': {'min': 1, 'max': 10, 'chance': 0.8},
            'leather': {'min': 1, 'max': 10, 'chance': 0.2},
            'cloth': {'min': 1, 'max': 10, 'chance': 0.5}
          },
          'buttons': {
            'leave': {'text': '离开', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'medicine': {
          'text': ['房子已被洗劫。', '但地板下面藏着一些药剂。'],
          'onLoad': 'markVisited',
          'loot': {
            'medicine': {'min': 2, 'max': 5, 'chance': 1.0}
          },
          'buttons': {
            'leave': {'text': '离开', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'occupied': {
          'combat': true,
          'enemy': 'squatter',
          'chara': 'E',
          'damage': 3,
          'hit': 0.8,
          'attackDelay': 2,
          'health': 10,
          'notification': '一个男人冲下大厅，手里拿着一把生锈的刀片',
          'onLoad': 'markVisited',
          'loot': {
            'cured meat': {'min': 1, 'max': 10, 'chance': 0.8},
            'leather': {'min': 1, 'max': 10, 'chance': 0.2},
            'cloth': {'min': 1, 'max': 10, 'chance': 0.5}
          },
          'buttons': {
            'leave': {'text': '离开', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'end': {
          'text': ['离开了旧房子，回到了荒野中。'],
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'finish'}
          }
        }
      },
      'audio': 'landmark_house'
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
    },

    // 铁矿
    'ironmine': {
      'title': '铁矿',
      'scenes': {
        'start': {
          'text': [
            '一个古老的铁矿坐落在这里，工具被遗弃并生锈。',
            '漂白的骨头散落在入口周围。许多骨头上都有锯齿状的深深凹槽。',
            '野性的嚎叫从黑暗中回荡出来。'
          ],
          'notification': '小径通向一个废弃的矿井',
          'buttons': {
            'enter': {
              'text': '进入',
              'nextScene': {'1': 'enter'},
              'cost': {'torch': 1}
            },
            'leave': {'text': '离开', 'nextScene': 'end'}
          }
        },
        'enter': {
          'combat': true,
          'enemy': 'beastly matriarch',
          'chara': 'T',
          'damage': 4,
          'hit': 0.8,
          'attackDelay': 2,
          'health': 10,
          'loot': {
            'teeth': {'min': 5, 'max': 10, 'chance': 1.0},
            'scales': {'min': 5, 'max': 10, 'chance': 0.8},
            'cloth': {'min': 5, 'max': 10, 'chance': 0.5}
          },
          'notification': '一个大型生物扑来，肌肉在火光中起伏',
          'buttons': {
            'leave': {
              'text': '离开',
              'cooldown': 1,
              'nextScene': {'1': 'cleared'}
            }
          }
        },
        'cleared': {
          'text': ['野兽死了。', '矿井现在对工人来说是安全的。'],
          'notification': '铁矿已清除危险',
          'onLoad': 'clearIronMine',
          'buttons': {
            'leave': {'text': '离开', 'nextScene': 'end'}
          }
        },
        'end': {
          'text': ['离开了铁矿，回到了荒野中。'],
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'finish'}
          }
        }
      },
      'audio': 'landmark_iron_mine'
    },

    // 煤矿
    'coalmine': {
      'title': '煤矿',
      'scenes': {
        'start': {
          'text': ['营火在矿井入口燃烧。', '男人们四处走动，武器准备就绪。'],
          'notification': '这个旧矿井并没有被遗弃',
          'buttons': {
            'attack': {
              'text': '攻击',
              'nextScene': {'1': 'a1'}
            },
            'leave': {'text': '离开', 'nextScene': 'end'}
          }
        },
        'a1': {
          'combat': true,
          'enemy': 'man',
          'chara': 'E',
          'damage': 3,
          'hit': 0.8,
          'attackDelay': 2,
          'health': 10,
          'loot': {
            'cured meat': {'min': 1, 'max': 5, 'chance': 0.8},
            'cloth': {'min': 1, 'max': 5, 'chance': 0.8}
          },
          'notification': '一个男人加入战斗',
          'buttons': {
            'continue': {
              'text': '继续',
              'cooldown': 1,
              'nextScene': {'1': 'a2'}
            },
            'run': {'text': '逃跑', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'a2': {
          'combat': true,
          'enemy': 'man',
          'chara': 'E',
          'damage': 3,
          'hit': 0.8,
          'attackDelay': 2,
          'health': 10,
          'loot': {
            'cured meat': {'min': 1, 'max': 5, 'chance': 0.8},
            'cloth': {'min': 1, 'max': 5, 'chance': 0.8}
          },
          'notification': '一个男人加入战斗',
          'buttons': {
            'continue': {
              'text': '继续',
              'cooldown': 1,
              'nextScene': {'1': 'a3'}
            },
            'run': {'text': '逃跑', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'a3': {
          'combat': true,
          'enemy': 'chief',
          'chara': 'D',
          'damage': 5,
          'hit': 0.8,
          'attackDelay': 2,
          'health': 20,
          'loot': {
            'cured meat': {'min': 5, 'max': 10, 'chance': 1.0},
            'cloth': {'min': 5, 'max': 10, 'chance': 0.8},
            'iron': {'min': 1, 'max': 5, 'chance': 0.8}
          },
          'notification': '只剩下首领了。',
          'buttons': {
            'continue': {
              'text': '继续',
              'cooldown': 1,
              'nextScene': {'1': 'cleared'}
            }
          }
        },
        'cleared': {
          'text': ['营地很安静，只有火焰的噼啪声。', '矿井现在对工人来说是安全的。'],
          'notification': '煤矿已清除危险',
          'onLoad': 'clearCoalMine',
          'buttons': {
            'leave': {'text': '离开', 'nextScene': 'end'}
          }
        },
        'end': {
          'text': ['离开了煤矿，回到了荒野中。'],
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'finish'}
          }
        }
      },
      'audio': 'landmark_coal_mine'
    },

    // 硫磺矿
    'sulphurmine': {
      'title': '硫磺矿',
      'scenes': {
        'start': {
          'text': ['军队已经在矿井入口设立了阵地。', '士兵们在周边巡逻，步枪挂在肩膀上。'],
          'notification': '矿井周围设立了军事警戒线。',
          'buttons': {
            'attack': {
              'text': '攻击',
              'nextScene': {'1': 'a1'}
            },
            'leave': {'text': '离开', 'nextScene': 'end'}
          }
        },
        'a1': {
          'combat': true,
          'enemy': 'soldier',
          'ranged': true,
          'chara': 'D',
          'damage': 8,
          'hit': 0.8,
          'attackDelay': 2,
          'health': 50,
          'loot': {
            'cured meat': {'min': 1, 'max': 5, 'chance': 0.8},
            'bullets': {'min': 1, 'max': 5, 'chance': 0.5},
            'rifle': {'min': 1, 'max': 1, 'chance': 0.2}
          },
          'notification': '一名士兵警觉地开火。',
          'buttons': {
            'continue': {
              'text': '继续',
              'cooldown': 1,
              'nextScene': {'1': 'a2'}
            },
            'run': {'text': '逃跑', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'a2': {
          'combat': true,
          'enemy': 'soldier',
          'ranged': true,
          'chara': 'D',
          'damage': 8,
          'hit': 0.8,
          'attackDelay': 2,
          'health': 50,
          'loot': {
            'cured meat': {'min': 1, 'max': 5, 'chance': 0.8},
            'bullets': {'min': 1, 'max': 5, 'chance': 0.5},
            'rifle': {'min': 1, 'max': 1, 'chance': 0.2}
          },
          'notification': '第二名士兵加入战斗。',
          'buttons': {
            'continue': {
              'text': '继续',
              'cooldown': 1,
              'nextScene': {'1': 'a3'}
            },
            'run': {'text': '逃跑', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'a3': {
          'combat': true,
          'enemy': 'veteran',
          'chara': 'D',
          'damage': 10,
          'hit': 0.8,
          'attackDelay': 2,
          'health': 65,
          'loot': {
            'bayonet': {'min': 1, 'max': 1, 'chance': 0.5},
            'cured meat': {'min': 1, 'max': 5, 'chance': 0.8}
          },
          'notification': '一名老兵挥舞着刺刀攻击。',
          'buttons': {
            'continue': {
              'text': '继续',
              'cooldown': 1,
              'nextScene': {'1': 'cleared'}
            }
          }
        },
        'cleared': {
          'text': ['军事存在已被清除。', '矿井现在对工人来说是安全的。'],
          'notification': '硫磺矿已清除危险',
          'onLoad': 'clearSulphurMine',
          'buttons': {
            'leave': {'text': '离开', 'nextScene': 'end'}
          }
        },
        'end': {
          'text': ['离开了硫磺矿，回到了荒野中。'],
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'finish'}
          }
        }
      },
      'audio': 'landmark_sulphur_mine'
    },

    // 城市
    'city': {
      'title': '废墟城市',
      'scenes': {
        'start': {
          'text': [
            '一块破旧的高速公路标志守卫着这座曾经伟大的城市的入口。',
            '那些没有倒塌的塔楼从景观中突出，就像某种古老野兽的肋骨。',
            '里面可能还有值得拥有的东西。'
          ],
          'notification': '腐朽城市的塔楼主宰着天际线',
          'buttons': {
            'enter': {
              'text': '探索',
              'nextScene': {'0.2': 'a1', '0.5': 'a2', '0.8': 'a3', '1': 'a4'}
            },
            'leave': {'text': '离开', 'nextScene': 'end'}
          }
        },
        'a1': {
          'text': ['街道空无一人。', '空气中弥漫着尘土，被猛烈的风无情地驱赶着。'],
          'buttons': {
            'continue': {
              'text': '继续',
              'nextScene': {'0.5': 'b1', '1': 'b2'}
            },
            'leave': {'text': '离开城市', 'nextScene': 'end'}
          }
        },
        'a2': {
          'text': ['一个小定居点在街道的尽头。', '人们在废墟中搭建了临时住所。'],
          'buttons': {
            'continue': {
              'text': '继续',
              'nextScene': {'0.5': 'b3', '1': 'b4'}
            },
            'leave': {'text': '离开城市', 'nextScene': 'end'}
          }
        },
        'a3': {
          'text': ['一座医院的废墟矗立在前方。', '绿色十字架在肮脏的窗户后面勉强可见。'],
          'buttons': {
            'enter': {
              'text': '进入',
              'cost': {'torch': 1},
              'nextScene': {'0.5': 'b5', '1': 'b6'}
            },
            'leave': {'text': '离开城市', 'nextScene': 'end'}
          }
        },
        'a4': {
          'text': ['地铁入口通向地下。', '台阶消失在黑暗中。'],
          'buttons': {
            'enter': {
              'text': '进入',
              'cost': {'torch': 1},
              'nextScene': {'0.5': 'b7', '1': 'b8'}
            },
            'leave': {'text': '离开城市', 'nextScene': 'end'}
          }
        },
        'b1': {
          'text': ['一个小商店的废墟。', '货架上散落着一些有用的物品。'],
          'loot': {
            'cured meat': {'min': 1, 'max': 5, 'chance': 0.8},
            'cloth': {'min': 1, 'max': 5, 'chance': 0.5},
            'medicine': {'min': 1, 'max': 2, 'chance': 0.1}
          },
          'buttons': {
            'continue': {
              'text': '继续',
              'cooldown': 1,
              'nextScene': {'0.5': 'c1', '1': 'c2'}
            },
            'leave': {'text': '离开城市', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'b2': {
          'combat': true,
          'enemy': 'thug',
          'chara': 'E',
          'damage': 3,
          'hit': 0.8,
          'attackDelay': 2,
          'health': 30,
          'loot': {
            'cloth': {'min': 5, 'max': 10, 'chance': 0.8},
            'leather': {'min': 5, 'max': 10, 'chance': 0.8},
            'cured meat': {'min': 1, 'max': 5, 'chance': 0.5}
          },
          'notification': '一个暴徒从阴影中走出。',
          'buttons': {
            'continue': {
              'text': '继续',
              'cooldown': 1,
              'nextScene': {'0.5': 'c2', '1': 'c3'}
            },
            'leave': {'text': '离开城市', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'end1': {
          'text': ['鸟儿一定喜欢闪亮的东西。', '一些好东西编织在它的巢穴里。'],
          'onLoad': 'clearCity',
          'loot': {
            'bullets': {'min': 5, 'max': 10, 'chance': 0.8},
            'bolas': {'min': 1, 'max': 5, 'chance': 0.5},
            'alien alloy': {'min': 1, 'max': 1, 'chance': 0.5}
          },
          'buttons': {
            'leave': {'text': '离开城市', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'end': {
          'text': ['离开了城市，回到了荒野中。'],
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'finish'}
          }
        }
      },
      'audio': 'landmark_city'
    },

    // 钻孔事件
    'borehole': {
      'title': '巨大的钻孔',
      'scenes': {
        'start': {
          'text': [
            '一个巨大的洞深深地切入地球，这是过去收获的证据。',
            '他们拿走了他们想要的东西，然后离开了。',
            '巨型钻头的废料仍然可以在悬崖边缘找到。'
          ],
          'notification': '一个巨大的钻孔切入大地',
          'onLoad': 'markVisited',
          'loot': {
            'alien alloy': {'min': 1, 'max': 3, 'chance': 1.0}
          },
          'buttons': {
            'leave': {'text': '离开', 'cooldown': 1, 'nextScene': 'end'}
          }
        },
        'end': {
          'text': ['离开了钻孔，回到了荒野中。'],
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'finish'}
          }
        }
      },
      'audio': 'landmark_borehole'
    },

    // 战场事件
    'battlefield': {
      'title': '被遗忘的战场',
      'scenes': {
        'start': {
          'text': ['很久以前，这里发生了一场战斗。', '双方破损的技术设备在荒芜的景观上静静地躺着。'],
          'notification': '古老战场的遗迹散落各处',
          'onLoad': 'markVisited',
          'loot': {
            'rifle': {'min': 1, 'max': 3, 'chance': 0.5},
            'bullets': {'min': 5, 'max': 20, 'chance': 0.8},
            'laser rifle': {'min': 1, 'max': 3, 'chance': 0.3},
            'energy cell': {'min': 5, 'max': 10, 'chance': 0.5},
            'grenade': {'min': 1, 'max': 5, 'chance': 0.5},
            'alien alloy': {'min': 1, 'max': 1, 'chance': 0.3}
          },
          'buttons': {
            'leave': {'text': '离开', 'nextScene': 'end'}
          }
        },
        'end': {
          'text': ['离开了战场，回到了荒野中。'],
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'finish'}
          }
        }
      },
      'audio': 'landmark_battlefield'
    },

    // 星舰事件
    'ship': {
      'title': '坠毁的星舰',
      'scenes': {
        'start': {
          'text': [
            '熟悉的流浪者飞船曲线从尘土和灰烬中升起。',
            '幸运的是，当地人无法操作这些机制。',
            '稍加努力，它可能会再次飞行。'
          ],
          'notification': '发现了一艘坠毁的星舰',
          'onLoad': 'activateShip',
          'buttons': {
            'salvage': {'text': '打捞', 'nextScene': 'end'}
          }
        },
        'end': {
          'text': ['从星舰中获得了有用的部件。'],
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'finish'}
          }
        }
      },
      'audio': 'landmark_crashed_ship'
    },

    // 执行者事件 - 简化版本
    'executioner': {
      'title': '被摧毁的战舰',
      'scenes': {
        'start': {
          'text': [
            '一艘巨大战舰的残骸嵌在地球中。',
            '它在深深的裂缝中倾斜，这是它从天空坠落时切出的。',
            '舱门都被密封了，但船体在泥土上方被炸开，提供了一个入口。'
          ],
          'notification': '巨大战舰的残骸嵌在地球中',
          'buttons': {
            'enter': {
              'text': '进入',
              'cost': {'torch': 1},
              'nextScene': 'interior'
            },
            'leave': {'text': '离开', 'nextScene': 'end'}
          }
        },
        'interior': {
          'text': ['船的内部寒冷而黑暗。仅有的一点光线只会突出其严酷的角度。', '墙壁发出微弱的嗡嗡声。'],
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'discovery'},
            'leave': {'text': '离开', 'nextScene': 'end'}
          }
        },
        'discovery': {
          'text': ['在一个小前厅中，一个奇怪的装置坐在地板上。', '看起来很重要。'],
          'onLoad': 'activateExecutioner',
          'loot': {
            'alien alloy': {'min': 2, 'max': 5, 'chance': 1.0},
            'energy cell': {'min': 3, 'max': 8, 'chance': 0.8},
            'laser rifle': {'min': 1, 'max': 2, 'chance': 0.6}
          },
          'buttons': {
            'take': {'text': '拿取装置并离开', 'nextScene': 'end'}
          }
        },
        'end': {
          'text': ['离开了战舰，回到了荒野中。'],
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'finish'}
          }
        }
      },
      'audio': 'landmark_crashed_ship'
    },

    // 缓存事件 - 当代遗产
    'cache': {
      'title': '被摧毁的村庄',
      'scenes': {
        'start': {
          'text': ['一个被摧毁的村庄躺在尘土中。', '烧焦的尸体散落在地上。'],
          'notification': '空气中弥漫着流浪者加力燃烧器的金属味',
          'buttons': {
            'enter': {'text': '进入', 'nextScene': 'underground'},
            'leave': {'text': '离开', 'nextScene': 'end'}
          }
        },
        'underground': {
          'text': ['在废墟下面发现了一个隐藏的地下室。', '里面存放着前代人留下的补给品。'],
          'onLoad': 'markVisited',
          'loot': {
            'cured meat': {'min': 10, 'max': 20, 'chance': 1.0},
            'fur': {'min': 5, 'max': 15, 'chance': 0.8},
            'scales': {'min': 5, 'max': 10, 'chance': 0.6},
            'iron': {'min': 10, 'max': 30, 'chance': 0.9},
            'coal': {'min': 10, 'max': 30, 'chance': 0.9},
            'wood': {'min': 20, 'max': 50, 'chance': 1.0}
          },
          'buttons': {
            'leave': {'text': '离开', 'nextScene': 'end'}
          }
        },
        'end': {
          'text': ['离开了被摧毁的村庄，回到了荒野中。'],
          'buttons': {
            'continue': {'text': '继续', 'nextScene': 'finish'}
          }
        }
      },
      'audio': 'landmark_destroyed_village'
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

  /// 补充水源并标记已访问
  void replenishWater() {
    World().setWater(World().getMaxWater());
    World().markVisited(World().curPos[0], World().curPos[1]);
    notifyListeners();
  }

  /// 清理铁矿
  void clearIronMine() {
    final sm = StateManager();
    sm.set('game.world.ironmine', true);
    World().markVisited(World().curPos[0], World().curPos[1]);
    notifyListeners();
  }

  /// 清理煤矿
  void clearCoalMine() {
    final sm = StateManager();
    sm.set('game.world.coalmine', true);
    World().markVisited(World().curPos[0], World().curPos[1]);
    notifyListeners();
  }

  /// 清理硫磺矿
  void clearSulphurMine() {
    final sm = StateManager();
    sm.set('game.world.sulphurmine', true);
    World().markVisited(World().curPos[0], World().curPos[1]);
    notifyListeners();
  }

  /// 清理城市
  void clearCity() {
    final sm = StateManager();
    sm.set('game.world.cityCleared', true);
    World().markVisited(World().curPos[0], World().curPos[1]);
    notifyListeners();
  }

  /// 激活星舰
  void activateShip() {
    final sm = StateManager();
    World().markVisited(World().curPos[0], World().curPos[1]);
    World().drawRoad();
    sm.set('game.world.ship', true);
    notifyListeners();
  }

  /// 激活执行者
  void activateExecutioner() {
    final sm = StateManager();
    World().markVisited(World().curPos[0], World().curPos[1]);
    World().drawRoad();
    sm.set('game.world.executioner', true);
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
