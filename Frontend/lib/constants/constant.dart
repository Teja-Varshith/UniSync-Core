import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const BASE_URI  = "http://172.19.23.196:3000/api";  

const anyUrl = 'https://api.campx.in/auth-server/auth-v2/login-mobile';
const totoUrl = 'https://api.campx.in/student-api/student-attendance?fromDate=&toDate=';
const totoourl = "https://api.campx.in/student-api/student-attendance/subject-attendance/";

final dio = Dio();

final dioProvider = Provider((ref) => dio);