# 测试覆盖率报告

**生成时间**: 2025-07-08 16:24
**报告类型**: 自动化测试覆盖率分析

## 📊 总体覆盖率统计

| 指标 | 数量 | 百分比 |
|------|------|--------|
| 源代码文件总数 | 63 | 100% |
| 已覆盖文件数 | 15 | 24% |
| 未覆盖文件数 | 48 | 76% |
| 测试文件总数 | 35 | - |

## 🏗️ 模块覆盖率详情

| 模块 | 总文件数 | 已覆盖 | 未覆盖 | 覆盖率 |
|------|----------|--------|--------|--------|
| root | 63 | 15 | 48 | 24% |

## 🧪 测试分类统计

### 核心系统 (8个测试)

- `audio_engine_test.dart`
- `engine_test.dart`
- `event_localization_fix_test.dart`
- `localization_test.dart`
- `notification_display_test.dart`
- `notification_manager_test.dart`
- `state_manager_simple_test.dart`
- `state_manager_test.dart`

### 游戏模块 (3个测试)

- `outside_module_test.dart`
- `room_module_test.dart`
- `ship_building_upgrade_system_test.dart`

### 事件系统 (3个测试)

- `event_frequency_test.dart`
- `event_trigger_test.dart`
- `executioner_events_test.dart`

### 地图系统 (2个测试)

- `landmarks_test.dart`
- `road_generation_fix_test.dart`

### 背包系统 (3个测试)

- `original_game_torch_requirements_test.dart`
- `torch_backpack_check_test.dart`
- `torch_backpack_simple_test.dart`

### UI系统 (3个测试)

- `armor_button_verification_test.dart`
- `progress_button_test.dart`
- `ruined_city_leave_buttons_test.dart`

### 资源系统 (2个测试)

- `crafting_system_verification_test.dart`
- `water_capacity_test.dart`

### 太空系统 (2个测试)

- `space_movement_sensitivity_test.dart`
- `space_optimization_test.dart`

### 音频系统 (1个测试)

- `audio_system_optimization_test.dart`

### 其他 (8个测试)

- `cave_landmark_integration_test.dart`
- `cave_setpiece_test.dart`
- `executioner_boss_fight_test.dart`
- `game_flow_integration_test.dart`
- `header_test.dart`
- `module_interaction_test.dart`
- `performance_test.dart`
- `run_coverage_tests.dart`

## ⚠️ 未覆盖文件列表

以下文件尚未有对应的测试：

- `config\game_config.dart`
- `core\audio_library.dart`
- `core\logger.dart`
- `core\notifications.dart`
- `core\progress_manager.dart`
- `core\responsive_layout.dart`
- `core\visibility_manager.dart`
- `core\visibility_manager_mobile.dart`
- `core\visibility_manager_stub.dart`
- `core\visibility_manager_web.dart`
- `core\web_audio_adapter.dart`
- `events\global_events.dart`
- `events\outside_events.dart`
- `events\outside_events_extended.dart`
- `events\room_events.dart`
- `events\room_events_extended.dart`
- `events\world_events.dart`
- `main.dart`
- `modules\fabricator.dart`
- `modules\path.dart`
- `modules\prestige.dart`
- `modules\score.dart`
- `modules\setpieces.dart`
- `modules\world.dart`
- `screens\combat_screen.dart`
- `screens\events_screen.dart`
- `screens\fabricator_screen.dart`
- `screens\outside_screen.dart`
- `screens\path_screen.dart`
- `screens\room_screen.dart`
- `screens\settings_screen.dart`
- `screens\ship_screen.dart`
- `screens\space_screen.dart`
- `screens\world_screen.dart`
- `utils\platform_adapter.dart`
- `utils\share_manager.dart`
- `utils\storage_adapter.dart`
- `utils\storage_adapter_mobile.dart`
- `utils\weapon_utils.dart`
- `utils\web_storage.dart`
- `utils\web_utils.dart`
- `utils\wechat_adapter.dart`
- `widgets\game_button.dart`
- `widgets\game_ending_dialog.dart`
- `widgets\import_export_dialog.dart`
- `widgets\simple_button.dart`
- `widgets\stores_display.dart`
- `widgets\unified_stores_container.dart`

## 💡 改进建议

- 🔴 **覆盖率偏低**: 当前覆盖率为 24%，建议提升至80%以上
- 📝 **优先添加测试**: 为上述 48 个未覆盖文件添加测试
- 🔄 **定期更新**: 建议每次代码变更后重新生成覆盖率报告

