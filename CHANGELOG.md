# Changelog

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
