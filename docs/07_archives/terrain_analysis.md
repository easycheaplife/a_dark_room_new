# A Dark Room 地形处理逻辑分析

**最后更新**: 2025-06-25

## 概述
本文档分析了A Dark Room游戏中所有地形类型的处理逻辑，包括访问机制、事件触发和状态管理。

## 地形符号对照表

| 符号 | 地形类型 | 分类 | 访问后状态 | 特殊机制 |
|------|----------|------|------------|----------|
| `.` | 荒地 | 普通地形 | 不变 | 消耗补给，可能遭遇战斗 |
| `,` | 田野 | 普通地形 | 不变 | 消耗补给，可能遭遇战斗 |
| `;` | 森林 | 普通地形 | 不变 | 消耗补给，可能遭遇战斗 |
| `#` | 道路 | 普通地形 | 不变 | 消耗补给，可能遭遇战斗 |
| `A` | 村庄 | 特殊地形 | 不变 | 回到小黑屋，不消耗补给 |
| `P` | 前哨站 | 特殊地形 | 变为`P!`(灰色) | 使用后变灰，不可重复使用 |
| `I` | 铁矿 | 矿物地标 | 变为`I!`(灰色) | Setpiece事件，完成后变灰 |
| `C` | 煤矿 | 矿物地标 | 变为`C!`(灰色) | Setpiece事件，完成后变灰 |
| `S` | 硫磺矿 | 矿物地标 | 变为`S!`(灰色) | Setpiece事件，完成后变灰 |
| `V` | 潮湿洞穴 | 复杂地标 | 完成后变为`P`(前哨站) | Setpiece事件，转换为前哨站 |
| `H` | 旧房子 | 简单地标 | 变为`H!`(灰色) | 访问后变灰，不可重复访问 |
| `B` | 钻孔 | 简单地标 | 变为`B!`(灰色) | 访问后变灰，不可重复访问 |
| `F` | 战场 | 简单地标 | 变为`F!`(灰色) | 访问后变灰，不可重复访问 |
| `Y` | 废墟城市 | 简单地标 | 变为`Y!`(灰色) | 访问后变灰，不可重复访问 |
| `W` | 坠毁星舰 | 简单地标 | 变为`W!`(灰色) | 访问后变灰，不可重复访问 |
| `O` | 废弃小镇 | 简单地标 | 变为`O!`(灰色) | 访问后变灰，不可重复访问 |
| `M` | 阴暗沼泽 | 简单地标 | 变为`M!`(灰色) | 访问后变灰，不可重复访问 |
| `U` | 被摧毁的村庄 | 简单地标 | 变为`U!`(灰色) | 访问后变灰，不可重复访问 |
| `X` | 执行者 | 复杂地标 | 变为`X!`(灰色) | Setpiece事件，最终Boss |

## 地形分类

### 1. 特殊地形
#### 村庄 (A)
- **符号**: `A`
- **处理**: 直接调用 `goHome()` 返回小黑屋
- **访问限制**: 无限制，始终可访问
- **状态变化**: 不标记为已访问

#### 前哨站 (P)
- **符号**: `P`
- **处理**: 特殊逻辑，检查是否已使用
- **访问限制**: 每个前哨站只能使用一次补充水源
- **状态变化**: 使用后标记为已访问 (`P!`)，变为灰色
- **功能**: 补充水源到最大值

### 2. 矿物地形（需要Setpiece事件）
这些地形需要通过复杂的Setpiece事件来处理，通常需要特定物品（如火把）。

#### 铁矿 (I)
- **符号**: `I`
- **处理**: 触发 `ironmine` Setpiece事件
- **访问限制**: 完成事件后标记为已访问
- **所需物品**: 火把 (torch)
- **奖励**: 铁、鳞片、布料等
- **解锁**: 完成后解锁村庄的铁矿建筑

#### 煤矿 (C)
- **符号**: `C`
- **处理**: 触发 `coalmine` Setpiece事件
- **访问限制**: 完成事件后标记为已访问
- **所需物品**: 火把 (torch)
- **奖励**: 煤炭、鳞片、布料等
- **解锁**: 完成后解锁村庄的煤矿建筑

