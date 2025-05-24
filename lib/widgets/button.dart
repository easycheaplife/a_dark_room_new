import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../core/state_manager.dart';
import '../core/audio_engine.dart';

/// GameButton is a custom button widget that mimics the behavior of buttons in the original game
class GameButton extends StatefulWidget {
  final String id;
  final String text;
  final VoidCallback? onClick;
  final Map<String, num>? cost;
  final int cooldown;
  final double width;
  final String? tooltipPosition;
  final bool disabled;
  final bool free;
  final bool Function()? boosted; // 用于检查是否有加速效果
  final bool saveCooldown; // 是否保存冷却时间到状态

  const GameButton({
    super.key,
    required this.id,
    required this.text,
    this.onClick,
    this.cost,
    this.cooldown = 0,
    this.width = 80.0,
    this.tooltipPosition,
    this.disabled = false,
    this.free = false,
    this.boosted,
    this.saveCooldown = true,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> with SingleTickerProviderStateMixin {
  bool _isDisabled = false;
  bool _isCoolingDown = false;
  late AnimationController _cooldownController;
  late Animation<double> _cooldownAnimation;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _isDisabled = widget.disabled;

    // Set up cooldown animation
    _cooldownController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.cooldown),
    );

    _cooldownAnimation = Tween<double>(
      begin: 1.0, // 从满开始，逐渐减少到0
      end: 0.0,
    ).animate(_cooldownController);

    _cooldownController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _clearCooldown(true);
      }
    });

    // 检查是否有残留的冷却时间
    _checkResidualCooldown();
  }

  @override
  void dispose() {
    _cooldownController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(GameButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.disabled != oldWidget.disabled) {
      setState(() {
        _isDisabled = widget.disabled;
      });
    }
  }

  // 检查残留的冷却时间
  void _checkResidualCooldown() {
    if (widget.cooldown <= 0) return;

    final sm = StateManager();
    final cooldownId = 'cooldown.${widget.id}';
    final residualTime = sm.get(cooldownId, true) ?? 0;

    if (residualTime > 0) {
      _startCooldown((residualTime * 1000).round()); // 转换回毫秒
    }
  }

  void _startCooldown([int? customDuration]) {
    if (widget.cooldown <= 0) return;

    int cd = customDuration ?? widget.cooldown;

    // 检查是否有加速效果
    if (widget.boosted?.call() == true) {
      cd = (cd / 2).round();
    }

    setState(() {
      _isCoolingDown = true;
    });

    // 保存冷却时间到状态
    if (widget.saveCooldown) {
      final sm = StateManager();
      final cooldownId = 'cooldown.${widget.id}';
      sm.set(cooldownId, cd / 1000); // 转换为秒

      // 每0.5秒减少冷却时间
      _countdownTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        final remaining = (sm.get(cooldownId, true) ?? 0) - 0.5;
        if (remaining <= 0) {
          timer.cancel();
          sm.remove(cooldownId);
        } else {
          sm.set(cooldownId, remaining, true); // true 表示 noNotify
        }
      });
    }

    // 设置动画持续时间
    _cooldownController.duration = Duration(milliseconds: cd);
    _cooldownController.reset();
    _cooldownController.forward();
  }

  void _clearCooldown([bool cooldownEnded = false]) {
    setState(() {
      _isCoolingDown = false;
    });

    if (!cooldownEnded) {
      _cooldownController.stop();
    }

    _cooldownController.reset();

    // 清理计时器和状态
    _countdownTimer?.cancel();
    _countdownTimer = null;

    if (widget.saveCooldown) {
      final sm = StateManager();
      final cooldownId = 'cooldown.${widget.id}';
      sm.remove(cooldownId);
    }
  }

  bool _canAfford(BuildContext context) {
    if (widget.cost == null || widget.free) return true;

    final sm = Provider.of<StateManager>(context, listen: false);

    for (final entry in widget.cost!.entries) {
      final have = sm.get('stores["${entry.key}"]', true) ?? 0;
      if (have < entry.value) {
        return false;
      }
    }

    return true;
  }

  void _handleClick() {
    if (_isDisabled || _isCoolingDown) return;

    if (!_canAfford(context)) {
      // Play "can't afford" sound
      AudioEngine().playSound('cant_afford');
      return;
    }

    // Start cooldown
    _startCooldown();

    // Call onClick handler
    if (widget.onClick != null) {
      widget.onClick!();
    }

    // Play click sound
    AudioEngine().playSound('click');
  }

  @override
  Widget build(BuildContext context) {
    final bool canAfford = _canAfford(context);
    final bool isActive = !_isDisabled && !_isCoolingDown && canAfford;

    return Tooltip(
      message: _buildTooltipText(),
      preferBelow: widget.tooltipPosition?.contains('bottom') ?? true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: widget.width,
        height: 40,
        decoration: BoxDecoration(
          color: _getButtonColor(isActive),
          border: Border.all(
            color: Colors.grey.shade700,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            // Cooldown overlay
            if (_isCoolingDown)
              AnimatedBuilder(
                animation: _cooldownAnimation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    widthFactor: 1.0 - _cooldownAnimation.value,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),

            // Button text
            Center(
              child: Text(
                widget.text,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Clickable area
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isActive ? _handleClick : null,
                splashColor: Colors.white24,
                highlightColor: Colors.white10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getButtonColor(bool isActive) {
    if (_isDisabled) {
      return Colors.grey.shade800;
    } else if (_isCoolingDown) {
      return Colors.grey.shade700;
    } else if (!isActive) {
      return Colors.grey.shade600;
    } else {
      return Colors.grey.shade500;
    }
  }

  String _buildTooltipText() {
    if (widget.cost == null || widget.cost!.isEmpty) {
      return '';
    }

    final StringBuffer buffer = StringBuffer();

    for (final entry in widget.cost!.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }

    return buffer.toString().trim();
  }

  // 静态方法用于外部控制（如果需要的话）
  // 在Flutter中，通常通过GlobalKey或者状态管理来控制Widget
  // 这些方法保留作为接口兼容性，但在实际使用中可能不需要
}
