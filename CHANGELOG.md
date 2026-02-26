# Changelog

## v2026-02-26 — Bussate live, multi‑share, sobbalzi

- Campanelli: notifiche live via Supabase Realtime per bussate (owner) e aperture (visitor), badge e dialog aggiornati in tempo reale.
- Flusso visitatore: niente ingresso immediato dopo bussata; si attende l’approvazione e, al grant, si salta al campanello con sobbalzo.
- Sobbalzi: hint verticale di metà schermo nell’apertura casa e nei thread conversazioni; sobbalzo orizzontale del campanello al grant.
- Condivisione multipla: nuovo dialog proprietario consente selezione di più contenuti (Honoo/Hinoo/Conversazioni). Scrigno visitatore mostra scelta quando presenti più opzioni.
- Schema: `house_share_settings.share_modes text[]` con backfill e retro‑compatibilità su `share_mode` (migrazione in `supabase/migrations/20260226211500_add_share_modes_to_house_share_settings.sql`).
- Robustezza test: sottoscrizioni Realtime avvolte in try/catch per compatibilità con MockSupabaseClient.
- Config: `lib/main.dart` ora legge `SUPABASE_URL`/`SUPABASE_ANON_KEY` via `env/env.dart`.
- Rispondi dai contenuti condivisi: dalle pagine condivise è possibile rispondere sia allo stesso tipo (Honoo→Honoo, Hinoo→Hinoo) sia “incrociato” (Honoo→Hinoo e Hinoo→Honoo, indirizzato al proprietario). Dopo l’invio si apre lo Scrigno con focus conversazioni.

## v2026-02-23.21 — Layout unificato Campanelli (header + full‑width/availableH + footer)

- Nuovo wrapper UI: `ThreadLayoutScaffold` (lib/UI/thread_layout_scaffold.dart)
  - Header fisso (52px)
  - Area centrale full‑width con altezza calcolata `availableH = viewH − header − footer`
  - Footer responsivo (icone/gap) senza restringimenti
  - Nessun `ConstrainedBox`, `maxWidth`/`contentMaxWidth`, Container decorativo, overlay esterni o padding riduttivi
- Pagine migrate al layout unificato:
  - Conversazione (reply/thread) → usa `ThreadLayoutScaffold`
  - SharedHonooPage (condivisi Honoo) → usa `ThreadLayoutScaffold`
  - SharedConversationsPage (conversazioni condivise) → usa `ThreadLayoutScaffold`
  - Luna (MoonPage) → usa `ThreadLayoutScaffold`
  - Scrigno (ChestPage) → usa `ThreadLayoutScaffold` con overlay `LunaFissa`
- Caroselli invariati (viewportFraction 1.0, nessun “peek”): logica e interazioni non cambiano
- Reply identiche ai contenuti normali per proporzioni e impaginazione:
  - HonooCard: rapporto 1.5, bordo rosso integrato per reply, nessun overlay/container
  - HinooViewer: canvas 1080×1920, bordo rosso integrato (parametro `isReply`), nessun overlay/container
- Analisi statica: pulizia warning (variabili inutilizzate rimosse)

Note: se non si vedono subito i cambiamenti sul web, effettuare un hard refresh (service worker) o usare una build con PWA disattivato (vedi workflow).
