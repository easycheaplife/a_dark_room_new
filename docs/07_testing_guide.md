# 测试指南

**创建时间**: 2025-07-08  
**文档类型**: 测试开发指南  
**适用范围**: 整个项目的测试开发  

## 📋 概述

本文档提供了项目的完整测试指南，包括测试策略、工具使用、最佳实践和自动化流程。

## 🎯 测试策略

### 测试金字塔

```
    🔺 E2E测试 (5%)
   🔺🔺 集成测试 (15%)  
  🔺🔺🔺 单元测试 (80%)
```

- **单元测试**: 测试单个函数、类或组件
- **集成测试**: 测试模块间的交互
- **端到端测试**: 测试完整的用户流程

### 测试分类

1. **🎯 核心系统测试** - 引擎、状态管理、本地化等
2. **🎮 游戏模块测试** - Room、Outside、World等模块
3. **🖥️ UI组件测试** - 按钮、界面、交互等
4. **📊 集成测试** - 模块间交互、数据流
5. **⚡ 性能测试** - 内存、渲染、响应时间

## 🛠️ 测试工具

### 核心工具

- **Flutter Test**: 主要测试框架
- **Mockito**: Mock对象生成
- **SharedPreferences Mock**: 存储模拟
- **Logger**: 测试日志输出

### 自定义工具

- **测试覆盖率工具**: `test/simple_coverage_tool.dart`
- **自动化测试运行器**: `test/run_coverage_tests.dart`
- **测试配置**: `test/test_config.dart`

## 📁 测试目录结构

```
test/
├── core/                    # 核心系统测试
│   ├── state_manager_test.dart
│   ├── engine_test.dart
│   ├── localization_test.dart
│   └── ...
├── modules/                 # 游戏模块测试
│   ├── room_module_test.dart
│   ├── outside_module_test.dart
│   └── ...
├── ui/                      # UI组件测试
│   ├── button_tests.dart
│   └── ...
├── integration/             # 集成测试
├── performance/             # 性能测试
├── all_tests.dart          # 所有测试入口
├── test_config.dart        # 测试配置
└── test_runner.dart        # 测试运行器
```

## ✍️ 编写测试

### 基本测试结构

```dart
import 'package:flutter_test/flutter_test.dart';
import '../lib/core/logger.dart';
import 'test_config.dart';

void main() {
  group('🧪 模块名称测试', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Logger.info('🚀 开始测试套件');
    });

    setUp(() {
      // 每个测试前的设置
    });

    tearDown() {
      // 每个测试后的清理
    });

    group('功能分组', () {
      test('应该正确执行某功能', () {
        Logger.info('🧪 测试描述');
        
        // 准备
        // 执行
        // 验证
        expect(actual, equals(expected));
        
        Logger.info('✅ 测试通过');
      });
    });

    tearDownAll(() {
      Logger.info('🏁 测试套件完成');
    });
  });
}
```

### 测试命名规范

- **测试文件**: `模块名_test.dart`
- **测试组**: `🧪 模块名称测试`
- **测试用例**: `应该正确执行某功能`
- **日志**: 使用emoji和中文描述

### Mock对象使用

```dart
// 设置SharedPreferences Mock
SharedPreferences.setMockInitialValues({});

// 设置资源加载Mock
TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    .setMockMessageHandler('flutter/assets', (message) async {
  final String key = utf8.decode(message!.buffer.asUint8List());
  if (key == 'assets/lang/zh.json') {
    return utf8.encode(mockJson).buffer.asByteData();
  }
  return null;
});
```

## 🚀 运行测试

### 命令行运行

```bash
# 运行所有测试
dart test/all_tests.dart

# 运行特定测试
dart test test/state_manager_test.dart

# 运行测试分类
dart test/run_coverage_tests.dart --category core

# 生成覆盖率报告
dart test/simple_coverage_tool.dart
```

### 自动化测试

```bash
# 完整自动化测试
dart test/run_coverage_tests.dart --threshold 80 --verbose

# 指定覆盖率阈值
dart test/run_coverage_tests.dart --threshold 90

# 不生成报告
dart test/run_coverage_tests.dart --no-report
```

### 脚本运行

```bash
# Linux/Mac
./test/run_tests.sh core

# Windows
test\run_tests.bat core
```

## 📊 测试覆盖率

### 覆盖率目标

- **短期目标**: 80%
- **中期目标**: 85%
- **长期目标**: 90%+

### 覆盖率检查

```bash
# 生成覆盖率报告
dart test/simple_coverage_tool.dart

# 查看报告
cat docs/test_coverage_report.md
```

### 覆盖率改进

1. **识别未覆盖文件**: 查看报告中的未覆盖列表
2. **优先级排序**: 核心系统 > 游戏模块 > UI组件
3. **逐步添加**: 每次提交增加1-2个测试文件
4. **定期检查**: 每周生成覆盖率报告

## 🔄 CI/CD集成

### GitHub Actions

项目配置了自动化CI/CD流程：

- **测试运行**: 每次push和PR触发
- **覆盖率检查**: 自动生成报告
- **性能测试**: 检查构建大小
- **安全扫描**: 检查敏感信息
- **预览部署**: PR自动部署预览

### 工作流程

1. **代码提交** → 触发CI
2. **运行测试** → 检查功能
3. **覆盖率检查** → 验证质量
4. **性能测试** → 确保性能
5. **安全扫描** → 保证安全
6. **部署预览** → 验证效果

## 📝 最佳实践

### 测试编写

1. **测试先行**: 先写测试，再写实现
2. **单一职责**: 每个测试只验证一个功能
3. **清晰命名**: 测试名称要描述期望行为
4. **独立性**: 测试间不应相互依赖
5. **可重复**: 测试结果应该一致

### 测试维护

1. **定期更新**: 代码变更时同步更新测试
2. **重构测试**: 消除重复代码
3. **性能优化**: 避免测试运行过慢
4. **文档更新**: 保持测试文档最新

### 调试技巧

1. **使用Logger**: 添加详细日志
2. **分步验证**: 逐步检查中间状态
3. **Mock验证**: 确保Mock设置正确
4. **隔离问题**: 单独运行失败测试

## 🔧 故障排除

### 常见问题

1. **测试超时**
   - 检查异步操作
   - 增加超时时间
   - 优化测试逻辑

2. **Mock失败**
   - 验证Mock设置
   - 检查路径匹配
   - 确认数据格式

3. **状态污染**
   - 清理测试状态
   - 重置单例对象
   - 隔离测试环境

4. **依赖问题**
   - 更新依赖版本
   - 检查兼容性
   - 重新获取依赖

### 调试命令

```bash
# 详细输出
dart test --verbose

# 单个测试
dart test test/specific_test.dart

# 调试模式
dart test --pause-after-load
```

## 📈 测试指标

### 关键指标

- **测试覆盖率**: 代码覆盖百分比
- **测试通过率**: 通过测试的百分比
- **测试执行时间**: 测试套件运行时间
- **缺陷发现率**: 测试发现的问题数量

### 监控方法

1. **自动化报告**: CI/CD生成报告
2. **定期检查**: 每周查看指标
3. **趋势分析**: 跟踪指标变化
4. **持续改进**: 根据指标优化

## 🔗 相关文档

- [测试覆盖率报告](test_coverage_report.md)
- [Bug修复记录](05_bug_fixes/)
- [功能优化记录](06_optimizations/)
- [项目README](../README.md)

## 📞 支持

如有测试相关问题，请：

1. 查看本文档
2. 检查测试日志
3. 参考现有测试
4. 提交Issue讨论
