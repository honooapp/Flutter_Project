import 'package:flutter/material.dart';

import '../Services/content_feed_service.dart';
import '../Services/reply_system_notification.dart';
import 'honoo_dialogs.dart';

class ConversationNotificationPrompt {
  const ConversationNotificationPrompt._();

  static Future<bool> shouldOfferForFirstConversation(
    String userId, {
    ContentFeedService contentFeedService = const ContentFeedService(),
  }) async {
    try {
      return !await contentFeedService.hasConversationRoots(userId);
    } catch (_) {
      // Il controllo non deve mai impedire il salvataggio del contenuto.
      return false;
    }
  }

  static Future<void> show(
    BuildContext context, {
    ReplySystemNotification? notification,
  }) async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const HonooConfirmDialog(
        title: 'Vuoi attivare le notifiche?',
        message:
            'Ricevi un avviso quando arriva una nuova risposta nelle tue conversazioni.',
        confirmLabel: 'Attiva notifiche',
        cancelLabel: 'Non ora',
      ),
    );
    if (accepted != true || !context.mounted) return;

    final systemNotification =
        notification ?? ReplySystemNotification.platform();
    final permission = await systemNotification.requestPermission();
    if (!context.mounted) return;

    final message = switch (permission) {
      ReplyNotificationPermission.granted => 'Notifiche attivate.',
      ReplyNotificationPermission.denied =>
        'Notifiche bloccate: puoi abilitarle nelle impostazioni del dispositivo.',
      ReplyNotificationPermission.unsupported =>
        'Le notifiche non sono supportate su questo dispositivo.',
      ReplyNotificationPermission.prompt =>
        'Conferma il permesso nelle impostazioni del dispositivo.',
    };
    showHonooToast(context, message: message);
  }
}
