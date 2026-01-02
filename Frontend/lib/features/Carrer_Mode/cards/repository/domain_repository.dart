import 'package:dio/dio.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/models/domain_model.dart';

class DomainRepository {
  Future<List<DomainModel>> getAllDomains() async{
    try{
      final _dio = Dio();
    final res = await _dio.get("$BASE_URI/domain/getAllDomains",);
    

    final List domainJson =  res.data["data"] ;

    print(domainJson);

    return domainJson.map(
      (json) => DomainModel.fromMap(json)
    ).toList();
  }catch(e) {
    throw Exception(e);
  }
  }

  Future<Map<String,String>> getNextQuestion(String userId, String domain, String subDomainId) async{
    try{
      final _dio = Dio();
      final res = await _dio.get(
        "$BASE_URI/progress/getNextQuestion",
        data: {
          "userId": userId,
          "domain": domain,
          "subDomainId": subDomainId,
        }
      );
      final json = res.data;
      return json;
    }catch(e){
      throw e;
    }
  }



}