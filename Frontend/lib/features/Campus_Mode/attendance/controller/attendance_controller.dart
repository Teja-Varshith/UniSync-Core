import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/features/Campus_Mode/attendance/repository/live_attedance_repositiry.dart';


final attendanceProvider = FutureProvider((ref) {
   return ref.read(LiveAttdncRepositoryProvider).fetchAttendance();
});


