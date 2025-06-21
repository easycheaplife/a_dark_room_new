import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/localization.dart';
import 'dart:async';

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
  });

  @override
  State<ProgressButton> createState() => _ProgressButtonState();
}

class _ProgressButtonState extends State<ProgressButton>
    with TickerProviderStateMixin {
  bool _isProgressing = false;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  Timer? _progressTimer;
  bool _isHovering = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: Duration(milliseconds: widget.progressDuration),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _progressController.dispose();
    _progressTimer?.cancel();
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
                              _getLocalizedResourceName(entry.key, localization),
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

  void _startProgress() {
    if (_isProgressing || widget.disabled || widget.onPressed == null) return;

    setState(() {
      _isProgressing = true;
    });

    _progressController.reset();
    _progressController.forward();

    _progressTimer = Timer(Duration(milliseconds: widget.progressDuration), () {
      if (mounted) {
        setState(() {
          _isProgressing = false;
        });
        widget.onPressed?.call();
        _progressController.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Localization>(
      builder: (context, localization, child) {
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
                if (widget.cost != null && widget.cost!.isNotEmpty && !widget.free) {
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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
                                    fontSize: 11,
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
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Container(
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
                                width: widget.width * _progressAnimation.value,
                                height: double.infinity,
                                color: Colors.blue[300]?.withValues(alpha: 0.7),
                              ),
                              // 进度文本
                              Center(
                                child: Text(
                                  '${(_progressAnimation.value * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontFamily: 'Times New Roman',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
