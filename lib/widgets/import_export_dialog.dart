import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/engine.dart';

/// 导入/导出对话框
class ImportExportDialog extends StatefulWidget {
  const ImportExportDialog({super.key});

  @override
  State<ImportExportDialog> createState() => _ImportExportDialogState();
}

class _ImportExportDialogState extends State<ImportExportDialog> {
  bool _isLoading = false;

  // 导出存档并直接复制到剪贴板
  Future<void> _exportSave() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exportData = await Engine().export64();

      // 直接复制到剪贴板
      await Clipboard.setData(ClipboardData(text: exportData));
      _showSuccessDialog('存档已导出并复制到剪贴板！');
    } catch (e) {
      _showErrorDialog('导出失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 从剪贴板导入存档
  Future<void> _importSave() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 从剪贴板读取数据
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData == null ||
          clipboardData.text == null ||
          clipboardData.text!.trim().isEmpty) {
        _showErrorDialog('剪贴板中没有存档数据');
        return;
      }

      final importData = clipboardData.text!.trim();
      final success = await Engine().import64(importData);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          _showSuccessDialog('存档导入成功！');
        } else {
          _showErrorDialog('存档导入失败，请检查数据格式');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('导入失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('成功'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导入/导出存档'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 说明文字
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 剪贴板操作',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• 导出：将存档数据自动复制到剪贴板\n• 导入：从剪贴板读取存档数据\n• 完全兼容原游戏存档格式',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 导出按钮
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _exportSave,
                icon: const Icon(Icons.download),
                label: const Text(
                  '导出存档到剪贴板',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 导入按钮
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _importSave,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.upload),
                label: Text(
                  _isLoading ? '导入中...' : '从剪贴板导入存档',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const Spacer(),

            // 关闭按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
