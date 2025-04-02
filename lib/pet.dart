import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math'; // Import Random

// Define life stages
enum LifeStage { baby, child, teen, adult }

// Represents the state of the pet
class PetState {
  final int hunger;
  final int happiness;
  final int cleanliness;
  final bool isSleeping;
  final bool isSick;
  final int age; // Add age (in ticks)
  final LifeStage lifeStage; // Add life stage
  final bool isAlive; // Add isAlive flag
  final int sickDuration; // Add sickness duration
  final int carePoints; // Add care points
  final int tiredness; // Add tiredness attribute

  PetState({
    this.hunger = 50,
    this.happiness = 50,
    this.cleanliness = 50,
    this.isSleeping = false,
    this.isSick = false,
    this.age = 0, // Start at age 0
    this.lifeStage = LifeStage.baby, // Start as baby
    this.isAlive = true, // Start alive
    this.sickDuration = 0, // Start not sick
    this.carePoints = 0, // Start with 0 care points
    this.tiredness = 30, // Start with some tiredness (0-100 scale)
  });

  // Helper method to create a copy with updated values
  PetState copyWith({
    int? hunger,
    int? happiness,
    int? cleanliness,
    bool? isSleeping,
    bool? isSick,
    int? age,
    LifeStage? lifeStage,
    bool? isAlive, // Add isAlive
    int? sickDuration, // Add sickDuration
    int? carePoints, // Add carePoints
    int? tiredness, // Add tiredness to copyWith
  }) {
    return PetState(
      hunger: hunger ?? this.hunger,
      happiness: happiness ?? this.happiness,
      cleanliness: cleanliness ?? this.cleanliness,
      isSleeping: isSleeping ?? this.isSleeping,
      isSick: isSick ?? this.isSick,
      age: age ?? this.age,
      lifeStage: lifeStage ?? this.lifeStage,
      isAlive: isAlive ?? this.isAlive, // Update copyWith
      sickDuration: sickDuration ?? this.sickDuration, // Update copyWith
      carePoints: carePoints ?? this.carePoints, // Update copyWith
      tiredness: tiredness ?? this.tiredness, // Pass tiredness
    );
  }
}

// Manages the state of the Pet
class PetNotifier extends StateNotifier<PetState> {
  // Age thresholds for evolution (in ticks)
  static const int childAgeThreshold =
      10; // e.g., 10 ticks * 5s/tick = 50 seconds
  static const int teenAgeThreshold = 30; // 150 seconds
  static const int adultAgeThreshold = 60; // 300 seconds (5 minutes)
  static const int maxSickDuration =
      20; // e.g., 20 ticks to potentially die from sickness

  // Care point thresholds for evolution
  static const int childCareThreshold = 5;
  static const int teenCareThreshold = 15;
  static const int adultCareThreshold = 30;

  // Maximum tiredness before pet needs rest
  static const int maxTirednessThreshold = 85;

  PetNotifier() : super(PetState());
  final _random = Random();

  void feed() {
    int currentHunger = state.hunger;
    int currentCare = state.carePoints;
    int currentHappiness = state.happiness;
    String message;

    if (currentHunger < 10) {
      // Overfeeding
      currentHappiness = (currentHappiness - 5).clamp(0, 100);
      currentCare = (currentCare - 1).clamp(0, 1000);
      message = "Pet is full! Overfeeding made it unhappy.";
    } else {
      int hungerDecrease = 15; // Base decrease
      int careGain = 1;
      if (currentHunger > 70) {
        careGain = 2; // More points if very hungry
      }
      currentHunger = (currentHunger - hungerDecrease).clamp(0, 100);
      currentCare += careGain;
      message = "Fed the pet.";
    }

    // Feeding takes a small amount of energy
    int currentTiredness = state.tiredness;
    currentTiredness = (currentTiredness + 2).clamp(0, 100);

    state = state.copyWith(
      hunger: currentHunger,
      happiness: currentHappiness,
      carePoints: currentCare,
      tiredness: currentTiredness,
    );
    print(
      "$message H:${state.hunger} Ha:${state.happiness} C:${state.carePoints}",
    );
  }

  void clean() {
    int currentCleanliness = state.cleanliness;
    int currentCare = state.carePoints;
    int currentHappiness = state.happiness;
    String message;

    if (currentCleanliness > 90) {
      // Cleaning when already clean
      currentHappiness = (currentHappiness - 5).clamp(0, 100);
      currentCare = (currentCare - 1).clamp(0, 1000);
      message = "Pet is already clean! It got annoyed.";
    } else {
      int cleanIncrease = 15; // Base increase
      int careGain = 1;
      if (currentCleanliness < 30) {
        careGain = 2; // More points if very dirty
      }
      currentCleanliness = (currentCleanliness + cleanIncrease).clamp(0, 100);
      currentCare += careGain;
      message = "Cleaned the pet.";
    }

    // Cleaning takes a small amount of energy
    int currentTiredness = state.tiredness;
    currentTiredness = (currentTiredness + 5).clamp(0, 100);

    state = state.copyWith(
      cleanliness: currentCleanliness,
      happiness: currentHappiness,
      carePoints: currentCare,
      tiredness: currentTiredness,
    );
    print(
      "$message Cl:${state.cleanliness} Ha:${state.happiness} C:${state.carePoints}",
    );
  }

