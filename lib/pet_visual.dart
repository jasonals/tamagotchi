import 'package:flutter/material.dart';
import 'package:tamagotchi/pet.dart'; // Import PetState and LifeStage

class PetVisual extends StatelessWidget {
  final PetState petState;

  const PetVisual({required this.petState, super.key});

  String _getPetEmoji() {
    // Check if alive first
    if (!petState.isAlive) {
      return '👻'; // Ghost emoji for death
    }
    // Prioritize other states
    if (petState.isSick) return '🤢';
    if (petState.isSleeping) return '😴';

    // Choose emoji based on life stage and happiness
    switch (petState.lifeStage) {
      case LifeStage.baby:
        return petState.happiness < 30
            ? '😭'
            : '👶'; // Crying baby or normal baby
      case LifeStage.child:
        return petState.happiness < 30
            ? '😟'
            : '🧒'; // Worried child or normal child
      case LifeStage.teen:
        return petState.happiness < 30
            ? '😠'
            : '🧑'; // Angry teen or normal teen
      case LifeStage.adult:
        return petState.happiness < 30
            ? '😞'
            : '🧓'; // Disappointed adult or normal adult
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_getPetEmoji(), style: const TextStyle(fontSize: 80));
  }
}
