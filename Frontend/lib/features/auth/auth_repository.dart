import 'package:dio/dio.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/models/user_model.dart';

final AuthRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.read(FirebaseAuthProvider),
    signIn: ref.read(googleSignInProvider),
  );
});

class AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required FirebaseAuth auth,
    required GoogleSignIn signIn,
  })  :  _auth = auth,
        _googleSignIn = signIn;

  Dio _createDioClient() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 12),
      ),
    );
  }

  String _dioMessage(DioException e, String fallback) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Unable to reach server. Please try again.';
    }

    if (e.response?.data is Map && e.response?.data['message'] != null) {
      return e.response!.data['message'].toString();
    }

    return fallback;
  }

  void _showErrorSnackBar(String message) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    const contentType = ContentType.failure;
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Sign in failed',
        message: message,
        contentType: contentType,
      ),
    );

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  Future<UserModel?> signInWithGoogle() async {


    // google will not give you signin prompt agai if your loggedin already
    // chck if loggedin then directly pass


    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
    final UserMeta  = (await _auth.signInWithCredential(credential)).user;

    if(UserMeta != null) {
      final userEmail = UserMeta.email;
      final userName = UserMeta.displayName;
      final photoUrl = UserMeta.photoURL;


    try{
     final dio = _createDioClient();
      print('req started////////////////////////////////');
       final res = await dio.post(
        '${BASE_URI}/auth/login',   //// ${BASE_URI}/login
        data: {
          'emailId' : userEmail,
          "name" : userName,
          "photoUrl": photoUrl
        },
        options: Options(
          headers: {
            
          }
        ),
      
      );
      print(res);

      final data = res.data["user"];
if (data == null) {
  _showErrorSnackBar('Sign in failed. Please try again.');
  return null;
}
return UserModel.fromMap(data);

} on DioException catch (e) {
  final msg = _dioMessage(e, 'Sign in failed. Please try again.');
  logOut(); // MAY CAUSE ISUUUUUUUUUUUUUUUUUUUUU
  _showErrorSnackBar(msg);
  print(e);
  return null;
} catch(e){
  _showErrorSnackBar('Sign in failed. Please try again.');
  print(e);
  return null;
}




      // first time user?
    // get additional information
    // create the new userModel and add to mongoose

    // returning user?
    // find in mongoose and return usermodel44
    }else{
      // error
    }
  }



  Future<UserModel?> updateProfile() async {

  }



  Future<UserModel?> signInWithGoogleBackendOnly({
  required String email,
  required String name,
}) async {
  try {
    final dio = _createDioClient();

    final res = await dio.post(
      '${BASE_URI}/auth/login', // http://10.185.91.196:3000/api/auth/login
      data: {
        'emailId': email,
        'name': name,
      },
    ); 

    print(res);

    return UserModel.fromMap(res.data['user']);
  } on DioException catch (e) {
    final msg = _dioMessage(e, 'Login failed. Please try again.');
    _showErrorSnackBar(msg);
    print(e);
    return null;
  } catch (e) {
    _showErrorSnackBar('Login failed. Please try again.');
    print(e);
    return null;
  }
}





   Future<UserModel?> completeProfile({
    required String emailId,
  required String name,
  required String collegeName,
  required int semester,
  required int year,
  String? about,
}) async {
  try{
    final dio = _createDioClient();

  final res = await dio.patch(
    '${BASE_URI}/auth/complete-profile',
    data: {
      "emailId": emailId,
      'name': name,
      'collegeName': collegeName,
      'semester': semester,
      'year': year,
      'about': about,
    },
  );

  print('raw response ${res.data["user"]}');

  final updatedUser =  UserModel.fromMap(res.data["user"]);
  
  return updatedUser;
  } on DioException catch (err) {
    final msg = _dioMessage(err, 'Unable to update profile. Please try again.');
    _showErrorSnackBar(msg);
    print("ERROR upadting: $err");
    return null;
  }catch(err){
    _showErrorSnackBar('Unable to update profile. Please try again.');
    print("ERROR upadting: $err");
    return null;
  }
}
   
  Future<User?> getCurrentUser() async{
    return _auth.currentUser;
  }

  Future<void> logOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
