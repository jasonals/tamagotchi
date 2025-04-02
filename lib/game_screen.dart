import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tamagotchi/pet.dart'; // Import PetState and provider
import 'package:tamagotchi/pet_visual.dart'; // Import PetVisual
import 'package:tamagotchi/mini_games.dart'; // Import mini-games
import 'dart:async'; // For Timer

// Helper to convert stat to qualitative description
String _getStatusDescription(int value, bool inverse) {
  if (inverse) {
    // For hunger and energy (lower is better)
    if (value < 20) return "Full";
    if (value < 40) return "Satisfied";
    if (value < 60) return "Hungry";
    if (value < 80) return "Very hungry";
    return "Starving";
  } else {
    // For happiness, cleanliness (higher is better)
    if (value > 80) return "Excellent";
    if (value > 60) return "Good";
    if (value > 40) return "Fair";
    if (value > 20) return "Poor";
    return "Critical";
  }
}

// Specialized description for energy levels
String _getEnergyDescription(int tiredness) {
  // For tiredness (lower is better)
  if (tiredness < 20) return "Well-rested";
  if (tiredness < 40) return "Awake";
  if (tiredness < 60) return "Getting tired";
  if (tiredness < 80) return "Tired";
  return "Exhausted";
}

class GameScreen extends HookConsumerWidget {
  // Change to HookConsumerWidget
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the pet state and notifier
    final petState = ref.watch(petProvider);
    final petNotifier = ref.read(petProvider.notifier);

    // Message state for feedback
    final messageController = useState('Welcome to your virtual pet!');

    // Show message with auto-dismissal
    void showMessage(String message) {
      messageController.value = message;
      Future.delayed(const Duration(seconds: 2), () {
        if (messageController.value == message) {
          messageController.value =
              ''; // Clear only if it's still the same message
        }
      });
    }

    // Wrapped action methods that display feedback
    void feed() {
      final hunger = petState.hunger;
      petNotifier.feed();
      showMessage(
        hunger < 10
            ? 'Pet is too full!'
            : hunger > 70
            ? 'Pet was very hungry!'
            : 'Pet was fed.',
      );
    }

    void clean() {
      final cleanliness = petState.cleanliness;
      petNotifier.clean();
      showMessage(
        cleanliness > 90
            ? 'Pet was already clean!'
            : cleanliness < 30
            ? 'Pet was very dirty!'
            : 'Pet was cleaned.',
      );
    }

    void play() {
      final happiness = petState.happiness;
      final tiredness = petState.tiredness;
      petNotifier.play();

      if (tiredness >= 85) {
        showMessage('Pet is too tired to play!');
      } else if (tiredness >= 70) {
        showMessage('Pet played but is getting tired!');
      } else if (happiness >= 100) {
        showMessage('Pet is already happy!');
      } else if (happiness < 40) {
        showMessage('Pet really needed playtime!');
      } else {
        showMessage('Pet enjoyed playing!');
      }
    }

    void giveMedicine() {
      final isSick = petState.isSick;
      petNotifier.cure();
      showMessage(isSick ? 'Pet is feeling better!' : 'Pet wasn\'t sick!');
    }

    void toggleSleep() {
      if (petState.isSleeping) {
        petNotifier.wakeUp();
        showMessage('Pet woke up!');
      } else {
        petNotifier.sleep();
        showMessage('Pet went to sleep.');
      }
    }

    // Effect hook for the timer
    useEffect(() {
      // Only run the timer if the pet is alive
      if (!petState.isAlive) {
        return null;
      }

      final timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (ref.read(petProvider).isAlive) {
          final previousState = petState; // Store the state before tick
          petNotifier.tick();
          final newState = ref.read(petProvider);

          // Check if pet fell asleep automatically due to tiredness
          if (!previousState.isSleeping &&
              newState.isSleeping &&
              newState.tiredness > 85) {
            showMessage('Pet fell asleep from exhaustion!');
            return;
          }

          // Optional: Show notifications about critical states
          if (newState.hunger > 80 && !newState.isSleeping) {
            showMessage('Pet is very hungry!');
          } else if (newState.happiness < 20 && !newState.isSleeping) {
            showMessage('Pet is very unhappy!');
          } else if (newState.cleanliness < 20 && !newState.isSleeping) {
            showMessage('Pet is very dirty!');
          } else if (newState.tiredness > 85 && !newState.isSleeping) {
            showMessage('Pet is exhausted!');
          } else if (newState.isSick) {
            showMessage('Pet is sick! (${newState.sickDuration}t)');
          }
        }
      });

