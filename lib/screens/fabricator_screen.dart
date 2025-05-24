import 'package:flutter/material.dart';

/// 制造器界面 - 显示高级物品制造
class FabricatorScreen extends StatelessWidget {
  const FabricatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '🔧 制造器\n\n即将推出...',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          color: Colors.white,
        ),
      ),
    );
  }
}
