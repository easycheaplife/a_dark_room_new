/// 音频库 - 定义所有音频文件路径
/// 对应原始游戏的 AudioLibrary 模块
/// 参考原游戏 AudioLibrary 常量定义
class AudioLibrary {
  // 原游戏常量映射 - 与原游戏JavaScript保持一致

  // 背景音乐常量 (MUSIC_*)
  static const String MUSIC_DUSTY_PATH = 'audio/dusty-path.flac';
  static const String MUSIC_SILENT_FOREST = 'audio/silent-forest.flac';
  static const String MUSIC_LONELY_HUT = 'audio/lonely-hut.flac';
  static const String MUSIC_TINY_VILLAGE = 'audio/tiny-village.flac';
  static const String MUSIC_MODEST_VILLAGE = 'audio/modest-village.flac';
  static const String MUSIC_LARGE_VILLAGE = 'audio/large-village.flac';
  static const String MUSIC_RAUCOUS_VILLAGE = 'audio/raucous-village.flac';

  // 火焰状态音乐常量
  static const String MUSIC_FIRE_DEAD = 'audio/fire-dead.flac';
  static const String MUSIC_FIRE_SMOLDERING = 'audio/fire-smoldering.flac';
  static const String MUSIC_FIRE_FLICKERING = 'audio/fire-flickering.flac';
  static const String MUSIC_FIRE_BURNING = 'audio/fire-burning.flac';
  static const String MUSIC_FIRE_ROARING = 'audio/fire-roaring.flac';

  // 场景音乐常量
  static const String MUSIC_WORLD = 'audio/world.flac';
  static const String MUSIC_SPACE = 'audio/space.flac';
  static const String MUSIC_ENDING = 'audio/ending.flac';
  static const String MUSIC_SHIP = 'audio/ship.flac';

  // 事件音乐常量 (EVENT_*)
  static const String EVENT_NOMAD = 'audio/event-nomad.flac';
  static const String EVENT_NOISES_OUTSIDE = 'audio/event-noises-outside.flac';
  static const String EVENT_NOISES_INSIDE = 'audio/event-noises-inside.flac';
  static const String EVENT_BEGGAR = 'audio/event-beggar.flac';
  static const String EVENT_SHADY_BUILDER = 'audio/event-shady-builder.flac';
  static const String EVENT_MYSTERIOUS_WANDERER =
      'audio/event-mysterious-wanderer.flac';
  static const String EVENT_SCOUT = 'audio/event-scout.flac';
  static const String EVENT_WANDERING_MASTER =
      'audio/event-wandering-master.flac';
  static const String EVENT_SICK_MAN = 'audio/event-sick-man.flac';
  static const String EVENT_RUINED_TRAP = 'audio/event-ruined-trap.flac';
  static const String EVENT_HUT_FIRE = 'audio/event-hut-fire.flac';
  static const String EVENT_SICKNESS = 'audio/event-sickness.flac';
  static const String EVENT_PLAGUE = 'audio/event-plague.flac';
  static const String EVENT_BEAST_ATTACK = 'audio/event-beast-attack.flac';
  static const String EVENT_SOLDIER_ATTACK = 'audio/event-soldier-attack.flac';
  static const String EVENT_THIEF = 'audio/event-thief.flac';

  // 动作音效常量 - 与原游戏Room.Craftables中的audio字段对应
  static const String LIGHT_FIRE = 'audio/light-fire.flac';
  static const String STOKE_FIRE = 'audio/stoke-fire.flac';
  static const String BUILD = 'audio/build.flac';
  static const String CRAFT = 'audio/craft.flac';
  static const String BUY = 'audio/buy.flac';
  static const String GATHER_WOOD = 'audio/gather-wood.flac';
  static const String CHECK_TRAPS = 'audio/check-traps.flac';
  static const String EMBARK = 'audio/embark.flac';

