import 'pending_knock.dart';

sealed class CampanelliRealtimeEvent {
  const CampanelliRealtimeEvent();
}

final class CampanelliPendingKnockReceived extends CampanelliRealtimeEvent {
  const CampanelliPendingKnockReceived(this.knock);

  final PendingKnock knock;
}

final class CampanelliPendingKnockRemoved extends CampanelliRealtimeEvent {
  const CampanelliPendingKnockRemoved(this.knockId);

  final String knockId;
}

final class CampanelliAccessGranted extends CampanelliRealtimeEvent {
  const CampanelliAccessGranted(this.targetTag);

  final String targetTag;
}
