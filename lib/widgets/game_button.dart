import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/localization.dart';
import '../core/responsive_layout.dart';

/// 游戏按钮组件 - 模拟原游戏的按钮样式
class GameButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Map<String, int>? cost;
  final double? width;
  final bool disabled;
  final bool free;
  final String? disabledReason; // 禁用原因
  final VoidCallback? onDisabledTap; // 禁用时的点击回调

  const GameButton({
    super.key,
    required this.text,
    this.onPressed,
    this.cost,
    this.width,
    this.disabled = false,
    this.free = false,
    this.disabledReason,
    this.onDisabledTap,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  void _showTooltip(BuildContext context, Localization localization) {
    _removeTooltip();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 100,
        child: CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(2, 30), // 原游戏tooltip.bottom和tooltip.right样式
          child: Material(
            elevation: 999, // 模拟原游戏的z-index: 999
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

  void _showDisabledTooltip(BuildContext context, Localization localization) {
    _removeTooltip();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 200, // 禁用tooltip稍微宽一些，因为要显示更多信息
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
                children: [
                  // 显示禁用原因
                  Text(
                    widget.disabledReason!,
                    style: const TextStyle(
                      color: Color(0xFFB2B2B2), // 灰色文字
                      fontSize: 12,
                      fontFamily: 'Times New Roman',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.cost!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${localization.translate('ui.tooltip.required_resources')}：',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontFamily: 'Times New Roman',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ...widget.cost!.entries.map((entry) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getLocalizedResourceName(
                                  entry.key, localization),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontFamily: 'Times New Roman',
                              ),
                            ),
                            Text(
                              '${entry.value}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontFamily: 'Times New Roman',
                              ),
                            ),
                          ],
                        )),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
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

  @override
  Widget build(BuildContext context) {
    final layoutParams = GameLayoutParams.getLayoutParams(context);

    return Consumer<Localization>(
      builder: (context, localization, child) {
        return Container(
          width: widget.width ?? layoutParams.buttonWidth,
          height: layoutParams.buttonHeight, // 确保有足够的触摸区域
          margin: EdgeInsets.only(bottom: layoutParams.buttonSpacing / 2),
          child: CompositedTransformTarget(
            link: _layerLink,
            child: MouseRegion(
              onEnter: (_) {
                // 显示tooltip（如果满足条件）
                if (widget.cost != null &&
                    widget.cost!.isNotEmpty &&
                    !widget.free) {
                  // 对于禁用按钮，显示包含禁用原因的tooltip
                  if (widget.disabled && widget.disabledReason != null) {
                    _showDisabledTooltip(context, localization);
                  } else if (!widget.disabled) {
                    _showTooltip(context, localization);
                  }
                }
              },
              onExit: (_) {
                _removeTooltip();
              },
              child: GestureDetector(
                onTap:
                    widget.disabled ? widget.onDisabledTap : widget.onPressed,
                // 增加触摸反馈，提升移动端体验
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity, // 确保按钮占满整个宽度
                  height: double.infinity, // 确保按钮占满整个高度
                  padding: EdgeInsets.symmetric(
                    horizontal: layoutParams.useVerticalLayout ? 12 : 8,
                    vertical: layoutParams.useVerticalLayout ? 8 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: widget.disabled
                          ? const Color(0xFFB2B2B2)
                          : Colors.black,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.disabled
                            ? const Color(0xFFB2B2B2)
                            : Colors.black,
                        fontSize: layoutParams.fontSize,
                        fontFamily: 'Times New Roman',
                        decoration:
                            widget.disabled ? null : TextDecoration.underline,
                      ),
                      maxLines: layoutParams.useVerticalLayout ? 2 : 1, // 移动端允许换行
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
