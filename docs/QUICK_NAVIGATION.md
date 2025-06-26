# 📚 文档快速导航索引

**最后更新**: 2025-06-26

## 🎯 快速查找指南

### 按问题类型查找

#### 🔍 "我想了解游戏机制"
- [游戏机制总览](01_game_mechanics/README.md) - 所有游戏机制的入口
- [地形系统](01_game_mechanics/terrain_system.md) - 地形处理和探索机制
- [火把系统](01_game_mechanics/torch_system.md) - 火把需求和使用机制
- [玩家进度系统](01_game_mechanics/player_progression.md) - 健康、水容量、背包成长
- [前哨站系统](01_game_mechanics/outpost_system.md) - 前哨站生成和管理
- [事件系统](01_game_mechanics/events_system.md) - 所有事件类型和处理

#### 🛠️ "我想了解技术实现"
- [实现指南总览](03_implementation/README.md) - 技术实现的入口
- [Flutter实现指南](03_implementation/flutter_implementation_guide.md) - 完整的技术架构
- [本地化进度](03_implementation/localization_progress.md) - 多语言实现状态

#### 🗺️ "我想了解地图设计"
- [地图设计总览](02_map_design/README.md) - 地图设计的入口
- [地图设计机制分析](02_map_design/map_design_analysis.md) - 核心设计理念
- [地图难度设计](02_map_design/map_difficulty_design.md) - 难度平衡机制
- [地图探索机制](02_map_design/map_exploration_and_progress_saving.md) - 探索和保存

#### 📊 "我想了解项目状态"
- [项目管理总览](04_project_management/README.md) - 项目管理的入口
- [功能状态报告](04_project_management/feature_status.md) - 完整的功能状态
- [项目总结](04_project_management/project_summary.md) - 项目整体情况

#### 🐛 "我遇到了问题"
- [Bug修复目录](05_bug_fixes/) - 所有已知问题的修复记录
- [一致性验证报告](04_project_management/terrain_analysis_consistency_verification_report.md) - 代码一致性检查

