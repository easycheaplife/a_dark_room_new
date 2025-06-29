import '../core/state_manager.dart';
import '../core/localization.dart';
import '../core/logger.dart';
import '../modules/world.dart';
import '../modules/setpieces.dart';

/// 执行者事件定义 - 参考原游戏executioner.js
class ExecutionerEvents {
  static final StateManager _sm = StateManager();

  /// 获取所有执行者事件
  static Map<String, Map<String, dynamic>> get events => {
        'executioner-intro': executionerIntro,
        'executioner-antechamber': executionerAntechamber,
        'executioner-engineering': executionerEngineering,
        'executioner-medical': executionerMedical,
        'executioner-martial': executionerMartial,
        'executioner-command': executionerCommand,
      };

  /// 执行者介绍事件 - 第一次访问X地标
  static Map<String, dynamic> get executionerIntro {
    final localization = Localization();
    return {
      'title': localization.translate('events.executioner.intro.title'),
      'scenes': {
        'start': {
          'notification': localization.translate('events.executioner.intro.notification'),
          'text': [
            localization.translate('events.executioner.intro.text1'),
            localization.translate('events.executioner.intro.text2'),
            localization.translate('events.executioner.intro.text3')
          ],
          'buttons': {
            'enter': {
              'text': localization.translate('ui.buttons.enter'),
              'cost': {'torch': 1},
              'nextScene': 'interior'
            },
            'leave': {
              'text': localization.translate('ui.buttons.leave'),
              'nextScene': 'end'
            }
          }
        },
        'interior': {
          'text': [
            localization.translate('events.executioner.intro.interior_text1'),
            localization.translate('events.executioner.intro.interior_text2'),
            localization.translate('events.executioner.intro.interior_text3')
          ],
          'buttons': {
            'continue': {
              'text': localization.translate('ui.buttons.continue'),
              'nextScene': 'discovery'
            }
          }
        },
        'discovery': {
          'text': [
            localization.translate('events.executioner.intro.discovery_text1'),
            localization.translate('events.executioner.intro.discovery_text2'),
            localization.translate('events.executioner.intro.discovery_text3')
          ],
          'onLoad': () {
            // 设置执行者完成状态 - 参考原游戏
            final world = World();
            world.state = world.state ?? {};
            world.state!['executioner'] = true;
            world.drawRoad();
            Logger.info('🔮 执行者intro完成，设置 World.state.executioner = true');
          },
          'buttons': {
            'leave': {
              'text': localization.translate('events.executioner.intro.take_device_and_leave'),
              'nextScene': 'end'
            }
          }
        }
      }
    };
  }

  /// 执行者前厅事件 - 第二次访问X地标
  static Map<String, dynamic> get executionerAntechamber {
    final localization = Localization();
    return {
      'title': localization.translate('events.executioner.antechamber.title'),
      'scenes': {
        'start': {
          'text': [
            localization.translate('events.executioner.antechamber.text1'),
            localization.translate('events.executioner.antechamber.text2')
          ],
          'buttons': {
            'engineering': {
              'text': localization.translate('events.executioner.antechamber.engineering'),
              'available': () {
                final world = World();
                return world.state!['engineering'] != true;
              },
              'nextEvent': 'executioner-engineering'
            },
            'medical': {
              'text': localization.translate('events.executioner.antechamber.medical'),
              'available': () {
                final world = World();
                return world.state!['medical'] != true;
              },
              'nextEvent': 'executioner-medical'
            },
            'martial': {
              'text': localization.translate('events.executioner.antechamber.martial'),
              'available': () {
                final world = World();
                return world.state!['martial'] != true;
              },
              'nextEvent': 'executioner-martial'
            },
            'command': {
              'text': localization.translate('events.executioner.antechamber.command_deck'),
              'available': () {
                final world = World();
                return world.state!['engineering'] == true && 
                       world.state!['medical'] == true && 
                       world.state!['martial'] == true;
              },
              'nextEvent': 'executioner-command'
            },
            'leave': {
              'text': localization.translate('ui.buttons.leave'),
              'nextScene': 'end'
            }
          }
        }
      }
    };
  }

