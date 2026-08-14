import 'package:flutter/material.dart';

import '../Pages/email_login_page.dart';
import 'supabase_provider.dart';

class AuthNavigationService {
  const AuthNavigationService._();

  static Future<bool> ensureLoggedIn(BuildContext context) async {
    if (SupabaseProvider.client.auth.currentUser != null) return true;

    final bool? loggedIn = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const EmailLoginPage()));

    return loggedIn == true && SupabaseProvider.client.auth.currentUser != null;
  }
}
