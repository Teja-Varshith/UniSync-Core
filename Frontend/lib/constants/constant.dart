import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const BASE_URI  = "http://172.19.23.196:3000/api";  


final dio = Dio();

final dioProvider = Provider((ref) => dio);