import 'package:flutter/material.dart';
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
    super.dispose();
  }

  // 获取本地化资源名称
  String _getLocalizedResourceName(String resourceKey) {
    const resourceNames = {
      'wood': '木材',
      'fur': '毛皮',
      'meat': '肉类',
      'bait': '诱饵',
      'leather': '皮革',
      'cured meat': '熏肉',
      'iron': '铁',
      'coal': '煤炭',
      'sulphur': '硫磺',
      'steel': '钢铁',
      'bullets': '子弹',
      'cloth': '布料',
      'teeth': '牙齿',
      'scales': '鳞片',
      'bone': '骨头',
      'alien alloy': '外星合金',
      'energy cell': '能量电池',
      'torch': '火把',
      'waterskin': '水壶',
      'cask': '水桶',
      'water tank': '水罐',
      'compass': '指南针',
    };
    return resourceNames[resourceKey] ?? resourceKey;
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
    final bool isDisabled = widget.disabled || _isProgressing;

    Widget buttonWidget = Container(
      width: widget.width,
      height: 40,
      margin: const EdgeInsets.only(bottom: 5),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 按钮文本
                      Flexible(
                        child: Text(
                          widget.text,
                          style: TextStyle(
                            color: isDisabled ? Colors.grey[600] : Colors.black,
                            fontSize: 11,
                            fontFamily: 'Times New Roman',
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // 成本显示 - 只在showCost为true时显示
                      if (widget.cost != null &&
                          !widget.free &&
                          widget.showCost) ...[
                        const SizedBox(height: 1),
                        Flexible(
                          child: Text(
                            widget.cost!.entries
                                .map((e) =>
                                    '${_getLocalizedResourceName(e.key)}: ${e.value}')
                                .join(', '),
                            style: TextStyle(
                              color: isDisabled
                                  ? Colors.grey[600]
                                  : Colors.grey[700],
                              fontSize: 9,
                              fontFamily: 'Times New Roman',
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],

                      // 免费标识
                      if (widget.free) ...[
                        const SizedBox(height: 1),
                        Flexible(
                          child: Text(
                            '(免费)',
                            style: TextStyle(
                              color: isDisabled
                                  ? Colors.grey[600]
                                  : Colors.green[700],
                              fontSize: 9,
                              fontFamily: 'Times New Roman',
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
    );

    // 如果有tooltip，包装在Tooltip中
    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }
}
