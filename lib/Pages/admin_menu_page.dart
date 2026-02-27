import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Services/admin_service.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'package:honoo/Widgets/honoo_scaffold.dart';
import 'package:honoo/Widgets/loading_spinner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_page.dart';
import 'admin_moon_search_page.dart';

class AdminMenuPage extends StatefulWidget {
  const AdminMenuPage({super.key});

  @override
  State<AdminMenuPage> createState() => _AdminMenuPageState();
}

class _AdminMenuPageState extends State<AdminMenuPage> {
  final TextEditingController _emailController = TextEditingController();
  final AdminService _adminService = AdminService();
  late final Future<bool> _adminCheck;
  bool _invitingAll = false;
  bool _invitingEmail = false;
  bool _loadingEmails = false;
  bool _loadingVisits = false;
  bool _loadingMoonCounts = false;
  bool _loadingDailyCounts = false;
  List<String> _emailHints = const [];
  Map<DateTime, int> _visits = const {};
  Map<String, int> _moonCounts = const {'honoo': 0, 'hinoo': 0};
  Map<String, int> _dailyCounts = const {
    'chest_honoo': 0,
    'chest_hinoo': 0,
    'moon_honoo': 0,
    'moon_hinoo': 0,
    'reply_honoo': 0,
    'reply_hinoo': 0,
  };
  Timer? _statsRefreshTimer;
  RealtimeChannel? _statsChannel;


  @override
  void initState() {
    super.initState();
    _adminCheck = _adminService.isCurrentUserAdmin();
    _adminCheck.then((isAdmin) {
      if (isAdmin) {
        _loadEmailHints();
        _loadVisits();
        _loadMoonCounts();
        _loadDailyCounts();
        _subscribeStats();
        _statsRefreshTimer = Timer.periodic(
          const Duration(seconds: 30),
          (_) {
            _loadVisits();
            _loadMoonCounts();
            _loadDailyCounts();
          },
        );
      }
    });
  }

  @override
  void dispose() {
    _statsRefreshTimer?.cancel();
    _statsChannel?.unsubscribe();
    _emailController.dispose();
    super.dispose();
  }

