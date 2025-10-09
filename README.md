# honoo

# DEV
flutter version to install
```
Flutter 3.9.0-9.0.pre.25 • channel master • https://github.com/flutter/flutter.git
Framework • revision be97d03a25 (1 year, 2 months ago) • 2023-03-16 16:13:04 -0700
Engine • revision 48628fb946
Tools • Dart 3.0.0 (build 3.0.0-337.0.dev) • DevTools 2.22.2
```

braking flutter version
```
Flutter 3.19.6 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 54e66469a9 (3 weeks ago) • 2024-04-17 13:08:03 -0700
Engine • revision c4cd48e186
Tools • Dart 3.3.4 • DevTools 2.31.1
```

```bash
flutter/bin/flutter run
# chosee chrome (second)
```


A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Web env

Verifica che l'accesso alle variabili d'ambiente sia compatibile con Flutter Web prima del deploy.

```bash
# (A) Verifica che lib/ non usi Platform.environment per le env
./tool/verify_web_compat.sh
```

```bash
# (B) Avvia Web con le define richieste
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://lnuzzrlkcbhxuzxyekbp.supabase.co \
  --dart-define=SUPABASE_ANON_KEY='LA_TUA_ANON_KEY'
```

Se l’app parte senza l’errore “Unsupported operation: Platform.environment”, il fix è applicato correttamente.

## Auth: Passwordless policy

- Password disabilitate: accesso e registrazione solo via magic link/OTP.
- UI reset password rimossa/nascosta in modalità passwordless.
- Script `tool/guard_no_password_flows.sh` blinda il repo da regressioni.
- Edge Function opzionale `otp-proxy` con rate limit per email/IP (richiede `SUPABASE_SERVICE_ROLE_KEY` lato server, non esporlo ai client).
