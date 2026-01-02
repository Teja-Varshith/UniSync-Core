import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/features/Carrer_Mode/cards/repository/domain_repository.dart';
import 'package:unisync/models/domain_model.dart';

final domainRepositoryProvider = Provider<DomainRepository>((ref) => DomainRepository());

final SelectedDomainProvider = StateProvider<String?>((ref) => null);


final getAllDomains = FutureProvider<List<DomainModel>>((ref) async{
   final _repo = ref.read(domainRepositoryProvider);
   return _repo.getAllDomains();
});