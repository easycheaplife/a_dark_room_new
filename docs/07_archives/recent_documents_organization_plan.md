# 最近新增文档整理计划

**创建时间**: 2025-06-29  
**目的**: 整理最近新增的文档，将其移动到合适的分类目录中

## 📋 需要整理的文档

### 🔍 当前在根目录的新增文档

1. **`docs/cured_meat_analysis.md`** - 熏肉资源分析
2. **`docs/iron_analysis.md`** - 铁资源分析  
3. **`docs/movement_food_consumption_analysis.md`** - 移动消耗熏肉机制分析
4. **`docs/fabricator_unlock_conditions.md`** - 制造器解锁条件分析
5. **`docs/master_event_trigger_conditions.md`** - 宗师事件触发条件分析

## 📁 整理方案

### 1. 游戏机制分析文档 → `01_game_mechanics/`

#### 移动文档：
- `docs/cured_meat_analysis.md` → `docs/01_game_mechanics/cured_meat_analysis.md`
- `docs/iron_analysis.md` → `docs/01_game_mechanics/iron_analysis.md`
- `docs/movement_food_consumption_analysis.md` → `docs/01_game_mechanics/movement_food_consumption_analysis.md`

#### 理由：
这些文档都是关于游戏核心机制的深度分析，属于游戏机制类别。

### 2. 事件系统分析文档 → `01_game_mechanics/`

#### 移动文档：
- `docs/fabricator_unlock_conditions.md` → `docs/01_game_mechanics/fabricator_unlock_conditions.md`
- `docs/master_event_trigger_conditions.md` → `docs/01_game_mechanics/master_event_trigger_conditions.md`

#### 理由：
这些文档分析特定事件的触发条件，属于游戏机制的事件系统部分。

## 🔄 执行步骤

### 步骤1: 移动资源分析文档
```bash
# 移动熏肉分析文档
mv docs/cured_meat_analysis.md docs/01_game_mechanics/cured_meat_analysis.md

# 移动铁分析文档  
mv docs/iron_analysis.md docs/01_game_mechanics/iron_analysis.md

# 移动移动消耗分析文档
mv docs/movement_food_consumption_analysis.md docs/01_game_mechanics/movement_food_consumption_analysis.md
```

### 步骤2: 移动事件分析文档
```bash
# 移动制造器解锁条件文档
mv docs/fabricator_unlock_conditions.md docs/01_game_mechanics/fabricator_unlock_conditions.md

# 移动宗师事件触发条件文档
mv docs/master_event_trigger_conditions.md docs/01_game_mechanics/master_event_trigger_conditions.md
```

### 步骤3: 更新README文件
更新 `docs/01_game_mechanics/README.md`，添加新增文档的索引。

### 步骤4: 更新导航文件
更新 `docs/QUICK_NAVIGATION.md`，确保新文档可以被快速找到。

## 📚 更新后的目录结构

### `docs/01_game_mechanics/` 目录内容
```
docs/01_game_mechanics/
├── README.md
├── advanced_gameplay_guide.md
├── events_system.md
├── outpost_system.md
├── player_progression.md
├── prestige_system_guide.md
├── room_mechanism.md
├── skills_system_implementation.md
├── terrain_system.md
├── torch_system.md
├── cured_meat_analysis.md          # 新增
├── iron_analysis.md                # 新增
├── movement_food_consumption_analysis.md  # 新增
├── fabricator_unlock_conditions.md # 新增
└── master_event_trigger_conditions.md    # 新增
```

## 🎯 整理后的好处

### 1. 更好的文档组织
- 所有游戏机制相关文档集中在一个目录
- 便于查找和维护
- 符合现有的文档分类体系

### 2. 清晰的根目录
- 根目录只保留核心导航文档
- 避免文档散乱分布
- 提高文档管理效率

### 3. 一致的分类标准
- 按功能和内容类型分类
- 遵循既定的文档组织原则
- 便于后续文档的归类

## 📝 注意事项

### 1. 链接更新
移动文档后需要检查并更新：
- README.md 中的文档链接
- CHANGELOG.md 中的文档路径
- 其他文档中的交叉引用

### 2. 保持一致性
- 确保所有相关文档都使用新的路径
- 更新文档索引和导航
- 维护文档间的关联关系

### 3. 版本控制
- 使用git mv命令移动文件以保持历史记录
- 在commit信息中说明文档重组的原因
- 确保团队成员了解文档位置变更

## ✅ 完成检查清单

- [ ] 移动熏肉分析文档
- [ ] 移动铁分析文档
- [ ] 移动移动消耗分析文档
- [ ] 移动制造器解锁条件文档
- [ ] 移动宗师事件触发条件文档
- [ ] 更新 `docs/01_game_mechanics/README.md`
- [ ] 更新 `docs/QUICK_NAVIGATION.md`
- [ ] 检查并更新所有相关链接
- [ ] 更新 CHANGELOG.md 中的文档路径
- [ ] 验证所有文档链接正常工作
