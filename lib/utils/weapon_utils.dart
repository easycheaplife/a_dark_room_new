/// 武器工具类 - 统一管理武器相关逻辑
/// 
/// 基于原游戏World.Weapons的定义，提供统一的武器判断和分类功能
/// 确保所有模块中的武器列表保持一致
class WeaponUtils {
  /// 所有武器列表（除了默认的fists）
  /// 基于原游戏World.Weapons定义
  static const List<String> allWeapons = [
    'bone spear',     // 骨枪 - 近战武器
    'iron sword',     // 铁剑 - 近战武器
    'steel sword',    // 钢剑 - 近战武器
    'bayonet',        // 刺刀 - 近战武器
    'rifle',          // 步枪 - 远程武器
    'laser rifle',    // 激光步枪 - 远程武器
    'grenade',        // 手榴弹 - 远程武器
    'bolas',          // 流星锤 - 远程武器
    'plasma rifle',   // 等离子步枪 - 远程武器
    'energy blade',   // 能量刀 - 近战武器
    'disruptor'       // 干扰器 - 远程武器
  ];

  /// 近战武器列表
  static const List<String> meleeWeapons = [
    'bone spear',
    'iron sword',
    'steel sword',
    'bayonet',
    'energy blade'
  ];

  /// 远程武器列表
  static const List<String> rangedWeapons = [
    'rifle',
    'laser rifle',
    'grenade',
    'bolas',
    'plasma rifle',
    'disruptor'
  ];

  /// 判断是否为武器
  /// 
  /// [itemName] 物品名称
  /// 返回true如果是武器，false如果不是
  static bool isWeapon(String itemName) {
    return allWeapons.contains(itemName);
  }

  /// 判断是否为近战武器
  /// 
  /// [itemName] 物品名称
  /// 返回true如果是近战武器，false如果不是
  static bool isMeleeWeapon(String itemName) {
    return meleeWeapons.contains(itemName);
  }

  /// 判断是否为远程武器
  /// 
  /// [itemName] 物品名称
  /// 返回true如果是远程武器，false如果不是
  static bool isRangedWeapon(String itemName) {
    return rangedWeapons.contains(itemName);
  }

  /// 获取武器类型
  /// 
  /// [itemName] 物品名称
  /// 返回'melee'、'ranged'或null（如果不是武器）
  static String? getWeaponType(String itemName) {
    if (isMeleeWeapon(itemName)) {
      return 'melee';
    } else if (isRangedWeapon(itemName)) {
      return 'ranged';
    }
    return null;
  }

  /// 获取所有武器数量
  static int get weaponCount => allWeapons.length;

  /// 获取近战武器数量
  static int get meleeWeaponCount => meleeWeapons.length;

  /// 获取远程武器数量
  static int get rangedWeaponCount => rangedWeapons.length;
}
