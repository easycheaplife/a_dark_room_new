import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/state_manager.dart';
import '../core/localization.dart';

/// 设置屏幕 - 包含游戏导入导出功能
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _saveTimeInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSaveTimeInfo();
  }

  Future<void> _loadSaveTimeInfo() async {
    final stateManager = Provider.of<StateManager>(context, listen: false);
    final timeInfo = await stateManager.getSaveTimeInfo();
    setState(() {
      _saveTimeInfo = timeInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<StateManager, Localization>(
      builder: (context, stateManager, localization, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              '游戏设置',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Times New Roman',
              ),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 保存状态信息
                _buildSaveInfoSection(stateManager),

                const SizedBox(height: 30),

                // 导入导出提示
                _buildImportExportHintSection(),

                const SizedBox(height: 30),

                // 危险操作
                _buildDangerSection(stateManager),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaveInfoSection(StateManager stateManager) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💾 保存状态',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Times New Roman',
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _saveTimeInfo != null ? '最后保存：$_saveTimeInfo' : '暂无保存记录',
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Times New Roman',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '游戏每30秒自动保存一次',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Times New Roman',
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportExportHintSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💾 导入/导出存档',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Times New Roman',
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '要导入或导出游戏存档，请点击右上角的导入/导出按钮 📥',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Times New Roman',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '• 导出：将当前游戏进度保存为文本，可以备份或分享\n• 导入：从导出的文本恢复游戏进度\n• 完全兼容原游戏存档格式',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Times New Roman',
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSection(StateManager stateManager) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚠️ 危险操作',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Times New Roman',
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '清除所有游戏数据，重新开始游戏（此操作不可撤销）',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Times New Roman',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _clearGameData(stateManager),
            icon: const Icon(Icons.delete_forever),
            label: const Text('清除游戏数据'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearGameData(StateManager stateManager) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 危险操作'),
        content: const Text('确定要清除所有游戏数据吗？此操作不可撤销！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确定清除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await stateManager.clearGameData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ 游戏数据已清除'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadSaveTimeInfo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 清除失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