  // 建造音效常量 - 对应原游戏Room.Craftables
  static const String BUILD_TRAP = 'audio/build.flac';
  static const String BUILD_CART = 'audio/build.flac';
  static const String BUILD_HUT = 'audio/build.flac';
  static const String BUILD_LODGE = 'audio/build.flac';
  static const String BUILD_TRADING_POST = 'audio/build.flac';
  static const String BUILD_TANNERY = 'audio/build.flac';
  static const String BUILD_SMOKEHOUSE = 'audio/build.flac';
  static const String BUILD_WORKSHOP = 'audio/build.flac';
  static const String BUILD_STEELWORKS = 'audio/build.flac';
  static const String BUILD_ARMOURY = 'audio/build.flac';

  // 制作音效常量 - 对应原游戏Room.Craftables
  static const String CRAFT_TORCH = 'audio/craft.flac';
  static const String CRAFT_WATERSKIN = 'audio/craft.flac';
  static const String CRAFT_CASK = 'audio/craft.flac';
  static const String CRAFT_WATER_TANK = 'audio/craft.flac';
  static const String CRAFT_BONE_SPEAR = 'audio/craft.flac';
  static const String CRAFT_RUCKSACK = 'audio/craft.flac';
  static const String CRAFT_WAGON = 'audio/craft.flac';
  static const String CRAFT_CONVOY = 'audio/craft.flac';
  static const String CRAFT_LEATHER_ARMOUR = 'audio/craft.flac';
  static const String CRAFT_IRON_ARMOUR = 'audio/craft.flac';
  static const String CRAFT_STEEL_ARMOUR = 'audio/craft.flac';
  static const String CRAFT_IRON_SWORD = 'audio/craft.flac';
  static const String CRAFT_STEEL_SWORD = 'audio/craft.flac';
  static const String CRAFT_RIFLE = 'audio/craft.flac';

  // 购买音效常量 - 对应原游戏Room.TradeGoods
  static const String BUY_SCALES = 'audio/buy.flac';
  static const String BUY_TEETH = 'audio/buy.flac';
  static const String BUY_IRON = 'audio/buy.flac';
  static const String BUY_COAL = 'audio/buy.flac';
  static const String BUY_STEEL = 'audio/buy.flac';
  static const String BUY_MEDICINE = 'audio/buy.flac';
  static const String BUY_BULLETS = 'audio/buy.flac';
  static const String BUY_ENERGY_CELL = 'audio/buy.flac';
  static const String BUY_BOLAS = 'audio/buy.flac';
  static const String BUY_GRENADES = 'audio/buy.flac';
  static const String BUY_BAYONET = 'audio/buy.flac';
  static const String BUY_ALIEN_ALLOY = 'audio/buy.flac';
  static const String BUY_COMPASS = 'audio/buy.flac';

  // 地标音乐常量
  static const String LANDMARK_FRIENDLY_OUTPOST =
      'audio/landmark-friendly-outpost.flac';
  static const String LANDMARK_SWAMP = 'audio/landmark-swamp.flac';
  static const String LANDMARK_CAVE = 'audio/landmark-cave.flac';
  static const String LANDMARK_TOWN = 'audio/landmark-town.flac';
  static const String LANDMARK_CITY = 'audio/landmark-city.flac';
  static const String LANDMARK_HOUSE = 'audio/landmark-house.flac';
  static const String LANDMARK_BATTLEFIELD = 'audio/landmark-battlefield.flac';
  static const String LANDMARK_BOREHOLE = 'audio/landmark-borehole.flac';
  static const String LANDMARK_CRASHED_SHIP =
      'audio/landmark-crashed-ship.flac';
  static const String LANDMARK_SULPHUR_MINE = 'audio/landmark-sulphurmine.flac';
  static const String LANDMARK_COAL_MINE = 'audio/landmark-coalmine.flac';
  static const String LANDMARK_IRON_MINE = 'audio/landmark-ironmine.flac';
  static const String LANDMARK_DESTROYED_VILLAGE =
      'audio/landmark-destroyed-village.flac';

  // 遭遇战音乐常量
  static const String ENCOUNTER_TIER_1 = 'audio/encounter-tier-1.flac';
  static const String ENCOUNTER_TIER_2 = 'audio/encounter-tier-2.flac';
  static const String ENCOUNTER_TIER_3 = 'audio/encounter-tier-3.flac';

