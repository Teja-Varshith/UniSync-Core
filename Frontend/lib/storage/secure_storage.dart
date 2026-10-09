import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  static const _tenantKey = 'x-tenant-id';
  static const _institutionKey = 'x-institution-code';
  static const _campxTokenKey = 'campx-session-token';
  static const _campxUsernameKey = 'campx-username';
  static const _campxPasswordKey = 'campx-password';
  static const _themeModeKey = 'theme-mode';

  Future<void> setLoginStatus(bool status,String uid) async {
    await _storage.write(key: 'isLoggedIn', value: status.toString());
    await _storage.write(key: 'uid', value: uid);
  }

  Future<void> setIds(String x_tenant_id, String x_institution_code) async {
    await _storage.write(key: _tenantKey, value: x_tenant_id);
    await _storage.write(key: _institutionKey, value: x_institution_code);
  }

  Future<void> setCampXSessionToken(String token) async {
    await _storage.write(key: _campxTokenKey, value: token);
  }

  Future<void> setCampXCredentials({
    required String username,
    required String password,
  }) async {
    await _storage.write(key: _campxUsernameKey, value: username);
    await _storage.write(key: _campxPasswordKey, value: password);
  }

  Future<void> persistCampXSession({
    required String token,
    required String tenantId,
    required String institutionCode,
    required String username,
    required String password,
  }) async {
    await setCampXSessionToken(token);
    await setIds(tenantId, institutionCode);
    await setCampXCredentials(username: username, password: password);
  }

  Future<String?> getXTenantId() async {
    final value = await _storage.read(key: _tenantKey);
    return value;
  }

  Future<String?> getXInstitutionCode() async {
    final value = await _storage.read(key: _institutionKey);
    return value;
  }

  Future<String?> getCampXSessionToken() async {
    final value = await _storage.read(key: _campxTokenKey);
    return value;
  }

  Future<String?> getCampXUsername() async {
    final value = await _storage.read(key: _campxUsernameKey);
    return value;
  }

  Future<String?> getCampXPassword() async {
    final value = await _storage.read(key: _campxPasswordKey);
    return value;
  }

  Future<void> setThemeMode(String mode) async {
    await _storage.write(key: _themeModeKey, value: mode);
  }

  Future<String?> getThemeMode() async {
    final value = await _storage.read(key: _themeModeKey);
    return value;
  }

  Future<bool> getLoginStatus() async {
    final value = await _storage.read(key: 'isLoggedIn');
    return value == 'true';
  }

  Future<String> getuid() async {
    final value = await _storage.read(key: 'uid');
    print(value);
    return value?? 'na' ;
  }
  Future<void> clearLoginStatus() async {
    print('clear l');
    await _storage.delete(key: 'isLoggedIn');
    await _storage.delete(key: 'uid');
  }

  Future<void> clearCampXSession() async {
    await _storage.delete(key: _tenantKey);
    await _storage.delete(key: _institutionKey);
    await _storage.delete(key: _campxTokenKey);
    await _storage.delete(key: _campxUsernameKey);
    await _storage.delete(key: _campxPasswordKey);
  }
}
