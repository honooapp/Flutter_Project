import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Entities/Hinoo.dart';

class HinooService {
  static final _supabase = Supabase.instance.client;
  static const String _table = 'hinoo';

  static String _toDbType(HinooType type) {
    switch (type) {
      case HinooType.moon:
        return 'public';
      default:
        return type.name;
    }
  }

  static HinooType _fromDbType(String? value) {
    if (value == 'public') return HinooType.moon;
    if (value == 'answer') return HinooType.answer;
    return HinooType.personal;
  }

  static Future<void> publishHinoo(HinooDraft draft) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw 'Utente non autenticato';

    final data = {
      'user_id': userId,
      'type': _toDbType(draft.type),
      'pages': draft.toJson()['pages'],
      'recipient_tag': draft.recipientTag,
      // fingerprint può essere null (solo moon lo usa per dedup)
      'fingerprint': (draft.type == HinooType.moon) ? fingerprint(draft) : null,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      debugPrint('[HinooService] publishHinoo data=$data');
      final res =
          await _supabase.from(_table).insert(data).select().maybeSingle();
      if (res == null) throw 'publishHinoo: insert fallita';
    } on PostgrestException catch (e) {
      debugPrint('[HinooService] publishHinoo error: ${e.message} details=${e.details} hint=${e.hint} code=${e.code}');
      final msg = e.message ?? e.code ?? 'sconosciuto';
      final details = e.details;
      final hint = e.hint;
      final extra = [
        if (details != null && details.isNotEmpty) details,
        if (hint != null && hint.isNotEmpty) 'hint: $hint',
      ].join(' — ');
      throw 'Errore salvataggio Hinoo: $msg${extra.isNotEmpty ? ' ($extra)' : ''}';
    }
  }

  /// Inserisce un record type='moon' se non già presente (dedup su fingerprint)
  static Future<bool> duplicateToMoon(HinooDraft draft) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw 'Utente non autenticato';

    final sanitized = draft.copyWith(type: HinooType.moon);
    final fp = fingerprint(sanitized);

    // Verifica duplicato nella STESSA tabella
    final existing = await _supabase
        .from(_table)
        .select('id')
        .eq('user_id', userId)
        .in_('type', ['moon', 'public'])
        .eq('fingerprint', fp)
        .limit(1);

    if (existing is List && existing.isNotEmpty) {
      return false;
    }

    final data = {
      'user_id': userId,
      'type': _toDbType(HinooType.moon),
      'pages': sanitized.toJson()['pages'],
      'fingerprint': fp,
      'recipient_tag': sanitized.recipientTag,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      debugPrint('[HinooService] duplicateToMoon data=$data');
      await _supabase.from(_table).insert(data);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('[HinooService] duplicateToMoon error: ${e.message} details=${e.details} hint=${e.hint} code=${e.code}');
      final msg = e.message ?? e.code ?? 'sconosciuto';
      final details = e.details;
      final hint = e.hint;
      final extra = [
        if (details != null && details.isNotEmpty) details,
        if (hint != null && hint.isNotEmpty) 'hint: $hint',
      ].join(' — ');
      throw 'Errore pubblicazione Luna: $msg${extra.isNotEmpty ? ' ($extra)' : ''}';
    }
  }

  static String fingerprint(HinooDraft d) {
    final parts = <String>[
      'type=${d.type.name}',
      'pages=${d.pages.length}',
      for (final p in d.pages)
        'bg:${p.backgroundImage ?? ''}|'
            'txt:${p.text}|'
            'col:${p.isTextWhite ? 'w' : 'b'}|'
            'tr:${p.bgScale.toStringAsFixed(4)},${p.bgOffsetX.toStringAsFixed(2)},${p.bgOffsetY.toStringAsFixed(2)}',
      if (d.recipientTag != null) 'recipient=${d.recipientTag}',
    ];
    return parts.join('||');
  }

  static Future<void> saveDraft(HinooDraft draft) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw 'Utente non autenticato';

    await _supabase.from('hinoo_drafts').upsert({
      'user_id': userId,
      'payload': draft.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }

  static Future<HinooDraft?> getDraft() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final res = await _supabase
        .from('hinoo_drafts')
        .select('payload')
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (res == null) return null;
    final payload = res['payload'];
    if (payload is Map<String, dynamic>) {
      return HinooDraft.fromJson(payload);
    }
    return null;
  }

  /// Carica gli Hinoo personali dell'utente (dallo scrigno)
  static Future<List<HinooDraft>> fetchUserHinoo(String userId,
      {HinooType type = HinooType.personal}) async {
    final typeStr = _toDbType(type);
    final baseQuery = _supabase
        .from(_table)
        .select('pages,type,recipient_tag,created_at')
        .eq('user_id', userId);

    final filteredQuery = type == HinooType.moon
        ? baseQuery.in_('type', ['moon', 'public'])
        : baseQuery.eq('type', typeStr);

    final rows = await filteredQuery.order('created_at', ascending: false);

    final List<HinooDraft> list = [];
    for (final r in (rows as List)) {
      final pages = r['pages'];
      final String? recipient = r['recipient_tag'] as String?;
      if (pages is List) {
        list.add(
          HinooDraft(
            pages: pages
                .whereType<Map<String, dynamic>>()
                .map((e) => HinooSlide.fromJson(e))
                .toList(),
            type: _fromDbType(r['type'] as String?),
            recipientTag: recipient,
          ),
        );
      }
    }
    return list;
  }
}
