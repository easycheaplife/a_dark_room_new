import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/state_manager.dart';
import '../core/audio_engine.dart';
import '../core/audio_library.dart';

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
  
  const GameButton({
    Key? key,
    required this.id,
    required this.text,
    this.onClick,
    this.cost,
    this.cooldown = 0,
    this.width = 80.0,
    this.tooltipPosition,
    this.disabled = false,
    this.free = false,
  }) : super(key: key);

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> with SingleTickerProviderStateMixin {
  bool _isDisabled = false;
  bool _isCoolingDown = false;
  late AnimationController _cooldownController;
  late Animation<double> _cooldownAnimation;
  
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
      begin: 0.0,
      end: 1.0,
    ).animate(_cooldownController);
    
    _cooldownController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isCoolingDown = false;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _cooldownController.dispose();
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
  
  void _startCooldown() {
    if (widget.cooldown > 0) {
      setState(() {
        _isCoolingDown = true;
      });
      _cooldownController.reset();
      _cooldownController.forward();
    }
  }
  
  void _clearCooldown() {
    setState(() {
      _isCoolingDown = false;
    });
    _cooldownController.reset();
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
                      color: Colors.grey.withOpacity(0.5),
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
  
  // Static methods for external control
  static void setDisabled(GameButton button, bool disabled) {
    if (button.key != null) {
      final state = button.key as GlobalKey<_GameButtonState>;
      state.currentState?.setState(() {
        state.currentState?._isDisabled = disabled;
      });
    }
  }
  
  static void cooldown(GameButton button) {
    if (button.key != null) {
      final state = button.key as GlobalKey<_GameButtonState>;
      state.currentState?._startCooldown();
    }
  }
  
  static void clearCooldown(GameButton button) {
    if (button.key != null) {
      final state = button.key as GlobalKey<_GameButtonState>;
      state.currentState?._clearCooldown();
    }
  }
}
