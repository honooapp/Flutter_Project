import 'package:flutter/foundation.dart';
import 'package:honoo/Services/supabase_provider.dart';
import '../Entities/honoo.dart';
import '../Services/honoo_service.dart';

/// Repository + cache in memoria (niente mock)
class HonooController {
  static final HonooController _instance = HonooController._internal();
  factory HonooController() => _instance;
  HonooController._internal();

  // Cache
  final List<Honoo> _personal = [];
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<int> version = ValueNotifier<int>(0);

  DateTime? _oldestCreatedAt;
  bool _hasMore = true;
  bool _isFetching = false;

  String get _uid => SupabaseProvider.client.auth.currentUser!.id;

  List<Honoo> get personal => List.unmodifiable(_personal);
  bool get hasMore => _hasMore;
  bool get isFetchingMore => _isFetching;
  DateTime? get oldestCreatedAt => _oldestCreatedAt;

  /// Carica dallo scrigno (destination='chest') – niente mock
  Future<List<Honoo>> loadChest({bool refresh = false}) async {
    if (_isFetching) return const [];

    if (refresh) {
      _personal.clear();
      _oldestCreatedAt = null;
      _hasMore = true;
    }

    if (!_hasMore) {
      return const [];
    }

    final bool showLoader = refresh || _personal.isEmpty;
    if (showLoader) {
      isLoading.value = true;
    }

    _isFetching = true;
    try {
      final fetched = await HonooService.fetchUserHonoo(
        _uid,
        'chest',
        limit: HonooService.defaultPageSize,
        before: refresh ? null : _oldestCreatedAt,
      );

      final newItems = _mergeNewHonoo(fetched);

      await _syncRepliesForIds(
        refresh
            ? _personal.map((h) => h.dbId).whereType<String>()
            : newItems.map((h) => h.dbId).whereType<String>(),
        updateAll: refresh,
      );

      _updateOldestTimestamp();
      _hasMore = fetched.length >= HonooService.defaultPageSize;

      if (newItems.isNotEmpty || refresh) {
        version.value++;
      }

      return newItems;
    } finally {
      _isFetching = false;
      if (showLoader) {
        isLoading.value = false;
      }
    }
  }

  Future<void> refreshChest() => loadChest(refresh: true);

  Future<void> loadMoreChest() => loadChest();

  /// History (thread) per un honoo: include il padre e le sue reply
  Future<List<Honoo>> getHonooHistory(Honoo honoo) async {
    final id = honoo.dbId;
    if (id == null) {
      // se non hai l'uuid (dbId), ritorna almeno la card corrente
      return [honoo];
    }

    final client = SupabaseProvider.client;

    // Prendiamo l'honoo originale + tutte le reply collegate
    // or('id.eq.<id>,reply_to.eq.<id>')
    final rows = await client
        .from('honoo')
        .select(
            'id,text,image_url,destination,reply_to,recipient_tag,created_at,updated_at,user_id')
        .or('id.eq.$id,reply_to.eq.$id')
        .order('created_at', ascending: true);

    final List<Honoo> thread = (rows as List)
        .map((m) => Honoo.fromMap(m as Map<String, dynamic>))
        .toList();

    // opzionale: marca il primo come personal/moon e le altre come answer se necessario
    return thread;
  }

  /// Pubblica una copia dell'honoo sulla Luna senza toccare l'originale nello scrigno.
  /// Ritorna:
  ///  - true  => inserito ora ("Spedito sulla Luna")
  ///  - false => già presente ("Già presente sulla Luna")
  Future<bool> sendToMoon(Honoo h) async {
    try {
      final inserted = await HonooService.duplicateToMoon(h);
      // Se vuoi, qui puoi anche marcare in cache un flag tipo `isFromMoonSaved`
      // e fare version.value++; se modifichi la UI locale.
      return inserted;
    } catch (e) {
      debugPrint('duplicateToMoon error: $e');
      return false; // la UI potrà distinguere tra "già presente" ed errore? vedi nota sotto
    }
  }

  Future<bool> saveToChest(Honoo h) async {
    try {
      final inserted = await HonooService.duplicateToChest(h);
      if (inserted) {
        await loadChest(refresh: true);
      }
      return inserted;
    } catch (e) {
      debugPrint('duplicateToChest error: $e');
      return false;
    }
  }

  List<Honoo> _mergeNewHonoo(List<Honoo> fetched) {
    if (fetched.isEmpty) {
      return const [];
    }

    final existingIds = {for (final h in _personal) _honooKey(h)};

    final List<Honoo> newItems = [];
    for (final honoo in fetched) {
      final key = _honooKey(honoo);
      if (existingIds.contains(key)) {
        continue;
      }
      newItems.add(honoo);
      existingIds.add(key);
      _personal.add(honoo);
    }

    _personal.sort((a, b) {
      final aDate = DateTime.tryParse(a.createdAt);
      final bDate = DateTime.tryParse(b.createdAt);
      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    return newItems;
  }

  Future<void> _syncRepliesForIds(
    Iterable<String> ids, {
    required bool updateAll,
  }) async {
    final targetIds = updateAll
        ? _personal.map((h) => h.dbId).whereType<String>().toSet()
        : ids.where((id) => id.isNotEmpty).toSet();
    if (targetIds.isEmpty) return;

    final client = SupabaseProvider.client;
    final rows = await client
        .from('honoo')
        .select('reply_to')
        .in_('reply_to', targetIds.toList());

    final repliedParents = <String>{};
    for (final row in (rows as List)) {
      final parent = row['reply_to']?.toString();
      if (parent != null) {
        repliedParents.add(parent);
      }
    }

    for (var i = 0; i < _personal.length; i++) {
      final honoo = _personal[i];
      final dbId = honoo.dbId;
      if (dbId == null || dbId.isEmpty) continue;
      if (!updateAll && !targetIds.contains(dbId)) {
        continue;
      }
      final has = repliedParents.contains(dbId);
      if (has != honoo.hasReplies) {
        _personal[i] = honoo.copyWith(hasReplies: has);
      }
    }
  }

  void _updateOldestTimestamp() {
    DateTime? oldest;
    for (final honoo in _personal) {
      final created = DateTime.tryParse(honoo.createdAt);
      if (created == null) continue;
      if (oldest == null || created.isBefore(oldest)) {
        oldest = created;
      }
    }
    _oldestCreatedAt = oldest;
  }

  String _honooKey(Honoo honoo) {
    if (honoo.dbId != null && honoo.dbId!.isNotEmpty) {
      return honoo.dbId!;
    }
    return '${honoo.id}_${honoo.createdAt}_${honoo.text.hashCode}';
  }

  Future<void> deleteHonoo(Honoo h) async {
    final String? id = (h.dbId ?? h.id) as String?;
    if (id == null || id.isEmpty) {
      debugPrint('deleteHonoo: id mancante');
      return;
    }

    await HonooService.deleteHonooById(id);

    _personal.removeWhere((x) => (x.dbId ?? x.id) == id);
    version.value++;
  }

  Future<void> deleteHonooById(String? id) async {
    if (id == null || id.isEmpty) {
      debugPrint('deleteHonooById: id vuoto');
      return;
    }

    await HonooService.deleteHonooById(id);

    _personal.removeWhere((x) => (x.dbId ?? x.id) == id);
    version.value++;
  }
}