  // 脚步声常量
  static const String FOOTSTEPS_1 = 'audio/footsteps-1.flac';
  static const String FOOTSTEPS_2 = 'audio/footsteps-2.flac';
  static const String FOOTSTEPS_3 = 'audio/footsteps-3.flac';
  static const String FOOTSTEPS_4 = 'audio/footsteps-4.flac';
  static const String FOOTSTEPS_5 = 'audio/footsteps-5.flac';
  static const String FOOTSTEPS_6 = 'audio/footsteps-6.flac';

  // 生存音效常量
  static const String EAT_MEAT = 'audio/eat-meat.flac';
  static const String USE_MEDS = 'audio/use-meds.flac';

  // 武器音效常量 - 徒手
  static const String WEAPON_UNARMED_1 = 'audio/weapon-unarmed-1.flac';
  static const String WEAPON_UNARMED_2 = 'audio/weapon-unarmed-2.flac';
  static const String WEAPON_UNARMED_3 = 'audio/weapon-unarmed-3.flac';

  // 武器音效常量 - 近战
  static const String WEAPON_MELEE_1 = 'audio/weapon-melee-1.flac';
  static const String WEAPON_MELEE_2 = 'audio/weapon-melee-2.flac';
  static const String WEAPON_MELEE_3 = 'audio/weapon-melee-3.flac';

  // 武器音效常量 - 远程
  static const String WEAPON_RANGED_1 = 'audio/weapon-ranged-1.flac';
  static const String WEAPON_RANGED_2 = 'audio/weapon-ranged-2.flac';
  static const String WEAPON_RANGED_3 = 'audio/weapon-ranged-3.flac';

  // 特殊音效常量
  static const String DEATH = 'audio/death.flac';
  static const String REINFORCE_HULL = 'audio/reinforce-hull.flac';
  static const String UPGRADE_ENGINE = 'audio/upgrade-engine.flac';
  static const String LIFT_OFF = 'audio/lift-off.flac';
  static const String CRASH = 'audio/crash.flac';

  // 小行星撞击音效常量
  static const String ASTEROID_HIT_1 = 'audio/asteroid-hit-1.flac';
  static const String ASTEROID_HIT_2 = 'audio/asteroid-hit-2.flac';
  static const String ASTEROID_HIT_3 = 'audio/asteroid-hit-3.flac';
  static const String ASTEROID_HIT_4 = 'audio/asteroid-hit-4.flac';
  static const String ASTEROID_HIT_5 = 'audio/asteroid-hit-5.flac';
  static const String ASTEROID_HIT_6 = 'audio/asteroid-hit-6.flac';
  static const String ASTEROID_HIT_7 = 'audio/asteroid-hit-7.flac';
  static const String ASTEROID_HIT_8 = 'audio/asteroid-hit-8.flac';

  // 音频预加载列表 - 参考原游戏Engine.init()中的预加载逻辑
  static const List<String> PRELOAD_MUSIC = [
    MUSIC_FIRE_DEAD,
    MUSIC_FIRE_SMOLDERING,
    MUSIC_FIRE_FLICKERING,
    MUSIC_FIRE_BURNING,
    MUSIC_FIRE_ROARING,
    MUSIC_WORLD,
    MUSIC_SHIP,
    MUSIC_SPACE,
  ];

  static const List<String> PRELOAD_EVENTS = [
    EVENT_NOMAD,
    EVENT_NOISES_OUTSIDE,
    EVENT_BEGGAR,
    EVENT_MYSTERIOUS_WANDERER,
    EVENT_SCOUT,
  ];

  static const List<String> PRELOAD_SOUNDS = [
    LIGHT_FIRE,
    STOKE_FIRE,
    BUILD,
    CRAFT,
    BUY,
    GATHER_WOOD,
    CHECK_TRAPS,
  ];

  // 兼容性别名 - 保持向后兼容
  // 背景音乐
  static const String musicDustyPath = MUSIC_DUSTY_PATH;
  static const String musicSilentForest = 'audio/silent-forest.flac';
  static const String musicLonelyHut = 'audio/lonely-hut.flac';
  static const String musicTinyVillage = 'audio/tiny-village.flac';
  static const String musicModestVillage = 'audio/modest-village.flac';
  static const String musicLargeVillage = 'audio/large-village.flac';
  static const String musicRaucousVillage = 'audio/raucous-village.flac';

