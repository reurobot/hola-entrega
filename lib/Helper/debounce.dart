import 'dart:async';

typedef DebounceCallback = void Function();

class Debounce {
  Debounce({required this.delay});
  final Duration delay;
  Timer? _timer;

  void call(DebounceCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }
}
