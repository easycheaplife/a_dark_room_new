import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../core/engine.dart';
import '../core/logger.dart';
import '../modules/score.dart';
import '../modules/prestige.dart';

/// 游戏结束对话框 - 显示胜利或失败界面
/// 参考原游戏的showEndingOptions功能
class GameEndingDialog extends StatefulWidget {
  final bool isVictory;
  final VoidCallback? onRestart;

  const GameEndingDialog({
    super.key,
    required this.isVictory,
    this.onRestart,
  });

  @override
  State<GameEndingDialog> createState() => _GameEndingDialogState();
}

class _GameEndingDialogState extends State<GameEndingDialog>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final Score _score = Score();
  final Prestige _prestige = Prestige();

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // 开始淡入动画
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = Localization();
    final currentScore = _score.totalScore();
    final totalScore = _prestige.getPreviousScore() + currentScore;

    return Material(
      color: Colors.black54, // 半透明背景
      child: Center(
        child: Container(
          width: 400,
          height: 500,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 标题
              Text(
                widget.isVictory
                    ? localization.translate('space.ending.victory_title')
                    : localization.translate('space.ending.defeat_title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Times New Roman',
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // 分数信息
              _buildScoreInfo(localization, currentScore, totalScore),

              const SizedBox(height: 30),

              // 按钮区域
              _buildButtons(localization),
            ],
          ),
        ),
        ),
      ),
    );
  }

  /// 构建分数信息
  Widget _buildScoreInfo(Localization localization, int currentScore, int totalScore) {
    return Column(
      children: [
        // 当前游戏分数
        Text(
          localization.translate('space.ending.current_score').replaceAll('{score}', currentScore.toString()),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Times New Roman',
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 10),

        // 总分数
        Text(
          localization.translate('space.ending.total_score').replaceAll('{score}', totalScore.toString()),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Times New Roman',
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        // 分数等级
        Text(
          localization.translate('space.ending.rank').replaceAll('{rank}', _score.getScoreRank(currentScore)),
          style: const TextStyle(
            color: Colors.yellow,
            fontSize: 14,
            fontFamily: 'Times New Roman',
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 构建按钮区域
  Widget _buildButtons(Localization localization) {
    return Column(
      children: [
        // 重新开始按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onRestart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              localization.translate('space.ending.restart'),
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Times New Roman',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 15),

        // 应用推广信息
        Text(
          localization.translate('space.ending.app_promotion'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'Times New Roman',
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 15),

        // 平台按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // iOS按钮
            TextButton(
              onPressed: _onIOSPressed,
              child: Text(
                localization.translate('space.ending.ios'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Times New Roman',
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            // Android按钮
            TextButton(
              onPressed: _onAndroidPressed,
              child: Text(
                localization.translate('space.ending.android'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Times New Roman',
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 重新开始游戏
  void _onRestart() async {
    Navigator.of(context).pop();

    Logger.info('🔄 开始重新开始游戏流程');

    try {
      // 调用Engine的删除存档方法，参考原游戏的deleteSave逻辑
      await Engine().deleteSave();
      Logger.info('🔄 存档已清除，游戏已重新初始化');

      // 调用回调（如果有的话）
      if (widget.onRestart != null) {
        widget.onRestart!();
      }
    } catch (e) {
      Logger.error('❌ 重新开始游戏失败: $e');
    }
  }

  /// iOS按钮点击
  void _onIOSPressed() {
    // 在实际应用中，这里应该打开App Store链接
    // 现在只是记录事件
    Engine().event('app', 'ios');
  }

  /// Android按钮点击
  void _onAndroidPressed() {
    // 在实际应用中，这里应该打开Google Play链接
    // 现在只是记录事件
    Engine().event('app', 'android');
  }
}
