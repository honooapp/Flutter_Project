import 'dart:async';

import 'package:flutter/material.dart';
import 'package:honoo/Pages/new_hinoo_page.dart';
import 'package:honoo/Services/house_invite_service.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GlobalInviteListener extends StatefulWidget {
  const GlobalInviteListener({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<GlobalInviteListener> createState() => _GlobalInviteListenerState();
}

class _GlobalInviteListenerState extends State<GlobalInviteListener> {
  final HouseInviteService _inviteService = HouseInviteService();
  StreamSubscription<AuthState>? _authSub;
  Timer? _inviteRefreshTimer;
  bool _checkingInviteFlow = false;
  bool _dialogOpen = false;
  RealtimeChannel? _inviteChannel;
  String? _inviteChannelUserId;
  RealtimeChannel? _inviteEmailChannel;
  String? _inviteChannelEmail;
  DateTime? _lastInviteToastAt;

  @override
  void initState() {
    super.initState();
    _authSub = SupabaseProvider.client.auth.onAuthStateChange.listen((state) {
      _handleAuthChange(state.session);
    });
    _handleAuthChange(SupabaseProvider.client.auth.currentSession);
  }

  @override
  void dispose() {
    _inviteRefreshTimer?.cancel();
    _inviteChannel?.unsubscribe();
    _inviteEmailChannel?.unsubscribe();
    _authSub?.cancel();
    super.dispose();
  }

  void _handleAuthChange(Session? session) {
    _inviteRefreshTimer?.cancel();
    _inviteChannel?.unsubscribe();
    _inviteEmailChannel?.unsubscribe();
    _inviteChannel = null;
    _inviteEmailChannel = null;
    _inviteChannelUserId = null;
    _inviteChannelEmail = null;
    _dialogOpen = false;
    if (session == null) return;

    _subscribeInviteChannel(session.user.id);
    final email = session.user.email;
    if (email != null && email.isNotEmpty) {
      _subscribeInviteEmailChannel(email);
    }
    _inviteRefreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _checkInviteFlow(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInviteFlow());
  }

  void _subscribeInviteChannel(String userId) {
    if (_inviteChannel != null && _inviteChannelUserId == userId) return;
    _inviteChannel?.unsubscribe();
    _inviteChannelUserId = userId;
    _inviteChannel = SupabaseProvider.client.channel('house-invites-$userId');
    _inviteChannel!
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: '*',
            schema: 'public',
            table: 'house_invites',
            filter: 'user_id=eq.$userId',
          ),
          _handleInviteChange,
        )
        .subscribe();
  }

  void _subscribeInviteEmailChannel(String email) {
    if (_inviteEmailChannel != null && _inviteChannelEmail == email) return;
    _inviteEmailChannel?.unsubscribe();
    _inviteChannelEmail = email;
    _inviteEmailChannel =
        SupabaseProvider.client.channel('house-invites-email-$email');
    _inviteEmailChannel!
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: '*',
            schema: 'public',
            table: 'house_invites',
            filter: 'email=eq.$email',
          ),
          _handleInviteChange,
        )
        .subscribe();
  }

  void _handleInviteChange(dynamic payload, [dynamic _]) {
    _checkInviteFlow();
    final eventType = payload is Map
        ? (payload['eventType'] ?? payload['event_type'])
        : null;
    final event = eventType?.toString().toLowerCase();
    if (event != null && event != 'insert' && event != 'update') {
      return;
    }
    final now = DateTime.now();
    if (_lastInviteToastAt != null &&
        now.difference(_lastInviteToastAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastInviteToastAt = now;
    final context = widget.navigatorKey.currentContext;
    if (context == null) return;
    showHonooToast(
      context,
      message: 'Invito ricevuto',
      duration: const Duration(milliseconds: 2000),
    );
  }

  Future<void> _checkInviteFlow() async {
    if (_checkingInviteFlow || _dialogOpen) return;
    _checkingInviteFlow = true;

    final user = SupabaseProvider.client.auth.currentUser;
    if (user == null) {
      _checkingInviteFlow = false;
      return;
    }

    final email = user.email;
    if (email != null && email.isNotEmpty) {
      try {
        await _inviteService.syncInvitesForEmail(email);
      } catch (_) {}
    }

    try {
      final hasCasa = await _inviteService.hasCasa(user.id);
      if (hasCasa) {
        return;
      }

      var hasInvite = await _inviteService.hasPendingOrAcceptedInvite(user.id);
      if (!hasInvite && email != null && email.isNotEmpty) {
        try {
          await _inviteService.syncInvitesForEmail(email);
        } catch (_) {}
        hasInvite = await _inviteService.hasPendingOrAcceptedInvite(user.id);
      }
      if (!hasInvite) {
        return;
      }

      final bool? accepted = await _showCasaInviteDialog();
      if (accepted != true) {
        await _inviteService.markInvitesDeclined(user.id);
        return;
      }

      final navigator = widget.navigatorKey.currentState;
      if (navigator == null) return;
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => const NewHinooPage(isCampanello: true),
        ),
      );
    } catch (_) {
    } finally {
      _checkingInviteFlow = false;
    }
  }

  Future<bool?> _showCasaInviteDialog() async {
    final context = widget.navigatorKey.currentContext;
    if (context == null) return null;
    _dialogOpen = true;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => HonooDialogShell(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Complimenti!',
                style: HonooDialogStyles.title(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ecco la tua casa sull\'Isola, crea il tuo campanello!',
                style: HonooDialogStyles.body(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Crea il campanello',
                        style: HonooDialogStyles.primaryAction(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                      child: Text(
                        'Non ora',
                        style: HonooDialogStyles.tertiaryAction(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    _dialogOpen = false;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
