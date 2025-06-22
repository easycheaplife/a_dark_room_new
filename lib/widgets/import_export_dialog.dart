import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/engine.dart';
import '../core/localization.dart';
import '../core/logger.dart';

/// 导入/导出对话框
class ImportExportDialog extends StatefulWidget {
  const ImportExportDialog({super.key});

  @override
  State<ImportExportDialog> createState() => _ImportExportDialogState();
}

class _ImportExportDialogState extends State<ImportExportDialog> {
  bool _isLoading = false;
  bool _isSecureContext = true;
  final TextEditingController _importTextController = TextEditingController();
  String _exportedData = '';
  bool _showExportData = false;

  @override
  void initState() {
    super.initState();
    _checkSecureContext();
  }

  @override
  void dispose() {
    _importTextController.dispose();
    super.dispose();
  }

  // 检查是否为安全上下文
  void _checkSecureContext() {
    if (kIsWeb) {
      final currentUrl = Uri.base.toString();
      _isSecureContext = currentUrl.startsWith('https://') ||
                        currentUrl.startsWith('http://localhost') ||
                        currentUrl.startsWith('http://127.0.0.1');
      Logger.info('🔒 安全上下文检查: $_isSecureContext (URL: $currentUrl)');
    }
  }

  // 导出存档 - 支持多种方式
  Future<void> _exportSave() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Logger.info('📤 开始导出存档...');
      final exportData = await Engine().export64();
      Logger.info('📤 存档导出成功，数据长度: ${exportData.length}');

      if (_isSecureContext) {
        // HTTPS环境：优先使用剪贴板API
        try {
          Logger.info('📋 HTTPS环境：尝试复制到剪贴板...');
          await Clipboard.setData(ClipboardData(text: exportData));
          Logger.info('📋 复制到剪贴板成功');

          final localization = Localization();
          _showSuccessDialog(localization.translate('import_export.export_success'));
          return;
        } catch (e) {
          Logger.error('⚠️ 剪贴板复制失败，回退到文本显示: $e');
        }
      }

      // 非HTTPS环境或剪贴板失败：显示文本和下载选项
      Logger.info('📋 显示导出数据供手动复制和下载');
      setState(() {
        _exportedData = exportData;
        _showExportData = true;
      });

      final localization = Localization();
      _showSuccessDialog(localization.translate('import_export.export_success_manual'));
    } catch (e) {
      Logger.error('❌ 导出存档时发生错误: $e');
      final localization = Localization();
      _showErrorDialog('${localization.translate('import_export.export_failed')}: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 复制导出数据到剪贴板（备用方法）
  Future<void> _copyExportedData() async {
    if (_exportedData.isEmpty) return;

    try {
      await Clipboard.setData(ClipboardData(text: _exportedData));
      final localization = Localization();
      _showSuccessDialog(localization.translate('import_export.copy_success'));
      Logger.info('📋 手动复制到剪贴板成功');
    } catch (e) {
      Logger.error('❌ 手动复制失败: $e');
      final localization = Localization();
      _showErrorDialog('${localization.translate('import_export.copy_failed')}: $e');
    }
  }

  // 从剪贴板导入存档（仅HTTPS环境）
  Future<void> _importFromClipboard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Logger.info('📋 尝试从剪贴板读取数据...');
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      Logger.info('📋 剪贴板数据获取结果: ${clipboardData != null ? '成功' : '失败'}');

      if (clipboardData == null ||
          clipboardData.text == null ||
          clipboardData.text!.trim().isEmpty) {
        final localization = Localization();
        Logger.error('❌ 剪贴板数据为空或无效');
        _showErrorDialog(localization.translate('import_export.clipboard_empty'));
        return;
      }

      final importData = clipboardData.text!.trim();
      await _performImport(importData);
    } catch (e) {
      Logger.error('❌ 从剪贴板导入时发生错误: $e');
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

  // 从文本输入导入存档（支持所有环境）
  Future<void> _importFromText() async {
    final importData = _importTextController.text.trim();
    if (importData.isEmpty) {
      final localization = Localization();
      _showErrorDialog(localization.translate('import_export.text_empty'));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _performImport(importData);
    } catch (e) {
      Logger.error('❌ 从文本导入时发生错误: $e');
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

  // 执行导入操作
  Future<void> _performImport(String importData) async {
    Logger.info('📋 开始导入存档，数据长度: ${importData.length}');
    Logger.info('📋 数据预览: ${importData.substring(0, importData.length > 50 ? 50 : importData.length)}...');

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
        width: 500,
        height: _showExportData ? 600 : 450,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 说明文字
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSecureContext ? Colors.blue[50] : Colors.orange[50],
                  border: Border.all(
                    color: _isSecureContext ? Colors.blue[200]! : Colors.orange[200]!
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isSecureContext ? Icons.security : Icons.warning,
                          color: _isSecureContext ? Colors.blue : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          localization.translate('import_export.description'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSecureContext
                        ? localization.translate('import_export.instructions')
                        : localization.translate('import_export.non_https_notice'),
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

              // 显示导出数据（非HTTPS环境）
              if (_showExportData) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localization.translate('import_export.export_data_instruction'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: _copyExportedData,
                      icon: const Icon(Icons.copy, size: 16),
                      label: Text(
                        localization.translate('import_export.copy_manual'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  child: SelectableText(
                    _exportedData,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 导入区域
              if (_isSecureContext) ...[
                // HTTPS环境：显示剪贴板导入按钮
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _importFromClipboard,
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
                        : const Icon(Icons.content_paste),
                    label: Text(
                      _isLoading
                        ? localization.translate('import_export.importing')
                        : localization.translate('import_export.import_clipboard_button'),
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
              ],

              // 文本导入（所有环境都支持）
              Text(
                localization.translate('import_export.paste_instruction'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _importTextController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'eyJ2ZXJzaW9uIjoxLjMsInN0b3JlcyI6...',
                    hintStyle: TextStyle(fontSize: 12),
                  ),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _importFromText,
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
                      : const Icon(Icons.text_fields),
                  label: Text(
                    _isLoading
                      ? localization.translate('import_export.importing')
                      : localization.translate('import_export.import_text_button'),
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),

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
      ),
    );
  }
}
