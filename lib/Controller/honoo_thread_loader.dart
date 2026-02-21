import 'package:flutter/foundation.dart';

import '../Entities/honoo.dart';
import 'honoo_controller.dart';

class HonooThreadState {
  final bool isLoading;
  final List<Honoo> thread;
  final Object? error;

  const HonooThreadState._({
    required this.isLoading,
    required this.thread,
    this.error,
  });

  const HonooThreadState.loading()
      : this._(isLoading: true, thread: const [], error: null);

  const HonooThreadState.success(List<Honoo> thread)
      : this._(isLoading: false, thread: thread, error: null);

  const HonooThreadState.failure(Object error)
      : this._(isLoading: false, thread: const [], error: error);
}

class HonooThreadLoader extends ValueNotifier<HonooThreadState> {
  final HonooController controller;
  bool _isDisposed = false;

  HonooThreadLoader({HonooController? controller})
      : controller = controller ?? HonooController(),
        super(const HonooThreadState.loading());

  Future<void> load(Honoo root) async {
    if (_isDisposed) return;
    value = const HonooThreadState.loading();
    try {
      final thread = await controller.getHonooHistory(root);
      if (_isDisposed) return;
      value = HonooThreadState.success(thread);
    } catch (e) {
      if (_isDisposed) return;
      value = HonooThreadState.failure(e);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
