import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

Future<void> main(List<String> rawArgs) async {
  final args = _Args.parse(rawArgs);
  if (args.showHelp) {
    _printUsage();
    exit(0);
  }

  final config = args.toConfig();
  final scenario = _scenarios[config.scenario];
  if (scenario == null) {
    stderr.writeln(
      'Scenario "${config.scenario}" non riconosciuto. Usa --help per l\'elenco.',
    );
    exit(64);
  }

  scenario.validate(config);

  stdout.writeln('▶ Scenario: ${scenario.name}');
  stdout.writeln('   VU: ${config.vus}  durata: ${config.duration.inSeconds}s  '
      'pausa: ${config.pauseMinMs}-${config.pauseMaxMs}ms  timeout: ${config.requestTimeout.inSeconds}s');
  stdout.writeln('   Base URL: ${config.baseUrl}');

  final metrics = _Metrics();
  final endInstant = DateTime.now().add(config.duration);

  final vus = List.generate(
    config.vus,
    (i) => _VirtualUser(i, config, scenario.requiresAuth),
  );

  await Future.wait(vus.map((vu) async {
    try {
      if (scenario.prefetchAuth) {
        await vu.ensureSession();
      }
      await _runVirtualUser(vu, scenario, config, metrics, endInstant);
    } finally {
      vu.dispose();
    }
  }));

  stdout.writeln('\n=== Risultati ===');
  metrics.printReport(config.duration);
}

Future<void> _runVirtualUser(
  _VirtualUser vu,
  _Scenario scenario,
  _RunConfig config,
  _Metrics metrics,
  DateTime endInstant,
) async {
  final random = vu.random;
  while (DateTime.now().isBefore(endInstant)) {
    final sw = Stopwatch()..start();
    try {
      await scenario.action(vu, config);
      sw.stop();
      metrics.recordSuccess(sw.elapsed);
    } catch (e, stack) {
      sw.stop();
      metrics.recordFailure(sw.elapsed, e.toString());
      if (config.verbose) {
        stderr.writeln('VU ${vu.id} errore: $e');
        if (config.verbose && config.debugStackTraces) {
          stderr.writeln(stack);
        }
      }
    }

    vu.markIterationComplete();

    if (!DateTime.now().isBefore(endInstant)) {
      break;
    }

    final pauseRange = config.pauseMaxMs - config.pauseMinMs;
    final pauseMs = pauseRange > 0
        ? config.pauseMinMs + random.nextInt(pauseRange + 1)
        : config.pauseMinMs;
    await Future.delayed(Duration(milliseconds: pauseMs));
  }
}

class _Scenario {
  _Scenario({
    required this.name,
    required this.description,
    required this.action,
    this.requiresAuth = false,
    this.prefetchAuth = false,
  });

  final String name;
  final String description;
  final Future<void> Function(_VirtualUser, _RunConfig) action;
  final bool requiresAuth;
  final bool prefetchAuth;

  void validate(_RunConfig config) {
    if (requiresAuth && (config.email == null || config.password == null)) {
      stderr.writeln(
        'Scenario "$name" richiede TEST_EMAIL e TEST_PASSWORD (o --email / --password).',
      );
      exit(64);
    }
  }
}

