import 'package:flutter/material.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../core/logger.dart';
import 'events.dart';
import 'world.dart';
import 'outside.dart';

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
  String get name {
    final localization = Localization();
    return localization.translate('setpieces.module_name');
  }

  /// 场景事件配置
  static Map<String, Map<String, dynamic>> get setpieces => {
        // 友好前哨站
        'outpost': {
          'title': () {
            final localization = Localization();
            return localization.translate('setpieces.outpost.title');
          }(),
          'scenes': {
            'start': {
              'text': () {
                final localization = Localization();
                return [localization.translate('setpieces.outpost.start_text')];
              }(),
              'notification': () {
                final localization = Localization();
                return localization.translate('setpieces.outpost.notification');
              }(),
              'loot': {
                'cured meat': {'min': 5, 'max': 10, 'chance': 1.0}
              },
              'onLoad': 'useOutpost',
              'buttons': {
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'end'
                }
              }
            },
            'end': {
              'text': () {
                final localization = Localization();
                return [localization.translate('setpieces.outpost.end_text')];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'finish'
                }
              }
            }
          },
          'audio': 'landmark_friendly_outpost'
        },

        // 阴暗沼泽
        'swamp': {
          'title': () {
            final localization = Localization();
            return localization.translate('setpieces.swamp.title');
          }(),
          'scenes': {
            'start': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.swamp.start.text1'),
                  localization.translate('setpieces.swamp.start.text2')
                ];
              }(),
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.swamp.start.notification');
              }(),
              'buttons': {
                'enter': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.enter');
                  }(),
                  'nextScene': {'1': 'cabin'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'nextScene': 'end'
                }
              }
            },
            'cabin': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.swamp.cabin.text1'),
                  localization.translate('setpieces.swamp.cabin.text2')
                ];
              }(),
              'buttons': {
                'talk': {
                  'cost': {'charm': 1},
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.talk');
                  }(),
                  'nextScene': {'1': 'talk'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'nextScene': 'end'
                }
              }
            },
            'talk': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.swamp.talk.text1'),
                  localization.translate('setpieces.swamp.talk.text2'),
                  localization.translate('setpieces.swamp.talk.text3'),
                  localization.translate('setpieces.swamp.talk.text4')
                ];
              }(),
              'onLoad': 'addGastronomePerk',
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
          },
          'audio': 'landmark_swamp'
        },

        // 潮湿洞穴
        'cave': {
          'title': () {
            final localization = Localization();
            return localization.translate('setpieces.cave.title');
          }(),
          'scenes': {
            'start': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.cave.start.text1'),
                  localization.translate('setpieces.cave.start.text2')
                ];
              }(),
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.cave.start.notification');
              }(),
              'buttons': {
                'enter': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.enter');
                  }(),
                  'cost': {'torch': 1},
                  'nextScene': {'0.3': 'a1', '0.6': 'a2', '1': 'a3'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'nextScene': 'leave_end'
                }
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
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.cave_scenes.beast_notification');
              }(),
              'loot': {
                'fur': {'min': 1, 'max': 10, 'chance': 1.0},
                'teeth': {'min': 1, 'max': 5, 'chance': 0.8}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'0.5': 'b1', '1': 'b2'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.cave_scenes.leave_cave');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'leave_end'
                }
              }
            },
            'a2': {
              'text': () {
                final localization = Localization();
                return [
                  localization
                      .translate('setpieces.cave_scenes.cave_narrow_text1'),
                  localization
                      .translate('setpieces.cave_scenes.cave_narrow_text2')
                ];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.cave_scenes.squeeze_through');
                  }(),
                  'nextScene': {'0.5': 'b2', '1': 'b3'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.cave_scenes.leave_cave');
                  }(),
                  'nextScene': 'leave_end'
                }
              }
            },
            'a3': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.cave_scenes.cave_a3_text1'),
                  localization.translate('setpieces.cave_scenes.cave_a3_text2')
                ];
              }(),
              'loot': {
                'cured meat': {'min': 1, 'max': 5, 'chance': 1.0},
                'torch': {'min': 1, 'max': 5, 'chance': 0.5},
                'leather': {'min': 1, 'max': 5, 'chance': 0.3}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'0.5': 'b3', '1': 'b4'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.cave_scenes.leave_cave');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'leave_end'
                }
              }
            },
            'b1': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.cave_scenes.cave_b1_text1'),
                  localization.translate('setpieces.cave_scenes.cave_b1_text2'),
                  localization.translate('setpieces.cave_scenes.cave_b1_text3')
                ];
              }(),
              'loot': {
                'cloth': {'min': 5, 'max': 10, 'chance': 1.0},
                'leather': {'min': 5, 'max': 10, 'chance': 0.8},
                'cured meat': {'min': 1, 'max': 5, 'chance': 0.5}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'1': 'c1'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.cave_scenes.leave_cave');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'leave_end'
                }
              }
            },
            'b2': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.cave_scenes.cave_b2_text1'),
                  localization.translate('setpieces.cave_scenes.cave_b2_text2')
                ];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cost': {'torch': 1},
                  'nextScene': {'1': 'c1'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.cave_scenes.leave_cave');
                  }(),
                  'nextScene': 'leave_end'
                }
              }
            },
            'b3': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.cave_scenes.cave_b3_text1'),
                  localization.translate('setpieces.cave_scenes.cave_b3_text2')
                ];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'1': 'c2'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.cave_scenes.leave_cave');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'leave_end'
                }
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
              'notification': () {
                final localization = Localization();
                return localization.translate(
                    'setpieces.cave_scenes.cave_lizard_notification');
              }(),
              'loot': {
                'scales': {'min': 1, 'max': 3, 'chance': 1.0},
                'teeth': {'min': 1, 'max': 2, 'chance': 0.5}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'1': 'c2'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.cave_scenes.leave_cave');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'leave_end'
                }
              }
            },
            'c1': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.cave_scenes.cave_c1_text1'),
                  localization.translate('setpieces.cave_scenes.cave_c1_text2')
                ];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'0.5': 'end1', '1': 'end2'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.cave_scenes.leave_cave');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'leave_end'
                }
              }
            },
            'c2': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.cave_scenes.cave_c2_text1'),
                  localization.translate('setpieces.cave_scenes.cave_c2_text2')
                ];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'0.7': 'end2', '1': 'end3'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.cave_scenes.leave_cave');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'leave_end'
                }
              }
            },
            'end1': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.cave_scenes.cave_end1_text')
                ];
              }(),
              'onLoad': 'clearDungeon',
              'loot': {
                'meat': {'min': 5, 'max': 10, 'chance': 1.0},
                'fur': {'min': 5, 'max': 10, 'chance': 1.0},
                'scales': {'min': 5, 'max': 10, 'chance': 1.0},
                'teeth': {'min': 5, 'max': 10, 'chance': 1.0},
                'cloth': {'min': 5, 'max': 10, 'chance': 0.5}
              },
              'buttons': {
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.cave_scenes.leave_cave');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'leave_end'
                }
              }
            },
            'end2': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.cave_scenes.cave_end2_text')
                ];
              }(),
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
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.cave_scenes.leave_cave');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'leave_end'
                }
              }
            },
            'end3': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.cave_scenes.cave_end3_text')
                ];
              }(),
              'onLoad': 'clearDungeon',
              'loot': {
                'steel sword': {'min': 1, 'max': 1, 'chance': 1.0},
                'bolas': {'min': 1, 'max': 3, 'chance': 0.5},
                'medicine': {'min': 1, 'max': 3, 'chance': 0.3}
              },
              'buttons': {
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.cave_scenes.leave_cave');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'leave_end'
                }
              }
            },
            'end': {
              'text': () {
                final localization = Localization();
                return [localization.translate('setpieces.cave.end_text')];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'finish'
                }
              }
            },
            'leave_end': {
              'text': () {
                final localization = Localization();
                return [localization.translate('setpieces.cave.leave_text')];
              }(),
              'onLoad': 'endEvent',
              'buttons': {}
            }
          },
          'audio': 'landmark_cave'
        },

        // 旧房子
        'house': {
          'title': () {
            final localization = Localization();
            return localization.translate('setpieces.house.title');
          }(),
          'scenes': {
            'start': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.house.start.text1'),
                  localization.translate('setpieces.house.start.text2')
                ];
              }(),
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.house.start.notification');
              }(),
              'buttons': {
                'enter': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.enter');
                  }(),
                  'nextScene': {
                    '0.25': 'medicine',
                    '0.75': 'supplies',
                    '1': 'occupied'
                  }
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'nextScene': 'end'
                }
              }
            },
            'supplies': {
              'text': () {
                final localization = Localization();
                return [
                  localization
                      .translate('setpieces.house_scenes.abandoned_text1'),
                  localization
                      .translate('setpieces.house_scenes.abandoned_text2')
                ];
              }(),
              'onLoad': 'markVisited',
              'loot': {
                'cured meat': {'min': 1, 'max': 10, 'chance': 0.8},
                'leather': {'min': 1, 'max': 10, 'chance': 0.2},
                'cloth': {'min': 1, 'max': 10, 'chance': 0.5}
              },
              'buttons': {
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'end'
                }
              }
            },
            'medicine': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.house_scenes.looted_text1'),
                  localization.translate('setpieces.house_scenes.looted_text2')
                ];
              }(),
              'onLoad': 'markVisited',
              'loot': {
                'medicine': {'min': 2, 'max': 5, 'chance': 1.0}
              },
              'buttons': {
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'end'
                }
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
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.house_scenes.squatter_notification');
              }(),
              'onLoad': 'markVisited',
              'loot': {
                'cured meat': {'min': 1, 'max': 10, 'chance': 0.8},
                'leather': {'min': 1, 'max': 10, 'chance': 0.2},
                'cloth': {'min': 1, 'max': 10, 'chance': 0.5}
              },
              'buttons': {
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'end'
                }
              }
            },
            'end': {
              'text': () {
                final localization = Localization();
                return [localization.translate('setpieces.house.end_text')];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'finish'
                }
              }
            }
          },
          'audio': 'landmark_house'
        },

        // 废弃城镇
        'town': {
          'title': () {
            final localization = Localization();
            return localization.translate('setpieces.town.title');
          }(),
          'scenes': {
            'start': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.town.start.text1'),
                  localization.translate('setpieces.town.start.text2')
                ];
              }(),
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.town.start.notification');
              }(),
              'buttons': {
                'enter': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.explore');
                  }(),
                  'nextScene': {'0.3': 'a1', '0.7': 'a3', '1': 'a2'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'nextScene': 'leave_end'
                }
              }
            },
            'a1': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.town_scenes.town_a1_text1'),
                  localization.translate('setpieces.town_scenes.town_a1_text2')
                ];
              }(),
              'buttons': {
                'enter': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.enter');
                  }(),
                  'nextScene': {'0.5': 'b1', '1': 'b2'},
                  'cost': {'torch': 1}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.town_scenes.leave_town');
                  }(),
                  'nextScene': 'end'
                }
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
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.town_scenes.town_a2_notification');
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'0.5': 'b3', '1': 'b4'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.town_scenes.leave_town');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'end'
                }
              }
            },
            'a3': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.town_scenes.town_a3_text')
                ];
              }(),
              'loot': {
                'cured meat': {'min': 1, 'max': 3, 'chance': 0.8},
                'cloth': {'min': 2, 'max': 5, 'chance': 0.6}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'end'
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.town_scenes.leave_town');
                  }(),
                  'nextScene': 'end'
                }
              }
            },
            'b1': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.town_scenes.town_b1_text')
                ];
              }(),
              'loot': {
                'cloth': {'min': 3, 'max': 8, 'chance': 1.0},
                'cured meat': {'min': 1, 'max': 2, 'chance': 0.3}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'end'
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.town_scenes.leave_town');
                  }(),
                  'nextScene': 'end'
                }
              }
            },
            'b2': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.town_scenes.town_b2_text')
                ];
              }(),
              'loot': {
                'medicine': {'min': 1, 'max': 2, 'chance': 0.5},
                'cloth': {'min': 5, 'max': 10, 'chance': 1.0}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'end'
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.town_scenes.leave_town');
                  }(),
                  'nextScene': 'end'
                }
              }
            },
            'b3': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.town_scenes.town_b3_text')
                ];
              }(),
              'loot': {
                'iron': {'min': 2, 'max': 5, 'chance': 0.7},
                'leather': {'min': 1, 'max': 3, 'chance': 0.5}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'end'
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.town_scenes.leave_town');
                  }(),
                  'nextScene': 'end'
                }
              }
            },
            'b4': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.town_scenes.town_b4_text')
                ];
              }(),
              'loot': {
                'cured meat': {'min': 3, 'max': 8, 'chance': 1.0},
                'medicine': {'min': 1, 'max': 3, 'chance': 0.4},
                'steel': {'min': 1, 'max': 2, 'chance': 0.2}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'end'
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.town_scenes.leave_town');
                  }(),
                  'nextScene': 'end'
                }
              }
            },
            'end': {
              'text': () {
                final localization = Localization();
                return [localization.translate('setpieces.town.end_text')];
              }(),
              'onLoad': 'clearDungeon',
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'finish'
                }
              }
            },
            'leave_end': {
              'text': () {
                final localization = Localization();
                return [localization.translate('setpieces.town.leave_text')];
              }(),
              'onLoad': 'endEvent',
              'buttons': {}
            }
          },
          'audio': 'landmark_town'
        },

        // 铁矿
        'ironmine': {
          'title': () {
            final localization = Localization();
            return localization.translate('setpieces.ironmine.title');
          }(),
          'scenes': {
            'start': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.ironmine.start.text1'),
                  localization.translate('setpieces.ironmine.start.text2'),
                  localization.translate('setpieces.ironmine.start.text3')
                ];
              }(),
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.ironmine.start.notification');
              }(),
              'buttons': {
                'enter': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.enter');
                  }(),
                  'nextScene': {'1': 'enter'},
                  'cost': {'torch': 1}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'nextScene': 'end'
                }
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
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.ironmine_scenes.beast_notification');
              }(),
              'buttons': {
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'1': 'cleared'}
                }
              }
            },
            'cleared': {
              'text': () {
                final localization = Localization();
                return [
                  localization
                      .translate('setpieces.ironmine_scenes.cleared_text1'),
                  localization
                      .translate('setpieces.ironmine_scenes.cleared_text2')
                ];
              }(),
              'notification': () {
                final localization = Localization();
                return localization.translate(
                    'setpieces.ironmine_scenes.cleared_notification');
              }(),
              'onLoad': 'clearIronMine',
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
            'end': {
              'text': () {
                final localization = Localization();
                return [localization.translate('setpieces.ironmine.end_text')];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'finish'
                }
              }
            }
          },
          'audio': 'landmark_iron_mine'
        },

        // 煤矿
        'coalmine': {
          'title': () {
            final localization = Localization();
            return localization.translate('setpieces.coalmine.title');
          }(),
          'scenes': {
            'start': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.coalmine.start.text1'),
                  localization.translate('setpieces.coalmine.start.text2')
                ];
              }(),
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.coalmine.start.notification');
              }(),
              'buttons': {
                'attack': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.attack');
                  }(),
                  'nextScene': {'1': 'a1'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'nextScene': 'end'
                }
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
              'notification': () {
                final localization = Localization();
                return localization.translate(
                    'setpieces.coalmine_scenes.man_joins_notification');
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'1': 'a2'}
                },
                'run': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.run');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'end'
                }
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
              'notification': () {
                final localization = Localization();
                return localization.translate(
                    'setpieces.coalmine_scenes.man_joins_notification');
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'1': 'a3'}
                },
                'run': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.run');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'end'
                }
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
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.coalmine_scenes.chief_notification');
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'1': 'cleared'}
                }
              }
            },
            'cleared': {
              'text': () {
                final localization = Localization();
                return [
                  localization
                      .translate('setpieces.coalmine_scenes.cleared_text1'),
                  localization
                      .translate('setpieces.coalmine_scenes.cleared_text2')
                ];
              }(),
              'notification': () {
                final localization = Localization();
                return localization.translate(
                    'setpieces.coalmine_scenes.cleared_notification');
              }(),
              'onLoad': 'clearCoalMine',
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
            'end': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.coalmine_scenes.end_text')
                ];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'finish'
                }
              }
            }
          },
          'audio': 'landmark_coal_mine'
        },

        // 硫磺矿
        'sulphurmine': {
          'title': () {
            final localization = Localization();
            return localization.translate('setpieces.sulphurmine.title');
          }(),
          'scenes': {
            'start': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.sulphurmine.start.text1'),
                  localization.translate('setpieces.sulphurmine.start.text2')
                ];
              }(),
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.sulphurmine.start.notification');
              }(),
              'buttons': {
                'attack': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.attack');
                  }(),
                  'nextScene': {'1': 'a1'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'nextScene': 'end'
                }
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
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.sulphurmine.soldier_notification');
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'1': 'a2'}
                },
                'run': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.run');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'end'
                }
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
              'notification': () {
                final localization = Localization();
                return localization.translate(
                    'setpieces.sulphurmine.second_soldier_notification');
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'1': 'a3'}
                },
                'run': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.run');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'end'
                }
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
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.sulphurmine.veteran_notification');
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'1': 'cleared'}
                }
              }
            },
            'cleared': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.sulphurmine.cleared_text1'),
                  localization.translate('setpieces.sulphurmine.cleared_text2')
                ];
              }(),
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.sulphurmine.cleared_notification');
              }(),
              'onLoad': 'clearSulphurMine',
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
            'end': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.sulphurmine.end_text')
                ];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'finish'
                }
              }
            }
          },
          'audio': 'landmark_sulphur_mine'
        },

        // 城市
        'city': {
          'title': () {
            final localization = Localization();
            return localization.translate('setpieces.city.title');
          }(),
          'scenes': {
            'start': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.city.start.text1'),
                  localization.translate('setpieces.city.start.text2'),
                  localization.translate('setpieces.city.start.text3')
                ];
              }(),
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.city.start.notification');
              }(),
              'buttons': {
                'enter': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.explore');
                  }(),
                  'nextScene': {
                    '0.2': 'a1',
                    '0.5': 'a2',
                    '0.8': 'a3',
                    '1': 'a4'
                  }
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'nextScene': 'finish'
                }
              }
            },
            'a1': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.city.empty_streets_text1'),
                  localization.translate('setpieces.city.empty_streets_text2')
                ];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': {'0.5': 'b1', '1': 'b2'}
                }
              }
            },
            'a2': {
              'text': () {
                final localization = Localization();
                return [
                  localization
                      .translate('setpieces.city_scenes.settlement_text1'),
                  localization
                      .translate('setpieces.city_scenes.settlement_text2')
                ];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': {'0.5': 'b3', '1': 'b4'}
                }
              }
            },
            'a3': {
              'text': () {
                final localization = Localization();
                return [
                  localization
                      .translate('setpieces.city_scenes.hospital_text1'),
                  localization.translate('setpieces.city_scenes.hospital_text2')
                ];
              }(),
              'buttons': {
                'enter': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.enter');
                  }(),
                  'cost': {'torch': 1},
                  'nextScene': {'0.5': 'b5', '1': 'b6'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave_city');
                  }(),
                  'nextScene': 'finish'
                }
              }
            },
            'a4': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.city_scenes.subway_text1'),
                  localization.translate('setpieces.city_scenes.subway_text2')
                ];
              }(),
              'buttons': {
                'enter': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.enter');
                  }(),
                  'cost': {'torch': 1},
                  'nextScene': {'0.5': 'b7', '1': 'b8'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave_city');
                  }(),
                  'nextScene': 'finish'
                }
              }
            },
            'b1': {
              'text': () {
                final localization = Localization();
                return [
                  localization
                      .translate('setpieces.city_scenes.store_ruins_text1'),
                  localization
                      .translate('setpieces.city_scenes.store_ruins_text2')
                ];
              }(),
              'loot': {
                'cured meat': {'min': 1, 'max': 5, 'chance': 0.8},
                'cloth': {'min': 1, 'max': 5, 'chance': 0.5},
                'medicine': {'min': 1, 'max': 2, 'chance': 0.1}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'0.5': 'c1', '1': 'c2'}
                }
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
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.city.thug_notification');
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'0.5': 'c2', '1': 'c3'}
                }
              }
            },
            'b3': {
              'text': () {
                final localization = Localization();
                return [
                  localization
                      .translate('setpieces.city_scenes.settlement_b3_text1'),
                  localization
                      .translate('setpieces.city_scenes.settlement_b3_text2')
                ];
              }(),
              'loot': {
                'steel': {'min': 1, 'max': 3, 'chance': 0.8},
                'bullets': {'min': 5, 'max': 15, 'chance': 0.6},
                'medicine': {'min': 1, 'max': 2, 'chance': 0.3}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'0.5': 'c4', '1': 'c5'}
                }
              }
            },
            'b4': {
              'combat': true,
              'enemy': 'scavenger',
              'chara': 'S',
              'damage': 4,
              'hit': 0.7,
              'attackDelay': 2.5,
              'health': 25,
              'loot': {
                'cloth': {'min': 3, 'max': 8, 'chance': 0.9},
                'leather': {'min': 2, 'max': 6, 'chance': 0.7},
                'steel': {'min': 1, 'max': 2, 'chance': 0.4}
              },
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.city.scavenger_notification');
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'0.5': 'c5', '1': 'c6'}
                }
              }
            },
            'b5': {
              'text': () {
                final localization = Localization();
                return [
                  localization
                      .translate('setpieces.city_scenes.hospital_b5_text1'),
                  localization
                      .translate('setpieces.city_scenes.hospital_b5_text2')
                ];
              }(),
              'loot': {
                'medicine': {'min': 3, 'max': 8, 'chance': 1.0},
                'steel': {'min': 1, 'max': 2, 'chance': 0.5},
                'cloth': {'min': 2, 'max': 5, 'chance': 0.7}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'0.5': 'c7', '1': 'c8'}
                }
              }
            },
            'b6': {
              'combat': true,
              'enemy': 'beast',
              'chara': 'B',
              'damage': 5,
              'hit': 0.6,
              'attackDelay': 3,
              'health': 40,
              'loot': {
                'meat': {'min': 8, 'max': 15, 'chance': 1.0},
                'fur': {'min': 3, 'max': 8, 'chance': 0.8},
                'teeth': {'min': 2, 'max': 5, 'chance': 0.6}
              },
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.city.beast_notification');
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'0.5': 'c8', '1': 'c9'}
                }
              }
            },
            'b7': {
              'text': () {
                final localization = Localization();
                return [
                  localization
                      .translate('setpieces.city_scenes.subway_b7_text1'),
                  localization
                      .translate('setpieces.city_scenes.subway_b7_text2')
                ];
              }(),
              'loot': {
                'steel': {'min': 2, 'max': 5, 'chance': 0.9},
                'bullets': {'min': 10, 'max': 20, 'chance': 0.7},
                'energy cell': {'min': 1, 'max': 3, 'chance': 0.3}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'0.5': 'c10', '1': 'end1'}
                }
              }
            },
            'b8': {
              'combat': true,
              'enemy': 'soldier',
              'chara': 'S',
              'damage': 6,
              'hit': 0.8,
              'attackDelay': 2,
              'health': 50,
              'loot': {
                'rifle': {'min': 1, 'max': 1, 'chance': 0.8},
                'bullets': {'min': 15, 'max': 30, 'chance': 1.0},
                'steel': {'min': 2, 'max': 4, 'chance': 0.6}
              },
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.city.soldier_notification');
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': {'0.5': 'end1', '1': 'c11'}
                }
              }
            },
            'c1': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.city_scenes.c1_text')
                ];
              }(),
              'loot': {
                'cloth': {'min': 2, 'max': 6, 'chance': 0.8},
                'steel': {'min': 1, 'max': 2, 'chance': 0.5}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'end1'
                }
              }
            },
            'c2': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.city_scenes.c2_text')
                ];
              }(),
              'loot': {
                'medicine': {'min': 1, 'max': 3, 'chance': 0.7},
                'bullets': {'min': 5, 'max': 10, 'chance': 0.6}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'end1'
                }
              }
            },
            'c3': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.city_scenes.c3_text1'),
                  localization.translate('setpieces.city_scenes.c3_text2'),
                  localization.translate('setpieces.city_scenes.c3_text3')
                ];
              }(),
              'buttons': {
                'enter': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.investigate');
                  }(),
                  'cost': {'torch': 1},
                  'nextScene': {'0.5': 'd2', '1': 'd3'}
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave_city');
                  }(),
                  'nextScene': 'finish'
                }
              }
            },
            'c4': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.city_scenes.c4_text')
                ];
              }(),
              'loot': {
                'steel': {'min': 1, 'max': 3, 'chance': 0.8},
                'bullets': {'min': 8, 'max': 15, 'chance': 0.7}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'end1'
                }
              }
            },
            'c5': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.city_scenes.c5_text')
                ];
              }(),
              'loot': {
                'medicine': {'min': 2, 'max': 5, 'chance': 0.9},
                'steel': {'min': 1, 'max': 2, 'chance': 0.6}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'end1'
                }
              }
            },
            'c6': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.city_scenes.c6_text')
                ];
              }(),
              'loot': {
                'cloth': {'min': 5, 'max': 10, 'chance': 1.0},
                'leather': {'min': 3, 'max': 6, 'chance': 0.8}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'end1'
                }
              }
            },
            'c7': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.city_scenes.c7_text')
                ];
              }(),
              'loot': {
                'medicine': {'min': 4, 'max': 8, 'chance': 1.0},
                'steel': {'min': 2, 'max': 3, 'chance': 0.7}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'end1'
                }
              }
            },
            'c8': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.city_scenes.c8_text')
                ];
              }(),
              'loot': {
                'meat': {'min': 10, 'max': 20, 'chance': 1.0},
                'fur': {'min': 5, 'max': 10, 'chance': 0.9}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'end1'
                }
              }
            },
            'c9': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.city_scenes.c9_text')
                ];
              }(),
              'loot': {
                'teeth': {'min': 3, 'max': 8, 'chance': 1.0},
                'scales': {'min': 2, 'max': 5, 'chance': 0.8}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'end1'
                }
              }
            },
            'c10': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.city_scenes.c10_text')
                ];
              }(),
              'loot': {
                'steel': {'min': 3, 'max': 6, 'chance': 1.0},
                'energy cell': {'min': 2, 'max': 4, 'chance': 0.6}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'end1'
                }
              }
            },
            'c11': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.city_scenes.c11_text')
                ];
              }(),
              'loot': {
                'rifle': {'min': 1, 'max': 1, 'chance': 1.0},
                'bullets': {'min': 20, 'max': 40, 'chance': 1.0},
                'alien alloy': {'min': 1, 'max': 2, 'chance': 0.5}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'end1'
                }
              }
            },
            'end1': {
              'text': () {
                final localization = Localization();
                return [
                  localization
                      .translate('setpieces.city_scenes.bird_nest_text1'),
                  localization
                      .translate('setpieces.city_scenes.bird_nest_text2')
                ];
              }(),
              'onLoad': 'clearCity',
              'loot': {
                'bullets': {'min': 5, 'max': 10, 'chance': 0.8},
                'bolas': {'min': 1, 'max': 5, 'chance': 0.5},
                'alien alloy': {'min': 1, 'max': 1, 'chance': 0.5}
              },
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'finish'
                }
              }
            },
          },
          'audio': 'landmark_city'
        },

        // 钻孔事件
        'borehole': {
          'title': () {
            final localization = Localization();
            return localization.translate('setpieces.borehole.title');
          }(),
          'scenes': {
            'start': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.borehole.start.text1'),
                  localization.translate('setpieces.borehole.start.text2'),
                  localization.translate('setpieces.borehole.start.text3')
                ];
              }(),
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.borehole.start.notification');
              }(),
              'onLoad': 'markVisited',
              'loot': {
                'alien alloy': {'min': 1, 'max': 3, 'chance': 1.0}
              },
              'buttons': {
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'cooldown': 1,
                  'nextScene': 'end'
                }
              }
            },
            'end': {
              'text': () {
                final localization = Localization();
                return [localization.translate('setpieces.borehole.end_text')];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'finish'
                }
              }
            }
          },
          'audio': 'landmark_borehole'
        },

        // 战场事件
        'battlefield': {
          'title': () {
            final localization = Localization();
            return localization.translate('setpieces.battlefield.title');
          }(),
          'scenes': {
            'start': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.battlefield.start.text1'),
                  localization.translate('setpieces.battlefield.start.text2')
                ];
              }(),
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.battlefield.start.notification');
              }(),
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
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'nextScene': 'end'
                }
              }
            },
            'end': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.battlefield.end_text')
                ];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'finish'
                }
              }
            }
          },
          'audio': 'landmark_battlefield'
        },

        // 星舰事件
        'ship': {
          'title': () {
            final localization = Localization();
            return localization.translate('setpieces.ship.title');
          }(),
          'scenes': {
            'start': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.ship.start.text1'),
                  localization.translate('setpieces.ship.start.text2'),
                  localization.translate('setpieces.ship.start.text3')
                ];
              }(),
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.ship.start.notification');
              }(),
              'onLoad': 'activateShip',
              'buttons': {
                'salvage': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('setpieces.ship.salvage');
                  }(),
                  'nextScene': 'end'
                }
              }
            },
            'end': {
              'text': () {
                final localization = Localization();
                return [localization.translate('setpieces.ship.end_text')];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'finish'
                }
              }
            }
          },
          'audio': 'landmark_crashed_ship'
        },

        // 执行者事件 - 简化版本
        'executioner': {
          'title': () {
            final localization = Localization();
            return localization.translate('setpieces.executioner.title');
          }(),
          'scenes': {
            'start': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.executioner.start.text1'),
                  localization.translate('setpieces.executioner.start.text2'),
                  localization.translate('setpieces.executioner.start.text3')
                ];
              }(),
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.executioner.start.notification');
              }(),
              'buttons': {
                'enter': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.enter');
                  }(),
                  'cost': {'torch': 1},
                  'nextScene': 'interior'
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'nextScene': 'end'
                }
              }
            },
            'interior': {
              'text': () {
                final localization = Localization();
                return [
                  localization
                      .translate('setpieces.executioner.interior_text1'),
                  localization.translate('setpieces.executioner.interior_text2')
                ];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'discovery'
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'nextScene': 'end'
                }
              }
            },
            'discovery': {
              'text': () {
                final localization = Localization();
                return [
                  localization
                      .translate('setpieces.executioner.discovery_text1'),
                  localization
                      .translate('setpieces.executioner.discovery_text2')
                ];
              }(),
              'onLoad': 'activateExecutioner',
              'loot': {
                'alien alloy': {'min': 2, 'max': 5, 'chance': 1.0},
                'energy cell': {'min': 3, 'max': 8, 'chance': 0.8},
                'laser rifle': {'min': 1, 'max': 2, 'chance': 0.6}
              },
              'buttons': {
                'take': {
                  'text': () {
                    final localization = Localization();
                    return localization
                        .translate('setpieces.executioner.take_device');
                  }(),
                  'nextScene': 'end'
                }
              }
            },
            'end': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.executioner.end_text')
                ];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'finish'
                }
              }
            }
          },
          'audio': 'landmark_crashed_ship'
        },

        // 缓存事件 - 当代遗产
        'cache': {
          'title': () {
            final localization = Localization();
            return localization.translate('setpieces.cache.title');
          }(),
          'scenes': {
            'start': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.cache.start.text1'),
                  localization.translate('setpieces.cache.start.text2')
                ];
              }(),
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('setpieces.cache.start.notification');
              }(),
              'buttons': {
                'enter': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.enter');
                  }(),
                  'nextScene': 'underground'
                },
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'nextScene': 'end'
                }
              }
            },
            'underground': {
              'text': () {
                final localization = Localization();
                return [
                  localization.translate('setpieces.cache.underground_text1'),
                  localization.translate('setpieces.cache.underground_text2')
                ];
              }(),
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
                'leave': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.leave');
                  }(),
                  'nextScene': 'end'
                }
              }
            },
            'end': {
              'text': () {
                final localization = Localization();
                return [localization.translate('setpieces.cache.end_text')];
              }(),
              'buttons': {
                'continue': {
                  'text': () {
                    final localization = Localization();
                    return localization.translate('ui.buttons.continue');
                  }(),
                  'nextScene': 'finish'
                }
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

    // 解锁铁矿建筑 - 参考原游戏的建筑解锁逻辑
    if ((sm.get('game.buildings["iron mine"]', true) ?? 0) == 0) {
      sm.add('game.buildings["iron mine"]', 1);
      Logger.info('🏠 解锁铁矿建筑');

      // 检查并添加铁矿工人到工人列表
      Outside().checkWorker('iron mine');
      Logger.info('🏠 添加铁矿工人到工人列表');
    }

    World().markVisited(World().curPos[0], World().curPos[1]);
    notifyListeners();
  }

  /// 清理煤矿
  void clearCoalMine() {
    final sm = StateManager();
    Logger.info('🔥 clearCoalMine() 开始执行');

    sm.set('game.world.coalmine', true);
    Logger.info('🔥 设置 game.world.coalmine = true');

    // 解锁煤矿建筑 - 参考原游戏的建筑解锁逻辑
    final currentCoalMine = sm.get('game.buildings["coal mine"]', true) ?? 0;
    Logger.info('🔥 当前煤矿建筑数量: $currentCoalMine');

    if (currentCoalMine == 0) {
      sm.add('game.buildings["coal mine"]', 1);
      Logger.info('🏠 解锁煤矿建筑 - 添加到 game.buildings["coal mine"]');

      // 检查并添加煤矿工人到工人列表
      final workerAdded = Outside().checkWorker('coal mine');
      Logger.info('🏠 添加煤矿工人到工人列表 - 结果: $workerAdded');

      // 验证建筑是否成功添加
      final verifyBuilding = sm.get('game.buildings["coal mine"]', true) ?? 0;
      Logger.info('🔍 验证煤矿建筑数量: $verifyBuilding');

      // 验证工人是否成功添加
      final verifyWorker = sm.get('game.workers["coal miner"]', true);
      Logger.info('🔍 验证煤矿工人: $verifyWorker');

      // 打印所有建筑状态
      final allBuildings = sm.get('game.buildings', true) ?? {};
      Logger.info('🔍 所有建筑状态: $allBuildings');

      // 打印所有工人状态
      final allWorkers = sm.get('game.workers', true) ?? {};
      Logger.info('🔍 所有工人状态: $allWorkers');
    } else {
      Logger.info('🔥 煤矿建筑已存在，跳过解锁');
    }

    World().markVisited(World().curPos[0], World().curPos[1]);
    Logger.info('🔥 clearCoalMine() 执行完成');
    notifyListeners();
  }

  /// 清理硫磺矿
  void clearSulphurMine() {
    final sm = StateManager();
    sm.set('game.world.sulphurmine', true);

    // 解锁硫磺矿建筑 - 参考原游戏的建筑解锁逻辑
    if ((sm.get('game.buildings["sulphur mine"]', true) ?? 0) == 0) {
      sm.add('game.buildings["sulphur mine"]', 1);
      Logger.info('🏠 解锁硫磺矿建筑');

      // 检查并添加硫磺矿工人到工人列表
      Outside().checkWorker('sulphur mine');
      Logger.info('🏠 添加硫磺矿工人到工人列表');
    }

    World().markVisited(World().curPos[0], World().curPos[1]);
    notifyListeners();
  }

  /// 清理城市
  void clearCity() {
    Logger.info('🏛️ ========== clearCity() 开始执行 ==========');

    final world = World();
    Logger.info('🏛️ 当前位置: [${world.curPos[0]}, ${world.curPos[1]}]');
    Logger.info('🏛️ World状态是否存在: ${world.state != null}');

    // 如果World状态不存在，尝试初始化
    if (world.state == null) {
      Logger.error('❌ World状态为空，尝试初始化...');
      world.onArrival();
      if (world.state == null) {
        Logger.error('❌ 无法初始化World状态！');
        return;
      }
      Logger.info('✅ World状态初始化成功');
    }

    // 检查当前地形
    final mapData = world.state?['map'];
    if (mapData == null) {
      Logger.error('❌ 地图数据为空！');
      return;
    }

    // 安全地转换地图数据类型
    final currentMap =
        List<List<String>>.from(mapData.map((row) => List<String>.from(row)));
    if (currentMap.isEmpty) {
      Logger.error('❌ 地图数据为空！');
      return;
    }

    final currentTile = currentMap[world.curPos[0]][world.curPos[1]];
    Logger.info('🏛️ 转换前地形: $currentTile');

    // 验证当前位置确实是城市
    if (currentTile != 'Y' && currentTile != 'Y!') {
      Logger.error('❌ 当前位置不是城市！当前地形: $currentTile');
      Logger.info('🔧 强制设置当前位置为城市Y');
      currentMap[world.curPos[0]][world.curPos[1]] = 'Y';
      world.state!['map'] = currentMap;
    }

    final sm = StateManager();
    sm.set('game.world.cityCleared', true);
    Logger.info('🏛️ 设置 game.world.cityCleared = true');

    // 城市清理后直接转换为前哨站，不需要先标记为已访问
    // 因为clearDungeon会直接将地形改为P，而不是Y!
    Logger.info('🏛️ 调用 World().clearDungeon()');
    world.clearDungeon();

    // 验证转换结果
    final newMap = world.state?['map'] as List<List<String>>?;
    final newTile = newMap?[world.curPos[0]][world.curPos[1]];
    Logger.info('🏛️ 转换后地形: $newTile');

    if (newTile == 'P') {
      Logger.info('✅ 城市转换成功！');
    } else {
      Logger.error('❌ 城市转换失败！预期: P, 实际: $newTile');

      // 强制转换 - 直接操作地图数据
      Logger.info('🔧 强制转换城市为前哨站');
      if (newMap != null) {
        newMap[world.curPos[0]][world.curPos[1]] = 'P';
        world.state!['map'] = newMap;
        Logger.info('🔧 强制转换完成，新地形: P');

        // 同时更新持久化状态
        final sm = StateManager();
        sm.setM('game.world', world.state!);
        Logger.info('🔧 强制保存到持久化状态');
      }
    }

    // 最终验证
    final finalMap = world.state?['map'] as List<List<String>>?;
    final finalTile = finalMap?[world.curPos[0]][world.curPos[1]];
    Logger.info('🏛️ 最终地形: $finalTile');

    if (finalTile == 'P') {
      Logger.info('🎉 城市转换最终成功！');
    } else {
      Logger.error('💥 城市转换最终失败！');
    }

    Logger.info('🏛️ ========== clearCity() 执行完成 ==========');
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
    sm.set('game.world.executioner', true);
    // 执行者完成后也要转换为前哨站
    World().clearDungeon();
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
