/// FNV-1a, 32-bit. Must match the web app's hash so a subject gets the same
/// tone and art on every platform.
int fnv1a32(String input) {
  var hash = 0x811c9dc5;
  // The web hashes UTF-16 code units (`charCodeAt`), so do the same here.
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}