  // 火焰状态音乐
  static const String musicFireDead = 'audio/fire-dead.flac';
  static const String musicFireSmoldering = 'audio/fire-smoldering.flac';
  static const String musicFireFlickering = 'audio/fire-flickering.flac';
  static const String musicFireBurning = 'audio/fire-burning.flac';
  static const String musicFireRoaring = 'audio/fire-roaring.flac';

  // 场景音乐
  static const String musicWorld = 'audio/world.flac';
  static const String musicSpace = 'audio/space.flac';
  static const String musicEnding = 'audio/ending.flac';
  static const String musicShip = 'audio/ship.flac';

  // 事件音乐
  static const String eventNomad = 'audio/event-nomad.flac';
  static const String eventNoisesOutside = 'audio/event-noises-outside.flac';
  static const String eventNoisesInside = 'audio/event-noises-inside.flac';
  static const String eventBeggar = 'audio/event-beggar.flac';
  static const String eventShadyBuilder = 'audio/event-shady-builder.flac';
  static const String eventMysteriousWanderer =
      'audio/event-mysterious-wanderer.flac';
  static const String eventScout = 'audio/event-scout.flac';
  static const String eventWanderingMaster =
      'audio/event-wandering-master.flac';
  static const String eventSickMan = 'audio/event-sick-man.flac';
  static const String eventRuinedTrap = 'audio/event-ruined-trap.flac';
  static const String eventHutFire = 'audio/event-hut-fire.flac';
  static const String eventSickness = 'audio/event-sickness.flac';
  static const String eventPlague = 'audio/event-plague.flac';
  static const String eventBeastAttack = 'audio/event-beast-attack.flac';
  static const String eventSoldierAttack = 'audio/event-soldier-attack.flac';
  static const String eventThief = 'audio/event-thief.flac';

  // 地标音乐
  static const String landmarkFriendlyOutpost =
      'audio/landmark-friendly-outpost.flac';
  static const String landmarkSwamp = 'audio/landmark-swamp.flac';
  static const String landmarkCave = 'audio/landmark-cave.flac';
  static const String landmarkTown = 'audio/landmark-town.flac';
  static const String landmarkCity = 'audio/landmark-city.flac';
  static const String landmarkHouse = 'audio/landmark-house.flac';
  static const String landmarkBattlefield = 'audio/landmark-battlefield.flac';
  static const String landmarkBorehole = 'audio/landmark-borehole.flac';
  static const String landmarkCrashedShip = 'audio/landmark-crashed-ship.flac';
  static const String landmarkSulphurMine = 'audio/landmark-sulphurmine.flac';
  static const String landmarkCoalMine = 'audio/landmark-coalmine.flac';
  static const String landmarkIronMine = 'audio/landmark-ironmine.flac';
  static const String landmarkDestroyedVillage =
      'audio/landmark-destroyed-village.flac';

  // 遭遇战音乐
  static const String encounterTier1 = 'audio/encounter-tier-1.flac';
  static const String encounterTier2 = 'audio/encounter-tier-2.flac';
  static const String encounterTier3 = 'audio/encounter-tier-3.flac';

  // 动作音效
  static const String lightFire = 'audio/light-fire.flac';
  static const String stokeFire = 'audio/stoke-fire.flac';
  static const String build = 'audio/build.flac';
  static const String craft = 'audio/craft.flac';
  static const String buy = 'audio/buy.flac';
  static const String gatherWood = 'audio/gather-wood.flac';
  static const String checkTraps = 'audio/check-traps.flac';
  static const String embark = 'audio/embark.flac';

  // 脚步声
  static const String footsteps1 = 'audio/footsteps-1.flac';
  static const String footsteps2 = 'audio/footsteps-2.flac';
  static const String footsteps3 = 'audio/footsteps-3.flac';
  static const String footsteps4 = 'audio/footsteps-4.flac';
  static const String footsteps5 = 'audio/footsteps-5.flac';
  static const String footsteps6 = 'audio/footsteps-6.flac';

  // 生存音效
  static const String eatMeat = 'audio/eat-meat.flac';
  static const String useMeds = 'audio/use-meds.flac';

