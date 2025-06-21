import 'package:flutter/material.dart';
import '../core/localization.dart';

/// 飞船界面 - 显示飞船状态和升级选项
class ShipScreen extends StatelessWidget {
  const ShipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = Localization();
    return Center(
      child: Text(
        '${localization.translate('ship_screen.title')}\n\n${localization.translate('ship_screen.coming_soon')}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
        ),
      ),
    );
  }
}
