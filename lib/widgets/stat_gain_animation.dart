import 'package:flutter/material.dart';
import '../models/workout_type.dart';

class StatGainWidget extends StatefulWidget {
  final StatType statType;
  final int amount;
  final AnimationController animationController;

  const StatGainWidget({
    super.key,
    required this.statType,
    required this.amount,
    required this.animationController,
  });

  @override
  State<StatGainWidget> createState() => _StatGainWidgetState();
}

class _StatGainWidgetState extends State<StatGainWidget> {
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Slide up animation
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: -80.0,
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    // Fade out animation
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    ));

    // Scale animation for emphasis
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));
  }

  Color _getStatColor() {
    switch (widget.statType) {
      case StatType.strength:
        return Colors.red[600]!;
      case StatType.agility:
        return Colors.yellow[600]!;
      case StatType.endurance:
        return Colors.green[600]!;
      case StatType.health:
        return Colors.pink[600]!;
      case StatType.happiness:
        return Colors.orange[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatColor(),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatColor().withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.statType.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${widget.amount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class StatGainAnimationOverlay extends StatefulWidget {
  final List<MapEntry<StatType, int>> statGains;
  final VoidCallback? onComplete;

  const StatGainAnimationOverlay({
    super.key,
    required this.statGains,
    this.onComplete,
  });

  @override
  State<StatGainAnimationOverlay> createState() => _StatGainAnimationOverlayState();
}

class _StatGainAnimationOverlayState extends State<StatGainAnimationOverlay>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<StatGainWidget> _widgets;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _controllers = [];
    _widgets = [];

    for (int i = 0; i < widget.statGains.length; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );
      
      final statGain = widget.statGains[i];
      final widget_ = StatGainWidget(
        statType: statGain.key,
        amount: statGain.value,
        animationController: controller,
      );

      _controllers.add(controller);
      _widgets.add(widget_);

      // Stagger the animations
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          controller.forward().then((_) {
            if (i == widget.statGains.length - 1) {
              widget.onComplete?.call();
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _widgets.asMap().entries.map((entry) {
        final index = entry.key;
        final widget_ = entry.value;
        
        return Align(
          alignment: Alignment.topRight,
          child: Transform.translate(
            offset: Offset(-20, 100 + (index * 30)), // Position from top-right
            child: widget_,
          ),
        );
      }).toList(),
    );
  }
}
