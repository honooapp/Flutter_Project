import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Services/house_invite_service.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'package:honoo/Widgets/honoo_scaffold.dart';
import 'package:honoo/Widgets/loading_spinner.dart';

import 'home_page.dart';

class CasaBuilderPage extends StatefulWidget {
  const CasaBuilderPage({super.key, required this.campanelloHinooId});

  final String campanelloHinooId;

  @override
  State<CasaBuilderPage> createState() => _CasaBuilderPageState();
}

class _CasaBuilderPageState extends State<CasaBuilderPage> {
  final HouseInviteService _inviteService = HouseInviteService();
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _createCasa();
  }

  Future<void> _createCasa() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final user = SupabaseProvider.client.auth.currentUser;
      if (user == null) {
        throw Exception('Utente non autenticato.');
      }

      final existing = await SupabaseProvider.client
          .from('case')
          .select('id')
          .eq('owner_id', user.id)
          .limit(1);
      if (existing is List && existing.isEmpty) {
        await SupabaseProvider.client.from('case').insert({
          'owner_id': user.id,
          'campanello_hinoo_id': widget.campanelloHinooId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      try {
        await _inviteService.markInvitesAccepted(user.id);
      } catch (_) {}

      if (!mounted) return;
      showHonooToast(context, message: 'Casa creata.');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Errore creazione casa: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HonooScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sto costruendo la tua casa…',
                textAlign: TextAlign.center,
                style: GoogleFonts.arvo(
                  color: HonooColor.onBackground,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (_isSaving) const LoadingSpinner() else const SizedBox.shrink(),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    color: HonooColor.onBackground.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _createCasa,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Riprova',
                    style: GoogleFonts.libreFranklin(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
