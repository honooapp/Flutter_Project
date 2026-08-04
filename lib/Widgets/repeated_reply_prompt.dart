import 'package:flutter/material.dart';

import '../Services/reply_conversation_service.dart';
import 'honoo_dialogs.dart';

/// Restituisce il conversation_id da usare. Se non esiste una risposta
/// precedente senza contro-risposta mantiene il thread naturale del contenuto.
Future<String?> chooseReplyConversation({
  required BuildContext context,
  required String parentId,
  required String defaultConversationId,
  required String contentName,
  ReplyConversationService? service,
}) async {
  final resolver = service ?? ReplyConversationService();
  final previous = await resolver.findPreviousUnansweredReply(
    parentId: parentId,
  );
  if (!context.mounted) return null;
  if (previous == null) return defaultConversationId;

  final createNew = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => HonooConfirmDialog(
      title: 'Hai già risposto a questo $contentName.',
      message: 'Vuoi che questa risposta crei una nuova conversazione?',
      confirmLabel: 'Sì',
      cancelLabel: 'No',
    ),
  );
  if (!context.mounted || createNew == null) return null;
  return createNew ? resolver.createConversationId() : previous.conversationId;
}