  // 武器音效 - 徒手
  static const String weaponUnarmed1 = 'audio/weapon-unarmed-1.flac';
  static const String weaponUnarmed2 = 'audio/weapon-unarmed-2.flac';
  static const String weaponUnarmed3 = 'audio/weapon-unarmed-3.flac';

  // 武器音效 - 近战
  static const String weaponMelee1 = 'audio/weapon-melee-1.flac';
  static const String weaponMelee2 = 'audio/weapon-melee-2.flac';
  static const String weaponMelee3 = 'audio/weapon-melee-3.flac';

  // 武器音效 - 远程
  static const String weaponRanged1 = 'audio/weapon-ranged-1.flac';
  static const String weaponRanged2 = 'audio/weapon-ranged-2.flac';
  static const String weaponRanged3 = 'audio/weapon-ranged-3.flac';

  // 特殊音效
  static const String death = 'audio/death.flac';
  static const String reinforceHull = 'audio/reinforce-hull.flac';
  static const String upgradeEngine = 'audio/upgrade-engine.flac';
  static const String liftOff = 'audio/lift-off.flac';
  static const String crash = 'audio/crash.flac';

  // 小行星撞击音效
  static const String asteroidHit1 = 'audio/asteroid-hit-1.flac';
  static const String asteroidHit2 = 'audio/asteroid-hit-2.flac';
  static const String asteroidHit3 = 'audio/asteroid-hit-3.flac';
  static const String asteroidHit4 = 'audio/asteroid-hit-4.flac';
  static const String asteroidHit5 = 'audio/asteroid-hit-5.flac';
  static const String asteroidHit6 = 'audio/asteroid-hit-6.flac';
  static const String asteroidHit7 = 'audio/asteroid-hit-7.flac';
  static const String asteroidHit8 = 'audio/asteroid-hit-8.flac';

  /// 根据火焰状态获取音乐
  static String getFireMusic(String fireState) {
    switch (fireState) {
      case 'dead':
        return musicFireDead;
      case 'smoldering':
        return musicFireSmoldering;
      case 'flickering':
        return musicFireFlickering;
      case 'burning':
        return musicFireBurning;
      case 'roaring':
        return musicFireRoaring;
      default:
        return musicFireDead;
    }
  }

  /// 根据村庄大小获取音乐
  static String getVillageMusic(int population) {
    if (population <= 0) {
      return musicLonelyHut;
    } else if (population <= 10) {
      return musicTinyVillage;
    } else if (population <= 30) {
      return musicModestVillage;
    } else if (population <= 60) {
      return musicLargeVillage;
    } else {
      return musicRaucousVillage;
    }
  }

  /// 获取随机脚步声
  static String getRandomFootsteps() {
    final footsteps = [
      footsteps1,
      footsteps2,
      footsteps3,
      footsteps4,
      footsteps5,
      footsteps6,
    ];
    return footsteps[
        (DateTime.now().millisecondsSinceEpoch % footsteps.length)];
  }

  /// 获取随机武器音效
  static String getRandomWeaponSound(String weaponType) {
    switch (weaponType) {
      case 'unarmed':
        final sounds = [weaponUnarmed1, weaponUnarmed2, weaponUnarmed3];
        return sounds[(DateTime.now().millisecondsSinceEpoch % sounds.length)];
      case 'melee':
        final sounds = [weaponMelee1, weaponMelee2, weaponMelee3];
        return sounds[(DateTime.now().millisecondsSinceEpoch % sounds.length)];
      case 'ranged':
        final sounds = [weaponRanged1, weaponRanged2, weaponRanged3];
        return sounds[(DateTime.now().millisecondsSinceEpoch % sounds.length)];
      default:
        return weaponUnarmed1;
    }
  }

  /// 获取随机小行星撞击音效
  static String getRandomAsteroidHitSound() {
    final sounds = [
      asteroidHit1,
      asteroidHit2,
      asteroidHit3,
      asteroidHit4,
      asteroidHit5,
      asteroidHit6,
      asteroidHit7,
      asteroidHit8,
    ];
    return sounds[(DateTime.now().millisecondsSinceEpoch % sounds.length)];
  }
}
