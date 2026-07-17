import 'package:flutter/foundation.dart';

import '../Services/campanelli_repository.dart';

@immutable
class CampanelliLoadState {
  const CampanelliLoadState({
    this.houseRows = const [],
    this.shareRows = const [],
    this.hinooRows = const [],
    this.ownedHinooIds = const [],
    this.isLoading = false,
    this.error,
  });

  final List<dynamic> houseRows;
  final List<dynamic> shareRows;
  final List<dynamic> hinooRows;
  final List<String> ownedHinooIds;
  final bool isLoading;
  final Object? error;

  CampanelliLoadState copyWith({
    List<dynamic>? houseRows,
    List<dynamic>? shareRows,
    List<dynamic>? hinooRows,
    List<String>? ownedHinooIds,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) {
    return CampanelliLoadState(
      houseRows: houseRows ?? this.houseRows,
      shareRows: shareRows ?? this.shareRows,
      hinooRows: hinooRows ?? this.hinooRows,
      ownedHinooIds: ownedHinooIds ?? this.ownedHinooIds,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class CampanelliController extends ChangeNotifier {
  CampanelliController({CampanelliDataRepository? repository})
      : _repository = repository ?? CampanelliDataRepository();

  final CampanelliDataRepository _repository;
  CampanelliLoadState _state = const CampanelliLoadState();

  CampanelliLoadState get state => _state;

  Future<CampanelliLoadState> load(String userId) async {
    if (_state.isLoading) return _state;
    _publish(_state.copyWith(isLoading: true, clearError: true));

    try {
      final houseRows = await _repository.fetchHouseRows();
      final hinooIds = <String>[];
      final ownedHinooIds = <String>[];
      for (final row in houseRows) {
        if (row is! Map) continue;
        final hinooId = row['campanello_hinoo_id']?.toString() ?? '';
        final ownerId = row['owner_id']?.toString() ?? '';
        if (hinooId.isEmpty || ownerId.isEmpty) continue;
        hinooIds.add(hinooId);
        if (ownerId == userId) ownedHinooIds.add(hinooId);
      }

      final shareRows = await _repository.fetchShareSettingsRows(hinooIds);
      final hinooRows = await _repository.fetchHinooRows(hinooIds);
      _publish(CampanelliLoadState(
        houseRows: List<dynamic>.unmodifiable(houseRows),
        shareRows: List<dynamic>.unmodifiable(shareRows),
        hinooRows: List<dynamic>.unmodifiable(hinooRows),
        ownedHinooIds: List<String>.unmodifiable(ownedHinooIds),
      ));
    } catch (error) {
      _publish(CampanelliLoadState(error: error));
    }
    return _state;
  }

  void _publish(CampanelliLoadState value) {
    _state = value;
    notifyListeners();
  }
}