final Map<String, _Scenario> _scenarios = {
  'fetch-moon': _Scenario(
    name: 'fetch-moon',
    description: 'Simula il caricamento della pagina Luna: honoo pubblici + hinoo moon',
    action: (_VirtualUser vu, _RunConfig config) async {
      await _fetchMoonContent(vu, config);
    },
  ),
  'login': _Scenario(
    name: 'login',
    description: 'Stress del login (password grant GoTrue)',
    requiresAuth: true,
    action: (_VirtualUser vu, _RunConfig config) async {
      final iteration = vu.iterations;
      if (config.loginReuseSession) {
        final refreshEvery = config.loginRefreshEvery;
        if (iteration == 0) {
          await vu.ensureSession();
        } else if (refreshEvery > 0 && iteration % refreshEvery == 0) {
          await vu.refreshSession();
        } else {
          await vu.ensureSession();
        }
      } else {
        await vu.refreshSession();
        vu.clearSession();
      }
    },
  ),
  'draft-upsert': _Scenario(
    name: 'draft-upsert',
    description: 'Simula salvataggi rapidi su hinoo_drafts',
    requiresAuth: true,
    prefetchAuth: true,
    action: (_VirtualUser vu, _RunConfig config) async {
      await vu.ensureSession();
      final now = DateTime.now().toUtc().toIso8601String();
      final payload = {
        'user_id': vu.userId,
        'payload': _sampleDraft(vu),
        'updated_at': now,
      };
      final headers = Map<String, String>.from(vu.writeHeaders)
        ..['Prefer'] = 'resolution=merge-duplicates,return=minimal';

      final resp = await vu.post(
        config.buildRestUri('hinoo_drafts', const {}),
        headers: headers,
        body: jsonEncode([payload]),
      );

      if (!_isOk(resp.statusCode, extraAccepted: {204})) {
        throw _LoadTestError(
          'Upsert hinoo_drafts fallito (${resp.statusCode}): ${resp.body}',
        );
      }
    },
  ),
  'honoo-cycle': _Scenario(
    name: 'honoo-cycle',
    description:
        'Inserisce un honoo nello scrigno e lo elimina per testare il flusso completo',
    requiresAuth: true,
    prefetchAuth: true,
    action: (_VirtualUser vu, _RunConfig config) async {
      await vu.ensureSession();
      final text = _randomHonooText(vu, 'cycle');
      final id = await _insertHonoo(
        vu,
        config,
        destination: 'chest',
        text: text,
        recipientTag: 'loadtest',
      );
      await _deleteHonooById(vu, config, id);
    },
  ),
  'honoo-write-chest': _Scenario(
    name: 'honoo-write-chest',
    description: 'Simula la creazione di un honoo nello scrigno (destination=chest)',
    requiresAuth: true,
    prefetchAuth: true,
    action: (_VirtualUser vu, _RunConfig config) async {
      await vu.ensureSession();
      final text = _randomHonooText(vu, 'chest');
      final id = await _insertHonoo(
        vu,
        config,
        destination: 'chest',
        text: text,
        recipientTag: 'loadtest',
      );
      if (!config.keepData) {
        await _deleteHonooById(vu, config, id);
      }
    },
  ),
  'honoo-duplicate-to-moon': _Scenario(
    name: 'honoo-duplicate-to-moon',
    description:
        'Replica il flusso di duplicazione: salva nello scrigno e duplica sulla Luna',
    requiresAuth: true,
    prefetchAuth: true,
    action: (_VirtualUser vu, _RunConfig config) async {
      await vu.ensureSession();
      final text = _randomHonooText(vu, 'dup');
      final chestId = await _insertHonoo(
        vu,
        config,
        destination: 'chest',
        text: text,
        recipientTag: 'loadtest',
      );
      final moonId = await _insertHonoo(
        vu,
        config,
        destination: 'moon',
        text: text,
        recipientTag: 'loadtest',
      );
      if (!config.keepData) {
        await _deleteHonooById(vu, config, moonId);
        await _deleteHonooById(vu, config, chestId);
      }
    },
  ),
  'honoo-update-to-moon': _Scenario(
    name: 'honoo-update-to-moon',
    description: 'Crea uno honoo nello scrigno e aggiorna destination=moon',
    requiresAuth: true,
    prefetchAuth: true,
    action: (_VirtualUser vu, _RunConfig config) async {
      await vu.ensureSession();
      final text = _randomHonooText(vu, 'update');
      final id = await _insertHonoo(
        vu,
        config,
        destination: 'chest',
        text: text,
        recipientTag: 'loadtest',
      );
      await _updateHonooDestination(vu, config, id: id, destination: 'moon');
      if (!config.keepData) {
        await _deleteHonooById(vu, config, id);
      }
    },
  ),
  'hinoo-publish': _Scenario(
    name: 'hinoo-publish',
    description: 'Pubblica un hinoo personale (type=personal)',
    requiresAuth: true,
    prefetchAuth: true,
    action: (_VirtualUser vu, _RunConfig config) async {
      await vu.ensureSession();
      final id = await _insertHinoo(
        vu,
        config,
        type: 'personal',
        recipientTag: 'loadtest',
      );
      if (!config.keepData) {
        await _deleteHinooById(vu, config, id);
      }
    },
  ),
  'hinoo-duplicate-to-moon': _Scenario(
    name: 'hinoo-duplicate-to-moon',
    description:
        'Duplica un hinoo personale sulla Luna (nuova insert type=moon con fingerprint)',
    requiresAuth: true,
    prefetchAuth: true,
    action: (_VirtualUser vu, _RunConfig config) async {
      await vu.ensureSession();
      final draftPages = _sampleDraft(vu)['pages'] as List<dynamic>;
      final personalId = await _insertHinoo(
        vu,
        config,
        type: 'personal',
        recipientTag: 'loadtest',
        pages: draftPages,
      );
      final fp = _randomFingerprint(vu, 'hinoo-moon');
      final moonId = await _insertHinoo(
        vu,
        config,
        type: 'moon',
        recipientTag: 'loadtest',
        pages: draftPages,
        fingerprint: fp,
      );
      if (!config.keepData) {
        await _deleteHinooById(vu, config, moonId);
        await _deleteHinooById(vu, config, personalId);
      }
    },
  ),
  'honoo-user-journey': _Scenario(
    name: 'honoo-user-journey',
    description:
        'Percorso realistico: consulta la Luna, salva nello scrigno e talvolta pubblica sulla Luna',
    requiresAuth: true,
    prefetchAuth: true,
    action: (_VirtualUser vu, _RunConfig config) async {
      await vu.ensureSession();
      await _fetchMoonContent(vu, config);
      await _fetchChestContent(vu, config);

      final text = _randomHonooText(vu, 'journey');
      final chestId = await _insertHonoo(
        vu,
        config,
        destination: 'chest',
        text: text,
        recipientTag: 'journey',
      );

      String? moonId;
      if (vu.random.nextBool()) {
        moonId = await _insertHonoo(
          vu,
          config,
          destination: 'moon',
          text: '$text-moon',
          recipientTag: 'journey',
        );
      }

      if (!config.keepData) {
        if (moonId != null) {
          await _deleteHonooById(vu, config, moonId);
        }
        await _deleteHonooById(vu, config, chestId);
      }
    },
  ),
};

