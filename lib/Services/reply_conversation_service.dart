import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'supabase_provider.dart';

class PreviousUnansweredReply {
  const PreviousUnansweredReply({required this.conversationId});

  final String conversationId;
}

typedef PreviousReplyLookup = Future<dynamic> Function(String parentId);

/// Individua l'ultima conversazione avviata dall'utente sullo stesso
/// contenuto che non ha ancora ricevuto una contro-risposta.
class ReplyConversationService {
  ReplyConversationService({SupabaseClient? client, this._lookup})
    : _client = client ?? SupabaseProvider.client;

  final SupabaseClient _client;
  final PreviousReplyLookup? _lookup;

  Future<PreviousUnansweredReply?> findPreviousUnansweredReply({
    required String parentId,
  }) async {
    if (_client.auth.currentUser == null || parentId.isEmpty) return null;
    try {
      final result = _lookup != null
          ? await _lookup(parentId)
          : await _client.rpc(
              'find_previous_unanswered_conversation',
              params: {'target_parent_id': parentId},
            );
      final conversationId = result?.toString() ?? '';
      return conversationId.isEmpty
          ? null
          : PreviousUnansweredReply(conversationId: conversationId);
    } catch (_) {
      // Una versione del backend non ancora migrata non deve impedire l'invio.
      return null;
    }
  }

  String createConversationId() => const Uuid().v4();
}
