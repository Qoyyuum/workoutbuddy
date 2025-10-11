import 'package:flutter/material.dart';
import '../models/workout_buddy.dart';
import '../models/workout_type.dart';
import 'pixel_sprite.dart';

class AnimatedWorkoutBuddy extends StatefulWidget {
  final WorkoutBuddy workoutBuddy;
  final WorkoutType? workoutType;
  final AnimationController animationController;
  final bool isActive;

  const AnimatedWorkoutBuddy({
    super.key,
    required this.workoutBuddy,
    this.workoutType,
    required this.animationController,
    this.isActive = false,
  });

  @override
  State<AnimatedWorkoutBuddy> createState() => _AnimatedWorkoutBuddyState();
}

class _AnimatedWorkoutBuddyState extends State<AnimatedWorkoutBuddy>
    with TickerProviderStateMixin {
  late Animation<double> _bounceAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Bounce animation for jumping exercises
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: -30.0,
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: Curves.elasticOut,
    ));

    // Scale animation for strength exercises
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: Curves.easeInOut,
    ));

    // Rotation animation for dynamic exercises
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: Curves.easeInOut,
    ));
  }

  Widget _buildWorkoutAnimation() {
    if (!widget.isActive || widget.workoutType == null) {
      return _buildIdleBuddy();
    }

    switch (widget.workoutType!) {
      case WorkoutType.pushUp:
        return _buildPushUpAnimation();
      case WorkoutType.sitUp:
        return _buildSitUpAnimation();
      case WorkoutType.squat:
        return _buildSquatAnimation();
      case WorkoutType.running:
        return _buildRunningAnimation();
      case WorkoutType.walking:
        return _buildWalkingAnimation();
      case WorkoutType.jumping:
        return _buildJumpingAnimation();
      case WorkoutType.plank:
        return _buildPlankAnimation();
      case WorkoutType.burpee:
        return _buildBurpeeAnimation();
      case WorkoutType.pullUp:
        return _buildPullUpAnimation();
      case WorkoutType.lunges:
        return _buildLungesAnimation();
    }
  }

  Widget _buildIdleBuddy() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: PixelSprite(
        sprite: widget.workoutBuddy.sprite,
        size: 120,
      ),
    );
  }

  Widget _buildPushUpAnimation() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                PixelSprite(
                  sprite: widget.workoutBuddy.sprite,
                  size: 120,
                ),
                Positioned(
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '💪 PUSH-UP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSitUpAnimation() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[300]!, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                PixelSprite(
                  sprite: widget.workoutBuddy.sprite,
                  size: 120,
                ),
                Positioned(
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🔥 SIT-UP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSquatAnimation() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scaleY: 2.0 - _scaleAnimation.value, // Compress vertically
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple[300]!, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                PixelSprite(
                  sprite: widget.workoutBuddy.sprite,
                  size: 120,
                ),
                Positioned(
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🦵 SQUAT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRunningAnimation() {
    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            20 * (widget.animationController.value - 0.5),
            0,
          ),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[300]!, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                PixelSprite(
                  sprite: widget.workoutBuddy.sprite,
                  size: 120,
                ),
                Positioned(
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🏃 RUNNING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWalkingAnimation() {
    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            10 * (widget.animationController.value - 0.5),
            0,
          ),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.lightGreen[300]!, width: 3),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                PixelSprite(
                  sprite: widget.workoutBuddy.sprite,
                  size: 120,
                ),
                Positioned(
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.lightGreen[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🚶 WALKING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildJumpingAnimation() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.yellow[600]!, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                PixelSprite(
                  sprite: widget.workoutBuddy.sprite,
                  size: 120,
                ),
                Positioned(
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.yellow[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '⚡ JUMPING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlankAnimation() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.brown[300]!, width: 3),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PixelSprite(
            sprite: widget.workoutBuddy.sprite,
            size: 120,
          ),
          Positioned(
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.brown[600],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🏋️ PLANK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBurpeeAnimation() {
    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _bounceAnimation.value * 0.5),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[600]!, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PixelSprite(
                    sprite: widget.workoutBuddy.sprite,
                    size: 120,
                  ),
                  Positioned(
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '🔥 BURPEE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPullUpAnimation() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value * 0.3),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[600]!, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                PixelSprite(
                  sprite: widget.workoutBuddy.sprite,
                  size: 120,
                ),
                Positioned(
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '💪 PULL-UP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLungesAnimation() {
    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            15 * (widget.animationController.value - 0.5),
            0,
          ),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.indigo[300]!, width: 3),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                PixelSprite(
                  sprite: widget.workoutBuddy.sprite,
                  size: 120,
                ),
                Positioned(
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🦵 LUNGES',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _buildWorkoutAnimation(),
    );
  }
}
