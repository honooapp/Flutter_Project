import 'package:supabase_flutter/supabase_flutter.dart';
import '../Entites/Honoo.dart';


class HonooService {
  static final _client = Supabase.instance.client;

  /// Recupera tutti gli honoo pubblicati sulla Luna
  static Future<List<Honoo>> fetchPublicHonoo() async {
    final response = await _client
        .from('honoo')
        .select()
        .eq('destination', 'moon')
        .order('created_at', ascending: false);

    return (response as List).map((e) => Honoo.fromMap(e)).toList();
  }

  /// Recupera tutti gli honoo scritti da un utente (es. per lo scrigno)
  static Future<List<Honoo>> fetchUserHonoo(String userId, String destination) async {
    final response = await _client
        .from('honoo')
        .select()
        .eq('destination', destination)
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Honoo.fromMap(e)).toList();
  }


  /// Recupera tutte le risposte ricevute da un utente
  static Future<List<Honoo>> fetchRepliesForUser(String recipientTag) async {
    final response = await _client
        .from('honoo')
        .select()
        .eq('destination', 'reply')
        .eq('recipient_tag', recipientTag)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Honoo.fromMap(e)).toList();
  }

  /// Pubblica un nuovo honoo su Supabase
  static Future<void> publishHonoo(Honoo honoo) async {
    await _client.from('honoo').insert(honoo.toMap());
  }
}