#### 硫磺矿 (S)
- **符号**: `S`
- **处理**: 触发 `sulphurmine` Setpiece事件
- **访问限制**: ✅ **已修复** - 不立即标记为已访问，允许重复访问直到完成事件
- **所需物品**: 火把 (torch)
- **奖励**: 硫磺、鳞片、布料等
- **解锁**: 完成后解锁村庄的硫磺矿建筑
- **实现状态**: ✅ 访问状态管理与原游戏完全一致

### 3. 简单地标地形（直接处理）
这些地形有简单的事件处理，访问一次后立即标记为已访问。

#### 旧房子 (H)
- **符号**: `H`
- **处理**: 直接在 `_handleMissingSetpiece` 中处理
- **访问限制**: 访问一次后标记为已访问 (`H!`)
- **奖励**: 
  - 木材 (50%概率，1-3个)
  - 布料 (30%概率，1-2个)

#### 钻孔 (B)
- **符号**: `B`
- **处理**: 直接在 `_handleMissingSetpiece` 中处理
- **访问限制**: 访问一次后标记为已访问 (`B!`)
- **奖励**: 无物质奖励，仅有描述文本

#### 战场 (F)
- **符号**: `F`
- **处理**: 直接在 `_handleMissingSetpiece` 中处理
- **访问限制**: 访问一次后标记为已访问 (`F!`)
- **奖励**: 
  - 子弹 (40%概率，1-5个)
  - 步枪 (20%概率，1个)

#### 废墟城市 (Y)
- **符号**: `Y`
- **处理**: 直接在 `_handleMissingSetpiece` 中处理
- **访问限制**: 访问一次后标记为已访问 (`Y!`)
- **奖励**: 无物质奖励，仅有描述文本

#### 坠毁星舰 (W)
- **符号**: `W`
- **处理**: 直接在 `_handleMissingSetpiece` 中处理
- **访问限制**: 访问一次后标记为已访问 (`W!`)
- **奖励**: 无物质奖励，仅有描述文本

#### 废弃小镇 (O)
- **符号**: `O`
- **处理**: 直接在 `_handleMissingSetpiece` 中处理
- **访问限制**: 访问一次后标记为已访问 (`O!`)
- **奖励**: 
  - 布料 (40%概率，1-3个)
  - 皮革 (30%概率，1-2个)
  - 药物 (20%概率，1个)

### 4. 复杂地标地形（需要Setpiece事件）
#### 潮湿洞穴 (V)
- **符号**: `V`
- **处理**: 触发 `cave` Setpiece事件（如缺失则使用默认处理）
- **访问限制**:
  - ✅ **已验证**: 不立即标记为已访问，允许重复访问
  - ✅ **已验证**: 只有完成探索后才转换为前哨站 (`P`)
- **所需物品**: 无（但深入探索可能需要火把）
- **奖励**: 根据探索深度获得不同奖励（默认：毛皮30%，牙齿20%）
- **特殊机制**: 完成后通过 `clearDungeon()` 转换为前哨站
- **实现状态**: ✅ 访问状态管理与原游戏完全一致

#### 阴暗沼泽 (M)
- **符号**: `M`
- **处理**: 直接在 `_handleMissingSetpiece` 中处理
- **访问限制**: 访问一次后标记为已访问 (`M!`)
- **奖励**: 
  - 鳞片 (30%概率，1-2个)
  - 牙齿 (20%概率，1-3个)
  - 外星合金 (10%概率，1个)

#### 被摧毁的村庄 (U)
- **符号**: `U`
- **处理**: 直接在 `_handleMissingSetpiece` 中处理
- **访问限制**: 访问一次后标记为已访问 (`U!`)
- **奖励**: 无物质奖励，仅有描述文本

#### 执行者 (X)
- **符号**: `X`
- **处理**: 触发 `executioner` Setpiece事件
- **访问限制**: 完成事件后标记为已访问
- **距离**: 固定在距离村庄28格处
- **数量**: 1个
- **特殊**: 游戏的最终Boss，需要高级装备