  /// 工程部门事件
  static Map<String, dynamic> get executionerEngineering {
    final localization = Localization();
    return {
      'title': localization.translate('events.executioner.engineering.title'),
      'scenes': {
        'start': {
          'text': [
            localization.translate('events.executioner.engineering.text1'),
            localization.translate('events.executioner.engineering.text2')
          ],
          'buttons': {
            'continue': {
              'text': localization.translate('ui.buttons.continue'),
              'nextScene': 'complete'
            },
            'leave': {
              'text': localization.translate('ui.buttons.leave'),
              'nextScene': 'end'
            }
          }
        },
        'complete': {
          'text': [
            localization.translate('events.executioner.engineering.complete_text')
          ],
          'onLoad': () {
            final world = World();
            world.state = world.state ?? {};
            world.state!['engineering'] = true;
            Logger.info('🔧 工程部门完成');
          },
          'buttons': {
            'leave': {
              'text': localization.translate('ui.buttons.leave'),
              'nextScene': 'end'
            }
          }
        }
      }
    };
  }

  /// 医疗部门事件
  static Map<String, dynamic> get executionerMedical {
    final localization = Localization();
    return {
      'title': localization.translate('events.executioner.medical.title'),
      'scenes': {
        'start': {
          'text': [
            localization.translate('events.executioner.medical.text1'),
            localization.translate('events.executioner.medical.text2')
          ],
          'buttons': {
            'continue': {
              'text': localization.translate('ui.buttons.continue'),
              'nextScene': 'complete'
            },
            'leave': {
              'text': localization.translate('ui.buttons.leave'),
              'nextScene': 'end'
            }
          }
        },
        'complete': {
          'text': [
            localization.translate('events.executioner.medical.complete_text')
          ],
          'onLoad': () {
            final world = World();
            world.state = world.state ?? {};
            world.state!['medical'] = true;
            Logger.info('🏥 医疗部门完成');
          },
          'buttons': {
            'leave': {
              'text': localization.translate('ui.buttons.leave'),
              'nextScene': 'end'
            }
          }
        }
      }
    };
  }

  /// 军事部门事件
  static Map<String, dynamic> get executionerMartial {
    final localization = Localization();
    return {
      'title': localization.translate('events.executioner.martial.title'),
      'scenes': {
        'start': {
          'text': [
            localization.translate('events.executioner.martial.text1'),
            localization.translate('events.executioner.martial.text2')
          ],
          'buttons': {
            'continue': {
              'text': localization.translate('ui.buttons.continue'),
              'nextScene': 'complete'
            },
            'leave': {
              'text': localization.translate('ui.buttons.leave'),
              'nextScene': 'end'
            }
          }
        },
        'complete': {
          'text': [
            localization.translate('events.executioner.martial.complete_text')
          ],
          'onLoad': () {
            final world = World();
            world.state = world.state ?? {};
            world.state!['martial'] = true;
            Logger.info('⚔️ 军事部门完成');
          },
          'buttons': {
            'leave': {
              'text': localization.translate('ui.buttons.leave'),
              'nextScene': 'end'
            }
          }
        }
      }
    };
  }

  /// 指挥部事件 - 最终解锁制造器
  static Map<String, dynamic> get executionerCommand {
    final localization = Localization();
    return {
      'title': localization.translate('events.executioner.command.title'),
      'scenes': {
        'start': {
          'text': [
            localization.translate('events.executioner.command.text1'),
            localization.translate('events.executioner.command.text2')
          ],
          'buttons': {
            'continue': {
              'text': localization.translate('ui.buttons.continue'),
              'nextScene': 'complete'
            }
          }
        },
        'complete': {
          'text': [
            localization.translate('events.executioner.command.complete_text')
          ],
          'onLoad': () {
            final world = World();
            world.state = world.state ?? {};
            world.state!['command'] = true;
            Logger.info('🎖️ 指挥部完成，制造器将在返回村庄时解锁');
          },
          'buttons': {
            'leave': {
              'text': localization.translate('ui.buttons.leave'),
              'nextScene': 'end'
            }
          }
        }
      }
    };
  }
}
