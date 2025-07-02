import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/localization.dart';
import '../core/logger.dart';
import '../core/progress_manager.dart';
import '../core/responsive_layout.dart';

/// 带进度条的按钮组件
class ProgressButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Map<String, int>? cost;
  final double width;
  final bool disabled;
  final bool free;
  final int progressDuration; // 进度持续时间（毫秒）
  final String? tooltip; // 悬停提示
  final bool showCost; // 是否显示成本信息
  final String? id; // 固定ID，用于进度跟踪
  final String? progressText; // 进度过程中显示的文字（如果为null则显示百分比）

  const ProgressButton({
    super.key,
    required this.text,
    this.onPressed,
    this.cost,
    this.width = 100,
    this.disabled = false,
    this.free = false,
    this.progressDuration = 2000, // 默认2秒
    this.tooltip,
    this.showCost = true, // 默认显示成本
    this.id, // 可选的固定ID
    this.progressText, // 进度过程中的文字
  });

  @override
  State<ProgressButton> createState() => _ProgressButtonState();
}

class _ProgressButtonState extends State<ProgressButton> {
  bool _isHovering = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  // 使用ProgressManager管理进度状态
  String get _progressId => widget.id ?? 'ProgressButton.${widget.text}';

  ProgressState? get _currentProgress =>
      ProgressManager().getProgress(_progressId);
  bool get _isProgressing => _currentProgress != null;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // 不要在dispose时取消进度，让ProgressManager自己管理
    // ProgressManager().cancelProgress(_progressId);
    _removeTooltip();
    super.dispose();
  }

  void _showTooltip(BuildContext context, Localization localization) {
    _removeTooltip();

    if (widget.cost == null || widget.cost!.isEmpty || widget.free) {
      return; // 没有成本信息或免费时不显示tooltip
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 100,
        child: CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(2, 30),
          child: Material(
            elevation: 999,
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF666666),
                    offset: Offset(-1, 3),
                    blurRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: widget.cost!.entries
                    .map((entry) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getLocalizedResourceName(
                                  entry.key, localization),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'Times New Roman',
                              ),
                            ),
                            Text(
                              '${entry.value}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'Times New Roman',
                              ),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // 获取本地化资源名称
  String _getLocalizedResourceName(
      String resourceKey, Localization localization) {
    String localizedName = localization.translate('resources.$resourceKey');
    if (localizedName == 'resources.$resourceKey') {
      // 如果没有找到翻译，使用原名称
      return resourceKey;
    }
    return localizedName;
  }

  void _onCooldownComplete() {
    // 冷却完成，按钮重新可用（不需要执行动作，动作已在点击时执行）
    Logger.info('✅ Cooldown completed for $_progressId');
  }

  void _startProgress() {
    if (_isProgressing || widget.disabled || widget.onPressed == null) return;

    Logger.info(
        '🚀 ProgressButton started: ${widget.text}, duration: ${widget.progressDuration}ms');
    Logger.info('🔧 Using ProgressManager for $_progressId');

    // 立即执行动作（参考原游戏：点击时立即执行，进度条只是冷却时间）
    widget.onPressed?.call();
    Logger.info('✅ Action executed immediately for $_progressId');

    // 使用ProgressManager启动冷却进度
    ProgressManager().startProgress(
      id: _progressId,
      duration: widget.progressDuration,
      onComplete: _onCooldownComplete,
    );

    Logger.info('✅ ProgressManager.startProgress called for $_progressId');
  }

  /// 获取布局参数
  GameLayoutParams _getLayoutParams() {
    return GameLayoutParams.getLayoutParams(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<Localization, ProgressManager>(
      builder: (context, localization, progressManager, child) {
        final bool isDisabled = widget.disabled || _isProgressing;

        Widget buttonWidget = Container(
          width: widget.width,
          height: 40,
          margin: const EdgeInsets.only(bottom: 5),
          child: CompositedTransformTarget(
            link: _layerLink,
            child: MouseRegion(
              onEnter: (_) {
                setState(() => _isHovering = true);
                // 显示tooltip（如果有成本信息且不是免费的）
                if (widget.cost != null &&
                    widget.cost!.isNotEmpty &&
                    !widget.free) {
                  _showTooltip(context, localization);
                }
              },
              onExit: (_) {
                setState(() => _isHovering = false);
                _removeTooltip();
              },
              child: Stack(
                children: [
                  // 主按钮
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: isDisabled ? Colors.grey[300] : Colors.white,
                      border: Border.all(
                        color: isDisabled ? Colors.grey : Colors.black,
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isDisabled ? null : _startProgress,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: _getLayoutParams().useVerticalLayout
                                  ? 6
                                  : 4), // 移动端增加垂直内边距
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 按钮文本
                              Flexible(
                                child: Text(
                                  widget.text,
                                  style: TextStyle(
                                    color: isDisabled
                                        ? Colors.grey[600]
                                        : Colors.black,
                                    fontSize:
                                        _getLayoutParams().useVerticalLayout
                                            ? 13
                                            : 11, // 移动端增大字体
                                    fontFamily: 'Times New Roman',
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // 移除按钮内的成本显示和免费标识
                              // 成本信息将通过tooltip显示
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 进度条覆盖层
                  if (_isProgressing)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Stack(
                        children: [
                          // 进度条背景
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.grey[200],
                          ),
                          // 进度条填充
                          Container(
                            width: widget.width *
                                (_currentProgress?.currentProgress ?? 0.0),
                            height: double.infinity,
                            color: Colors.blue[300]?.withValues(alpha: 0.7),
                          ),
                          // 进度文本 - 支持自定义文字或百分比
                          Center(
                            child: Text(
                              widget.progressText ??
                                  '${_currentProgress?.progressPercent ?? 0}%',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: _getLayoutParams().useVerticalLayout
                                    ? 12
                                    : 11, // 移动端增大字体
                                fontFamily: 'Times New Roman',
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

        // 如果有tooltip，包装在Tooltip中
        if (widget.tooltip != null) {
          return Tooltip(
            message: widget.tooltip!,
            child: buttonWidget,
          );
        }

        return buttonWidget;
      },
    );
  }
}
