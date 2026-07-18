import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:honoo/Services/house_invite_service.dart';

class _MockClient extends Mock implements SupabaseClient {}

class _MockQueryChain extends Mock
    implements
        SupabaseQueryBuilder,
        PostgrestFilterBuilder<dynamic>,
        PostgrestTransformBuilder<dynamic> {
  final Queue<dynamic> _responses = Queue<dynamic>();

  void queueResponse(dynamic value) => _responses.add(value);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #then &&
        invocation.positionalArguments.isNotEmpty) {
      final onValue =
          invocation.positionalArguments[0] as dynamic Function(dynamic);
      final result = _responses.isEmpty ? null : _responses.removeFirst();
      return Future.value(onValue(result));
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  late _MockClient client;
  late _MockQueryChain chain;
  late HouseInviteService service;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    client = _MockClient();
    chain = _MockQueryChain();
    service = HouseInviteService(client: client);

    when(() => client.from('house_invites')).thenAnswer((_) => chain);
    when(() => chain.select(any())).thenAnswer((_) => chain);
    when(() => chain.eq(any(), any())).thenAnswer((_) => chain);
    when(() => chain.in_(any(), any())).thenAnswer((_) => chain);
    when(() => chain.limit(any())).thenAnswer((_) => chain);
  });

  test('hasPendingOrAcceptedInvite filtra status pending/accepted', () async {
    chain.queueResponse([
      {'status': 'pending'}
    ]);

    final result = await service.hasPendingOrAcceptedInvite('user-1');

    expect(result, isTrue);
    verify(() => client.from('house_invites')).called(1);
    verify(() => chain.select('status')).called(1);
    verify(() => chain.eq('user_id', 'user-1')).called(1);
    verify(() => chain.in_('status', ['pending', 'accepted'])).called(1);
    verify(() => chain.limit(1)).called(1);
  });

  test('createPendingRequest mantiene il payload della richiesta', () async {
    final createdAt = DateTime.utc(2026, 7, 18, 12);
    when(() => chain.insert(any())).thenAnswer((_) => chain);
    chain.queueResponse(<String, dynamic>{});

    await service.createPendingRequest(
      userId: 'user-1',
      email: 'user@example.com',
      createdAt: createdAt,
    );

    verify(() => chain.insert({
          'user_id': 'user-1',
          'email': 'user@example.com',
          'status': 'pending',
          'created_at': '2026-07-18T12:00:00.000Z',
        })).called(1);
  });
}