#### ⚡ "我想优化性能"
- [优化目录](06_optimizations/) - 所有性能优化记录
- [技术实现对比](04_project_management/feature_status.md#技术实现对比) - 架构优势分析

### 按开发阶段查找

#### 🚀 新手入门
1. [项目总结](project_summary.md) - 了解项目概况
2. [Flutter实现指南](flutter_implementation_guide.md) - 了解技术架构
3. [游戏机制总览](01_game_mechanics/README.md) - 了解游戏系统

#### 🔧 功能开发
1. [功能状态报告](04_project_management/feature_status.md) - 查看功能完成度
2. [地形系统](01_game_mechanics/terrain_system.md) - 地形相关开发
3. [事件系统](01_game_mechanics/events_system.md) - 事件相关开发

#### 🧪 测试验证
1. [一致性验证报告](terrain_analysis_consistency_verification_report.md) - 地形系统验证
2. [火把需求验证](torch_requirements_consistency_verification_report.md) - 火把系统验证
3. [地标转换验证](landmark_conversion_consistency_verification_report.md) - 转换机制验证

#### 📝 文档维护
1. [文档整理报告](docs_organization_completion_report.md) - 文档整理情况
2. [重复文档整合计划](duplicate_documents_consolidation_plan.md) - 整合策略
3. [归档说明](07_archives/README.md) - 已删除文档记录

## 🔗 关键链接速查

### 核心系统
| 系统 | 主文档 | 验证报告 | 实现状态 |
|------|--------|----------|----------|
| 地形 | [地形系统](01_game_mechanics/terrain_system.md) | [验证报告](terrain_analysis_consistency_verification_report.md) | 96% ✅ |
| 火把 | [火把系统](01_game_mechanics/torch_system.md) | [验证报告](torch_requirements_consistency_verification_report.md) | 98% ✅ |
| 进度 | [玩家进度](01_game_mechanics/player_progression.md) | [验证报告](game_mechanics_consistency_verification_report.md) | 94% ✅ |
| 前哨站 | [前哨站系统](01_game_mechanics/outpost_system.md) | [验证报告](landmark_conversion_consistency_verification_report.md) | 92% ✅ |
| 事件 | [事件系统](01_game_mechanics/events_system.md) | - | 100% ✅ |

### 项目管理
| 类型 | 文档 | 用途 |
|------|------|------|
| 总体状态 | [功能状态报告](04_project_management/feature_status.md) | 查看整体进度 |
| 项目总结 | [项目总结](project_summary.md) | 了解项目概况 |
| 变更记录 | [CHANGELOG.md](CHANGELOG.md) | 查看更新历史 |

### 技术实现
| 方面 | 文档 | 用途 |
|------|------|------|
| 架构设计 | [Flutter实现指南](flutter_implementation_guide.md) | 技术架构参考 |
| 本地化 | [本地化进度](localization_progress.md) | 多语言实现 |
| 地图设计 | [地图设计分析](a_dark_room_map_design_analysis.md) | 设计理念 |

## 🎮 游戏机制速查

### 关键数值
| 属性 | 基础值 | 最大值 | 升级路径 |
|------|--------|--------|----------|
| 健康 | 10 | 85 | 护甲升级 |
| 水容量 | 10 | 110 | 容器升级 |
| 背包 | 10 | 110 | 载具升级 |

### 火把需求
| 地形 | 需要火把 | 数量 |
|------|----------|------|
| 潮湿洞穴 (V) | ✅ | 1个 |
| 铁矿 (I) | ✅ | 1个 |
| 煤矿 (C) | ❌ | 0个 |
| 硫磺矿 (S) | ❌ | 0个 |

### 地标转换
| 地标 | 转换条件 | 结果 |
|------|----------|------|
| 潮湿洞穴 (V) | 完全探索 | 前哨站 |
| 废弃小镇 (O) | 完全探索 | 前哨站 |
| 废墟城市 (Y) | 完全探索 | 前哨站 |
| 执行者 (X) | 击败Boss | 前哨站 |

## 📋 常见问题快速解答

### Q: 如何查看某个功能的完成状态？
**A**: 查看 [功能状态报告](04_project_management/feature_status.md)

### Q: 如何了解地形处理逻辑？
**A**: 查看 [地形系统完整指南](01_game_mechanics/terrain_system.md)

### Q: 如何了解火把的使用规则？
**A**: 查看 [火把系统完整指南](01_game_mechanics/torch_system.md)

### Q: 如何查看已修复的Bug？
**A**: 查看 [bug_fix目录](bug_fix/) 下的相关文档

### Q: 如何了解项目的技术架构？
**A**: 查看 [Flutter实现指南](flutter_implementation_guide.md)

### Q: 如何查看文档的变更历史？
**A**: 查看 [CHANGELOG.md](CHANGELOG.md) 和各文档的"最后更新"标记

### Q: 如何找到已删除的文档内容？
**A**: 查看 [归档说明](07_archives/README.md) 了解内容整合情况

## 🔍 搜索技巧

### 按关键词搜索
- **地形**: terrain, 地形, doSpace, 地标
- **火把**: torch, 火把, 背包检查, cost
- **前哨站**: outpost, 前哨站, clearDungeon, 道路
- **事件**: event, 事件, setpiece, 遭遇
- **状态**: state, 状态, StateManager, 存档

### 按文件类型搜索
- **系统指南**: `*_system.md`
- **验证报告**: `*_verification_report.md`
- **Bug修复**: `bug_fix/*.md`
- **优化记录**: `optimize/*.md`
- **目录索引**: `*/README.md`

## 📱 移动端友好

本导航索引设计为移动端友好，支持：
- 快速滚动到相关章节
- 清晰的层级结构
- 简洁的链接格式
- 关键信息突出显示

---

*本导航索引涵盖了docs目录中的所有重要文档，为开发者提供最便捷的文档查找体验。*
