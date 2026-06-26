import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestTimerState {
  final int remaining;
  final int total;
  final bool isRunning;

  const RestTimerState({
    required this.remaining,
    required this.total,
    required this.isRunning,
  });

  RestTimerState copyWith({int? remaining, int? total, bool? isRunning}) =>
      RestTimerState(
        remaining: remaining ?? this.remaining,
        total: total ?? this.total,
        isRunning: isRunning ?? this.isRunning,
      );

  double get progress => total > 0 ? remaining / total : 0;
}

const _defaultState = RestTimerState(remaining: 0, total: 0, isRunning: false);

class RestTimerNotifier extends Notifier<RestTimerState> {
  Timer? _timer;

  @override
  RestTimerState build() {
    ref.onDispose(() => _timer?.cancel());
    return _defaultState;
  }

  void start(int seconds) {
    _timer?.cancel();
    state = RestTimerState(remaining: seconds, total: seconds, isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remaining <= 1) {
        _timer?.cancel();
        state = state.copyWith(remaining: 0, isRunning: false);
      } else {
        state = state.copyWith(remaining: state.remaining - 1);
      }
    });
  }

  void addTime(int seconds) {
    if (!state.isRunning) return;
    state = state.copyWith(
      remaining: state.remaining + seconds,
      total: state.total + seconds,
    );
  }

  void skip() {
    _timer?.cancel();
    state = _defaultState;
  }


}

final restTimerProvider = NotifierProvider<RestTimerNotifier, RestTimerState>(
  RestTimerNotifier.new,
);
