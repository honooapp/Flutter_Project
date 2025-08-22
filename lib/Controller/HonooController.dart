import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Entites/Honoo.dart';
import '../Services/HonooService.dart';

/// Repository + cache in memoria (niente mock)
class HonooController {
  static final HonooController _instance = HonooController._internal();
  factory HonooController() => _instance;
  HonooController._internal();

  // Cache
  final List<Honoo> _personal = [];
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<int> version = ValueNotifier<int>(0);

  String get _uid => Supabase.instance.client.auth.currentUser!.id;

  List<Honoo> get personal => List.unmodifiable(_personal);

  /// Carica dallo scrigno (destination='chest') – niente mock
  Future<void> loadChest() async {
    isLoading.value = true;
    try {
      final chest = await HonooService.fetchUserHonoo(_uid, 'chest');

      // Popola cache iniziale
      _personal
        ..clear()
        ..addAll(chest);

      // === Calcolo hasReplies con una query IN (...) su reply_to ===
      // prendo tutti gli uuid (dbId) disponibili
      final ids = _personal.map((h) => h.dbId).whereType<String>().toList();
      if (ids.isNotEmpty) {
        final client = Supabase.instance.client;
        final rows = await client
            .from('honoo')
            .select('reply_to')
            .in_('reply_to', ids);

        // reply_to presenti → esistono risposte
        final repliedParents = <String>{};
        for (final row in (rows as List)) {
          final p = row['reply_to']?.toString();
          if (p != null) repliedParents.add(p);
        }

        // marca i tuoi honoo personali che hanno risposte
        for (var i = 0; i < _personal.length; i++) {
          final h = _personal[i];
          final has = h.dbId != null && repliedParents.contains(h.dbId);
          if (has != h.hasReplies) {
            _personal[i] = h.copyWith(hasReplies: has);
          }
        }
      }

      // NB: isFromMoonSaved resta quello che arriva da DB (o false se non hai colonna)
      version.value++;
    } finally {
      isLoading.value = false;
    }
  }


  /// History (thread) per un honoo: include il padre e le sue reply
  Future<List<Honoo>> getHonooHistory(Honoo honoo) async {
    final id = honoo.dbId;
    if (id == null) {
      // se non hai l'uuid (dbId), ritorna almeno la card corrente
      return [honoo];
    }

    final client = Supabase.instance.client;

    // Prendiamo l'honoo originale + tutte le reply collegate
    // or('id.eq.<id>,reply_to.eq.<id>')
    final rows = await client
        .from('honoo')
        .select('id,text,image_url,destination,reply_to,recipient_tag,created_at,updated_at,user_id')
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


  /// (Esempio) Cancella su DB, poi da cache
  Future<void> deleteHonoo(Honoo h) async {
    final id = h.dbId;
    if (id == null) return;
    // TODO: await HonooService.deleteHonoo(id);
    _personal.removeWhere((x) => x.dbId == id);
    version.value++;
  }
}