  void play() {
    int currentHappiness = state.happiness;
    int currentCare = state.carePoints;
    int currentTiredness = state.tiredness;
    String message;

    // Check if the pet is too tired to play
    if (currentTiredness >= maxTirednessThreshold) {
      // If pet is very tired, playing hurts happiness and doesn't boost it
      currentHappiness = (currentHappiness - 5).clamp(0, 100);
      currentCare = (currentCare - 1).clamp(0, 1000);
      // Still gets even more tired!
      currentTiredness = (currentTiredness + 10).clamp(0, 100);
      message = "Pet is too tired to play!";
    } else {
      // Normal play behavior
      int happinessIncrease = 15;
      int careGain = 1;
      if (currentHappiness < 40) {
        careGain = 2; // More points if sad
      }
      currentHappiness = (currentHappiness + happinessIncrease).clamp(0, 100);
      currentCare += careGain;

      // Playing makes pet tired
      currentTiredness = (currentTiredness + 15).clamp(0, 100);

      message = "Played with the pet.";
    }

    state = state.copyWith(
      happiness: currentHappiness,
      carePoints: currentCare,
      tiredness: currentTiredness,
    );

    // Auto-sleep if extremely tired
    if (currentTiredness > 95 && !state.isSleeping && !state.isSick) {
      Future.delayed(const Duration(milliseconds: 500), () {
        sleep();
      });
    }

    print(
      "$message Ha:${state.happiness} T:${state.tiredness} C:${state.carePoints}",
    );
  }

  void sleep() {
    if (!state.isSleeping) {
      state = state.copyWith(isSleeping: true);
      print("Pet is now sleeping. Tiredness: ${state.tiredness}");
    }
  }

  void wakeUp() {
    if (state.isSleeping) {
      // Penalty for waking up while still tired
      int happinessPenalty = 0;
      String message = "Pet woke up!";

      if (state.tiredness > 50) {
        happinessPenalty = 10; // Greater penalty if still tired
        message = "Pet woke up too early and feels grumpy!";
      } else if (state.tiredness > 20) {
        happinessPenalty = 5; // Small penalty if somewhat tired
        message = "Pet would have liked to sleep a bit more.";
      }

      state = state.copyWith(
        isSleeping: false,
        happiness: (state.happiness - happinessPenalty).clamp(0, 100),
      );

      print(
        "$message Happiness: ${state.happiness}, Tiredness: ${state.tiredness}",
      );
    }
  }

  void cure() {
    if (state.isSick) {
      state = state.copyWith(
        isSick: false,
        sickDuration: 0,
        carePoints: state.carePoints + 3,
      );
      print("Gave medicine. Pet is feeling better! C:${state.carePoints}");
    } else {
      // Giving medicine when not sick
      state = state.copyWith(
        happiness: (state.happiness - 10).clamp(0, 100),
        carePoints: (state.carePoints - 2).clamp(0, 1000),
      );
      print(
        "Pet wasn't sick! Medicine made it unhappy. Ha:${state.happiness} C:${state.carePoints}",
      );
    }
  }

