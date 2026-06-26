import '../models/workout.dart';

int computeStreak(List<Workout> workouts) {
  if (workouts.isEmpty) return 0;

  final days = workouts
      .map((w) => DateTime(w.startedAt.year, w.startedAt.month, w.startedAt.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  final today = DateTime.now();
  final todayNorm = DateTime(today.year, today.month, today.day);
  final yesterday = todayNorm.subtract(const Duration(days: 1));

  // Streak must start from today or yesterday
  if (days.first != todayNorm && days.first != yesterday) return 0;

  int streak = 1;
  for (int i = 1; i < days.length; i++) {
    final expected = days[i - 1].subtract(const Duration(days: 1));
    if (days[i] == expected) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final bool unlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.unlocked,
  });
}

List<Achievement> computeAchievements(List<Workout> workouts) {
  final total = workouts.length;
  final streak = computeStreak(workouts);
  final totalVolume = workouts.fold<double>(0, (s, w) => s + w.totalVolume);

  return [
    Achievement(
      id: 'first_workout',
      title: 'First Rep',
      description: 'Complete your first workout',
      emoji: '🏋️',
      unlocked: total >= 1,
    ),
    Achievement(
      id: 'ten_workouts',
      title: 'Getting Serious',
      description: 'Complete 10 workouts',
      emoji: '🔥',
      unlocked: total >= 10,
    ),
    Achievement(
      id: 'fifty_workouts',
      title: 'Dedicated',
      description: 'Complete 50 workouts',
      emoji: '💪',
      unlocked: total >= 50,
    ),
    Achievement(
      id: 'hundred_workouts',
      title: 'Century Club',
      description: 'Complete 100 workouts',
      emoji: '🏆',
      unlocked: total >= 100,
    ),
    Achievement(
      id: 'streak_3',
      title: 'Hat Trick',
      description: '3-day workout streak',
      emoji: '⚡',
      unlocked: streak >= 3,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Week Warrior',
      description: '7-day workout streak',
      emoji: '🗓️',
      unlocked: streak >= 7,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Iron Will',
      description: '30-day workout streak',
      emoji: '🦾',
      unlocked: streak >= 30,
    ),
    Achievement(
      id: 'volume_1000',
      title: 'Ton Lifted',
      description: 'Lift 1,000 kg total volume',
      emoji: '📦',
      unlocked: totalVolume >= 1000,
    ),
    Achievement(
      id: 'volume_10000',
      title: 'Ten Tonnes',
      description: 'Lift 10,000 kg total volume',
      emoji: '🚀',
      unlocked: totalVolume >= 10000,
    ),
  ];
}