### 5. 普通地形
这些地形是地图的基础组成部分，可无限次通过，消耗补给并可能遭遇战斗。

#### 荒地 (.)
- **符号**: `.`
- **处理**: 消耗补给，检查战斗
- **访问限制**: 无限制
- **状态变化**: 不标记为已访问
- **生成概率**: 50%（最常见的地形）

#### 田野 (,)
- **符号**: `,`
- **处理**: 消耗补给，检查战斗
- **访问限制**: 无限制
- **状态变化**: 不标记为已访问
- **生成概率**: 35%

#### 森林 (;)
- **符号**: `;`
- **处理**: 消耗补给，检查战斗
- **访问限制**: 无限制
- **状态变化**: 不标记为已访问
- **生成概率**: 15%
- **特殊**: 村庄周围必须是森林

#### 道路 (#)
- **符号**: `#`
- **处理**: 消耗补给，检查战斗
- **访问限制**: 无限制
- **状态变化**: 不标记为已访问
- **特殊**: 由系统自动生成，连接村庄和前哨站

## 访问状态管理

### 标记机制
- **未访问**: 地形显示原始符号 (如 `I`, `H`, `F`)
- **已访问**: 地形符号后添加 `!` (如 `I!`, `H!`, `F!`)
- **视觉效果**: 已访问的地形在地图上显示为灰色

### markVisited() 函数
```dart
void markVisited(int x, int y) {
  if (state != null && state!['map'] != null) {
    final map = state!['map'];
    if (!map[x][y].endsWith('!')) {
      map[x][y] = map[x][y] + '!';
      // 更新临时状态，回到村庄时保存
    }
  }
}
```

### 状态持久化
- **临时状态**: 在探险过程中，访问状态保存在临时的 `state` 对象中
- **永久保存**: 只有回到村庄时，通过 `goHome()` 函数将状态保存到 `StateManager`
- **死亡重置**: 如果玩家死亡，所有临时状态丢失

## 问题分析：地形I重复访问

### 问题现象
玩家报告访问地形I（铁矿）后，还可以继续访问，没有被标记为已访问。

### 可能原因
1. **事件未完成**: 玩家进入铁矿事件但没有完成整个流程就离开
2. **markVisited时机**: 只有在 `clearIronMine()` 中才调用 `markVisited()`
3. **状态保存**: 如果玩家没有回到村庄，临时状态不会被保存

### 解决方案
需要在铁矿事件的开始阶段就标记为已访问，而不是等到完成时才标记。

## 设计原则

### 1. 一次性地标
大部分地标（H, B, F, Y, W, O, M, U）都是一次性的，访问后立即标记为已访问。

### 2. 复杂地标
- **矿物地标**（I, C, S）：需要通过Setpiece事件处理，完成后才标记为已访问
- **洞穴地标**（V）：✅ 特殊访问机制，不立即标记为已访问，允许重复探索
- **执行者**（X）：最终Boss，需要Setpiece事件处理

### 2.1 特殊访问机制
- **洞穴地标(V)**: ✅ 已验证 - 不立即标记为已访问，允许重复探索
- **执行者地标(X)**: 不立即标记为已访问，等待完整事件实现
- **其他地标**: 访问后立即标记为已访问，不可重复访问

### 3. 特殊地标
- **村庄**（A）：始终可访问，回到小黑屋
- **前哨站**（P）：可重复访问但只能使用一次补充水源

### 4. 普通地形
所有普通地形（., ,, ;, #）不标记访问状态，可无限次通过，但会消耗补给并可能遭遇战斗。

## 技术实现

### doSpace() 函数流程
1. 获取当前地形和访问状态
2. 检查地形类型：
   - 村庄 → 回家
   - 前哨站 → 检查使用状态
   - 地标 → 检查访问状态，触发相应事件
   - 普通地形 → 消耗补给，检查战斗

### 事件触发机制
- **Setpiece事件**: 复杂的多场景事件（矿物地标）
- **直接处理**: 简单的一次性奖励（其他地标）

### 状态同步
- **临时状态**: 探险期间的地图变化
- **永久状态**: 回到村庄时保存的状态
- **装备同步**: 获得的物品立即同步到装备中
