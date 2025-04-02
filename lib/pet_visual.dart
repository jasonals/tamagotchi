import 'package:flutter/material.dart';
import 'package:tamagotchi/pet.dart'; // Import PetState and LifeStage

class PetVisual extends StatefulWidget {
  final PetState petState;

  const PetVisual({required this.petState, super.key});

  @override
  State<PetVisual> createState() => _PetVisualState();
}

class _PetVisualState extends State<PetVisual>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Adjust animation speed based on pet state
    final duration = _getAnimationDuration();

    _controller = AnimationController(duration: duration, vsync: this)
      ..repeat(reverse: true);

    _sizeAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  Duration _getAnimationDuration() {
    // Adjust animation speed based on pet state
    if (widget.petState.isSleeping) {
      return const Duration(milliseconds: 2000); // Slower when sleeping
    }
    if (widget.petState.isSick) {
      return const Duration(milliseconds: 800); // Faster when sick
    }
    if (widget.petState.happiness < 30 || widget.petState.hunger > 80) {
      return const Duration(milliseconds: 1000); // Agitated when unhappy/hungry
    }

    // Default animation speed
    return const Duration(milliseconds: 1500);
  }

  @override
  void didUpdateWidget(PetVisual oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update animation speed if pet state changes
    final newDuration = _getAnimationDuration();
    if (_controller.duration != newDuration) {
      _controller.stop();
      _controller.duration = newDuration;
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!widget.petState.isAlive) {
          // Ghost floats gently
          return Transform.translate(
            offset: Offset(0, _bounceAnimation.value / 2),
            child: _getPetDisplay(),
          );
        }

        if (widget.petState.isSleeping) {
          // Gentle breathing when sleeping
          return Transform.translate(
            offset: Offset(0, _bounceAnimation.value / 3),
            child: _getPetDisplay(),
          );
        }

        if (widget.petState.isSick) {
          // Wobble and shake when sick
          return Transform.translate(
            offset: Offset(
              _bounceAnimation.value / 2 * ((_controller.value > 0.5) ? 1 : -1),
              0,
            ),
            child: Transform.rotate(
              angle: (_controller.value - 0.5) * 0.1,
              child: _getPetDisplay(),
            ),
          );
        }

        if (widget.petState.hunger > 80) {
          // Drooping movement when hungry
          return Transform.translate(
            offset: Offset(0, _bounceAnimation.value),
            child: Transform.rotate(
              angle: (_controller.value - 0.5) * 0.05,
              child: _getPetDisplay(),
            ),
          );
        }

        if (widget.petState.happiness < 30) {
          // Agitated movement when unhappy
          return Transform.translate(
            offset: Offset(
              _bounceAnimation.value / 3 * ((_controller.value > 0.5) ? 1 : -1),
              0,
            ),
            child: _getPetDisplay(),
          );
        }

        if (widget.petState.cleanliness < 30) {
          // Sluggish movement when dirty
          return Transform.scale(
            scale: 0.95 + (_sizeAnimation.value - 0.9) / 2, // Reduced bounce
            child: Transform.translate(
              offset: Offset(0, _bounceAnimation.value / 2), // Slower movement
              child: _getPetDisplay(),
            ),
          );
        }

        if (widget.petState.tiredness > 80 && !widget.petState.isSleeping) {
          // Tired pet shows droopy, slow movement
          return Transform.translate(
            offset: Offset(0, _bounceAnimation.value / 2),
            child: Transform.rotate(
              angle: (_controller.value - 0.5) * 0.02, // Very slight tilt
              child: _getPetDisplay(),
            ),
          );
        }

        // Default: happy bounce animation
        return Transform.scale(
          scale: _sizeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _bounceAnimation.value),
            child: _getPetDisplay(),
          ),
        );
      },
    );
  }

  Widget _getPetDisplay() {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: _getPetBackgroundColor(),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main pet emoji
          Text(_getPetEmoji(), style: const TextStyle(fontSize: 60)),

          // Cleanliness indicator (dirt spots if dirty)
          if (widget.petState.cleanliness < 30)
            Positioned(
              right: 30,
              bottom: 35,
              child: Text('💩', style: TextStyle(fontSize: 20)),
            ),

          // Hunger indicator (food bubble if hungry)
          if (widget.petState.hunger > 70 && !widget.petState.isSleeping)
            Positioned(
              left: 30,
              top: 30,
              child: Text('🍽️', style: TextStyle(fontSize: 20)),
            ),

          // Sleep indicator (Zzz if sleeping)
          if (widget.petState.isSleeping)
            Positioned(
              right: 25,
              top: 30,
              child: Text('💤', style: TextStyle(fontSize: 20)),
            ),

          // Sick indicator (thermometer if sick)
          if (widget.petState.isSick)
            Positioned(
              left: 25,
              bottom: 30,
              child: Text('🤒', style: TextStyle(fontSize: 20)),
            ),

          // Tiredness indicator
          if (widget.petState.tiredness > 70 &&
              !widget.petState.isSleeping &&
              !widget.petState.isSick)
            Positioned(
              right: 30,
              top: 30,
              child: Text('😪', style: TextStyle(fontSize: 20)),
            ),
        ],
      ),
    );
  }

  Color _getPetBackgroundColor() {
    if (!widget.petState.isAlive) return Colors.grey.withOpacity(0.3);
    if (widget.petState.isSick) return Colors.green.withOpacity(0.3);
    if (widget.petState.isSleeping) return Colors.indigo.withOpacity(0.2);
    if (widget.petState.hunger > 80) return Colors.orange.withOpacity(0.2);
    if (widget.petState.happiness < 30) return Colors.red.withOpacity(0.2);
    if (widget.petState.cleanliness < 30) return Colors.brown.withOpacity(0.2);
    if (widget.petState.tiredness > 80 && !widget.petState.isSleeping)
      return Colors.grey.withOpacity(0.2);

    // Color based on life stage
    switch (widget.petState.lifeStage) {
      case LifeStage.baby:
        return Colors.lightBlue.withOpacity(0.2);
      case LifeStage.child:
        return Colors.teal.withOpacity(0.2);
      case LifeStage.teen:
        return Colors.purple.withOpacity(0.2);
      case LifeStage.adult:
        return Colors.deepOrange.withOpacity(0.2);
    }
  }

  String _getPetEmoji() {
    // Prioritize states
    if (!widget.petState.isAlive) return '👻';
    if (widget.petState.isSick) return '🤢';
    if (widget.petState.isSleeping) return '😴';

    // Prioritize needs
    if (widget.petState.hunger > 80) return '😫';
    if (widget.petState.cleanliness < 20) return '😖';
    if (widget.petState.happiness < 30) {
      // Unhappy expression based on life stage
      switch (widget.petState.lifeStage) {
        case LifeStage.baby:
          return '😭';
        case LifeStage.child:
          return '😟';
        case LifeStage.teen:
          return '😠';
        case LifeStage.adult:
          return '😞';
      }
    }

    // Add tired state
    if (widget.petState.tiredness > 80 && !widget.petState.isSleeping)
      return '😴';

    // Happy (default state) based on life stage
    switch (widget.petState.lifeStage) {
      case LifeStage.baby:
        return '👶';
      case LifeStage.child:
        return '🧒';
      case LifeStage.teen:
        return '🧑';
      case LifeStage.adult:
        return '🧓';
    }
  }
}