bool _isOk(int statusCode, {Set<int> extraAccepted = const {}}) {
  if (statusCode >= 200 && statusCode < 300) {
    return true;
  }
  return extraAccepted.contains(statusCode);
}

Future<void> _fetchMoonContent(_VirtualUser vu, _RunConfig config) async {
  final respHonoo = await vu.get(
    config.buildRestUri('honoo', {
      'select': 'id,text,destination,created_at',
      'destination': 'eq.moon',
      'order': 'created_at.desc',
      'limit': config.readLimit,
    }),
    headers: vu.readHeaders,
  );
  if (!_isOk(respHonoo.statusCode)) {
    throw _LoadTestError(
      'GET honoo moon fallita (${respHonoo.statusCode}): ${respHonoo.body}',
    );
  }
  final honoo = jsonDecode(respHonoo.body);
  if (honoo is! List) {
    throw _LoadTestError('Risposta honoo non valida: ${respHonoo.body}');
  }

  final respHinoo = await vu.get(
    config.buildRestUri('hinoo', {
      'select': 'pages,recipient_tag,created_at',
      'type': 'eq.moon',
      'order': 'created_at.desc',
      'limit': config.readLimit,
    }),
    headers: vu.readHeaders,
  );
  if (!_isOk(respHinoo.statusCode)) {
    throw _LoadTestError(
      'GET hinoo moon fallita (${respHinoo.statusCode}): ${respHinoo.body}',
    );
  }
  final hinoo = jsonDecode(respHinoo.body);
  if (hinoo is! List) {
    throw _LoadTestError('Risposta hinoo non valida: ${respHinoo.body}');
  }
}

Future<void> _fetchChestContent(_VirtualUser vu, _RunConfig config) async {
  final uid = vu.userId;
  if (uid == null || uid.isEmpty) {
    throw _LoadTestError('UserId non disponibile per fetch chest');
  }
  final resp = await vu.get(
    config.buildRestUri('honoo', {
      'select': 'id,text,destination,created_at',
      'destination': 'eq.chest',
      'user_id': 'eq.$uid',
      'order': 'created_at.desc',
      'limit': config.readLimit,
    }),
    headers: vu.writeHeaders,
  );
  if (!_isOk(resp.statusCode)) {
    throw _LoadTestError(
      'GET honoo chest fallita (${resp.statusCode}): ${resp.body}',
    );
  }
  final data = jsonDecode(resp.body);
  if (data is! List) {
    throw _LoadTestError('Risposta honoo chest non valida: ${resp.body}');
  }
}

