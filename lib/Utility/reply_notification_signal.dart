import 'package:flutter/foundation.dart';

/// Segnale leggero in-process per riallineare subito i contatori delle risposte.
class ReplyNotificationSignal {
  ReplyNotificationSignal._();

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void notifyChanged() {
    revision.value += 1;
  }
}
