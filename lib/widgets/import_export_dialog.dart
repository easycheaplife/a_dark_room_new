import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/engine.dart';
import '../core/localization.dart';

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
      final localization = Localization();
      _showSuccessDialog(localization.translate('import_export.export_success'));
    } catch (e) {
      final localization = Localization();
      _showErrorDialog('${localization.translate('import_export.export_failed')}: $e');
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
        final localization = Localization();
        _showErrorDialog(localization.translate('import_export.clipboard_empty'));
        return;
      }

      final importData = clipboardData.text!.trim();
      final success = await Engine().import64(importData);

      if (mounted) {
        final localization = Localization();
        if (success) {
          Navigator.of(context).pop();
          _showSuccessDialog(localization.translate('import_export.import_success'));
        } else {
          _showErrorDialog(localization.translate('import_export.import_failed'));
        }
      }
    } catch (e) {
      if (mounted) {
        final localization = Localization();
        _showErrorDialog('${localization.translate('import_export.import_failed')}: $e');
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
    final localization = Localization();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.translate('import_export.error')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localization.translate('import_export.ok')),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    final localization = Localization();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.translate('import_export.success')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localization.translate('import_export.ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = Localization();
    return AlertDialog(
      title: Text(localization.translate('import_export.title')),
      content: SizedBox(
        width: 400,
        height: 320,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.translate('import_export.description'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localization.translate('import_export.instructions'),
                    style: const TextStyle(fontSize: 14),
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
                label: Text(
                  localization.translate('import_export.export_button'),
                  style: const TextStyle(fontSize: 16),
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
                  _isLoading
                    ? localization.translate('import_export.importing')
                    : localization.translate('import_export.import_button'),
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
                  child: Text(localization.translate('ui.buttons.close')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
