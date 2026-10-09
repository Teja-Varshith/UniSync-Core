/// Firestore maps in `exam_data` are keyed by numeric strings ("1", "2", …,
/// "10"). Sorting them as strings would put "10" before "2".
int compareNumericKeys(String a, String b) {
  final na = num.tryParse(a.trim());
  final nb = num.tryParse(b.trim());
  if (na != null && nb != null) return na.compareTo(nb);
  if (na != null) return -1;
  if (nb != null) return 1;
  return a.compareTo(b);
}

/// Returns the entries of [map] sorted by numeric key. Non-map input yields
/// an empty list so malformed documents never throw.
List<MapEntry<String, dynamic>> sortedNumericEntries(Object? map) {
  if (map is! Map) return const [];
  final entries = map.entries
      .map((e) => MapEntry<String, dynamic>(e.key.toString(), e.value))
      .toList()
    ..sort((a, b) => compareNumericKeys(a.key, b.key));
  return entries;
}
