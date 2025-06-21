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
            title: Text(
              localization.translate('settings.title'),
              style: const TextStyle(
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
          Text(
            Localization().translate('settings.save_status'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Times New Roman',
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _saveTimeInfo != null
              ? '${Localization().translate('settings.last_save')}$_saveTimeInfo'
              : Localization().translate('settings.no_save_record'),
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Times New Roman',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            Localization().translate('settings.auto_save_info'),
            style: const TextStyle(
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
          Consumer<Localization>(
            builder: (context, localization, child) {
              return Text(
                '💾 ${localization.translate('settings.import_export_title')}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Times New Roman',
                  color: Colors.black,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            Localization().translate('settings.import_export_instruction'),
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Times New Roman',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            Localization().translate('settings.import_export_description'),
            style: const TextStyle(
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
          Text(
            Localization().translate('settings.danger_section'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Times New Roman',
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            Localization().translate('settings.clear_data_description'),
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Times New Roman',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _clearGameData(stateManager),
            icon: const Icon(Icons.delete_forever),
            label: Text(Localization().translate('settings.clear_data_button')),
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
    final localization = Localization();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.translate('settings.confirm_clear_title')),
        content: Text(localization.translate('settings.confirm_clear_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localization.translate('ui.buttons.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(localization.translate('settings.confirm_clear_button')),
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
        final localization = Localization();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization.translate('settings.clear_success')),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadSaveTimeInfo();
      }
    } catch (e) {
      if (mounted) {
        final localization = Localization();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localization.translate('settings.clear_failed')}$e'),
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