Map<String, dynamic> _sampleDraft(_VirtualUser vu) {
  final bgId = vu.random.nextInt(1 << 32).toString();
  return {
    'type': 'personal',
    'recipientTag': 'loadtest',
    'baseCanvasHeight': 812,
    'pages': [
      {
        'backgroundImage': 'https://example.com/background/$bgId.jpg',
        'text': 'Load test ${vu.id}',
        'isTextWhite': true,
        'bgScale': 1.0,
        'bgOffsetX': 0.0,
        'bgOffsetY': 0.0,
      }
    ],
  };
}

String _randomHonooText(_VirtualUser vu, String tag) {
  final now = DateTime.now().toUtc().millisecondsSinceEpoch;
  return 'lt-$tag-${vu.id}-$now-${vu.random.nextInt(1 << 32)}';
}

String _randomFingerprint(_VirtualUser vu, String tag) {
  final now = DateTime.now().toUtc().millisecondsSinceEpoch;
  return 'fp-$tag-${vu.id}-$now-${vu.random.nextInt(1 << 32)}';
}

Future<String> _insertHonoo(
  _VirtualUser vu,
  _RunConfig config, {
  required String destination,
  required String text,
  String? imageUrl,
  String? replyTo,
  String? recipientTag,
}) async {
  final headers = Map<String, String>.from(vu.writeHeaders)
    ..['Prefer'] = 'return=representation';
  final now = DateTime.now().toUtc().toIso8601String();
  final safeImage = imageUrl ?? 'https://via.placeholder.com/1x1.png?text=${Uri.encodeComponent(text)}';
  final payload = <String, dynamic>{
    'text': text,
    'image_url': safeImage,
    'destination': destination,
    'reply_to': replyTo,
    'recipient_tag': recipientTag,
    'user_id': vu.userId,
    'created_at': now,
  };

  final resp = await vu.post(
    config.buildRestUri('honoo', const {}),
    headers: headers,
    body: jsonEncode([payload]),
  );

  if (resp.statusCode != 201) {
    throw _LoadTestError(
      'Insert honoo fallito (${resp.statusCode}): ${resp.body}',
    );
  }

  final decoded = jsonDecode(resp.body);
  if (decoded is! List || decoded.isEmpty) {
    throw _LoadTestError('Risposta insert honoo inattesa: ${resp.body}');
  }
  final id = (decoded.first as Map<String, dynamic>)['id'] as String?;
  if (id == null || id.isEmpty) {
    throw _LoadTestError('ID honoo mancante dopo insert: ${resp.body}');
  }
  return id;
}

Future<void> _deleteHonooById(
  _VirtualUser vu,
  _RunConfig config,
  String id,
) async {
  final resp = await vu.delete(
    config.buildRestUri('honoo', {'id': 'eq.$id'}),
    headers: vu.writeHeaders,
  );
  if (resp.statusCode != 204) {
    throw _LoadTestError(
      'Delete honoo fallito (${resp.statusCode}): ${resp.body}',
    );
  }
}

Future<void> _updateHonooDestination(
  _VirtualUser vu,
  _RunConfig config, {
  required String id,
  required String destination,
}) async {
  final headers = Map<String, String>.from(vu.writeHeaders)
    ..['Prefer'] = 'return=minimal';
  final resp = await vu.patch(
    config.buildRestUri('honoo', {'id': 'eq.$id'}),
    headers: headers,
    body: jsonEncode({'destination': destination}),
  );
  if (!_isOk(resp.statusCode, extraAccepted: {204})) {
    throw _LoadTestError(
      'Update honoo fallito (${resp.statusCode}): ${resp.body}',
    );
  }
}

