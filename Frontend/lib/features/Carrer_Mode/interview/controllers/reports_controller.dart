import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/features/Carrer_Mode/interview/repository/reports_repository.dart';
import 'package:unisync/features/Carrer_Mode/interview/view/carrer_interview_screen.dart';
import 'package:unisync/models/interview_report_model.dart';

final ReportsRepositoryProvider = Provider((ref) => ReportsRepository());
final ReportsControllerProvider = AsyncNotifierProvider<ReportsController,List<InterviewSession>>(ReportsController.new);

class ReportsController extends AsyncNotifier<List<InterviewSession>>{
  late final ReportsRepository _repo;
  late final String userId;
  late final String templateId;

  @override
  FutureOr<List<InterviewSession>> build() {
    _repo = ref.read(ReportsRepositoryProvider);
    userId = ref.read(userProvider)!.id!;
    templateId = ref.read(selectedTemplateProvider)!.id;
    return _repo.getInterviewReports(userId: userId, templateId: templateId);
  }






   Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _repo.getInterviewReports(userId: userId,templateId: templateId));
  }
}