import 'package:dio/dio.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/models/interview_report_model.dart';

class ReportsRepository {
  Future<List<InterviewSession>> getInterviewReports({required userId, required templateId}) async{
    final _dio = Dio();
    


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