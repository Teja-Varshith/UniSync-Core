import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/features/interview/repository/reports_repository.dart';
import 'package:UniSync/features/interview/view/carrer_interview_screen.dart';
import 'package:UniSync/models/interview_report_model.dart';

final ReportsRepositoryProvider = Provider((ref) => ReportsRepository());
final ReportsControllerProvider = AsyncNotifierProvider<ReportsController,List<InterviewSession>>(ReportsController.new);
class ReportsController extends AsyncNotifier<List<InterviewSession>> {
  @override
  FutureOr<List<InterviewSession>> build() {
    final repo = ref.read(ReportsRepositoryProvider);
    final userId = ref.read(userProvider)!.id!;
    final templateId = ref.read(selectedTemplateProvider)!.id;

    return repo.getInterviewReports( 
      userId: userId,
      templateId: templateId,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    final repo = ref.read(ReportsRepositoryProvider);
    final userId = ref.read(userProvider)!.id!;
    final templateId = ref.read(selectedTemplateProvider)!.id;

    state = AsyncData(
      await repo.getInterviewReports(
        userId: userId,
        templateId: templateId,
      ),
    );
  }
}
