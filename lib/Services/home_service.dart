import '../Utility/replies_seen_tracker.dart';
import 'supabase_provider.dart';

class HomeService {
  const HomeService();

  Future<int> fetchUnreadReplyCount(String userId) async {
    final lastSeen = await RepliesSeenTracker.lastSeen();
    final honooRows = await SupabaseProvider.client
        .from('honoo')
        .select('created_at,user_id')
        .eq('destination', 'reply')
        .eq('recipient_tag', userId)
        .neq('user_id', userId);
    final hinooRows = await SupabaseProvider.client
        .from('hinoo')
        .select('created_at,user_id')
        .eq('type', 'answer')
        .eq('recipient_tag', userId)
        .neq('user_id', userId);

    int count = 0;
    for (final row in [...(honooRows as List), ...(hinooRows as List)]) {
      final createdAt = DateTime.tryParse((row['created_at'] ?? '').toString());
      if (createdAt != null &&
          (lastSeen == null || createdAt.isAfter(lastSeen))) {
        count++;
      }
    }
    return count;
  }

  Future<void> recordVisit() =>
      SupabaseProvider.client.rpc('increment_site_visit');
}
