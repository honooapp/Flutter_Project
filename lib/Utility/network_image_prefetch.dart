import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Entities/honoo.dart';

/// Warms Flutter's image cache without changing what is painted while loading.
void prefetchImageUrls(BuildContext context, Iterable<String?> urls) {
  final uniqueUrls = urls
      .whereType<String>()
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toSet();

  for (final url in uniqueUrls) {
    unawaited(
      precacheImage(NetworkImage(url), context).catchError((Object _) {}),
    );
  }
}

Iterable<String?> honooImageUrls(Honoo honoo) sync* {
  yield honoo.image;
}

Iterable<String?> hinooImageUrls(HinooDraft draft) sync* {
  if (draft.pages.isNotEmpty) yield draft.pages.first.backgroundImage;
}
