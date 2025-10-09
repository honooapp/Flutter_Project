# Load test Supabase

Questo scenario Locust esercita gli endpoint REST di Supabase utilizzati da honoo
per Luna e Scrigno. Prima di eseguire il test esporta le variabili richieste:

```bash
export SUPABASE_URL="https://<project>.supabase.co"
export SUPABASE_ANON_KEY="<chiave anon>"
# ID di un utente reale del progetto per lo scenario Scrigno
export LOADTEST_USER_ID="00000000-0000-0000-0000-000000000000"
```

Esecuzione rapida con 25 utenti simultanei e ramp-up di 2 al secondo:

```bash
locust -f tool/loadtest/locustfile.py \
  --users 25 --spawn-rate 2 \
  --host "$SUPABASE_URL"
```

Apri l’interfaccia web (default http://localhost:8089) per monitorare latenza,
errori e throughput. Imposta `LOADTEST_BEFORE` se vuoi simulare la paginazione
con cursore (timestamp ISO8601 più vecchio rispetto ai dati correnti).

Per un run non interattivo:

```bash
locust -f tool/loadtest/locustfile.py \
  --host "$SUPABASE_URL" \
  --headless --users 50 --spawn-rate 5 \
  --run-time 10m \
  --csv build/loadtest
```

I report CSV conterranno percentile e rate degli endpoint principali. Ricorda di
rigenerare i token Supabase se esegui test su ambienti pubblici.
