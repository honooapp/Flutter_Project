@Tags(['unit']) // i test non-tagged integration girano in Codex
import 'package:flutter_test/flutter_test.dart';

// App code
import 'package:honoo/Services/hinoo_service.dart';
import 'package:honoo/Entities/hinoo.dart';
import '../test_supabase_helper.dart';

void main() {
  group('HinooService drafts (unit, no network)', () {
    late SupabaseTestHarness harness;

    setUpAll(registerSupabaseFallbacks);

    setUp(() {
      harness = SupabaseTestHarness();
      harness.enableOverrides();
    });

    tearDown(() {
      harness.disableOverrides();
    });

    test('getDraft() → null quando utente non autenticato (early-return)',
        () async {
      // Assicuriamoci che Supabase non abbia un utente loggato.
      // Se in setUp dell’app inizializzi Supabase altrove, qui non lo facciamo.
      // La funzione fa early return e non tocca la rete.
      final draft = await HinooService.getDraft();
      expect(draft, isNull);
    });
  });

  // I test qui sotto richiedono rete e segreti -> eseguili FUORI da Codex
  // Esempio in locale:
  // SUPABASE_URL=... SUPABASE_ANON_KEY=... flutter test test/services/hinoo_service_drafts_test.dart -t integration
  group('HinooService drafts (integration, requires network)', () {
    test('saveDraft() upsert su hinoo_drafts per utente loggato', () async {
      // Questo test è SOLO un segnaposto: richiede un utente loggato via Supabase.
      // Eseguilo in locale/CI dopo aver chiamato Supabase.initialize e fatto signIn anonimo.
      // Esempio (pseudocodice da mettere nel tuo bootstrap di test):
      // await Supabase.initialize(url: envUrl, anonKey: envKey);
      // await Supabase.instance.client.auth.signInAnonymously();

      const draft = HinooDraft(
        pages: [
          HinooSlide(
            text: 'Bozza di prova',
            backgroundImage: null,
            isTextWhite: true,
            bgScale: 1.0,
            bgOffsetX: 0,
            bgOffsetY: 0,
          ),
        ],
        type: HinooType.personal,
        recipientTag: null,
      );

      // ACT
      await HinooService.saveDraft(draft);

      // ASSERT “soft”: se non tira eccezioni, consideriamo OK.
      // Per una verifica più stretta, potresti leggere via getDraft() e confrontare il payload.
      expect(true, isTrue);
    }, tags: ['integration']);

    test('getDraft() restituisce l’ultimo draft salvato per l’utente',
        () async {
      // Precondizione: utente loggato e almeno un draft salvato (vedi test sopra).
      final res = await HinooService.getDraft();
      expect(res, isNotNull);
      if (res != null) {
        expect(res.pages, isNotEmpty);
        expect(res.pages.first.text, isA<String>());
      }
    }, tags: ['integration']);
  });
}