      return () {
        print("Cancelling timer...");
        timer.cancel();
      };
    }, [petState.isAlive]);

    // Disable actions if sleeping, sick, OR dead
    final bool actionsEnabled =
        !petState.isSleeping && !petState.isSick && petState.isAlive;
    final bool sleepEnabled = !petState.isSick && petState.isAlive;
    final bool medicineEnabled = petState.isSick && petState.isAlive;

    // Theme colors
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final backgroundColor = Theme.of(context).colorScheme.background;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              // Pet display area - increase flex since we removed the app bar
              Expanded(
                flex: 6,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (petState.isAlive) ...[
                          // Title text to replace the app bar
                          Text(
                            'My Virtual Pet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 24),

                          // Pet visual
                          PetVisual(petState: petState),

                          // Status text
                          const SizedBox(height: 8),
                          Text(
                            petState.isSleeping
                                ? 'Sleeping'
                                : petState.isSick
                                ? 'Sick (${petState.sickDuration}t)'
                                : 'Awake',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // Message area
                          const SizedBox(height: 8),
                          AnimatedOpacity(
                            opacity:
                                messageController.value.isEmpty ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: secondaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                messageController.value,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ] else
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Game Over',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              PetVisual(petState: petState),
                              const SizedBox(height: 20),
                              const Text(
                                'Your pet has passed away...',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  petNotifier.resetPet();
                                  showMessage('Starting a new game!');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text('Start Over'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Stats area - only if alive
              if (petState.isAlive)
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Age and Stage - keep these visible since evolution is obvious
                        Text(
                          'Age: Growing ${petState.lifeStage.name}', // Remove precise age in ticks
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Remove Care Points text - this should be inferred from pet's growth

                        // Replace stat bars with qualitative indicators
                        _buildStatusIndicator(
                          context: context,
                          label: 'Hunger',
                          value: petState.hunger,
                          color: Colors.orange,
                          icon: Icons.restaurant,
                          inverse: true,
                        ),

                        _buildStatusIndicator(
                          context: context,
                          label: 'Mood',
                          value: petState.happiness,
                          color: Colors.pink,
                          icon: Icons.favorite,
                        ),

                        _buildStatusIndicator(
                          context: context,
                          label: 'Cleanliness',
                          value: petState.cleanliness,
                          color: Colors.blue,
                          icon: Icons.water_drop,
                        ),

                        // Add tiredness indicator
                        _buildStatusIndicator(
                          context: context,
                          label: 'Energy',
                          value: petState.tiredness,
                          color: Colors.indigo,
                          icon: Icons.hotel,
                          inverse: true,
                          customDescription: _getEnergyDescription(
                            petState.tiredness,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Action buttons - only if alive
              if (petState.isAlive)
                Container(
                  height: 100,
                  margin: const EdgeInsets.only(
                    bottom: 16,
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      _buildActionButton(
                        icon: Icons.restaurant,
                        label: 'Feed',
                        onPressed: actionsEnabled ? feed : null,
                        color: Colors.orange,
                      ),
                      _buildActionButton(
                        icon: Icons.cleaning_services,
                        label: 'Clean',
                        onPressed: actionsEnabled ? clean : null,
                        color: Colors.blue,
                      ),
                      _buildActionButton(
                        icon: Icons.sports_esports,
                        label: 'Play',
                        onPressed: actionsEnabled ? play : null,
                        color: Colors.pink,
                      ),
                      _buildActionButton(
                        icon: Icons.medical_services,
                        label: 'Medicine',
                        onPressed: medicineEnabled ? giveMedicine : null,
                        color: Colors.red,
                      ),
                      _buildActionButton(
                        icon:
                            petState.isSleeping
                                ? Icons.wb_sunny
                                : Icons.nightlight_round,
                        label: petState.isSleeping ? 'Wake' : 'Sleep',
                        onPressed:
                            petState.isSleeping
                                ? toggleSleep
                                : (sleepEnabled ? toggleSleep : null),
                        color: Colors.indigo,
                      ),
                      _buildActionButton(
                        icon: Icons.sports_esports,
                        label: 'Games',
                        onPressed:
                            actionsEnabled
                                ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const MiniGameSelectionScreen(),
                                  ),
                                )
                                : null,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Replacement for _buildStatBar - shows descriptive text instead of numbers
  Widget _buildStatusIndicator({
    required BuildContext context,
    required String label,
    required int value,
    required Color color,
    required IconData icon,
    bool inverse = false,
    String? customDescription,
  }) {
    final description =
        customDescription ?? _getStatusDescription(value, inverse);
    final displayColor =
        inverse
            ? (value > 80 ? Colors.red : (value > 50 ? Colors.orange : color))
            : (value < 20 ? Colors.red : (value < 50 ? Colors.orange : color));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: displayColor),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: displayColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build action buttons
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                onPressed == null
                    ? Colors.grey.withOpacity(0.3)
                    : color.withOpacity(0.2),
          ),
          child: IconButton(
            icon: Icon(icon, color: onPressed == null ? Colors.grey : color),
            onPressed: onPressed,
            tooltip: label,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: onPressed == null ? Colors.grey : color,
          ),
        ),
      ],
    );
  }
}
