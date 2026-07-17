import 'package:flutter/foundation.dart';

@immutable
class PendingKnock {
  const PendingKnock({
    required this.id,
    required this.targetTag,
    required this.createdAt,
    this.hinooId,
    this.honooId,
  });

  final String id;
  final String targetTag;
  final DateTime createdAt;
  final String? hinooId;
  final String? honooId;
}
