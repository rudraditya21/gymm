abstract final class MuscleGroup {
  static const chest = 'Chest';
  static const back = 'Back';
  static const shoulders = 'Shoulders';
  static const biceps = 'Biceps';
  static const triceps = 'Triceps';
  static const forearms = 'Forearms';
  static const quads = 'Quadriceps';
  static const hamstrings = 'Hamstrings';
  static const glutes = 'Glutes';
  static const calves = 'Calves';
  static const core = 'Core';
  static const cardio = 'Cardio';
  static const fullBody = 'Full Body';

  static const all = [
    chest,
    back,
    shoulders,
    biceps,
    triceps,
    forearms,
    quads,
    hamstrings,
    glutes,
    calves,
    core,
    cardio,
    fullBody,
  ];

  // Grouped for filter chips in the exercises screen
  static const filterGroups = [
    chest,
    back,
    shoulders,
    biceps,
    triceps,
    quads,
    hamstrings,
    glutes,
    calves,
    core,
    cardio,
  ];
}

abstract final class Equipment {
  static const barbell = 'Barbell';
  static const dumbbell = 'Dumbbell';
  static const cable = 'Cable';
  static const machine = 'Machine';
  static const bodyweight = 'Bodyweight';
  static const band = 'Resistance Band';
  static const kettlebell = 'Kettlebell';
  static const other = 'Other';
}
