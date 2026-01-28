class CasaModel {
  final String id;
  final String ownerId;
  final String campanelloHinooId;
  final DateTime createdAt;

  const CasaModel({
    required this.id,
    required this.ownerId,
    required this.campanelloHinooId,
    required this.createdAt,
  });

  factory CasaModel.fromJson(Map<String, dynamic> json, String id) {
    return CasaModel(
      id: id,
      ownerId: json['owner_id'] as String? ?? '',
      campanelloHinooId: json['campanello_hinoo_id'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'owner_id': ownerId,
      'campanello_hinoo_id': campanelloHinooId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