Future<String> _insertHinoo(
  _VirtualUser vu,
  _RunConfig config, {
  required String type,
  String? recipientTag,
  List<dynamic>? pages,
  String? fingerprint,
}) async {
  final headers = Map<String, String>.from(vu.writeHeaders)
    ..['Prefer'] = 'return=representation';
  final draft = pages;
  final effectivePages = draft ?? (_sampleDraft(vu)['pages'] as List<dynamic>);
  final payload = <String, dynamic>{
    'user_id': vu.userId,
    'type': type,
    'pages': effectivePages,
    'recipient_tag': recipientTag ?? 'loadtest',
    'created_at': DateTime.now().toUtc().toIso8601String(),
  };
  if (type == 'moon') {
    payload['fingerprint'] = fingerprint ?? _randomFingerprint(vu, 'hinoo');
  } else if (fingerprint != null) {
    payload['fingerprint'] = fingerprint;
  }

  final resp = await vu.post(
    config.buildRestUri('hinoo', const {}),
    headers: headers,
    body: jsonEncode([payload]),
  );

  if (resp.statusCode != 201) {
    throw _LoadTestError(
      'Insert hinoo fallito (${resp.statusCode}): ${resp.body}',
    );
  }

  final decoded = jsonDecode(resp.body);
  if (decoded is! List || decoded.isEmpty) {
    throw _LoadTestError('Risposta insert hinoo inattesa: ${resp.body}');
  }
  final id = (decoded.first as Map<String, dynamic>)['id'] as String?;
  if (id == null || id.isEmpty) {
    throw _LoadTestError('ID hinoo mancante dopo insert: ${resp.body}');
  }
  return id;
}

Future<void> _deleteHinooById(
  _VirtualUser vu,
  _RunConfig config,
  String id,
) async {
  final resp = await vu.delete(
    config.buildRestUri('hinoo', {'id': 'eq.$id'}),
    headers: vu.writeHeaders,
  );
  if (resp.statusCode != 204) {
    throw _LoadTestError(
      'Delete hinoo fallito (${resp.statusCode}): ${resp.body}',
    );
  }
}

class _VirtualUser {
  _VirtualUser(this.id, this.config, bool needsAuth)
      : client = http.Client(),
        random = Random(id + DateTime.now().millisecondsSinceEpoch) {
    if (needsAuth) {
      email = config.email;
      password = config.password;
    }
  }

  final int id;
  final _RunConfig config;
  final http.Client client;
  final Random random;
  int iterations = 0;

  String? email;
  String? password;
  String? _accessToken;
  String? userId;
  DateTime _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(0);

  Map<String, String> get readHeaders => {
        'apikey': config.anonKey,
        'Authorization': 'Bearer ${config.anonKey}',
        'Accept': 'application/json',
      };

  Map<String, String> get writeHeaders {
    final token = _accessToken;
    if (token == null || DateTime.now().isAfter(_tokenExpiry)) {
      throw _LoadTestError('Token non disponibile, chiama ensureSession() prima.');
    }
    return {
      'apikey': config.anonKey,
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
  }) {
    return client
        .get(uri, headers: headers)
        .timeout(config.requestTimeout, onTimeout: () {
      throw _LoadTestError('Timeout GET ${uri.toString()}');
    });
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return client
        .post(uri, headers: headers, body: body)
        .timeout(config.requestTimeout, onTimeout: () {
      throw _LoadTestError('Timeout POST ${uri.toString()}');
    });
  }

