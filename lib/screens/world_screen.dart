import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../modules/world.dart';
import '../modules/path.dart';
import '../core/state_manager.dart';
import '../screens/events_screen.dart';
import '../screens/combat_screen.dart';

/// 世界地图屏幕 - 参考原游戏的world.js
class WorldScreen extends StatefulWidget {
  const WorldScreen({super.key});

  @override
  State<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends State<WorldScreen> {
  @override
  void initState() {
    super.initState();
    // 设置键盘监听
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final world = Provider.of<World>(context, listen: false);
      _handleKeyPress(event, world);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 白色背景
      body: Stack(
        children: [
          // 主界面
          Consumer<World>(
            builder: (context, world, child) {
              return Column(
                children: [
                  // 标题栏
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white, // 白色背景
                      border: Border(
                        bottom:
                            BorderSide(color: Colors.black, width: 1), // 黑色底边框
                      ),
                    ),
                    child: const Text(
                      '荒芜世界',
                      style: TextStyle(
                        color: Colors.black, // 黑色文字
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 状态信息 - 参考原游戏的状态栏布局
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white, // 白色背景
                      border: Border(
                        bottom:
                            BorderSide(color: Colors.black, width: 1), // 黑色底边框
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          '生命值: ${world.health}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        Text(
                          '距离: ${world.getDistance()}',
                          style: const TextStyle(color: Colors.black), // 黑色文字
                        ),
                      ],
                    ),
                  ),

                  // 主内容区域 - 使用SingleChildScrollView让页面可滚动
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      physics: const ClampingScrollPhysics(), // 使用更平滑的滚动物理
                      child: Column(
                        children: [
                          // 背包区域 - 参考原游戏的bagspace-world
                          _buildBagspace(world),

                          const SizedBox(height: 16),

                          // 地图区域 - 固定大小，不滚动
                          _buildMap(world),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 事件界面覆盖层
          const EventsScreen(),

          // 战斗界面覆盖层
          const CombatScreen(),
        ],
      ),
    );
  }

  /// 构建地图 - 参考原游戏的drawMap函数，固定大小显示地图，不使用内部滚动
  Widget _buildMap(World world) {
    try {
      final mapData = world.state?['map'];
      final maskData = world.state?['mask'];

      if (mapData == null || maskData == null) {
        return const Center(
          child: Text(
            '地图未初始化',
            style: TextStyle(color: Colors.black), // 黑色文字
          ),
        );
      }

      final map =
          List<List<String>>.from(mapData.map((row) => List<String>.from(row)));
      final mask =
          List<List<bool>>.from(maskData.map((row) => List<bool>.from(row)));
      final curPos = world.getCurrentPosition();

      // 确保地图数据有效
      if (map.isEmpty || map[0].isEmpty || mask.isEmpty || mask[0].isEmpty) {
        return const Center(
          child: Text(
            '地图数据为空',
            style: TextStyle(color: Colors.black), // 黑色文字
          ),
        );
      }

      // 参考原游戏：显示完整的61x61地图 (0 <= i,j <= RADIUS * 2)
      // 原游戏代码：for(var j = 0; j <= World.RADIUS * 2; j++) { for(var i = 0; i <= World.RADIUS * 2; i++)
      const radius = 30; // 原游戏的World.RADIUS = 30
      final mapSize = radius * 2 + 1; // 61x61

      return Center(
        child: GestureDetector(
          onTapDown: (details) => _handleMapClick(details, world),
          child: Container(
            padding: const EdgeInsets.all(4.0),
            decoration: const BoxDecoration(
              color: Colors.white, // 白色背景，与原游戏一致
              border: Border.fromBorderSide(
                BorderSide(color: Colors.black, width: 1), // 黑色边框
              ),
            ),
            // 参考原游戏CSS: overflow: hidden - 地图固定大小，不滚动
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(), // 使用更平滑的滚动物理
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: const ClampingScrollPhysics(), // 使用更平滑的滚动物理
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(mapSize, (j) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(mapSize, (i) {
                        // 检查遮罩：只有mask[i][j]为true或者是玩家位置时才显示内容
                        final isPlayerPos = i == curPos[0] && j == curPos[1];
                        final isVisible = mask[i][j] || isPlayerPos;

                        return _buildMapTile(
                          map[i][j],
                          isVisible, // 使用遮罩系统控制可见性
                          isPlayerPos, // 检查是否是玩家位置
                          i, // X坐标
                          j, // Y坐标
                          world,
                        );
                      }),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return Center(
        child: Text(
          '地图渲染错误: $e',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
  }

  /// 构建地图瓦片 - 参考原游戏的drawMap函数逻辑
  Widget _buildMapTile(
      String tile, bool visible, bool isPlayer, int x, int y, World world) {
    // 如果不可见且不是玩家位置，显示空白（对应原游戏的'&nbsp;'）
    if (!visible && !isPlayer) {
      return Container(
        width: 12, // 与其他瓦片保持一致的大小
        height: 12,
        alignment: Alignment.center,
        child: const Text(
          ' ', // 空白字符
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'Courier',
          ),
        ),
      );
    }

    String displayChar;
    Color color = Colors.grey;
    String? tooltip;
    bool isLandmarkStyle = false; // 是否使用地标样式（黑色粗体）

    if (isPlayer) {
      displayChar = '@';
      color = Colors.yellow;
      tooltip = '流浪者';
      isLandmarkStyle = true;
    } else {
      // 参考原游戏的地标显示逻辑
      // 原游戏逻辑：if(typeof World.LANDMARKS[c] != 'undefined' && (c != World.TILE.OUTPOST || !World.outpostUsed(i, j)))

      // 获取原始字符（去掉可能的'!'标记）
      final originalTile = tile.length > 1 ? tile[0] : tile;
      final isVisited = tile.length > 1 && tile.endsWith('!'); // 检查是否已访问
      final isLandmark =
          _isLandmarkTile(originalTile) || originalTile == 'A'; // 村庄也是地标
      final isUsedOutpost = (originalTile == 'P' && world.outpostUsed());

      if (isLandmark && !isUsedOutpost && !isVisited) {
        // 未访问的地标 - 显示为地标样式（黑色粗体）
        displayChar = originalTile;
        final styleResult = _getLandmarkStyle(originalTile);
        color = styleResult['color'];
        tooltip = styleResult['tooltip'];
        isLandmarkStyle = true;
      } else {
        // 已访问的地标、已使用的前哨站或普通地形 - 显示为普通样式
        displayChar = originalTile;

        if (isVisited && isLandmark) {
          // 已访问的地标显示为普通灰色，与原游戏一致（#999）
          color = const Color(0xFF999999); // 原游戏CSS中的#999颜色
          final styleResult = _getLandmarkStyle(originalTile);
          tooltip = styleResult['tooltip'];
        } else {
          // 普通地形或已使用的前哨站
          color = _getTerrainColor(displayChar);
        }
        isLandmarkStyle = false;
      }
    }

    Widget tileWidget = Container(
      width: 12, // 缩小瓦片大小以适应61x61地图
      height: 12,
      alignment: Alignment.center,
      child: Text(
        displayChar,
        style: TextStyle(
          color: color,
          fontSize: 10, // 缩小字体以适应更小的瓦片
          fontFamily: 'Courier',
          fontWeight: isLandmarkStyle ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );

    if (tooltip != null) {
      tileWidget = Tooltip(
        message: tooltip,
        child: tileWidget,
      );
    }

    return tileWidget;
  }

  /// 检查是否是地标瓦片
  bool _isLandmarkTile(String tile) {
    const landmarks = [
      'H',
      'V',
      'O',
      'Y',
      'P',
      'W',
      'I',
      'C',
      'S',
      'B',
      'F',
      'M',
      'U',
      'X'
    ];
    return landmarks.contains(tile);
  }

  /// 获取地标样式 - 参考原游戏，所有未访问地标都使用黑色粗体
  Map<String, dynamic> _getLandmarkStyle(String tile) {
    switch (tile) {
      case 'A': // 村庄
        return {'color': Colors.black, 'tooltip': '村庄'};
      case 'H': // 房子
        return {'color': Colors.black, 'tooltip': '旧房子'};
      case 'V': // 洞穴
        return {'color': Colors.black, 'tooltip': '潮湿洞穴'};
      case 'O': // 小镇
        return {'color': Colors.black, 'tooltip': '废弃小镇'};
      case 'Y': // 城市
        return {'color': Colors.black, 'tooltip': '废墟城市'};
      case 'P': // 前哨站
        return {'color': Colors.black, 'tooltip': '前哨站'};
      case 'W': // 飞船
        return {'color': Colors.black, 'tooltip': '坠毁星舰'};
      case 'I': // 铁矿
        return {'color': Colors.black, 'tooltip': '铁矿'};
      case 'C': // 煤矿
        return {'color': Colors.black, 'tooltip': '煤矿'};
      case 'S': // 硫磺矿
        return {'color': Colors.black, 'tooltip': '硫磺矿'};
      case 'B': // 钻孔
        return {'color': Colors.black, 'tooltip': '钻孔'};
      case 'F': // 战场
        return {'color': Colors.black, 'tooltip': '战场'};
      case 'M': // 沼泽
        return {'color': Colors.black, 'tooltip': '阴暗沼泽'};
      case 'U': // 缓存
        return {'color': Colors.black, 'tooltip': '被摧毁的村庄'};
      case 'X': // 执行者
        return {'color': Colors.black, 'tooltip': '被摧毁的战舰'};
      default:
        return {'color': Colors.black, 'tooltip': null};
    }
  }

  /// 获取地形颜色 - 参考原游戏，普通地形使用#999灰色
  Color _getTerrainColor(String tile) {
    // 所有普通地形都使用原游戏的#999灰色
    return const Color(0xFF999999); // 原游戏CSS中的#999颜色
  }

  /// 构建背包区域 - 参考原游戏的bagspace-world和updateSupplies函数
  Widget _buildBagspace(World world) {
    return Consumer<Path>(
      builder: (context, path, child) {
        final supplies = <Widget>[];

        // 参考原游戏逻辑：首先添加水
        if (world.water > 0) {
          supplies.add(_buildSupplyItem('水', world.water));
        }

        // 然后按照原游戏逻辑添加其他物品
        for (final entry in path.outfit.entries) {
          final itemName = entry.key;
          final num = entry.value;

          if (num > 0) {
            if (itemName == 'cured meat') {
              // 熏肉：如果有水则在水后面，否则在最前面
              if (world.water > 0) {
                // 在水后面插入（这里简化为直接添加）
                supplies.add(_buildSupplyItem('熏肉', num));
              } else {
                // 在最前面插入
                supplies.insert(0, _buildSupplyItem('熏肉', num));
              }
            } else {
              // 其他物品添加到末尾
              supplies
                  .add(_buildSupplyItem(_getItemDisplayName(itemName), num));
            }
          }
        }

        // 计算背包信息
        final total = path.outfit.entries.fold<double>(0.0, (sum, entry) {
          return sum + (entry.value * path.getWeight(entry.key));
        });
        final capacity = path.getCapacity();
        final freeSpace = capacity - total;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
            color: Colors.white,
          ),
          height: 80,
          child: Stack(
            children: [
              // 背包标题
              Positioned(
                top: 0,
                left: 10,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    (StateManager().get('stores["rucksack"]', true) ?? 0) > 0
                        ? '背包'
                        : '口袋',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // 背包空间信息
              Positioned(
                top: 0,
                right: 10,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '剩余 ${freeSpace.floor()}/${capacity.floor()}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              // 物品列表
              Positioned(
                top: 16,
                left: 6,
                right: 6,
                bottom: 6,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(), // 使用更平滑的滚动物理
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 6,
                    children: supplies,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 获取物品显示名称 - 参考原游戏的物品翻译
  String _getItemDisplayName(String itemName) {
    switch (itemName) {
      case 'fur':
        return '毛皮';
      case 'meat':
        return '肉';
      case 'scales':
        return '鳞片';
      case 'teeth':
        return '牙齿';
      case 'cloth':
        return '布料';
      case 'leather':
        return '皮革';
      case 'iron':
        return '铁';
      case 'coal':
        return '煤炭';
      case 'steel':
        return '钢铁';
      case 'sulphur':
        return '硫磺';
      case 'energy cell':
        return '能量电池';
      case 'bullets':
        return '子弹';
      case 'medicine':
        return '药物';
      case 'cured meat':
        return '熏肉';
      case 'bone spear':
        return '骨矛';
      case 'iron sword':
        return '铁剑';
      case 'steel sword':
        return '钢剑';
      case 'bayonet':
        return '刺刀';
      case 'rifle':
        return '步枪';
      case 'laser rifle':
        return '激光步枪';
      case 'grenade':
        return '手榴弹';
      case 'bolas':
        return '流星锤';
      case 'plasma rifle':
        return '等离子步枪';
      case 'energy blade':
        return '能量剑';
      case 'disruptor':
        return '干扰器';
      case 'hypo':
        return '注射器';
      case 'rucksack':
        return '背包';
      default:
        return itemName;
    }
  }

  /// 构建补给品项目
  Widget _buildSupplyItem(String name, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$name: $count',
        style: const TextStyle(color: Colors.black, fontSize: 12), // 黑色文字
      ),
    );
  }

  /// 处理键盘按键
  void _handleKeyPress(KeyDownEvent event, World world) {
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        world.moveNorth();
        break;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        world.moveSouth();
        break;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        world.moveWest();
        break;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        world.moveEast();
        break;
    }
  }

  /// 处理地图点击 - 参考原游戏的click函数，使用象限判断
  void _handleMapClick(TapDownDetails details, World world) {
    final localPosition = details.localPosition;
    final curPos = world.curPos;

    final tileSize = 12.0;
    final padding = 4.0;

    // 参考原游戏的click函数逻辑
    // 计算地图中心点（玩家位置）
    final mapWidth = (30 * 2 + 1) * tileSize; // 61 * 12
    final mapHeight = (30 * 2 + 1) * tileSize; // 61 * 12
    final centreX = padding + mapWidth * curPos[0] / (30 * 2);
    final centreY = padding + mapHeight * curPos[1] / (30 * 2);

    // 计算相对于中心的点击位置
    final clickX = localPosition.dx - centreX;
    final clickY = localPosition.dy - centreY;

    // 使用原游戏的象限判断逻辑
    if (clickX > clickY && clickX < -clickY) {
      world.moveNorth();
    } else if (clickX < clickY && clickX > -clickY) {
      world.moveSouth();
    } else if (clickX < clickY && clickX < -clickY) {
      world.moveWest();
    } else if (clickX > clickY && clickX > -clickY) {
      world.moveEast();
    }
    // 如果点击在玩家位置 (deltaX == 0 && deltaY == 0)，不移动
  }
}
