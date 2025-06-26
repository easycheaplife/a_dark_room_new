# docs目录重组计划

**最后更新**: 2025-06-26

## 📋 当前问题分析

### 存在的问题

1. **文档分散**: 相关主题的文档分散在不同位置
2. **命名不一致**: 文档命名规则不统一
3. **重复内容**: 多个文档包含相似或重复的信息
4. **层级混乱**: 缺乏清晰的文档层级结构
5. **查找困难**: 开发者难以快速找到所需信息

### 影响

- 开发效率降低
- 文档维护困难
- 信息不一致风险
- 新开发者上手困难

## 🎯 重组目标

1. **逻辑分组**: 按功能模块组织文档
2. **统一命名**: 建立一致的命名规范
3. **消除重复**: 合并或整合重复内容
4. **清晰层级**: 建立清晰的文档层级
5. **易于查找**: 提供快速导航和索引

## 📁 建议的新目录结构

```
docs/
├── README.md                           # 文档总索引
├── CHANGELOG.md                        # 变更日志
├── 
├── 01_game_mechanics/                  # 游戏机制
│   ├── README.md                       # 游戏机制总览
│   ├── terrain_system.md              # 地形系统 (整合多个地形文档)
│   ├── torch_system.md                # 火把系统 (整合火把相关文档)
│   ├── player_progression.md          # 玩家进度系统 (整合健康、水容量、背包等)
│   ├── outpost_system.md              # 前哨站系统
│   ├── room_system.md                 # 房间系统
│   ├── skills_system.md               # 技能系统
│   ├── prestige_system.md             # 声望系统
│   └── events_system.md               # 事件系统
│
├── 02_map_design/                      # 地图设计
│   ├── README.md                       # 地图设计总览
│   ├── map_generation.md              # 地图生成机制
│   ├── landmark_system.md             # 地标系统
│   ├── difficulty_design.md           # 难度设计
│   └── exploration_mechanics.md       # 探索机制
│
├── 03_implementation/                  # 实现指南
│   ├── README.md                       # 实现指南总览
│   ├── flutter_migration_guide.md     # Flutter迁移指南
│   ├── localization_guide.md          # 本地化指南
│   ├── testing_guide.md               # 测试指南
│   └── code_consistency_guide.md      # 代码一致性指南
│
├── 04_project_management/              # 项目管理
│   ├── README.md                       # 项目管理总览
│   ├── project_summary.md             # 项目摘要
│   ├── feature_checklist.md           # 功能清单
│   ├── missing_features.md            # 缺失功能
│   └── comparison_analysis.md         # 对比分析
│
├── 05_bug_fixes/                       # Bug修复 (重命名现有bug_fix)
│   ├── README.md                       # Bug修复索引
│   ├── critical/                       # 严重Bug
│   ├── major/                          # 主要Bug
│   ├── minor/                          # 次要Bug
│   └── resolved/                       # 已解决Bug
│
├── 06_optimizations/                   # 优化 (重命名现有optimize)
│   ├── README.md                       # 优化索引
│   ├── performance/                    # 性能优化
│   ├── ui_ux/                          # UI/UX优化
│   └── code_quality/                   # 代码质量优化
│
└── 07_archives/                        # 归档文档
    ├── README.md                       # 归档说明
    ├── deprecated/                     # 已废弃文档
    └── historical/                     # 历史版本文档
```

## 📝 文档整合计划

### 1. 地形系统整合

**目标文档**: `01_game_mechanics/terrain_system.md`

**整合来源**:
- `terrain_analysis.md` (主要内容)
- `terrain_analysis_code_consistency_check.md`
- `terrain_analysis_improvement_plan.md`
- `terrain_analysis_original_game_comparison.md`
- `cave_terrain_verification.md`

**整合策略**: 以terrain_analysis.md为基础，补充其他文档的验证和对比信息

### 2. 火把系统整合

**目标文档**: `01_game_mechanics/torch_system.md`

**整合来源**:
- `original_game_torch_analysis.md` (主要内容)
- `torch_requirements_final_analysis.md`
- `torch_usage_analysis.md`
- `torch_backpack_check_implementation.md`
- `torch_documentation_update_summary.md`

**整合策略**: 以最终分析为基础，整合所有火把相关逻辑

### 3. 玩家进度系统整合

**目标文档**: `01_game_mechanics/player_progression.md`

**整合来源**:
- `player_health_growth_mechanism.md`
- `water_capacity_growth_mechanism.md`
- `backpack_capacity_growth_mechanism.md`

**整合策略**: 统一描述所有玩家属性的增长机制

### 4. 前哨站系统整合

**目标文档**: `01_game_mechanics/outpost_system.md`

**整合来源**:
- `outpost_and_road_system.md`
- `outpost_generation_mechanism.md`
- `landmarks_to_outposts.md`
- `outpost_access_inconsistency_analysis.md`

**整合策略**: 完整描述前哨站的生成、转换和使用机制

### 5. 事件系统整合

**目标文档**: `01_game_mechanics/events_system.md`

**整合来源**:
- `encounter_events_system.md`
- `events_system_complete.md`
- `landmark_event_patterns.md`

**整合策略**: 统一描述所有事件系统的实现

## 🔄 迁移步骤

### 阶段1: 创建新目录结构
1. 创建新的目录结构
2. 创建各目录的README.md索引文件

### 阶段2: 整合核心文档
1. 整合地形系统文档
2. 整合火把系统文档
3. 整合玩家进度系统文档
4. 整合前哨站系统文档
5. 整合事件系统文档

### 阶段3: 重组其他文档
1. 迁移地图设计文档
2. 迁移实现指南文档
3. 迁移项目管理文档
4. 重组Bug修复文档
5. 重组优化文档

### 阶段4: 清理和验证
1. 删除已整合的原文档
2. 更新所有文档间的引用链接
3. 验证文档内容的一致性
4. 更新README.md主索引

## 📋 命名规范

### 文件命名
- 使用小写字母和下划线
- 避免特殊字符和空格
- 使用描述性名称
- 保持名称简洁

### 目录命名
- 使用数字前缀表示优先级
- 使用英文名称便于代码引用
- 保持层级清晰

### 文档标题
- 使用中文标题
- 保持标题层级一致
- 包含最后更新日期

## ✅ 预期效果

### 改进后的优势

1. **结构清晰**: 按功能模块组织，易于理解
2. **查找便捷**: 通过目录索引快速定位
3. **内容统一**: 消除重复和不一致
4. **维护简单**: 相关文档集中管理
5. **扩展性好**: 新文档有明确的归属位置

### 开发者体验提升

1. **新手友好**: 清晰的文档结构便于上手
2. **效率提升**: 快速找到所需信息
3. **一致性保证**: 统一的文档规范
4. **维护便利**: 集中的文档管理

## 📅 实施时间表

- **第1天**: 创建新目录结构和索引文件
- **第2-3天**: 整合核心游戏机制文档
- **第4天**: 重组其他分类文档
- **第5天**: 清理、验证和更新引用

## 🎯 成功指标

1. 文档查找时间减少50%
2. 重复内容减少80%
3. 文档维护工作量减少30%
4. 新开发者上手时间缩短40%
