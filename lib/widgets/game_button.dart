import 'package:flutter/material.dart';

/// 游戏按钮组件 - 模拟原游戏的按钮样式
class GameButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 100,
      margin: const EdgeInsets.only(bottom: 2),
      child: GestureDetector(
        onTap: disabled ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: disabled ? Colors.grey : Colors.black,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 按钮文本
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: disabled ? Colors.grey : Colors.black,
                  fontSize: 14,
                  fontFamily: 'serif', // 使用serif字体模拟Times New Roman
                  decoration: disabled ? null : TextDecoration.underline,
                ),
              ),

              // 成本显示
              if (cost != null && !free)
                ...cost!.entries.map((entry) => Text(
                      '${entry.key}: ${entry.value}',
                      style: TextStyle(
                        color: disabled ? Colors.grey : const Color(0xFF666666),
                        fontSize: 10,
                        fontFamily: 'serif',
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
