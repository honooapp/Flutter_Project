# TODO honoo

## Contenuti editoriali

- Sostituire le pagine "in arrivo" di YouTube, podcast e Twitch con link e contenuti definitivi.
- Pubblicare le schede definitive dei libri oppure mantenerle esplicitamente come aggiornamenti editoriali.
- Rivedere i testi pubblici in `lib/Utility/utility.dart` e rimuovere le promesse "fra poco" relative a funzioni già disponibili.
- Decidere, per ogni sezione editoriale, se deve essere interattiva o una pagina informativa.

## Consolidamento tecnico

- Continuare a suddividere `campanelli_page.dart` e `chest_page.dart` in controller, repository e widget per singolo flusso.
- Portare progressivamente tutte le query Supabase fuori dalle pagine, mantenendo test di regressione per ogni estrazione.
- Estendere i test staging a RLS, Realtime, condivisione multipla, bussate e recupero della sessione.
- Verificare manualmente download e interazioni su Safari iOS e browser mobile reali prima di ogni release.