  Future<http.Response> patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return client
        .patch(uri, headers: headers, body: body)
        .timeout(config.requestTimeout, onTimeout: () {
      throw _LoadTestError('Timeout PATCH ${uri.toString()}');
    });
  }

  Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
  }) {
    return client
        .delete(uri, headers: headers)
        .timeout(config.requestTimeout, onTimeout: () {
      throw _LoadTestError('Timeout DELETE ${uri.toString()}');
    });
  }

  Future<void> ensureSession() async {
    if (_accessToken != null && DateTime.now().isBefore(_tokenExpiry)) {
      return;
    }
    await signIn(force: false);
  }

  Future<void> refreshSession() => signIn(force: true);

  Future<void> signIn({bool force = false}) async {
    if (!force && _accessToken != null && DateTime.now().isBefore(_tokenExpiry)) {
      return;
    }

    final email = this.email;
    final password = this.password;
    if (email == null || password == null) {
      throw _LoadTestError('Credenziali non configurate.');
    }

    final resp = await client
        .post(
          config.authUri,
          headers: {
            'apikey': config.anonKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(config.requestTimeout, onTimeout: () {
      throw _LoadTestError('Timeout login');
    });

    if (resp.statusCode != 200) {
      throw _LoadTestError('Login fallito (${resp.statusCode}): ${resp.body}');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    _accessToken = json['access_token'] as String?;
    userId = json['user']?['id'] as String?;
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 3600;
    // rinnovo leggermente prima della scadenza effettiva
    _tokenExpiry = DateTime.now().add(Duration(seconds: max(10, expiresIn - 30)));

    if (_accessToken == null || userId == null) {
      throw _LoadTestError('Risposta login incompleta: ${resp.body}');
    }
  }

  void clearSession() {
    _accessToken = null;
    userId = null;
    _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(0);
  }

  void markIterationComplete() {
    iterations += 1;
  }

  void dispose() {
    client.close();
  }
}

class _LoadTestError implements Exception {
  _LoadTestError(this.message);
  final String message;
  @override
  String toString() => message;
}

class _Metrics {
  final List<int> _latenciesMs = [];
  final List<int> _failureLatenciesMs = [];
  final Map<String, int> _errors = {};
  int success = 0;
  int failure = 0;

  void recordSuccess(Duration elapsed) {
    success += 1;
    _latenciesMs.add(elapsed.inMilliseconds);
  }

  void recordFailure(Duration elapsed, String error) {
    failure += 1;
    _failureLatenciesMs.add(elapsed.inMilliseconds);
    final key = error.length > 160 ? '${error.substring(0, 160)}…' : error;
    _errors[key] = (_errors[key] ?? 0) + 1;
  }

  void printReport(Duration plannedDuration) {
    final total = success + failure;
    stdout.writeln('Richieste: $total  Successi: $success  Errori: $failure');
    final rate = total == 0 ? 0.0 : (success / total) * 100;
    stdout.writeln('Success rate: ${rate.toStringAsFixed(2)}%');

    if (_latenciesMs.isNotEmpty) {
      _latenciesMs.sort();
      final avg = _latenciesMs.reduce((a, b) => a + b) / _latenciesMs.length;
      final p50 = _percentile(_latenciesMs, 0.50);
      final p95 = _percentile(_latenciesMs, 0.95);
      final maxLatency = _latenciesMs.last;
      stdout.writeln('Latencies (ms)  avg: ${avg.toStringAsFixed(1)}  '
          'p50: ${p50.toStringAsFixed(1)}  p95: ${p95.toStringAsFixed(1)}  max: $maxLatency');
    } else {
      stdout.writeln('Nessuna richiesta riuscita, nessuna metrica di latenza disponibile.');
    }

    if (_errors.isNotEmpty) {
      stdout.writeln('\nErrori principali:');
      final sorted = _errors.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sorted.take(5)) {
        stdout.writeln(' - ${entry.value}× ${entry.key}');
      }
    }

    stdout.writeln('Durata pianificata: ${plannedDuration.inSeconds}s');
  }

  double _percentile(List<int> sorted, double p) {
    if (sorted.isEmpty) return double.nan;
    final idx = (p * (sorted.length - 1)).clamp(0, sorted.length - 1).toDouble();
    final lower = sorted[idx.floor()];
    final upper = sorted[idx.ceil()];
    if (idx.floor() == idx.ceil()) {
      return lower.toDouble();
    }
    final fraction = idx - idx.floor();
    return lower + (upper - lower) * fraction;
  }
}

class _RunConfig {
  _RunConfig({
    required this.baseUrl,
    required this.anonKey,
    required this.vus,
    required this.duration,
    required this.pauseMinMs,
    required this.pauseMaxMs,
    required this.requestTimeout,
    required this.scenario,
    required this.readLimit,
    required this.keepData,
    this.loginReuseSession = true,
    this.loginRefreshEvery = 30,
    this.email,
    this.password,
    this.verbose = false,
    this.debugStackTraces = false,
  }) : baseUri = _normalizeBaseUri(baseUrl);

  final String baseUrl;
  final Uri baseUri;
  final String anonKey;
  final int vus;
  final Duration duration;
  final int pauseMinMs;
  final int pauseMaxMs;
  final Duration requestTimeout;
  final String scenario;
  final String? email;
  final String? password;
  final bool verbose;
  final bool debugStackTraces;
  final String readLimit;
  final bool keepData;
  final bool loginReuseSession;
  final int loginRefreshEvery;

  Uri get authUri => baseUri.replace(
        path: _buildPath(baseUri.path, 'auth/v1/token'),
        queryParameters: const {'grant_type': 'password'},
      );

  Uri buildRestUri(String resource, Map<String, String> query) {
    return baseUri.replace(
      path: _buildPath(baseUri.path, 'rest/v1/$resource'),
      queryParameters: query.isEmpty ? null : query,
    );
  }

  static Uri _normalizeBaseUri(String baseUrl) {
    final trimmed = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final uri = Uri.parse(trimmed);
    if (!uri.hasScheme || uri.host.isEmpty) {
      stderr.writeln('SUPABASE_URL non valido: $baseUrl');
      exit(64);
    }
    return uri;
  }

  static String _buildPath(String basePath, String child) {
    if (basePath.isEmpty || basePath == '/') {
      return '/$child';
    }
    if (basePath.endsWith('/')) {
      return '$basePath$child';
    }
    return '$basePath/$child';
  }
}

class _Args {
  _Args({
    required this.baseUrl,
    required this.anonKey,
    this.email,
    this.password,
    this.scenario = 'fetch-moon',
    this.vus = 5,
    this.durationSeconds = 30,
    this.pauseMinMs = 150,
    this.pauseMaxMs = 300,
    this.timeoutSeconds = 10,
    this.readLimit = '50',
    this.verbose = false,
    this.debugStackTraces = false,
    this.showHelp = false,
    this.keepData = false,
    this.loginReuseSession = true,
    this.loginRefreshEvery = 30,
  });

  factory _Args.parse(List<String> raw) {
    final env = Platform.environment;
    var baseUrl = env['SUPABASE_URL'] ?? '';
    var anonKey = env['SUPABASE_ANON_KEY'] ?? '';
    String? email = env['TEST_EMAIL'];
    String? password = env['TEST_PASSWORD'];
    var scenario = 'fetch-moon';
    var vus = 5;
    var durationSeconds = 30;
    var pauseMinMs = 150;
    var pauseMaxMs = 300;
    var timeoutSeconds = 10;
    var readLimit = '50';
    var verbose = false;
    var debugStack = false;
    var showHelp = false;
    var keepData = false;
    var loginReuseSession = true;
    var loginRefreshEvery = 30;

    for (final arg in raw) {
      if (arg == '--help' || arg == '-h') {
        showHelp = true;
        continue;
      }
      if (!arg.startsWith('--')) {
        stderr.writeln('Argomento non riconosciuto: $arg');
        continue;
      }
      final idx = arg.indexOf('=');
      final key = idx == -1 ? arg.substring(2) : arg.substring(2, idx);
      final value = idx == -1 ? '' : arg.substring(idx + 1);

      switch (key) {
        case 'url':
          baseUrl = value;
          break;
        case 'anon-key':
          anonKey = value;
          break;
        case 'email':
          email = value;
          break;
        case 'password':
          password = value;
          break;
        case 'scenario':
          scenario = value;
          break;
        case 'vus':
          vus = int.tryParse(value) ?? vus;
          break;
        case 'duration':
          durationSeconds = _parseDurationSeconds(value) ?? durationSeconds;
          break;
        case 'pause':
          final parsed = _parsePause(value);
          if (parsed != null) {
            pauseMinMs = parsed.item1;
            pauseMaxMs = parsed.item2;
          }
          break;
        case 'timeout':
          timeoutSeconds = int.tryParse(value) ?? timeoutSeconds;
          break;
        case 'read-limit':
          if (value.isNotEmpty) {
            readLimit = value;
          }
          break;
        case 'verbose':
          verbose = value.isEmpty ? true : value == 'true';
          break;
        case 'debug-stack':
          debugStack = value.isEmpty ? true : value == 'true';
          break;
        case 'keep-data':
          keepData = value.isEmpty ? true : value == 'true';
          break;
        case 'login-reuse-session':
          loginReuseSession = value.isEmpty ? true : value == 'true';
          break;
        case 'login-refresh-every':
          loginRefreshEvery = int.tryParse(value) ?? loginRefreshEvery;
          break;
        default:
          stderr.writeln('Opzione sconosciuta: --$key');
      }
    }

    if (baseUrl.isEmpty || anonKey.isEmpty) {
      stderr.writeln(
        'SUPABASE_URL e SUPABASE_ANON_KEY sono obbligatori (env o --url/--anon-key).',
      );
      exit(64);
    }

    if (loginRefreshEvery < 0) {
      loginRefreshEvery = 0;
    }

    return _Args(
      baseUrl: baseUrl,
      anonKey: anonKey,
      email: email,
      password: password,
      scenario: scenario,
      vus: vus,
      durationSeconds: durationSeconds,
      pauseMinMs: pauseMinMs,
      pauseMaxMs: pauseMaxMs,
      timeoutSeconds: timeoutSeconds,
      readLimit: readLimit,
      verbose: verbose,
      debugStackTraces: debugStack,
      showHelp: showHelp,
      keepData: keepData,
      loginReuseSession: loginReuseSession,
      loginRefreshEvery: loginRefreshEvery,
    );
  }

  final String baseUrl;
  final String anonKey;
  final String? email;
  final String? password;
  final String scenario;
  final int vus;
  final int durationSeconds;
  final int pauseMinMs;
  final int pauseMaxMs;
  final int timeoutSeconds;
  final String readLimit;
  final bool verbose;
  final bool debugStackTraces;
  final bool showHelp;
  final bool keepData;
  final bool loginReuseSession;
  final int loginRefreshEvery;

  _RunConfig toConfig() {
    return _RunConfig(
      baseUrl: baseUrl,
      anonKey: anonKey,
      email: email,
      password: password,
      scenario: scenario,
      vus: max(1, vus),
      duration: Duration(seconds: max(1, durationSeconds)),
      pauseMinMs: max(0, pauseMinMs),
      pauseMaxMs: max(pauseMaxMs, pauseMinMs),
      requestTimeout: Duration(seconds: max(1, timeoutSeconds)),
      readLimit: readLimit,
      verbose: verbose,
      debugStackTraces: debugStackTraces,
      keepData: keepData,
      loginReuseSession: loginReuseSession,
      loginRefreshEvery: loginRefreshEvery,
    );
  }
}

int? _parseDurationSeconds(String raw) {
  if (raw.isEmpty) return null;
  final lower = raw.toLowerCase();
  if (lower.endsWith('ms')) {
    final value = int.tryParse(lower.substring(0, lower.length - 2));
    return value == null ? null : (value / 1000).ceil();
  }
  if (lower.endsWith('s')) {
    return int.tryParse(lower.substring(0, lower.length - 1));
  }
  if (lower.endsWith('m')) {
    final minutes = int.tryParse(lower.substring(0, lower.length - 1));
    return minutes == null ? null : minutes * 60;
  }
  return int.tryParse(lower);
}

_Tuple<int, int>? _parsePause(String raw) {
  if (raw.isEmpty) return null;
  final parts = raw.split('-');
  if (parts.length == 1) {
    final value = int.tryParse(parts[0]);
    if (value == null) return null;
    return _Tuple(value, value);
  }
  if (parts.length == 2) {
    final min = int.tryParse(parts[0]);
    final max = int.tryParse(parts[1]);
    if (min == null || max == null) return null;
    if (max < min) {
      return _Tuple(max, min);
    }
    return _Tuple(min, max);
  }
  return null;
}

void _printUsage() {
  stdout.writeln('Supabase load test helper');
  stdout.writeln('Uso: dart run tool/supabase_load_test.dart [opzioni]\n');
  stdout.writeln('Opzioni:');
  stdout.writeln('  --scenario=<nome>        fetch-moon | login | draft-upsert | honoo-cycle');
  stdout.writeln('  --vus=<n>                utenti virtuali (default 5)');
  stdout.writeln('  --duration=<30s|2m>      durata test (default 30s)');
  stdout.writeln('  --pause=<min-max>        think time in ms (default 150-300)');
  stdout.writeln('  --timeout=<s>            timeout HTTP per richiesta (default 10)');
  stdout.writeln('  --read-limit=<n>         LIMIT usato negli scenari di sola lettura (default 50)');
  stdout.writeln('  --url=<https://...>      override SUPABASE_URL');
  stdout.writeln('  --anon-key=<key>         override SUPABASE_ANON_KEY');
  stdout.writeln('  --email=<user>           override TEST_EMAIL (solo scenari auth)');
  stdout.writeln('  --password=<pwd>         override TEST_PASSWORD');
  stdout.writeln('  --verbose[=true|false]   log errori immediati');
  stdout.writeln('  --debug-stack[=true]     stampa stack trace sugli errori (con verbose)');
  stdout.writeln('  --keep-data[=true]       non pulire le righe create (default false)');
  stdout.writeln('  --login-reuse-session    riusa la sessione tra le iterazioni (default true)');
  stdout.writeln('  --login-refresh-every=<n>   rinnova la sessione ogni n iterazioni (default 30)');
  stdout.writeln('  --help                   mostra questo aiuto');
}

class _Tuple<A, B> {
  _Tuple(this.item1, this.item2);
  final A item1;
  final B item2;
}
