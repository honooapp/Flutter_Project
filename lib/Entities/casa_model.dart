class CasaModel {
  final String id;
  final String ownerId;
  final String campanelloHinooId;
  final String? houseImageUrl;
  final List<double>? bgTransform;
  final DateTime createdAt;

  const CasaModel({
    required this.id,
    required this.ownerId,
    required this.campanelloHinooId,
    this.houseImageUrl,
    this.bgTransform,
    required this.createdAt,
  });

  factory CasaModel.fromJson(Map<String, dynamic> json, String id) {
    return CasaModel(
      id: id,
      ownerId: json['owner_id'] as String? ?? '',
      campanelloHinooId: json['campanello_hinoo_id'] as String? ?? '',
      houseImageUrl: json['house_image_url'] as String?,
      bgTransform: _parseTransform(json['bg_transform']),
      createdAt: DateTime.parse(json['created_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'owner_id': ownerId,
      'campanello_hinoo_id': campanelloHinooId,
      'house_image_url': houseImageUrl,
      'bg_transform': bgTransform,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static List<double>? _parseTransform(dynamic raw) {
    if (raw is! List) return null;
    try {
      return raw.map((e) => (e as num).toDouble()).toList();
    } catch (_) {
      return null;
    }
  }
}
