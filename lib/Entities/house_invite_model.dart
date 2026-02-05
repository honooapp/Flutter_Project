enum HouseInviteStatus {
  pending,
  accepted,
  declined,
}

class HouseInviteModel {
  final String id;
  final String invitedBy;
  final String? userId;
  final String? email;
  final HouseInviteStatus status;
  final DateTime createdAt;

  const HouseInviteModel({
    required this.id,
    required this.invitedBy,
    required this.status,
    required this.createdAt,
    this.userId,
    this.email,
  });

  factory HouseInviteModel.fromJson(Map<String, dynamic> json, String id) {
    return HouseInviteModel(
      id: id,
      invitedBy: json['invited_by'] as String? ?? '',
      userId: json['user_id'] as String?,
      email: json['email'] as String?,
      status: HouseInviteStatus.values.firstWhere(
        (value) => value.name == (json['status'] as String? ?? 'pending'),
        orElse: () => HouseInviteStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invited_by': invitedBy,
      'user_id': userId,
      'email': email,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
