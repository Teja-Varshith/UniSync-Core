import 'package:dio/dio.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/models/interview_report_model.dart';

class ReportsRepository {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );

  Future<List<InterviewSession>> getInterviewReports({required userId, required templateId}) async{
    final res = await _dio.get("${BASE_URI}/carrer/getAllReports",
      data: {
        "userId": userId,
        "templateId": templateId
      },
    );

    if(res.statusCode != 200){
      throw Exception("error finding sessions");
    }

    final data = res.data;

    print(data);

    final allSessionData = InterviewReportResponse.fromJson(data);

    return  allSessionData.data;





    



  }


    
}