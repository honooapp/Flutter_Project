import 'package:flutter/material.dart';

import '../Services/reply_system_notification.dart';
import 'honoo_dialogs.dart';

class ReplyNotificationButton extends StatefulWidget {
  const ReplyNotificationButton({super.key, this.notification});

  final ReplySystemNotification? notification;

  @override
  State<ReplyNotificationButton> createState() =>
      _ReplyNotificationButtonState();
}

class _ReplyNotificationButtonState extends State<ReplyNotificationButton> {
  late final ReplySystemNotification _notification =
      widget.notification ?? ReplySystemNotification.platform();
  late ReplyNotificationPermission _permission = _notification.permission;

  Future<void> _configure() async {
    final permission = await _notification.requestPermission();
    if (!mounted) return;
    setState(() => _permission = permission);
    final message = switch (permission) {
      ReplyNotificationPermission.granted => 'Notifiche attivate.',
      ReplyNotificationPermission.denied =>
        'Notifiche bloccate: abilìtale nelle impostazioni del browser.',
      ReplyNotificationPermission.unsupported =>
        'Le notifiche di sistema non sono supportate su questo dispositivo.',
      ReplyNotificationPermission.prompt =>
        'Conferma il permesso nelle impostazioni del browser.',
    };
    showHonooToast(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _permission == ReplyNotificationPermission.granted;
    return IconButton(
      key: const Key('configure_reply_notifications'),
      onPressed: _configure,
      icon: Icon(
        enabled ? Icons.notifications_active : Icons.notifications_none,
        color: Colors.white,
      ),
      tooltip:
          enabled ? 'Notifiche risposte attive' : 'Attiva notifiche risposte',
    );
  }
}
