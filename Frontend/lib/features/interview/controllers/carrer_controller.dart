import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/features/interview/repository/carrer_repository.dart';
import 'package:unisync/models/template_model.dart';

final carrerRepositoryProvider = Provider<CarrerRepository>((ref) {
  return CarrerRepository();
});

final carrerControllerProvider =
    AsyncNotifierProvider<CarrerController, List<TemplateModel>>(
  CarrerController.new,
);

final getAllUserTemplate = FutureProvider<List<TemplateModel>>((ref) async{
   final _repo = ref.read(carrerRepositoryProvider);
   return _repo.getTemplatesByUserId(ref.read(userProvider)!.id!);
});


class CarrerController extends AsyncNotifier<List<TemplateModel>> {
  late final CarrerRepository _repo;

  List<TemplateModel> _allTemplates = [];
  List<TemplateModel> get allTemplates => _allTemplates;

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
    _allTemplates = await _repo.getTemplates();
    state = AsyncData(_allTemplates);
  }
}
