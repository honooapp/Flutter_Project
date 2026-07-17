/// Identifica in modo coerente il padre, il thread e il destinatario di una
/// risposta, indipendentemente dal fatto che padre/risposta siano honoo o hinoo.
class ConversationLink {
  const ConversationLink({
    required this.replyTo,
    required this.conversationId,
    required this.recipientId,
  });

  final String replyTo;
  final String conversationId;
  final String recipientId;

  factory ConversationLink.fromParent({
    required String parentId,
    required String? parentConversationId,
    required String recipientId,
  }) {
    if (parentId.isEmpty) {
      throw ArgumentError.value(parentId, 'parentId', 'non può essere vuoto');
    }
    if (recipientId.isEmpty) {
      throw ArgumentError.value(
        recipientId,
        'recipientId',
        'non può essere vuoto',
      );
    }
    return ConversationLink(
      replyTo: parentId,
      conversationId: parentConversationId?.isNotEmpty == true
          ? parentConversationId!
          : parentId,
      recipientId: recipientId,
    );
  }
}