  void tick() {
    // Do nothing if the pet is not alive
    if (!state.isAlive) {
      print("Pet is not alive. No tick.");
      return;
    }

    // Check for death conditions *before* applying other changes
    if (_shouldDie()) {
      state = state.copyWith(isAlive: false);
      print("Oh no! The pet is gone... :(");
      return; // Stop processing this tick
    }

    // --- Sickness Logic Update ---
    bool currentlySick = state.isSick;
    int currentSickDuration = state.sickDuration;

    if (currentlySick) {
      // If sick, increment duration
      currentSickDuration++;
      print("Pet has been sick for $currentSickDuration ticks.");
    } else {
      // Check if pet becomes sick this tick
      if (_shouldGetSick()) {
        currentlySick = true;
        currentSickDuration = 1; // Start duration
        print("Pet got sick!");
      }
    }
    // --- End Sickness Logic Update ---

    // Increment age regardless of sleep/awake state
    int currentAge = state.age + 1;
    int currentCarePoints = state.carePoints;
    int currentTiredness = state.tiredness;
    LifeStage currentStage = state.lifeStage;

    // Penalties for bad states - Scaled penalties
    if (state.hunger > 80) {
      int penalty =
          ((state.hunger - 80) / 10)
              .ceil(); // 1 point penalty at 81, 2 at 91 etc.
      currentCarePoints = (currentCarePoints - penalty).clamp(0, 1000);
    }
    if (state.cleanliness < 20) {
      int penalty =
          ((20 - state.cleanliness) / 10).ceil(); // 1 point at 19, 2 at 9 etc.
      currentCarePoints = (currentCarePoints - penalty).clamp(0, 1000);
    }
    if (state.happiness < 20) {
      int penalty =
          ((20 - state.happiness) / 10).ceil(); // 1 point at 19, 2 at 9 etc.
      currentCarePoints = (currentCarePoints - penalty).clamp(0, 1000);
    }
    if (state.isSick) {
      // Maybe scale penalty with duration? For now, keep flat penalty per tick.
      currentCarePoints = (currentCarePoints - 1).clamp(0, 1000);
    }

    // Auto-sleep when extremely tired (if not already sleeping or sick)
    if (currentTiredness >= maxTirednessThreshold &&
        !state.isSleeping &&
        !state.isSick) {
      print("Pet is exhausted, falling asleep automatically...");
      sleep();
      return; // Exit tick since pet is now sleeping
    }

    // Check for evolution
    LifeStage newStage = _getLifeStage(currentAge, currentCarePoints);
    if (newStage != currentStage) {
      print(
        "Pet evolved to ${newStage.name}! (Age: $currentAge, Care: $currentCarePoints)",
      );
      currentStage = newStage;
    }

    // Apply state changes common to both sleeping and awake
    state = state.copyWith(
      age: currentAge,
      lifeStage: currentStage,
      isSick: currentlySick,
      sickDuration: currentSickDuration,
      carePoints: currentCarePoints,
    );

    if (state.isSleeping) {
      // Sleeping reduces tiredness
      currentTiredness = (currentTiredness - 10).clamp(0, 100);

      state = state.copyWith(
        hunger: (state.hunger + 0).clamp(0, 100),
        tiredness: currentTiredness,
      );

      print("Tick... zZzZz (Age: ${state.age}, Tiredness: ${state.tiredness})");
      _applySicknessEffects();
      return;
    }

    // Awake tick logic - being awake makes pet gradually more tired
    currentTiredness = (currentTiredness + 3).clamp(0, 100);

    state = state.copyWith(
      hunger: (state.hunger + 2).clamp(0, 100),
      happiness: (state.happiness - 0).clamp(0, 100),
      cleanliness: (state.cleanliness - 1).clamp(0, 100),
      tiredness: currentTiredness,
    );

    _applySicknessEffects();

    print(
      "Tick! Alive:${state.isAlive} Age:${state.age} T:${state.tiredness} Stage:${state.lifeStage.name} H:${state.hunger} Ha:${state.happiness} C:${state.cleanliness} Sick:${state.isSick ? '${state.sickDuration}t' : 'No'} Care:${state.carePoints}",
    );
  }

  // Updated evolution logic
  LifeStage _getLifeStage(int age, int carePoints) {
    if (age >= adultAgeThreshold && carePoints >= adultCareThreshold) {
      return LifeStage.adult;
    } else if (age >= teenAgeThreshold && carePoints >= teenCareThreshold) {
      return LifeStage.teen;
    } else if (age >= childAgeThreshold && carePoints >= childCareThreshold) {
      return LifeStage.child;
    } else {
      return LifeStage.baby;
    }
  }

  // Helper to determine if the pet gets sick
  bool _shouldGetSick() {
    // Higher chance if cleanliness is low or hunger is high
    double sickChance = 0.01; // Base chance (1%)
    if (state.cleanliness < 20) sickChance += 0.05; // Add 5% if dirty
    if (state.hunger > 80) sickChance += 0.05; // Add 5% if very hungry

    return _random.nextDouble() < sickChance;
  }

  // Helper to apply ongoing effects of sickness
  void _applySicknessEffects() {
    if (state.isSick) {
      print("Pet is sick... cough cough... (Duration: ${state.sickDuration})");
      // Decrease happiness faster when sick
      state = state.copyWith(happiness: (state.happiness - 2).clamp(0, 100));
    }
  }

  // Helper to check death conditions
  bool _shouldDie() {
    // Example conditions: hunger maxed OR happiness zeroed for too long?
    // Let's keep it simple for now: Hunger >= 100 OR Happiness <= 0
    if (state.hunger >= 100) {
      print("Death Condition: Hunger maxed out.");
      return true;
    }
    if (state.happiness <= 0) {
      print("Death Condition: Happiness zeroed out.");
      return true;
    }
    // Add death condition for being sick too long
    if (state.isSick && state.sickDuration >= maxSickDuration) {
      print(
        "Death Condition: Sick for too long (${state.sickDuration} ticks).",
      );
      return true;
    }
    return false;
  }

  // Add a method to reset the game
  void resetPet() {
    print("Resetting pet state.");
    state = PetState(); // Create a new initial state
  }
}

// The provider that allows the UI to interact with the PetNotifier
final petProvider = StateNotifierProvider<PetNotifier, PetState>((ref) {
  return PetNotifier();
});
