import 'package:cloud_firestore/cloud_firestore.dart';

/// Documents under `app_config` that drive admin access and feature flags.
///
/// Both are single documents rather than collections: they are read on every
/// launch by every user, so keeping them to one cheap document read matters.
class AdminConfigRepository {
  AdminConfigRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const collection = 'app_config';
  static const accessDoc = 'access';
  static const featuresDoc = 'features';

  DocumentReference<Map<String, dynamic>> get _access =>
      _firestore.collection(collection).doc(accessDoc);

  DocumentReference<Map<String, dynamic>> get _features =>
      _firestore.collection(collection).doc(featuresDoc);

  /// Live feature flags. A stream so a flag flipped in the panel reaches
  /// every open app without a restart.
  Stream<AppFeatureFlags> watchFeatureFlags() =>
      _features.snapshots().map(AppFeatureFlags.fromSnapshot);

  Future<AppFeatureFlags> fetchFeatureFlags() async =>
      AppFeatureFlags.fromSnapshot(await _features.get());

  Future<void> setAdsEnabled(bool enabled) async {
    await _features.set(
      {
        'adsEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setAttendanceEnabled(bool enabled) async {
    await _features.set(
      {
        'attendanceEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// The super-user allowlist.
  ///
  /// Read as a one-shot rather than a stream: access shouldn't change
  /// mid-session, and a live listener on this document from every client is
  /// a needless cost.
  Future<AdminAccessConfig> fetchAccessConfig() async =>
      AdminAccessConfig.fromSnapshot(await _access.get());

  /// The raw document, described rather than parsed.
  ///
  /// When the console clearly shows the right data but the app disagrees,
  /// the fault is between the two — wrong project, wrong path, or a field
  /// that isn't the type it looks like. Reporting what actually arrived
  /// settles that in one look, where a parsed view cannot.
  Future<String> describeAccessDoc() async {
    try {
      final snap = await _access.get();
      final buffer = StringBuffer()
        ..writeln('path    : ${_access.path}')
        ..writeln('project : ${_firestore.app.options.projectId}')
        ..writeln('exists  : ${snap.exists}')
        ..writeln('source  : ${snap.metadata.isFromCache ? 'CACHE' : 'server'}');

      final data = snap.data();
      if (data == null || data.isEmpty) {
        buffer.writeln('fields  : (none)');
        return buffer.toString().trim();
      }

      buffer.writeln('fields  :');
      data.forEach((key, value) {
        final type = value.runtimeType.toString();
        final detail = value is List ? ' (${value.length} items)' : '';
        buffer.writeln('  $key: $type$detail');
      });
      return buffer.toString().trim();
    } catch (error) {
      return 'raw read failed: $error';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class AppFeatureFlags {
  const AppFeatureFlags({
    this.attendanceEnabled = true,
    this.adsEnabled = true,
  });

  /// When false the attendance tab is removed from the nav bar entirely and
  /// its routes refuse to open, so the feature reads as simply not existing.
  final bool attendanceEnabled;

  /// Master switch for every ad format. Users who have paid for ad-free stay
  /// ad-free regardless of this flag.
  final bool adsEnabled;

  /// Defaults are permissive on purpose: if the document is missing or the
  /// read fails, the app must behave as it does today rather than silently
  /// hiding a feature everyone relies on.
  static const defaults = AppFeatureFlags();

  factory AppFeatureFlags.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return defaults;
    return AppFeatureFlags(
      attendanceEnabled: data['attendanceEnabled'] is bool
          ? data['attendanceEnabled'] as bool
          : true,
      adsEnabled:
          data['adsEnabled'] is bool ? data['adsEnabled'] as bool : true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class AdminAccessConfig {
  const AdminAccessConfig({
    this.uids = const {},
    this.emails = const {},
    this.passcode,
  });

  final Set<String> uids;

  /// Lower-cased for comparison — an allowlist that is case-sensitive on
  /// email is an allowlist that fails at the worst moment.
  final Set<String> emails;

  /// Optional second factor, checked after the allowlist. Guards against an
  /// unlocked phone belonging to someone who is on the list; it is not a
  /// substitute for the allowlist or for Firestore rules.
  final String? passcode;

  /// Closed by default: a missing or unreadable config grants nobody access.
  /// The opposite of the feature-flag default, and deliberately so.
  static const denyAll = AdminAccessConfig();

  bool allows({String? uid, String? email}) {
    if (uid != null && uids.contains(uid)) return true;
    if (email != null && emails.contains(email.trim().toLowerCase())) {
      return true;
    }
    return false;
  }

  bool get requiresPasscode => (passcode ?? '').isNotEmpty;

  bool matchesPasscode(String input) => passcode == input.trim();

  factory AdminAccessConfig.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return denyAll;

    return AdminAccessConfig(
      uids: _stringSet(data['uids']),
      emails: _stringSet(data['emails']).map((e) => e.toLowerCase()).toSet(),
      passcode: (data['passcode'] as Object?)?.toString().trim(),
    );
  }

  static Set<String> _stringSet(Object? value) {
    if (value is! List) return const {};
    return value
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet();
  }
}
