/// A Dark Room 游戏配置文件
///
/// 包含游戏中各种时间、数值等配置参数
/// 基于原游戏 doublespeakgames/adarkroom 的配置
class GameConfig {
  // ==================== 房间模块配置 ====================

  /// 添柴冷却时间 (秒)
  /// 原游戏: _STOKE_COOLDOWN: 10
  static const int stokeFireCooldown = 10;

  /// 火焰冷却延迟 (毫秒)
  /// 原游戏: _FIRE_COOL_DELAY: 5 * 60 * 1000
  static const int fireCoolDelay = 5 * 60 * 1000; // 5分钟

  /// 房间温度更新延迟 (毫秒)
  /// 原游戏: _ROOM_WARM_DELAY: 30 * 1000
  static const int roomWarmDelay = 30 * 1000; // 30秒

  /// 建造者状态更新延迟 (毫秒)
  /// 原游戏: _BUILDER_STATE_DELAY: 0.5 * 60 * 1000
  static const int builderStateDelay = 30 * 1000; // 30秒 (Flutter版本调整)

  /// 需要木材提示延迟 (毫秒)
  /// 原游戏: _NEED_WOOD_DELAY: 15 * 1000
  static const int needWoodDelay = 15 * 1000; // 15秒

  // ==================== 漫漫尘途模块配置 ====================

  /// 出发冷却时间 (秒)
  /// 原游戏: DEATH_COOLDOWN: 120
  static const int embarkCooldown = 120; // 2分钟

  /// 首次出发是否有冷却时间
  /// 原游戏: 首次出发无冷却，死亡后才有冷却
  static const bool firstEmbarkHasCooldown = false;

  // ==================== 外部模块配置 ====================

  /// 伐木操作延迟 (秒)
  /// 原游戏: _GATHER_DELAY: 60
  static const int gatherWoodDelay = 60;

  /// 查看陷阱操作延迟 (秒)
  /// 原游戏: _TRAPS_DELAY: 90
  static const int checkTrapsDelay = 90;

  /// 人口增长延迟范围 (分钟)
  /// 原游戏: _POP_DELAY: [0.5, 3]
  static const List<double> popDelayRange = [0.5, 3.0];

  /// 每个小屋容纳人数
  /// 原游戏: _HUT_ROOM: 4
  static const int hutRoom = 4;

  // ==================== 事件模块配置 ====================

  /// 事件触发时间范围 (分钟)
  /// 原游戏: _EVENT_TIME_RANGE: [3, 6]
  static const List<int> eventTimeRange = [3, 6];

  /// 面板淡入淡出时间 (毫秒)
  static const int panelFade = 200;

  /// 战斗速度 (毫秒)
  static const int fightSpeed = 100;

  // ==================== 战斗相关配置 ====================

  /// 各种物品冷却时间 (秒)
  static const int eatCooldown = 5;
  static const int medsCooldown = 7;
  static const int hypoCooldown = 7;
  static const int shieldCooldown = 10;
  static const int stimCooldown = 10;
  static const int leaveCooldown = 1;

  /// 各种效果持续时间 (毫秒)
  static const int stunDuration = 4000;
  static const int explosionDuration = 3000;
  static const int enrageDuration = 4000;
  static const int meditateDuration = 5000;
  static const int boostDuration = 3000;

  /// 伤害和治疗数值
  static const int boostDamage = 10;
  static const int energiseMultiplier = 4;
  static const int dotTick = 1000;

  // ==================== 世界地图配置 ====================

  /// 地图半径
  static const int worldRadius = 30;

  /// 村庄位置
  static const List<int> villagePosition = [30, 30];

  /// 粘性系数 (0 <= x <= 1)
  static const double stickiness = 0.5;

  /// 光照半径
  static const int lightRadius = 2;

  /// 基础水量
  static const int baseWater = 10;

  /// 每次移动消耗
  static const int movesPerFood = 2;
  static const int movesPerWater = 1;

  /// 死亡冷却时间 (秒)
  static const int deathCooldown = 120;

  /// 战斗概率
  static const double fightChance = 0.20;

  /// 基础生命值
  static const int baseHealth = 10;

  /// 基础命中率
  static const double baseHitChance = 0.8;

  /// 治疗数值
  static const int meatHeal = 8;
  static const int medsHeal = 20;
  static const int hypoHeal = 30;

  /// 战斗延迟 (移动次数)
  static const int fightDelay = 3;

