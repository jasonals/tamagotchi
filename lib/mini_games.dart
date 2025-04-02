import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tamagotchi/pet.dart';
import 'dart:async'; // Add Timer import
import 'dart:math'; // Add Random import

// A class to hold state and logic for mini-games
class MiniGameState {
  final String name;
  final String description;
  final int difficultyLevel;
  final int happinessReward;
  final int energyCost;

  const MiniGameState({
    required this.name,
    required this.description,
    required this.difficultyLevel, // 1-5, with 5 being hardest
    required this.happinessReward,
    required this.energyCost,
  });
}

// List of available mini-games
final miniGames = [
  MiniGameState(
    name: 'Ball Catch',
    description: 'Tap the screen when the ball is in the target zone!',
    difficultyLevel: 1,
    happinessReward: 20,
    energyCost: 10,
  ),
  MiniGameState(
    name: 'Memory Match',
    description: 'Remember and repeat the pattern!',
    difficultyLevel: 2,
    happinessReward: 25,
    energyCost: 15,
  ),
  MiniGameState(
    name: 'Food Rush',
    description: 'Collect as much food as possible in 30 seconds!',
    difficultyLevel: 3,
    happinessReward: 30,
    energyCost: 20,
  ),
];

// Provider to track the currently selected mini-game
final selectedMiniGameProvider = StateProvider<MiniGameState?>((ref) => null);

// Results for mini-games
class MiniGameResult {
  final bool success;
  final int scorePercent; // 0-100
  final int happinessGained;

  const MiniGameResult({
    required this.success,
    required this.scorePercent,
    required this.happinessGained,
  });
}

// Screen to select a mini-game
class MiniGameSelectionScreen extends HookConsumerWidget {
  const MiniGameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petState = ref.watch(petProvider);

    // Cannot play games if tired, sick, sleeping, or dead
    final bool canPlay =
        petState.isAlive &&
        !petState.isSleeping &&
        !petState.isSick &&
        petState.tiredness < 85;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Games'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a Game to Play',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                canPlay
                    ? 'Playing games will make your pet happier but will cost energy!'
                    : _getStatusMessage(petState),
                style: TextStyle(
                  color: canPlay ? Colors.black87 : Colors.red,
                  fontStyle: canPlay ? FontStyle.normal : FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: miniGames.length,
                  itemBuilder: (context, index) {
                    final game = miniGames[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(
                          game.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(game.description),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildInfoChip(
                                  'Difficulty: ${_getDifficultyStars(game.difficultyLevel)}',
                                  Colors.blue.withOpacity(0.2),
                                ),
                                const SizedBox(width: 8),
                                _buildInfoChip(
                                  'Reward: +${game.happinessReward} happiness',
                                  Colors.green.withOpacity(0.2),
                                ),
                                const SizedBox(width: 8),
                                _buildInfoChip(
                                  'Cost: ${game.energyCost} energy',
                                  Colors.orange.withOpacity(0.2),
                                ),
                              ],
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        enabled:
                            canPlay &&
                            petState.tiredness + game.energyCost <= 100,
                        onTap:
                            canPlay &&
                                    petState.tiredness + game.energyCost <= 100
                                ? () => _startGame(context, ref, game)
                                : null,
                        trailing: Icon(
                          Icons.play_circle_filled,
                          color:
                              canPlay &&
                                      petState.tiredness + game.energyCost <=
                                          100
                                  ? Colors.green
                                  : Colors.grey,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusMessage(PetState petState) {
    if (!petState.isAlive) return 'Your pet is not alive. Cannot play games.';
    if (petState.isSleeping)
      return 'Your pet is sleeping. Wake it up to play games.';
    if (petState.isSick) return 'Your pet is sick. Cure it to play games.';
    if (petState.tiredness >= 85) return 'Your pet is too tired. Let it rest.';
    return 'Cannot play games right now.';
  }

  String _getDifficultyStars(int level) {
    return '★' * level + '☆' * (5 - level);
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  void _startGame(BuildContext context, WidgetRef ref, MiniGameState game) {
    ref.read(selectedMiniGameProvider.notifier).state = game;

    // Launch the appropriate game based on name
    switch (game.name) {
      case 'Ball Catch':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BallCatchGameScreen(game: game),
          ),
        );
        break;
      case 'Memory Match':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MemoryMatchGameScreen(game: game),
          ),
        );
        break;
      case 'Food Rush':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FoodRushGameScreen(game: game),
          ),
        );
        break;
      default:
        // Fallback to Ball Catch if something goes wrong
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BallCatchGameScreen(game: game),
          ),
        );
    }
  }
}

