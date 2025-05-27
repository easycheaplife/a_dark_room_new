import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/localization.dart';

/// 游戏按钮组件 - 模拟原游戏的按钮样式
class GameButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Map<String, int>? cost;
  final double? width;
  final bool disabled;
  final bool free;

  const GameButton({
    super.key,
    required this.text,
    this.onPressed,
    this.cost,
    this.width,
    this.disabled = false,
    this.free = false,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _isHovering = false;
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
                              localization.translate('resources.${entry.key}'),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<Localization>(
      builder: (context, localization, child) {
        return Container(
          width: widget.width ?? 100,
          margin: const EdgeInsets.only(bottom: 2),
          child: CompositedTransformTarget(
            link: _layerLink,
            child: MouseRegion(
              onEnter: (_) {
                setState(() => _isHovering = true);
                // 显示tooltip（如果满足条件）
                if (widget.cost != null &&
                    widget.cost!.isNotEmpty &&
                    !widget.free &&
                    !widget.disabled) {
                  _showTooltip(context, localization);
                }
              },
              onExit: (_) {
                setState(() => _isHovering = false);
                _removeTooltip();
              },
              child: GestureDetector(
                onTap: widget.disabled ? null : widget.onPressed,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: widget.disabled
                          ? const Color(0xFFB2B2B2)
                          : Colors.black,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.disabled
                          ? const Color(0xFFB2B2B2)
                          : Colors.black,
                      fontSize: 16,
                      fontFamily: 'Times New Roman',
                      decoration:
                          widget.disabled ? null : TextDecoration.underline,
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
