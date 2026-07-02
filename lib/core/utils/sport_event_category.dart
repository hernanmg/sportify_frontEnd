import 'package:sportify_amateur/models/sport_event.dart';

extension SportEventCategoryFilter on SportEvent {
  List<int> get categoryIdsFromMetadata {
    final meta = metadata;
    if (meta == null) return [];
    final rawList = meta['categoryIds'];
    if (rawList is List) {
      return rawList
          .map((e) => e is int ? e : int.tryParse(e.toString()))
          .whereType<int>()
          .toList();
    }
    final single = meta['categoryId'];
    if (single is int) return [single];
    if (single != null) {
      final parsed = int.tryParse(single.toString());
      if (parsed != null) return [parsed];
    }
    return [];
  }

  bool matchesCategoryFilter(int? categoryId) {
    if (categoryId == null) return true;
    final ids = categoryIdsFromMetadata;
    if (ids.isEmpty) return true;
    return ids.contains(categoryId);
  }
}
