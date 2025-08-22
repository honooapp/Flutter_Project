import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Entites/Honoo.dart';

class HonooService {
  static final _client = Supabase.instance.client;

  /// Honoo pubblici (Luna)
  static Future<List<Honoo>> fetchPublicHonoo() async {
    final response = await _client
        .from('honoo')
        .select('*')
        .eq('destination', 'moon')
        .order('created_at', ascending: false);
    return (response as List).map((e) => Honoo.fromMap(e)).toList();
  }

  /// Honoo dell’utente per una certa destination (es. 'chest')
  static Future<List<Honoo>> fetchUserHonoo(String userId, String destination) async {
    final response = await _client
        .from('honoo')
        .select('*')
        .eq('destination', destination)
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => Honoo.fromMap(e)).toList();
  }

  /// Tutte le reply indirizzate a recipientTag (se usi i tag poetici)
  static Future<List<Honoo>> fetchRepliesForUser(String recipientTag) async {
    final response = await _client
        .from('honoo')
        .select('*')
        .eq('destination', 'reply')
        .eq('recipient_tag', recipientTag)
        .order('created_at', ascending: false);
    return (response as List).map((e) => Honoo.fromMap(e)).toList();
  }

  /// Pubblica un nuovo honoo
  static Future<void> publishHonoo(Honoo honoo) async {
    await _client.from('honoo').insert(honoo.toInsertMap());
  }

  /// Aggiorna la destination (chest|moon|reply) per id (UUID DB)
  static Future<void> updateDestination({
    required String id,
    required String destination,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _client
        .from('honoo')
        .update({
      'destination': destination,
    })
        .eq('id', id);
  }

  /// Duplica un honoo dello scrigno pubblicandolo sulla Luna (nuova INSERT).
  /// Non tocca l'originale in 'chest'.
  static Future<bool> duplicateToMoon(Honoo h) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('Nessuna sessione attiva');
    }
    final uid = session.user.id;

    // esiste già?
    final existing = await _client
        .from('honoo')
        .select('id')
        .eq('user_id', uid)
        .eq('destination', 'moon')
        .eq('text', h.text)
        .eq('image_url', (h.image.isEmpty) ? null : h.image)
        .limit(1);

    if (existing != null && existing.isNotEmpty) {
      // già presente
      return false;
    }

    // inserisci
    final payload = <String, dynamic>{
      'text': h.text,
      'image_url': (h.image.isEmpty) ? null : h.image,
      'destination': 'moon',
      'reply_to': null,
      'recipient_tag': null,
      'user_id': uid, // se hai un trigger che lo mette da solo, puoi ometterlo
    };
    await _client.from('honoo').insert(payload);
    return true;
  }
}