  void _subscribeStats() {
    if (_statsChannel != null) return;
    _statsChannel = SupabaseProvider.client.channel('admin-stats');
    void refresh(dynamic _, [dynamic __]) {
      _loadVisits();
      _loadMoonCounts();
      _loadDailyCounts();
    }

    _statsChannel!
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(event: '*', schema: 'public', table: 'honoo'),
          refresh,
        )
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(event: '*', schema: 'public', table: 'hinoo'),
          refresh,
        )
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(event: '*', schema: 'public', table: 'site_visits'),
          refresh,
        );
    _statsChannel!.subscribe();
  }

  Future<void> _loadEmailHints() async {
    if (_loadingEmails) return;
    setState(() => _loadingEmails = true);
    try {
      final emails = await _adminService.fetchUserEmails();
      if (!mounted) return;
      setState(() => _emailHints = emails);
    } finally {
      if (mounted) setState(() => _loadingEmails = false);
    }
  }

  Future<void> _loadVisits() async {
    if (_loadingVisits) return;
    setState(() => _loadingVisits = true);
    try {
      final visits = await _adminService.fetchRecentVisits();
      if (!mounted) return;
      setState(() => _visits = visits);
    } finally {
      if (mounted) setState(() => _loadingVisits = false);
    }
  }

  Future<void> _loadMoonCounts() async {
    if (_loadingMoonCounts) return;
    setState(() => _loadingMoonCounts = true);
    try {
      final counts = await _adminService.fetchTodayMoonCounts();
      if (!mounted) return;
      setState(() => _moonCounts = counts);
    } finally {
      if (mounted) setState(() => _loadingMoonCounts = false);
    }
  }

  Future<void> _loadDailyCounts() async {
    if (_loadingDailyCounts) return;
    setState(() => _loadingDailyCounts = true);
    try {
      final counts = await _adminService.fetchDailyContentCounts();
      if (!mounted) return;
      setState(() => _dailyCounts = counts);
    } finally {
      if (mounted) setState(() => _loadingDailyCounts = false);
    }
  }

  Future<void> _inviteAll() async {
    if (_invitingAll) return;
    setState(() => _invitingAll = true);
    try {
      final user = SupabaseProvider.client.auth.currentUser;
      if (user == null) {
        throw Exception('Utente non autenticato.');
      }
      final users = await _adminService.fetchAllUsersWithEmails();
      final count = await _adminService.inviteUsers(
        adminUid: user.id,
        userIds: users.map((u) => u.authUserId).toList(),
        userEmails: {
          for (final u in users)
            if ((u.email ?? '').isNotEmpty) u.authUserId: u.email!,
        },
      );
      if (!mounted) return;
      final message = count == 0
          ? 'Nessun nuovo invito da inviare.'
          : 'Inviti inviati: $count.';
      showHonooToast(context, message: message);
    } catch (e) {
      if (!mounted) return;
      showHonooToast(context, message: 'Errore inviti: $e');
    } finally {
      if (mounted) setState(() => _invitingAll = false);
    }
  }

  Future<void> _inviteByEmail() async {
    if (_invitingEmail) return;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showHonooToast(context, message: 'Inserisci una email.');
      return;
    }
    setState(() => _invitingEmail = true);
    try {
      final user = SupabaseProvider.client.auth.currentUser;
      if (user == null) {
        throw Exception('Utente non autenticato.');
      }
      final target = await _adminService.findUserByEmail(email);
      if (target == null) {
        final inserted = await _adminService.inviteByEmailOnly(
          adminUid: user.id,
          email: email,
        );
        if (!mounted) return;
        showHonooToast(
          context,
          message: inserted ? 'Invito inviato.' : 'Invito già presente.',
        );
        return;
      }
      final hasCasa = await _adminService.hasCasaForUser(target.authUserId);
      final hasCampanello =
          await _adminService.hasCampanelloForUser(target.authUserId);
      if (hasCasa || hasCampanello) {
        if (!mounted) return;
        showHonooToast(
          context,
          message: 'Utente già con casa o campanello.',
        );
        return;
      }
      final inserted = await _adminService.inviteUsers(
        adminUid: user.id,
        userIds: [target.authUserId],
        userEmails: {
          if ((target.email ?? '').isNotEmpty)
            target.authUserId: target.email!,
        },
      );
      if (!mounted) return;
      if (inserted == 0) {
        showHonooToast(context, message: 'Invito già presente.');
      } else {
        showHonooToast(context, message: 'Invito inviato.');
      }
    } catch (e) {
      if (!mounted) return;
      showHonooToast(context, message: 'Errore invito: $e');
    } finally {
      if (mounted) setState(() => _invitingEmail = false);
    }
  }

  void _redirectHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      hintText: 'Email utente',
      hintStyle: GoogleFonts.lora(color: Colors.white70, fontSize: 16),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white60),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );

    return FutureBuilder<bool>(
      future: _adminCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const HonooScaffold(
            body: Center(child: LoadingSpinner()),
          );
        }

        final isAdmin = snapshot.data == true;
        if (!isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _redirectHome();
          });
          return const SizedBox.shrink();
        }

        return HonooScaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Menu Admin',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.arvo(
                        color: HonooColor.onBackground,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Invita gli utenti a creare la loro casa.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        color: HonooColor.onBackground.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Ricerca Luna (admin)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminMoonSearchPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Cerca su Luna (admin)',
                        style: GoogleFonts.libreFranklin(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _invitingAll ? null : _inviteAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _invitingAll
                          ? const LoadingSpinner(color: Colors.black)
                          : Text(
                              'Invita tutti gli utenti',
                              style: GoogleFonts.libreFranklin(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Invita un utente per email',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.arvo(
                        color: HonooColor.onBackground,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Autocomplete<String>(
                      optionsBuilder: (value) {
                        if (value.text.trim().isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        final query = value.text.toLowerCase();
                        return _emailHints.where(
                            (email) => email.toLowerCase().contains(query));
                      },
                      onSelected: (selection) {
                        _emailController.text = selection;
                      },
                      fieldViewBuilder: (
                        context,
                        textController,
                        focusNode,
                        onFieldSubmitted,
                      ) {
                        if (textController.text != _emailController.text) {
                          textController.text = _emailController.text;
                          textController.selection =
                              TextSelection.collapsed(
                            offset: textController.text.length,
                          );
                        }
                        return TextField(
                          controller: textController,
                          focusNode: focusNode,
                          keyboardType: TextInputType.emailAddress,
                          textAlign: TextAlign.center,
                          style:
                              GoogleFonts.lora(color: Colors.white, fontSize: 16),
                          cursorColor: Colors.white,
                          decoration: inputDecoration.copyWith(
                            suffixIcon: _loadingEmails
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            _emailController.text = value;
                          },
                        );
                      },
                      optionsViewBuilder:
                          (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topCenter,
                          child: Material(
                            color: Colors.black.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxHeight: 220, maxWidth: 420),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      option,
                                      style: GoogleFonts.lora(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _invitingEmail ? null : _inviteByEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _invitingEmail
                          ? const LoadingSpinner(color: Colors.black)
                          : Text(
                              'Invita utente',
                              style: GoogleFonts.libreFranklin(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Visite',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.arvo(
                        color: HonooColor.onBackground,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _loadingVisits
                        ? const Center(child: LoadingSpinner())
                        : _VisitsSummary(visits: _visits),
                    const SizedBox(height: 24),
                    Text(
                      'Luna oggi',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.arvo(
                        color: HonooColor.onBackground,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _loadingMoonCounts
                        ? const Center(child: LoadingSpinner())
                        : _MoonCountsSummary(counts: _moonCounts),
                    const SizedBox(height: 24),
                    Text(
                      'Oggi',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.arvo(
                        color: HonooColor.onBackground,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _loadingDailyCounts
                        ? const Center(child: LoadingSpinner())
                        : _DailyCountsSummary(counts: _dailyCounts),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VisitsSummary extends StatelessWidget {
  const _VisitsSummary({required this.visits});

  final Map<DateTime, int> visits;

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final DateTime day0 = DateTime(today.year, today.month, today.day);
    final DateTime day1 = day0.subtract(const Duration(days: 1));
    final DateTime day2 = day0.subtract(const Duration(days: 2));

    final rows = [
      _VisitRow(label: 'Oggi', count: visits[day0] ?? 0),
      _VisitRow(label: 'Ieri', count: visits[day1] ?? 0),
      _VisitRow(label: "L'altro ieri", count: visits[day2] ?? 0),
    ];

    return Column(
      children: rows,
    );
  }
}

class _VisitRow extends StatelessWidget {
  const _VisitRow({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '$label: $count',
        textAlign: TextAlign.center,
        style: GoogleFonts.lora(
          color: HonooColor.onBackground.withOpacity(0.85),
          fontSize: 16,
        ),
      ),
    );
  }
}

class _MoonCountsSummary extends StatelessWidget {
  const _MoonCountsSummary({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final honoo = counts['honoo'] ?? 0;
    final hinoo = counts['hinoo'] ?? 0;
    return Column(
      children: [
        _RollingCount(label: 'honoo', count: honoo),
        _RollingCount(label: 'hinoo', count: hinoo),
      ],
    );
  }
}

class _RollingCount extends StatelessWidget {
  const _RollingCount({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.lora(
              color: HonooColor.onBackground.withOpacity(0.85),
              fontSize: 16,
            ),
          ),
          _RollingNumber(value: count),
        ],
      ),
    );
  }
}

class _RollingNumber extends StatelessWidget {
  const _RollingNumber({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, -0.6),
          end: Offset.zero,
        ).animate(animation);
        return ClipRect(
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: Text(
        '$value',
        key: ValueKey(value),
        style: GoogleFonts.libreFranklin(
          color: HonooColor.onBackground,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DailyCountsSummary extends StatelessWidget {
  const _DailyCountsSummary({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RollingCount(
          label: 'honoo nello scrigno',
          count: counts['chest_honoo'] ?? 0,
        ),
        _RollingCount(
          label: 'hinoo nello scrigno',
          count: counts['chest_hinoo'] ?? 0,
        ),
        _RollingCount(
          label: 'honoo sulla luna',
          count: counts['moon_honoo'] ?? 0,
        ),
        _RollingCount(
          label: 'hinoo sulla luna',
          count: counts['moon_hinoo'] ?? 0,
        ),
        _RollingCount(
          label: 'honoo in risposta',
          count: counts['reply_honoo'] ?? 0,
        ),
        _RollingCount(
          label: 'hinoo in risposta',
          count: counts['reply_hinoo'] ?? 0,
        ),
      ],
    );
  }
}
