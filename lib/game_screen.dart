import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tamagotchi/pet.dart'; // Import PetState and provider
import 'package:tamagotchi/pet_visual.dart'; // Import PetVisual
import 'dart:async'; // For Timer

class GameScreen extends HookConsumerWidget {
  // Change to HookConsumerWidget
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the pet state and notifier
    final petState = ref.watch(petProvider);
    final petNotifier = ref.read(petProvider.notifier);

    // Effect hook for the timer
    useEffect(() {
      // Only run the timer if the pet is alive
      if (!petState.isAlive) {
        return null; // Return null or an empty cleanup function if timer shouldn't run
      }

      final timer = Timer.periodic(const Duration(seconds: 5), (_) {
        // Check isAlive again inside timer callback in case state changes
        if (ref.read(petProvider).isAlive) {
          petNotifier.tick();
        } else {
          // Cancel timer if pet dies during the interval
          // This might require storing the timer instance to cancel it
          // For simplicity, we rely on the useEffect cleanup
        }
      });

      // Cleanup function
      return () {
        print("Cancelling timer...");
        timer.cancel();
      };
      // Re-run effect if isAlive changes
    }, [petState.isAlive]);

    // Disable actions if sleeping, sick, OR dead
    final bool actionsEnabled =
        !petState.isSleeping && !petState.isSick && petState.isAlive;
    final bool sleepEnabled = !petState.isSick && petState.isAlive;
    final bool medicineEnabled = petState.isSick && petState.isAlive;

    return Scaffold(
      appBar: AppBar(title: const Text('My Tamagotchi')),
      body: Center(
        // Display Pet Status
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use the PetVisual widget
            PetVisual(petState: petState),
            const SizedBox(height: 20),
            if (petState.isAlive) ...[
              Text('Age: ${petState.age} ticks (${petState.lifeStage.name})'),
              Text('Care Points: ${petState.carePoints}'),
              const SizedBox(height: 10),
              Text('Hunger: ${petState.hunger}/100'),
              Text('Happiness: ${petState.happiness}/100'),
              Text('Cleanliness: ${petState.cleanliness}/100'),
              const SizedBox(height: 10),
              Text(
                petState.isSleeping
                    ? '(Sleeping)'
                    : petState.isSick
                    ? '(Sick - ${petState.sickDuration}t)'
                    : '(Awake)',
              ),
            ] else
              Column(
                children: [
                  const Text(
                    'Game Over',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: petNotifier.resetPet,
                    child: const Text('Start Over?'),
                  ),
                ],
              ),
          ],
        ),
      ),
      // Disable bottom bar if pet is not alive
      bottomNavigationBar:
          petState.isAlive
              ? BottomAppBar(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.fastfood),
                      tooltip: 'Feed',
                      // Disable button if sleeping or sick
                      onPressed: actionsEnabled ? petNotifier.feed : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.cleaning_services),
                      tooltip: 'Clean',
                      // Disable button if sleeping or sick
                      onPressed: actionsEnabled ? petNotifier.clean : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.games),
                      tooltip: 'Play',
                      // Disable button if sleeping or sick
                      onPressed: actionsEnabled ? petNotifier.play : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.medical_services),
                      tooltip: 'Medicine',
                      // Only enable if sick
                      onPressed: medicineEnabled ? petNotifier.cure : null,
                    ),
                    IconButton(
                      icon: Icon(
                        petState.isSleeping
                            ? Icons.wb_sunny
                            : Icons.nightlight_round,
                      ),
                      tooltip: petState.isSleeping ? 'Wake Up' : 'Sleep',
                      // Disable sleep toggle if sick?
                      onPressed:
                          petState.isSleeping
                              ? petNotifier.wakeUp
                              : (sleepEnabled ? petNotifier.sleep : null),
                    ),
                  ],
                ),
              )
              : null, // Hide bottom bar when dead
    );
  }
}
