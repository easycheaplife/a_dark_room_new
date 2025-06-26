# 原游戏A Dark Room火把需求分析

**最后更新**: 2025-06-26

## 概述

基于原游戏源代码`../adarkroom/script/events/setpieces.js`的详细分析，确定哪些地形真正需要火把。

## 🔍 原游戏源代码分析结果

### ✅ 需要火把的地形

#### 1. 洞穴 (Cave) - 地形标记 V
```javascript
"cave": {
    title: _('A Damp Cave'),
    scenes: {
        'start': {
            buttons: {
                'enter': {
                    text: _('go inside'),
                    cost: { torch: 1 },  // ✅ 需要1个火把
                    nextScene: {0.3: 'a1', 0.6: 'a2', 1: 'a3'}
                }
            }
        }
    }
}
```

#### 2. 废弃小镇 (Town) - 地形标记 O
```javascript
"town": {
    title: _('A Deserted Town'),
    scenes: {
        'start': {
            buttons: {
                'enter': {
                    text: _('explore'),
                    nextScene: {0.3: 'a1', 0.7: 'a3', 1: 'a2'}
                    // ❌ 初始进入不需要火把
                }
            }
        },
        'a1': {
            buttons: {
                'enter': {
                    text: _('enter'),
                    nextScene: {0.5: 'b1', 1: 'b2'},
                    cost: {torch: 1}  // ✅ 进入建筑需要1个火把
                }
            }
        },
        'a3': {
            buttons: {
                'enter': {
                    text: _('enter'),
                    nextScene: {0.5: 'b5', 1: 'end5'},
                    cost: {torch: 1}  // ✅ 进入建筑需要1个火把
                }
            }
        }
    }
}
```

#### 3. 废墟城市 (City) - 地形标记 Y
```javascript
"city": {
    title: _('A Ruined City'),
    scenes: {
        'a1': {
            buttons: {
                'enter': {
                    text: _('enter'),
                    cost: { 'torch': 1 },  // ✅ 进入医院需要1个火把
                    nextScene: {0.5: 'b7', 1: 'b8'}
                }
            }
        },
        'c9': {
            buttons: {
                'enter': {
                    text: _('investigate'),
                    cost: { 'torch': 1 },  // ✅ 调查隧道需要1个火把
                    nextScene: {0.5: 'd2', 1: 'd3'}
                }
            }
        }
    }
}
```

#### 4. 铁矿 (Iron Mine) - 地形标记 I
```javascript
"ironmine": {
    title: _('The Iron Mine'),
    scenes: {
        'start': {
            buttons: {
                'enter': {
                    text: _('go inside'),
                    nextScene: { 1: 'enter' },
                    cost: { 'torch': 1 }  // ✅ 需要1个火把
                }
            }
        }
    }
}
```

### ❌ 不需要火把的地形

#### 1. 煤矿 (Coal Mine) - 地形标记 C
```javascript
"coalmine": {
    title: _('The Coal Mine'),
    scenes: {
        'start': {
            buttons: {
                'attack': {
                    text: _('attack'),
                    nextScene: {1: 'a1'}
                    // ❌ 直接攻击，不需要火把
                }
            }
        }
    }
}
```

#### 2. 硫磺矿 (Sulphur Mine) - 地形标记 S
```javascript
"sulphurmine": {
    title: _('The Sulphur Mine'),
    scenes: {
        'start': {
            buttons: {
                'attack': {
                    text: _('attack'),
                    nextScene: {1: 'a1'}
                    // ❌ 直接攻击，不需要火把
                }
            }
        }
    }
}
```

## 📊 火把需求总结

### ✅ 需要火把的地形 (4个)

| 地形 | 标记 | 火把需求 | 使用场景 |
|------|------|----------|----------|
| 潮湿洞穴 | V | 1个 | 进入洞穴探索 |
| 废弃小镇 | O | 1个 | 进入建筑物内部 |
| 废墟城市 | Y | 1个 | 进入医院/调查隧道 |
| 铁矿 | I | 1个 | 进入矿井 |

### ❌ 不需要火把的地形 (2个)

| 地形 | 标记 | 火把需求 | 原因 |
|------|------|----------|------|
| 煤矿 | C | 无 | 直接攻击场景 |
| 硫磺矿 | S | 无 | 直接攻击场景 |

## 🔧 关键发现

### 1. 废弃小镇的复杂逻辑

废弃小镇(Town)有两层逻辑：
- **初始探索**: 不需要火把，可以直接进入小镇
- **进入建筑**: 需要火把照明，进入具体建筑物时需要1个火把

### 2. 矿山的区别

- **铁矿**: 需要火把进入，因为是探索场景
- **煤矿/硫磺矿**: 不需要火把，因为是直接攻击军事据点

### 3. 城市的特殊情况

废墟城市(City)在某些特定场景中需要火把：
- 进入废弃医院
- 调查地下隧道

## 🎯 与当前实现的对比

### 当前实现的错误

1. **过度简化**: 将所有"危险"地形都加入火把检查
2. **忽略复杂逻辑**: 没有考虑废弃小镇的两层逻辑
3. **错误分类**: 将煤矿和硫磺矿归类为需要火把的地形

### 需要修复的问题

1. **废弃小镇**: 初始进入不需要火把，只有进入建筑时才需要
2. **煤矿/硫磺矿**: 完全不需要火把检查
3. **城市**: 需要在特定场景中检查火把

## 🔄 修复建议

### 1. 更新火把检查逻辑

```dart
bool _needsTorchCheck(String setpieceName, String? sceneName) {
  switch (setpieceName) {
    case 'cave':
      return sceneName == 'start'; // 洞穴进入时需要
    case 'town':
      return sceneName == 'a1' || sceneName == 'a3'; // 进入建筑时需要
    case 'city':
      return sceneName == 'a1' || sceneName == 'c9'; // 特定场景需要
    case 'ironmine':
      return sceneName == 'start'; // 铁矿进入时需要
    default:
      return false; // 其他地形不需要
  }
}
```

### 2. 移除错误的火把检查

- 煤矿(coalmine): 完全移除火把检查
- 硫磺矿(sulphurmine): 完全移除火把检查

## 📝 结论

原游戏的火把需求比之前分析的更复杂：

1. **洞穴**: 始终需要火把 ✅
2. **废弃小镇**: 只在进入建筑时需要火把 ⚠️
3. **废墟城市**: 只在特定场景需要火把 ⚠️
4. **铁矿**: 进入时需要火把 ✅
5. **煤矿**: 不需要火把 ❌
6. **硫磺矿**: 不需要火把 ❌

这个分析纠正了之前文档中的错误，确保了与原游戏的完全一致性。
