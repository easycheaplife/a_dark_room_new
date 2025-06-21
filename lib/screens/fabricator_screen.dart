import 'package:flutter/material.dart';
import '../core/localization.dart';

/// 制造器界面 - 显示高级物品制造
class FabricatorScreen extends StatelessWidget {
  const FabricatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = Localization();
    return Center(
      child: Text(
        '${localization.translate('fabricator_screen.title')}\n\n${localization.translate('fabricator_screen.coming_soon')}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
        ),
      ),
    );
  }
}