  /// 战斗动画和延迟配置 (毫秒)
  static const int rangedAttackDelay = 200; // 远程攻击子弹飞行时间
  static const int enemyDisappearDelay = 1000; // 敌人消失动画延迟
  static const int defaultAttackDelay = 2000; // 默认攻击间隔
  static const int specialSkillDelay = 5000; // 特殊技能默认延迟

  // ==================== 太空模块配置 ====================

  /// 飞船速度
  static const double shipSpeed = 3.0;

  /// 小行星相关配置
  static const int baseAsteroidDelay = 500;
  static const int baseAsteroidSpeed = 1500;

  /// FTB速度
  static const int ftbSpeed = 60000;

  /// 星空配置
  static const int starWidth = 3000;
  static const int starHeight = 3000;
  static const int numStars = 200;
  static const int starSpeed = 60000;

  /// 帧延迟
  static const int frameDelay = 100;

  // ==================== UI界面配置 ====================

  /// 按钮宽度配置 (像素)
  static const int combatButtonWidth = 100; // 战斗按钮宽度，参考原游戏CSS
  static const int pathButtonWidth = 130; // 出发按钮宽度，与伐木按钮一致
  static const int defaultButtonWidth = 100; // 默认按钮宽度

  /// 进度时间配置 (毫秒)
  static const int embarkProgressDuration = 1000; // 出发按钮进度时间

  // ==================== 背包和物品配置 ====================

  /// 默认背包空间
  static const int defaultBagSpace = 10;

  /// 物品重量配置
  static const Map<String, double> itemWeights = {
    'bone spear': 2.0,
    'iron sword': 3.0,
    'steel sword': 5.0,
    'rifle': 5.0,
    'bullets': 0.1,
    'energy cell': 0.2,
    'laser rifle': 5.0,
    'plasma rifle': 5.0,
    'bolas': 0.5,
  };

  // ==================== 工人和建筑配置 ====================

  /// 工人收入间隔 (毫秒)
  static const int workerIncomeInterval = 10000; // 10秒

  /// 建筑工人配置
  static const Map<String, List<String>> buildingWorkers = {
    'lodge': ['hunter', 'trapper'],
    'smokehouse': ['charcutier'],
    'tannery': ['tanner'],
  };

  // ==================== UI相关配置 ====================

  /// 进度条动画时间 (毫秒)
  /// 这些是Flutter版本的UI配置，用于ProgressButton组件
  static const int lightFireProgressDuration = stokeFireCooldown * 1000; // 10秒
  static const int stokeFireProgressDuration = stokeFireCooldown * 1000; // 10秒
  static const int gatherWoodProgressDuration = gatherWoodDelay * 1000; // 60秒
  static const int checkTrapsProgressDuration = checkTrapsDelay * 1000; // 90秒

  // ==================== 调试模式配置 ====================

  /// 调试模式下的快速时间配置
  static const bool debugMode = false;

  /// 调试模式下的时间配置 (毫秒)
  static const int debugRoomWarmDelay = 5000;
  static const int debugBuilderStateDelay = 5000;
  static const int debugNeedWoodDelay = 5000;

  /// 调试模式下的操作延迟 (秒)
  static const int debugGatherDelay = 0;
  static const int debugTrapsDelay = 0;
  static const int debugStokeCooldown = 0;

  // ==================== 辅助方法 ====================

  /// 获取当前配置下的添柴冷却时间
  static int getCurrentStokeCooldown() {
    return debugMode ? debugStokeCooldown : stokeFireCooldown;
  }

  /// 获取当前配置下的伐木延迟时间
  static int getCurrentGatherDelay() {
    return debugMode ? debugGatherDelay : gatherWoodDelay;
  }

  /// 获取当前配置下的陷阱检查延迟时间
  static int getCurrentTrapsDelay() {
    return debugMode ? debugTrapsDelay : checkTrapsDelay;
  }

  /// 获取当前配置下的房间温度更新延迟
  static int getCurrentRoomWarmDelay() {
    return debugMode ? debugRoomWarmDelay : roomWarmDelay;
  }

  /// 获取当前配置下的建造者状态更新延迟
  static int getCurrentBuilderStateDelay() {
    return debugMode ? debugBuilderStateDelay : builderStateDelay;
  }

  /// 获取当前配置下的需要木材提示延迟
  static int getCurrentNeedWoodDelay() {
    return debugMode ? debugNeedWoodDelay : needWoodDelay;
  }
}
