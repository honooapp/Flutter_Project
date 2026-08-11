import 'package:supabase_flutter/supabase_flutter.dart';

import '../Entities/chest_item.dart';
import '../Entities/honoo.dart';
import 'supabase_provider.dart';

class HouseSharedContentService {
  HouseSharedContentService({SupabaseClient? client})
    : _client = client ?? SupabaseProvider.client;

  final SupabaseClient _client;

  Future<List<ChestItem>> fetch(String ownerId) async {
    final response = await _client.rpc(
      'get_shared_house_chest',
      params: {'p_owner_id': ownerId},
    );
    if (response is! List) return const [];

    final items = <ChestItem>[];
    for (final raw in response.whereType<Map>()) {
      final kind = raw['kind']?.toString();
      final data = raw['data'];
      if (data is! Map) continue;
      final row = Map<String, dynamic>.from(data);
      if (kind == 'honoo') {
        final honoo = Honoo.fromMap(row);
        final createdAt =
            DateTime.tryParse(honoo.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        items.add(ChestItem.honoo(honoo, createdAt));
      } else if (kind == 'hinoo') {
        final hinoo = ChestHinooItem.fromDatabaseRow(row);
        if (hinoo != null) items.add(ChestItem.hinoo(hinoo));
      }
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<ChestItem>.unmodifiable(items);
  }
}