// A simple mini-game: Ball Catch
class BallCatchGameScreen extends HookConsumerWidget {
  final MiniGameState game;

  const BallCatchGameScreen({required this.game, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petNotifier = ref.read(petProvider.notifier);
    final petState = ref.watch(petProvider);

    // Game state
    final score = useState(0);
    final targetPosition = useState(0.5);
    final ballPosition = useState(0.0);
    final isMovingUp = useState(true);
    final gameActive = useState(true);
    final remainingTime = useState(30);

    // Control game speed based on difficulty
    final double gameSpeed = 0.01 * game.difficultyLevel;

    // Game timer
    useEffect(() {
      if (!gameActive.value) return null;

      final timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        // Update ball position
        if (isMovingUp.value) {
          ballPosition.value += gameSpeed;
          if (ballPosition.value >= 1.0) {
            ballPosition.value = 1.0;
            isMovingUp.value = false;
          }
        } else {
          ballPosition.value -= gameSpeed;
          if (ballPosition.value <= 0.0) {
            ballPosition.value = 0.0;
            isMovingUp.value = true;
          }
        }
      });

      // Countdown timer
      final countdownTimer = Timer.periodic(const Duration(seconds: 1), (
        timer,
      ) {
        remainingTime.value -= 1;
        if (remainingTime.value <= 0) {
          gameActive.value = false;
          timer.cancel();
          _endGame(context, ref, score.value, petNotifier, petState);
        }
      });

      return () {
        timer.cancel();
        countdownTimer.cancel();
      };
    }, [gameActive.value]);

