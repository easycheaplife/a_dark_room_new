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
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  String? _exportData;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // 导出存档
  Future<void> _exportSave() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exportData = await Engine().export64();
      setState(() {
        _exportData = exportData;
        _textController.text = exportData;
      });
    } catch (e) {
      _showErrorDialog('导出失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 导入存档
  Future<void> _importSave() async {
    final importData = _textController.text.trim();
    if (importData.isEmpty) {
      _showErrorDialog('请输入存档数据');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
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

  // 从文件导入 - 暂时禁用
  Future<void> _importFromFile() async {
    _showErrorDialog('文件导入功能暂时不可用，请使用复制粘贴方式');
  }

  // 保存到文件 - 暂时禁用
  Future<void> _saveToFile() async {
    _showErrorDialog('文件保存功能暂时不可用，请使用复制功能');
  }

  // 复制到剪贴板
  void _copyToClipboard() {
    if (_exportData != null && _exportData!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _exportData!));
      _showSuccessDialog('存档数据已复制到剪贴板');
    }
  }

  // 从剪贴板粘贴
  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null && clipboardData.text != null) {
        setState(() {
          _textController.text = clipboardData.text!.trim();
        });
      }
    } catch (e) {
      _showErrorDialog('粘贴失败: $e');
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
        width: 500,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 导出区域
            const Text(
              '导出存档:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _exportSave,
                  child: const Text('导出'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _exportData != null ? _copyToClipboard : null,
                  child: const Text('复制'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _exportData != null ? _saveToFile : null,
                  child: const Text('保存到文件'),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // 导入区域
            const Text(
              '导入存档:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _pasteFromClipboard,
                  child: const Text('粘贴'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _importFromFile,
                  child: const Text('从文件导入'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 文本输入框
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: '在此粘贴存档数据...',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _importSave,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('导入'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
