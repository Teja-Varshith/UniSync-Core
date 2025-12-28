import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/features/Carrer_Mode/interview/repository/carrer_repository.dart';
import 'package:unisync/models/template_model.dart';

final carrerRepositoryProvider = Provider<CarrerRepository>((ref) {
  return CarrerRepository();
});

final carrerControllerProvider =
    AsyncNotifierProvider<CarrerController, List<TemplateModel>>(
  CarrerController.new,
);


class CarrerController extends AsyncNotifier<List<TemplateModel>> {
  late final CarrerRepository _repo;

  List<TemplateModel> _allTemplates = [];

  @override
  Future<List<TemplateModel>> build() async {
    _repo = ref.read(carrerRepositoryProvider);
    _allTemplates = await _repo.getTemplates(); 
    return _allTemplates;
  }

  List<String> get AvailableDomains{
    final domains = _allTemplates
    .map((e) => e.domain)
    .where((d) => d.isNotEmpty)
    .toList();
    domains.sort();
    return domains;
  }

  void filterByDomain(String domain) {
    if(domain == "All"){
      state = AsyncData(_allTemplates);
      return;
    }
    final filtered = _allTemplates.where((t) => t.domain == domain).toList();
    state = AsyncData(filtered);
  }



  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _repo.getTemplates());
  }
}
