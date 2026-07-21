/// طريقة عرض صور المعرض (حتى 4 صور) داخل قسم "صور إضافية".
enum GalleryLayout { grid, stacked, sideBySide }

extension GalleryLayoutLabel on GalleryLayout {
  String get arabicLabel {
    switch (this) {
      case GalleryLayout.grid:
        return 'شبكة (2×2)';
      case GalleryLayout.stacked:
        return 'فوق بعض (سلايدر)';
      case GalleryLayout.sideBySide:
        return 'جنب بعض (تمرير أفقي)';
    }
  }

  static GalleryLayout fromKey(String key) =>
      GalleryLayout.values.firstWhere((e) => e.name == key, orElse: () => GalleryLayout.sideBySide);
}
