import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/logger.dart';

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
  ];

  /// 商队事件
  static Map<String, dynamic> get convoy => {
    'title': '商队',
    'isAvailable': () {
      final tradingPost = _sm.get('game.buildings.trading post', true) ?? 0;
      return tradingPost > 0; // 需要贸易站
    },
    'scenes': {
      'start': {
        'text': [
          '一支商队出现在地平线上。',
          '他们的马车装满了货物。',
          '商队首领走向你，想要进行贸易。'
        ],
        'buttons': {
          'trade': {
            'text': '交易',
            'nextScene': 'trade'
          },
          'attack': {
            'text': '袭击商队',
            'nextScene': 'attack'
          },
          'ignore': {
            'text': '忽视',
            'nextScene': 'ignore'
          }
        }
      },
      'trade': {
        'text': [
          '商队首领很高兴与你交易。',
          '你们进行了一次公平的交换。'
        ],
        'cost': {
          'fur': 100,
          'meat': 50
        },
        'reward': {
          'bullets': 20,
          'medicine': 3,
          'steel': 10
        },
        'buttons': {
          'continue': {
            'text': '继续',
            'nextScene': 'end'
          }
        }
      },
      'attack': {
        'text': [
          '你决定袭击商队。',
          '这是一个危险的决定...'
        ],
        'nextScene': 'combat'
      },
      'ignore': {
        'text': [
          '商队继续他们的旅程。',
          '也许你错过了一个好机会。'
        ],
        'buttons': {
          'continue': {
            'text': '继续',
            'nextScene': 'end'
          }
        }
      },
      'combat': {
        'combat': true,
        'enemy': '商队护卫',
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
    'title': '袭击者',
    'isAvailable': () {
      final population = _sm.get('game.population', true) ?? 0;
      return population >= 10; // 需要一定人口才会吸引袭击者
    },
    'scenes': {
      'start': {
        'text': [
          '一群袭击者出现在村庄边缘。',
          '他们看起来很危险，想要抢夺你的资源。',
          '战斗不可避免！'
        ],
        'nextScene': 'combat'
      },
      'combat': {
        'combat': true,
        'enemy': '袭击者',
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
    'title': '野兽',
    'isAvailable': () {
      final lodge = _sm.get('game.buildings.lodge', true) ?? 0;
      return lodge > 0; // 需要狩猎小屋
    },
    'scenes': {
      'start': {
        'text': [
          '一只巨大的野兽在村庄附近游荡。',
          '它威胁着村民的安全。',
          '你必须做出选择。'
        ],
        'buttons': {
          'fight': {
            'text': '战斗',
            'nextScene': 'combat'
          },
          'hide': {
            'text': '躲藏',
            'nextScene': 'hide'
          }
        }
      },
      'combat': {
        'combat': true,
        'enemy': '野兽',
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
        'text': [
          '你选择躲藏起来。',
          '野兽在村庄周围徘徊了一会儿。',
          '它破坏了一些建筑后离开了。'
        ],
        'cost': {
          'wood': 100,
          'fur': 20
        },
        'buttons': {
          'continue': {
            'text': '继续',
            'nextScene': 'end'
          }
        }
      }
    }
  };

  /// 商人事件
  static Map<String, dynamic> get trader => {
    'title': '商人',
    'isAvailable': () {
      final tradingPost = _sm.get('game.buildings.trading post', true) ?? 0;
      return tradingPost > 0; // 需要贸易站
    },
    'scenes': {
      'start': {
        'text': [
          '一个独行商人来到你的村庄。',
          '他背着一个大包，里面装满了稀有物品。',
          '"我有一些特殊的商品，"他说，"但价格不菲。"'
        ],
        'buttons': {
          'buyMedicine': {
            'text': '购买药品',
            'cost': {'scales': 10},
            'nextScene': 'buyMedicine'
          },
          'buyWeapon': {
            'text': '购买武器',
            'cost': {'scales': 15, 'teeth': 5},
            'nextScene': 'buyWeapon'
          },
          'decline': {
            'text': '拒绝购买',
            'nextScene': 'decline'
          }
        }
      },
      'buyMedicine': {
        'text': [
          '商人给了你一些珍贵的药品。',
          '"这些在危急时刻会救你的命。"'
        ],
        'reward': {
          'medicine': 5
        },
        'buttons': {
          'continue': {
            'text': '继续',
            'nextScene': 'end'
          }
        }
      },
      'buyWeapon': {
        'text': [
          '商人从包里取出一把精制的武器。',
          '"这是我最好的作品之一。"'
        ],
        'reward': {
          'steel sword': 1
        },
        'buttons': {
          'continue': {
            'text': '继续',
            'nextScene': 'end'
          }
        }
      },
      'decline': {
        'text': [
          '商人点点头，收拾好他的物品。',
          '"也许下次你会需要的。"'
        ],
        'buttons': {
          'continue': {
            'text': '继续',
            'nextScene': 'end'
          }
        }
      }
    }
  };

  /// 难民事件
  static Map<String, dynamic> get refugees => {
    'title': '难民',
    'isAvailable': () {
      final huts = _sm.get('game.buildings.hut', true) ?? 0;
      final population = _sm.get('game.population', true) ?? 0;
      final maxPop = huts * 4;
      return huts >= 5 && population < maxPop; // 需要足够的小屋和空余人口空间
    },
    'scenes': {
      'start': {
        'text': [
          '一群难民来到你的村庄。',
          '他们看起来疲惫不堪，急需庇护。',
          '"请让我们留下来，"他们恳求道，"我们会努力工作的。"'
        ],
        'buttons': {
          'accept': {
            'text': '接受他们',
            'cost': {'meat': 50, 'fur': 20},
            'nextScene': 'accept'
          },
          'refuse': {
            'text': '拒绝',
            'nextScene': 'refuse'
          }
        }
      },
      'accept': {
        'text': [
          '难民们感激地定居在你的村庄。',
          '他们很快就开始为社区做贡献。'
        ],
        'onLoad': () {
          final currentPop = _sm.get('game.population', true) ?? 0;
          _sm.set('game.population', currentPop + 3);
          Logger.info('👥 人口增加3人');
        },
        'buttons': {
          'continue': {
            'text': '继续',
            'nextScene': 'end'
          }
        }
      },
      'refuse': {
        'text': [
          '难民们失望地离开了。',
          '你看着他们消失在远方。'
        ],
        'buttons': {
          'continue': {
            'text': '继续',
            'nextScene': 'end'
          }
        }
      }
    }
  };

  /// 侦察兵事件
  static Map<String, dynamic> get scout => {
    'title': '侦察兵',
    'isAvailable': () {
      final armoury = _sm.get('game.buildings.armoury', true) ?? 0;
      return armoury > 0; // 需要军械库
    },
    'scenes': {
      'start': {
        'text': [
          '一个侦察兵匆忙赶到村庄。',
          '"我发现了一个废弃的前哨站，"他报告道。',
          '"那里可能有有用的物资，但也可能有危险。"'
        ],
        'buttons': {
          'investigate': {
            'text': '调查',
            'nextScene': 'investigate'
          },
          'ignore': {
            'text': '忽视',
            'nextScene': 'ignore'
          }
        }
      },
      'investigate': {
        'text': [
          '你派遣一支小队前往调查。',
          '他们发现了一些有价值的物资。'
        ],
        'reward': {
          'bullets': 30,
          'medicine': 2,
          'energy cell': 1
        },
        'buttons': {
          'continue': {
            'text': '继续',
            'nextScene': 'end'
          }
        }
      },
      'ignore': {
        'text': [
          '你决定不冒险调查。',
          '侦察兵点点头，理解你的谨慎。'
        ],
        'buttons': {
          'continue': {
            'text': '继续',
            'nextScene': 'end'
          }
        }
      }
    }
  };
}
