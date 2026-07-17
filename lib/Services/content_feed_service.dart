import 'supabase_provider.dart';

/// Query di lettura per feed pubblici e contenuti condivisi.
/// Il mapping visuale resta nelle feature che conoscono il relativo modello UI.
class ContentFeedService {
  const ContentFeedService();

  Future<List<Map<String, dynamic>>> fetchMoonRows() async {
    final rows = await SupabaseProvider.client
        .from('moon_public')
        .select(
            'id,user_id,kind,pages,text,image_url,recipient_tag,created_at,conversation_id')
        .order('created_at', ascending: false);
    return (rows as List)
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchSharedHinooRows(
      String ownerId) async {
    final rows = await SupabaseProvider.client
        .from('hinoo')
        .select(
            'id,pages,type,recipient_tag,created_at,conversation_id,reply_to')
        .eq('user_id', ownerId)
        .eq('type', 'personal')
        .order('created_at', ascending: false);
    return (rows as List)
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList(growable: false);
  }

  /// Radici delle conversazioni condivise, Honoo e Hinoo, ordinate per data.
  /// Restituisce un solo elemento per conversation_id senza imporre modelli UI.
  Future<List<Map<String, dynamic>>> fetchSharedConversationRoots(
      String ownerId) async {
    final honooRows = await SupabaseProvider.client
        .from('honoo')
        .select('id,conversation_id,created_at')
        .eq('user_id', ownerId)
        .eq('destination', 'chest')
        .order('created_at', ascending: false);
    final hinooRows = await SupabaseProvider.client
        .from('hinoo')
        .select('id,conversation_id,created_at')
        .eq('user_id', ownerId)
        .eq('type', 'personal')
        .order('created_at', ascending: false);

    final combined = <Map<String, dynamic>>[
      ...(honooRows as List)
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>()),
      ...(hinooRows as List)
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>()),
    ]..sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    final seen = <String>{};
    return combined.where((row) {
      final id = row['id']?.toString() ?? '';
      final conversationId = row['conversation_id']?.toString();
      final effectiveId = conversationId?.isNotEmpty == true
          ? conversationId!
          : id;
      if (effectiveId.isEmpty || !seen.add(effectiveId)) return false;
      row['conversation_id'] = effectiveId;
      return true;
    }).toList(growable: false);
  }
}
