# Virtual Pet Game

A Flutter-based virtual pet simulator, similar to the classic Tamagotchi toys.

## Features

- **Pet Care System**: Feed, clean, and play with your pet to keep it happy and healthy.
- **Evolution System**: Your pet will grow and evolve based on your care and accumulated care points.
- **Health Mechanics**: Monitor hunger, happiness, cleanliness, and energy levels.
- **Sleep System**: Let your pet rest to recover energy.
- **Sickness System**: Pets can get sick if neglected and need medicine to recover.
- **Mini-Games**: Play fun mini-games with your pet:
  - Ball Catch: Test your reflexes by tapping at the right moment
  - Memory Match: Remember and repeat color patterns
  - Food Rush: Catch falling food items by sliding or tapping
- **Visual Feedback**: Watch your pet's emotions and state through animations and visual cues.

## How to Play

1. **Basic Care**:
   - Tap the "Feed" button when your pet is hungry
   - Tap the "Clean" button when your pet is dirty
   - Tap the "Play" button to increase happiness
   - Tap the "Sleep" button to let your pet rest and recover energy
   - Give medicine when your pet is sick

2. **Mini-Games**:
   - Access games through the "Games" button
   - Each game costs energy but rewards happiness
   - Higher scores give better happiness rewards
   - Let your pet rest after playing games to recover energy

3. **Evolution**:
   - Your pet will evolve as it ages and gains care points
   - Consistent care leads to better evolutions
   - Neglect can lead to poor health and even death

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

## Tech Stack

- Flutter for UI and animations
- Riverpod for state management
- Flutter Hooks for side effects
