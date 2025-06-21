import 'package:flutter/material.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';

/// 分数模块 - 处理游戏的分数计算系统
/// 包括各种成就和里程碑的分数统计
class Score extends ChangeNotifier {
  static final Score _instance = Score._internal();

  factory Score() {
    return _instance;
  }

  static Score get instance => _instance;

  Score._internal();

  // 模块名称
  String get name {
    final localization = Localization();
    return localization.translate('score.module_name');
  }

  /// 分数权重配置
  static const Map<String, int> scoreWeights = {
    // 基础资源分数
    'wood': 1,
    'fur': 2,
    'meat': 2,
    'iron': 3,
    'coal': 3,
    'sulphur': 5,
    'steel': 5,
    'cured meat': 3,
    'scales': 4,
    'teeth': 2,
    'leather': 3,
    'bait': 2,
    'torch': 2,
    'cloth': 3,

    // 武器分数
    'bone spear': 10,
    'iron sword': 20,
    'steel sword': 30,
    'bayonet': 25,
    'rifle': 40,
    'laser rifle': 60,
    'energy blade': 80,
    'plasma rifle': 100,
    'disruptor': 50,

    // 弹药分数
    'bullets': 2,
    'energy cell': 5,
    'grenade': 10,
    'bolas': 8,

    // 特殊物品分数
    'alien alloy': 50,
    'medicine': 15,
    'hypo': 25,
    'stim': 20,
    'glowstone': 30,

    // 建筑分数
    'trap': 5,
    'cart': 10,
    'hut': 20,
    'lodge': 30,
    'trading post': 40,
    'tannery': 50,
    'smokehouse': 60,
    'workshop': 80,
    'steelworks': 100,
    'armoury': 120,

    // 工人分数
    'builder': 10,
    'hunter': 15,
    'trapper': 12,
    'tanner': 18,
    'charcutier': 20,
    'iron miner': 25,
    'coal miner': 25,
    'sulphur miner': 30,
    'armourer': 35,
    'steelworker': 40,
    'gatherer': 8,
  };

  /// 里程碑分数
  static const Map<String, int> milestoneScores = {
    'first_fire': 100,
    'first_building': 200,
    'first_worker': 300,
    'first_exploration': 500,
    'first_combat': 400,
    'reached_ship': 1000,
    'built_ship': 2000,
    'escaped_planet': 5000,
    'completed_game': 10000,
  };

  /// 计算物品分数
  int calculateStoresScore() {
    final sm = StateManager();
    int totalScore = 0;

    for (final entry in scoreWeights.entries) {
      final itemName = entry.key;
      final weight = entry.value;
      final amount = (sm.get('stores["$itemName"]', true) ?? 0) as int;
      totalScore += amount * weight;
    }

    return totalScore;
  }

  /// 计算里程碑分数
  int calculateMilestonesScore() {
    final sm = StateManager();
    int totalScore = 0;

    for (final entry in milestoneScores.entries) {
      final milestone = entry.key;
      final score = entry.value;
      final achieved = sm.get('milestones["$milestone"]', true) == true;
      if (achieved) {
        totalScore += score;
      }
    }

    return totalScore;
  }

  /// 计算探索分数
  int calculateExplorationScore() {
    final sm = StateManager();
    
    // 基于探索的地图格子数量
    final exploredTiles = (sm.get('game.world.exploredTiles', true) ?? 0) as int;
    
    // 基于到达的地标数量
    final visitedLandmarks = (sm.get('game.world.visitedLandmarks', true) ?? 0) as int;
    
    return exploredTiles * 2 + visitedLandmarks * 50;
  }

  /// 计算战斗分数
  int calculateCombatScore() {
    final sm = StateManager();
    
    // 基于击败的敌人数量
    final enemiesDefeated = (sm.get('game.combat.enemiesDefeated', true) ?? 0) as int;
    
    // 基于战斗胜利次数
    final battlesWon = (sm.get('game.combat.battlesWon', true) ?? 0) as int;
    
    return enemiesDefeated * 10 + battlesWon * 25;
  }

  /// 计算生存分数
  int calculateSurvivalScore() {
    final sm = StateManager();
    
    // 基于生存天数
    final daysAlive = (sm.get('game.stats.daysAlive', true) ?? 0) as int;
    
    // 基于移动步数
    final stepsTaken = (sm.get('game.stats.stepsTaken', true) ?? 0) as int;
    
    return daysAlive * 5 + (stepsTaken / 100).floor();
  }

  /// 计算总分数
  int totalScore() {
    int total = 0;
    
    total += calculateStoresScore();
    total += calculateMilestonesScore();
    total += calculateExplorationScore();
    total += calculateCombatScore();
    total += calculateSurvivalScore();
    
    return total;
  }

  /// 获取分数详情
  Map<String, int> getScoreBreakdown() {
    return {
      'stores': calculateStoresScore(),
      'milestones': calculateMilestonesScore(),
      'exploration': calculateExplorationScore(),
      'combat': calculateCombatScore(),
      'survival': calculateSurvivalScore(),
      'total': totalScore(),
    };
  }

  /// 获取分数等级
  String getScoreRank(int score) {
    final localization = Localization();
    if (score >= 50000) {
      return localization.translate('score.ranks.legendary_wanderer');
    } else if (score >= 25000) {
      return localization.translate('score.ranks.master_explorer');
    } else if (score >= 15000) {
      return localization.translate('score.ranks.veteran_adventurer');
    } else if (score >= 10000) {
      return localization.translate('score.ranks.experienced_traveler');
    } else if (score >= 5000) {
      return localization.translate('score.ranks.skilled_survivor');
    } else if (score >= 2500) {
      return localization.translate('score.ranks.novice_explorer');
    } else if (score >= 1000) {
      return localization.translate('score.ranks.junior_adventurer');
    } else {
      return localization.translate('score.ranks.beginner');
    }
  }

  /// 记录里程碑
  void recordMilestone(String milestone) {
    final sm = StateManager();
    sm.set('milestones["$milestone"]', true);
    notifyListeners();
  }

  /// 检查里程碑是否已达成
  bool isMilestoneAchieved(String milestone) {
    final sm = StateManager();
    return sm.get('milestones["$milestone"]', true) == true;
  }

  /// 获取已达成的里程碑列表
  List<String> getAchievedMilestones() {
    final achieved = <String>[];
    for (final milestone in milestoneScores.keys) {
      if (isMilestoneAchieved(milestone)) {
        achieved.add(milestone);
      }
    }
    return achieved;
  }

  /// 获取里程碑描述
  String getMilestoneDescription(String milestone) {
    final localization = Localization();
    final key = 'score.milestones.$milestone';
    final translated = localization.translate(key);
    return translated != key ? translated : milestone;
  }

  /// 获取分数统计
  Map<String, dynamic> getScoreStats() {
    final breakdown = getScoreBreakdown();
    final total = breakdown['total']!;
    
    return {
      'breakdown': breakdown,
      'rank': getScoreRank(total),
      'achievedMilestones': getAchievedMilestones(),
      'totalMilestones': milestoneScores.length,
      'completionPercentage': (getAchievedMilestones().length / milestoneScores.length * 100).round(),
    };
  }

  /// 重置分数（用于新游戏）
  void reset() {
    final sm = StateManager();
    for (final milestone in milestoneScores.keys) {
      sm.remove('milestones["$milestone"]');
    }
    sm.remove('game.stats');
    sm.remove('game.combat');
    sm.remove('game.world.exploredTiles');
    sm.remove('game.world.visitedLandmarks');
    notifyListeners();
  }
}
