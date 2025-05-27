import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _importController = TextEditingController();
  String? _saveTimeInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSaveTimeInfo();
  }

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
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
                
                // 导出功能
                _buildExportSection(stateManager),
                
                const SizedBox(height: 30),
                
                // 导入功能
                _buildImportSection(stateManager),
                
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

  Widget _buildExportSection(StateManager stateManager) {
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
            '📤 导出游戏',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Times New Roman',
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '将当前游戏进度导出为文本，可以备份或分享给其他设备',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Times New Roman',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _exportGame(stateManager),
            icon: const Icon(Icons.download),
            label: const Text('导出游戏数据'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportSection(StateManager stateManager) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📥 导入游戏',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Times New Roman',
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '从导出的文本恢复游戏进度（会覆盖当前进度）',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Times New Roman',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _importController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '在此粘贴导出的游戏数据...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _importGame(stateManager),
            icon: const Icon(Icons.upload),
            label: const Text('导入游戏数据'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
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

  Future<void> _exportGame(StateManager stateManager) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exportData = stateManager.exportGameState();
      
      // 复制到剪贴板
      await Clipboard.setData(ClipboardData(text: exportData));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 游戏数据已复制到剪贴板'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 导出失败：$e'),
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

  Future<void> _importGame(StateManager stateManager) async {
    final importData = _importController.text.trim();
    
    if (importData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ 请输入要导入的游戏数据'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认导入'),
        content: const Text('导入新的游戏数据会覆盖当前进度，确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await stateManager.importGameState(importData);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 游戏数据导入成功'),
              backgroundColor: Colors.green,
            ),
          );
          _importController.clear();
          await _loadSaveTimeInfo();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ 导入失败：数据格式无效'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 导入失败：$e'),
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
