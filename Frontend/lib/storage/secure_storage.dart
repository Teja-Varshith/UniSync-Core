import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> setLoginStatus(bool status,String uid) async {
    await _storage.write(key: 'isLoggedIn', value: status.toString());
    await _storage.write(key: 'uid', value: uid);
  }

  Future<void> setIds(String x_tenant_id, String x_institution_code) async {
    await _storage.write(key: 'x-tenant-id', value: x_tenant_id);
    await _storage.write(key: 'x-institution-code', value: x_institution_code);
  }

  Future<String?> getXTenantId() async {
    final value = await _storage.read(key: 'x-tenant-id');
    return value;
  }

  Future<String?> getXInstitutionCode() async {
    final value = await _storage.read(key: 'x-institution-code');
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
}