    return Scaffold(
      appBar: AppBar(title: Text(game.name), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Score: ${score.value}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Time: ${remainingTime.value}s',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          remainingTime.value <= 5 ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!gameActive.value) return;

                  // Check if ball is in target zone (center 20%)
                  final distance = (ballPosition.value - 0.5).abs();
                  if (distance < 0.1) {
                    // Direct hit!
                    score.value += 10;
                  } else if (distance < 0.2) {
                    // Close hit
                    score.value += 5;
                  } else {
                    // Miss
                    score.value = (score.value - 2).clamp(0, 1000);
                  }
                },
                child: Container(
                  color: Colors.blue.withOpacity(0.1),
                  child: Stack(
                    children: [
                      // Target zone
                      Positioned(
                        left: 0,
                        right: 0,
                        top: MediaQuery.of(context).size.height * 0.4,
                        height: MediaQuery.of(context).size.height * 0.2,
                        child: Container(
                          color: Colors.green.withOpacity(0.2),
                          child: const Center(
                            child: Text(
                              'TAP WHEN BALL IS HERE',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Ball
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 50),
                        left: MediaQuery.of(context).size.width / 2 - 25,
                        top:
                            MediaQuery.of(context).size.height *
                            ballPosition.value,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                      // Game over overlay
                      if (!gameActive.value)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Game Over!',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Final Score: ${score.value}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 40),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        // Reset the game state
                                        score.value = 0;
                                        remainingTime.value = 30;
                                        ballPosition.value = 0.0;
                                        isMovingUp.value = true;
                                        gameActive.value = true;
                                      },
                                      child: Text('Play Again'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    ElevatedButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      child: Text('Return to Pet'),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _endGame(
    BuildContext context,
    WidgetRef ref,
    int score,
    PetNotifier petNotifier,
    PetState petState,
  ) {
    // Calculate happiness reward based on score and difficulty
    final maxPossibleScore = game.difficultyLevel * 100;
    final percentScore = (score / maxPossibleScore * 100).clamp(0, 100).toInt();

    // Calculate happiness gained (between 0 and the max happiness reward)
    final happinessGained = (game.happinessReward * percentScore / 100).toInt();

    // Apply effects to pet
    final int currentHappiness = petState.happiness;
    final int currentTiredness = petState.tiredness;

    // Increase happiness
    final newHappiness = (currentHappiness + happinessGained).clamp(0, 100);

    // Increase tiredness
    final newTiredness = (currentTiredness + game.energyCost).clamp(0, 100);

    // Update pet state
    petNotifier.updateAfterMiniGame(
      happinessGained: happinessGained,
      energyCost: game.energyCost,
    );

    // Show result
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Game over! Your pet gained $happinessGained happiness but lost ${game.energyCost} energy.',
          style: const TextStyle(fontSize: 16),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Memory Match Game
class MemoryMatchGameScreen extends HookConsumerWidget {
  final MiniGameState game;

  const MemoryMatchGameScreen({required this.game, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petNotifier = ref.read(petProvider.notifier);
    final petState = ref.watch(petProvider);

    // Game state
    final score = useState(0);
    final gameActive = useState(true);
    final remainingTime = useState(45);
    final sequence = useState<List<int>>([]);
    final playerInput = useState<List<int>>([]);
    final round = useState(1);
    final showingSequence = useState(false);
    final currentIndex = useState(0);

    // Define colors for the game
    final colors = [Colors.red, Colors.green, Colors.blue, Colors.yellow];

    // Initialize the game
    useEffect(() {
      // Start with a sequence of length 2
      _generateNewSequence(sequence, round.value);

      // Start showing the sequence after a brief delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        showingSequence.value = true;
      });

      return null;
    }, []);

    // Show sequence timer
    useEffect(() {
      if (!showingSequence.value || !gameActive.value) return null;

      // Use periodic timer to show each item in sequence with delay
      final timer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
        if (currentIndex.value < sequence.value.length) {
          currentIndex.value += 1;

          // If we've shown all items, end the sequence after a delay
          if (currentIndex.value >= sequence.value.length) {
            Future.delayed(const Duration(milliseconds: 800), () {
              showingSequence.value = false;
              currentIndex.value = 0;
              timer.cancel();
            });
          }
        }
      });

      return () => timer.cancel();
    }, [showingSequence.value]);

    // Game countdown timer
    useEffect(() {
      if (!gameActive.value) return null;

      final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        remainingTime.value -= 1;
        if (remainingTime.value <= 0) {
          gameActive.value = false;
          timer.cancel();
          _endGame(context, ref, score.value, petNotifier, petState);
        }
      });

      return () => timer.cancel();
    }, [gameActive.value]);

    // Check if player input matches the sequence
    void _checkInput() {
      if (playerInput.value.length != sequence.value.length) return;

      bool correct = true;
      for (int i = 0; i < sequence.value.length; i++) {
        if (playerInput.value[i] != sequence.value[i]) {
          correct = false;
          break;
        }
      }

      if (correct) {
        // Success! Award points and move to next round
        final points = 5 * round.value;
        score.value += points;
        round.value += 1;

        // Generate longer sequence for next round
        _generateNewSequence(sequence, round.value);
        playerInput.value = [];
        showingSequence.value = true;
        currentIndex.value = 0;
      } else {
        // Failed attempt
        score.value = (score.value - 2).clamp(0, 1000);
        playerInput.value = [];
        showingSequence.value = true;
        currentIndex.value = 0;
      }
    }

    // Handle player input
    void _handleButtonPress(int colorIndex) {
      if (showingSequence.value || !gameActive.value) return;

      playerInput.value = [...playerInput.value, colorIndex];

      // Check if we should validate the sequence
      if (playerInput.value.length == sequence.value.length) {
        _checkInput();
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(game.name), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Score: ${score.value}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Round: ${round.value}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Time: ${remainingTime.value}s',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          remainingTime.value <= 5 ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Status indicator
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color:
                    showingSequence.value
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    showingSequence.value
                        ? "Watch the sequence..."
                        : "Repeat the sequence!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: showingSequence.value ? Colors.blue : Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!showingSequence.value &&
                      round.value == 1 &&
                      playerInput.value.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Tap the colored squares in the same order they flashed",
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),

            // Progress indicator for input
            if (!showingSequence.value)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    sequence.value.length,
                    (index) => Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            index < playerInput.value.length
                                ? colors[playerInput.value[index]].withOpacity(
                                  0.7,
                                )
                                : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),

            // Game area (color buttons)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(
                    4,
                    (index) => GestureDetector(
                      onTap: () => _handleButtonPress(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color:
                              (showingSequence.value &&
                                      currentIndex.value > 0 &&
                                      sequence.value[currentIndex.value - 1] ==
                                          index)
                                  ? colors[index]
                                  : colors[index].withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                            if (showingSequence.value &&
                                currentIndex.value > 0 &&
                                sequence.value[currentIndex.value - 1] == index)
                              BoxShadow(
                                color: Colors.white,
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                          ],
                        ),
                        child: Center(
                          child:
                              showingSequence.value &&
                                      currentIndex.value > 0 &&
                                      sequence.value[currentIndex.value - 1] ==
                                          index
                                  ? Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 40,
                                  )
                                  : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Game over overlay
            if (!gameActive.value)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Game Over!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Final Score: ${score.value}',
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                      Text(
                        'Reached Round: ${round.value}',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // Reset the game state
                              score.value = 0;
                              round.value = 1;
                              remainingTime.value = 45;
                              _generateNewSequence(sequence, 1);
                              playerInput.value = [];
                              gameActive.value = true;

                              // Start showing sequence after a delay
                              Future.delayed(
                                const Duration(milliseconds: 1000),
                                () {
                                  showingSequence.value = true;
                                  currentIndex.value = 0;
                                },
                              );
                            },
                            child: Text('Play Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                          SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Return to Pet'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Generate a new sequence for the round
  void _generateNewSequence(ValueNotifier<List<int>> sequence, int round) {
    // Create a sequence of length round + 1 (minimum 2)
    final length = (round + 1).clamp(2, 10);
    final random = Random();
    List<int> newSequence = [];

    for (int i = 0; i < length; i++) {
      newSequence.add(random.nextInt(4));
    }

    sequence.value = newSequence;
  }

  void _endGame(
    BuildContext context,
    WidgetRef ref,
    int score,
    PetNotifier petNotifier,
    PetState petState,
  ) {
    // Calculate happiness reward based on score and difficulty
    final maxPossibleScore = game.difficultyLevel * 150;
    final percentScore = (score / maxPossibleScore * 100).clamp(0, 100).toInt();

    // Calculate happiness gained
    final happinessGained = (game.happinessReward * percentScore / 100).toInt();

    // Update pet state
    petNotifier.updateAfterMiniGame(
      happinessGained: happinessGained,
      energyCost: game.energyCost,
    );

    // Show result
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Game over! Your pet gained $happinessGained happiness but lost ${game.energyCost} energy.',
          style: const TextStyle(fontSize: 16),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Food Rush Game
class FoodRushGameScreen extends HookConsumerWidget {
  final MiniGameState game;

  const FoodRushGameScreen({required this.game, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petNotifier = ref.read(petProvider.notifier);
    final petState = ref.watch(petProvider);

    // Game state
    final score = useState(0);
    final gameActive = useState(true);
    final remainingTime = useState(30);
    final playerPosition = useState(0.5);
    final foodItems = useState<List<Map<String, dynamic>>>([]);

    // Set up the game area dimensions
    final gameWidth = MediaQuery.of(context).size.width;
    final gameHeight = MediaQuery.of(context).size.height * 0.6;
    final playerSize = 70.0; // Slightly larger player
    final foodSize = 40.0;

    // Calculate the actual bottom position (where the player sits)
    final playerBottom = gameHeight - 10; // Keep player just above bottom

    // Food types and their points
    final foodTypes = [
      {'emoji': '🍎', 'points': 10, 'speed': 2.5},
      {'emoji': '🍌', 'points': 5, 'speed': 2.0},
      {'emoji': '🍕', 'points': 15, 'speed': 3.0},
      {'emoji': '🍔', 'points': 20, 'speed': 3.5},
      {'emoji': '🍩', 'points': 25, 'speed': 4.0},
      {'emoji': '🥦', 'points': 30, 'speed': 4.5},
    ];

    // Game initialization
    useEffect(() {
      // Add a single food item to start
      final newFood = _createFoodItem(foodTypes, gameWidth);
      foodItems.value = [newFood];

      // Add more food items with a delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (gameActive.value) {
          final anotherFood = _createFoodItem(foodTypes, gameWidth);
          foodItems.value = [...foodItems.value, anotherFood];
        }
      });

      return null;
    }, []);

    // Game update timer
    useEffect(() {
      if (!gameActive.value) return null;

      // Counter to track frames for spawning food consistently
      int frameCount = 0;

      final timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        // Update frame counter
        frameCount++;

        // Update food positions
        List<Map<String, dynamic>> updatedFood = [];

        for (var food in foodItems.value) {
          // Move food downward
          double newY = food['y'] + food['speed'];

          // Check if food is still on screen or has passed the player
          if (newY < gameHeight + foodSize) {
            // Calculate accurate hitbox positions
            final playerLeft =
                playerPosition.value * gameWidth - playerSize / 2;
            final playerRight =
                playerPosition.value * gameWidth + playerSize / 2;
            final playerTop = playerBottom - playerSize;

            final foodLeft = food['x'] - foodSize / 2;
            final foodRight = food['x'] + foodSize / 2;
            final foodTop = newY - foodSize / 2;
            final foodBottom = newY + foodSize / 2;

            // Only check for collision if food is near player's vertical position
            if (foodBottom >= playerTop &&
                foodTop <= playerBottom &&
                playerLeft < foodRight &&
                playerRight > foodLeft) {
              // Collision! Award points
              score.value += food['points'] as int;
              // Don't add this food item back
            } else {
              // No collision, keep the food
              updatedFood.add({...food, 'y': newY});
            }
          }
        }

        // Make sure food spawning happens regardless of collisions
        // Spawn new food at regular intervals (every 20 frames = 1 second)
        if (frameCount % 20 == 0) {
          // Direct manipulation of the foodItems list
          final newFood = _createFoodItem(foodTypes, gameWidth);
          foodItems.value = [...foodItems.value, newFood];
        }

        // Occasional random spawns for variety (reduced probability)
        if (Random().nextDouble() < 0.01) {
          // Direct manipulation of the foodItems list
          final newFood = _createFoodItem(foodTypes, gameWidth);
          foodItems.value = [...foodItems.value, newFood];
        }

        // Update food items
        foodItems.value = updatedFood;
      });

      return () => timer.cancel();
    }, [gameActive.value]);

    // Countdown timer
    useEffect(() {
      if (!gameActive.value) return null;

      final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        remainingTime.value -= 1;
        if (remainingTime.value <= 0) {
          gameActive.value = false;
          timer.cancel();
          _endGame(context, ref, score.value, petNotifier, petState);
        }
      });

      return () => timer.cancel();
    }, [gameActive.value]);

    return Scaffold(
      appBar: AppBar(title: Text(game.name), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Score: ${score.value}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Time: ${remainingTime.value}s',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          remainingTime.value <= 5 ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (!gameActive.value) return;

                  // Update player position
                  double newPosition =
                      playerPosition.value + details.delta.dx / gameWidth;

                  // Clamp position to game bounds
                  playerPosition.value = newPosition.clamp(
                    playerSize / (2 * gameWidth),
                    1 - playerSize / (2 * gameWidth),
                  );
                },
                onTapDown: (details) {
                  if (!gameActive.value) return;

                  // Set player position directly to tap position
                  double newPosition = details.localPosition.dx / gameWidth;

                  // Clamp position to game bounds
                  playerPosition.value = newPosition.clamp(
                    playerSize / (2 * gameWidth),
                    1 - playerSize / (2 * gameWidth),
                  );
                },
                child: Container(
                  color: Colors.blue.withOpacity(0.1),
                  child: Stack(
                    children: [
                      // Path indicators - show where food is headed
                      ...foodItems.value.map(
                        (food) => Positioned(
                          left: food['x'] - 1,
                          top: food['y'],
                          bottom: 0,
                          child: IgnorePointer(
                            child: Container(
                              width: 2,
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Food items
                      ...foodItems.value.map(
                        (food) => Positioned(
                          left: food['x'] - foodSize / 2,
                          top: food['y'] - foodSize / 2,
                          child: SizedBox(
                            width: foodSize,
                            height: foodSize,
                            child: Center(
                              child: Text(
                                food['emoji'],
                                style: const TextStyle(fontSize: 30),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Player
                      Positioned(
                        left: playerPosition.value * gameWidth - playerSize / 2,
                        bottom: gameHeight - playerBottom,
                        child: Container(
                          width: playerSize,
                          height: playerSize,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('😋', style: TextStyle(fontSize: 36)),
                          ),
                        ),
                      ),

                      // Instructions
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Slide or tap to move and catch food!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Game over overlay
                      if (!gameActive.value)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Game Over!',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Final Score: ${score.value}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 40),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        // Reset the game state
                                        score.value = 0;
                                        remainingTime.value = 30;
                                        foodItems.value = [];
                                        gameActive.value = true;

                                        // Add a single food item to start
                                        final newFood = _createFoodItem(
                                          foodTypes,
                                          gameWidth,
                                        );
                                        foodItems.value = [newFood];

                                        // Add more food with delay
                                        Future.delayed(
                                          const Duration(milliseconds: 800),
                                          () {
                                            if (gameActive.value) {
                                              final anotherFood =
                                                  _createFoodItem(
                                                    foodTypes,
                                                    gameWidth,
                                                  );
                                              foodItems.value = [
                                                ...foodItems.value,
                                                anotherFood,
                                              ];
                                            }
                                          },
                                        );
                                      },
                                      child: Text('Play Again'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    ElevatedButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      child: Text('Return to Pet'),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Create a single food item
  Map<String, dynamic> _createFoodItem(
    List<Map<String, dynamic>> foodTypes,
    double gameWidth,
  ) {
    final random = Random();
    final foodSize = 40.0;

    // Randomly choose a food type
    final foodType = foodTypes[random.nextInt(foodTypes.length)];

    // Random x position (keep fully within the screen and avoid edge spawns)
    final margin = foodSize * 1.5; // Add margin to keep away from edges
    final x = margin + random.nextDouble() * (gameWidth - margin * 2);

    // Start from top of screen
    const y = 0.0;

    // Calculate base speed and add slight random variation (but keep it consistent)
    final baseSpeed = foodType['speed'] as double;
    final speedMultiplier =
        0.9 + (random.nextDouble() * 0.2); // 0.9-1.1 variation
    final adjustedSpeed = baseSpeed * speedMultiplier;

    // Create and return the new food item
    return {
      'x': x,
      'y': y,
      'emoji': foodType['emoji'],
      'points': foodType['points'],
      'speed': adjustedSpeed,
    };
  }

  void _endGame(
    BuildContext context,
    WidgetRef ref,
    int score,
    PetNotifier petNotifier,
    PetState petState,
  ) {
    // Calculate happiness reward based on score and difficulty
    final maxPossibleScore = game.difficultyLevel * 300;
    final percentScore =
        ((score / maxPossibleScore) * 100).clamp(0, 100).toInt();

    // Calculate happiness gained
    final happinessGained = (game.happinessReward * percentScore ~/ 100);

    // Update pet state
    petNotifier.updateAfterMiniGame(
      happinessGained: happinessGained,
      energyCost: game.energyCost,
    );

    // Show result
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Game over! Your pet gained $happinessGained happiness but lost ${game.energyCost} energy.',
          style: const TextStyle(fontSize: 16),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
