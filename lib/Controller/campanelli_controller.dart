import 'package:flutter/foundation.dart';

import '../Entities/campanelli_entry.dart';
import '../Entities/hinoo.dart';
import '../Services/campanelli_repository.dart';

@immutable
class CampanelliLoadState {
  const CampanelliLoadState({
    this.entries = const [],
    this.shareRows = const [],
    this.ownedHinooIds = const [],
    this.isLoading = false,
    this.error,
  });

  final List<CampanelliEntry> entries;
  final List<dynamic> shareRows;
  final List<String> ownedHinooIds;
  final bool isLoading;
  final Object? error;

  CampanelliLoadState copyWith({
    List<CampanelliEntry>? entries,
    List<dynamic>? shareRows,
    List<String>? ownedHinooIds,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) {
    return CampanelliLoadState(
      entries: entries ?? this.entries,
      shareRows: shareRows ?? this.shareRows,
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
      final ownerByHinooId = <String, String>{};
      final houseByHinooId = <String, Map<String, dynamic>>{};
      final hinooIds = <String>[];
      final ownedHinooIds = <String>[];
      for (final row in houseRows) {
        if (row is! Map) continue;
        final hinooId = row['campanello_hinoo_id']?.toString() ?? '';
        final ownerId = row['owner_id']?.toString() ?? '';
        if (hinooId.isEmpty || ownerId.isEmpty) continue;
        ownerByHinooId[hinooId] = ownerId;
        houseByHinooId[hinooId] = Map<String, dynamic>.from(row);
        hinooIds.add(hinooId);
        if (ownerId == userId) ownedHinooIds.add(hinooId);
      }

      final shareRows = await _repository.fetchShareSettingsRows(hinooIds);
      final hinooRows = await _repository.fetchHinooRows(hinooIds);
      final entries = <CampanelliEntry>[];
      for (final row in hinooRows) {
        if (row is! Map) continue;
        final id = row['id']?.toString() ?? '';
        final pages = row['pages'];
        if (id.isEmpty || pages is! List || pages.isEmpty) continue;
        final firstPage = pages.first;
        if (firstPage is! Map) continue;
        final ownerId = ownerByHinooId[id];
        if (ownerId == null) continue;
        final slide = HinooSlide.fromJson(firstPage.cast<String, dynamic>());
        final text = slide.text.trim();
        if (text.isEmpty) continue;
        final houseRow = houseByHinooId[id] ?? const <String, dynamic>{};
        entries.add(CampanelliEntry(
          hinooId: id,
          ownerId: ownerId,
          text: text,
          campanelloBackgroundUrl: slide.backgroundImage,
          houseImageUrl: houseRow['house_image_url']?.toString(),
          bgTransform: _parseTransform(houseRow['bg_transform']),
          bgScale: slide.bgScale,
          bgOffsetX: slide.bgOffsetX,
          bgOffsetY: slide.bgOffsetY,
        ));
      }
      _publish(CampanelliLoadState(
        entries: List<CampanelliEntry>.unmodifiable(entries),
        shareRows: List<dynamic>.unmodifiable(shareRows),
        ownedHinooIds: List<String>.unmodifiable(ownedHinooIds),
      ));
    } catch (error) {
      _publish(CampanelliLoadState(error: error));
    }
    return _state;
  }

  static List<double>? _parseTransform(dynamic raw) {
    if (raw is! List) return null;
    try {
      return List<double>.unmodifiable(
        raw.map((value) => (value as num).toDouble()),
      );
    } catch (_) {
      return null;
    }
  }

  void _publish(CampanelliLoadState value) {
    _state = value;
    notifyListeners();
  }
}
