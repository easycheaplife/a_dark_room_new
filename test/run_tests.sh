#!/bin/bash

# A Dark Room Flutter 测试运行脚本
# 提供简单的测试运行功能，避免复杂的依赖问题

echo "🧪 A Dark Room Flutter 测试套件"
echo "=================================================="

# 检查参数
if [ $# -eq 0 ]; then
    echo "用法: ./test/run_tests.sh <command> [options]"
    echo ""
    echo "命令:"
    echo "  all        - 运行所有测试"
    echo "  core       - 运行核心系统测试"
    echo "  events     - 运行事件系统测试"
    echo "  map        - 运行地图系统测试"
    echo "  backpack   - 运行背包系统测试"
    echo "  ui         - 运行UI系统测试"
    echo "  resources  - 运行资源系统测试"
    echo "  space      - 运行太空系统测试"
    echo "  single     - 运行单个测试文件"
    echo ""
    echo "示例:"
    echo "  ./test/run_tests.sh all"
    echo "  ./test/run_tests.sh events"
    echo "  ./test/run_tests.sh single event_frequency_test.dart"
    exit 0
fi

COMMAND=$1

case $COMMAND in
    "all")
        echo "🚀 运行所有测试..."
        flutter test test/all_tests.dart
        ;;
    "core")
        echo "🎯 运行核心系统测试..."
        flutter test test/state_manager_test.dart
        flutter test test/engine_test.dart
        flutter test test/localization_test.dart
        flutter test test/notification_manager_test.dart
        flutter test test/audio_engine_test.dart
        ;;
    "events")
        echo "📅 运行事件系统测试..."
        flutter test test/event_frequency_test.dart
        flutter test test/event_localization_fix_test.dart
        flutter test test/event_trigger_test.dart
        flutter test test/executioner_events_test.dart
        ;;
    "map")
        echo "🗺️ 运行地图系统测试..."
        flutter test test/landmarks_test.dart
        flutter test test/road_generation_fix_test.dart
        ;;
    "backpack")
        echo "🎒 运行背包系统测试..."
        flutter test test/torch_backpack_check_test.dart
        flutter test test/torch_backpack_simple_test.dart
        flutter test test/original_game_torch_requirements_test.dart
        ;;
    "ui")
        echo "🏛️ 运行UI系统测试..."
        flutter test test/ruined_city_leave_buttons_test.dart
        flutter test test/armor_button_verification_test.dart
        ;;
    "resources")
        echo "💧 运行资源系统测试..."
        flutter test test/water_capacity_test.dart
        ;;
    "space")
        echo "🚀 运行太空系统测试..."
        flutter test test/space_movement_sensitivity_test.dart
        flutter test test/space_optimization_test.dart
        ;;
    "single")
        if [ $# -lt 2 ]; then
            echo "❌ 请指定要运行的测试文件"
            echo "示例: ./test/run_tests.sh single event_frequency_test.dart"
            exit 1
        fi
        TEST_FILE=$2
        if [[ $TEST_FILE != test/* ]]; then
            TEST_FILE="test/$TEST_FILE"
        fi
        echo "🎯 运行单个测试: $TEST_FILE"
        flutter test "$TEST_FILE"
        ;;
    *)
        echo "❌ 未知命令: $COMMAND"
        echo "使用 './test/run_tests.sh' 查看帮助"
        exit 1
        ;;
esac

echo ""
echo "✅ 测试执行完成"
