import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:unisync/app/providers.dart';
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

  Future<UserModel?> signInWithGoogle() async {
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
      final dio = Dio();
      print('req started////////////////////////////////');
       final res = await dio.post(
        'http://10.185.91.196:3000/login',
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

      final data = res.data["user"];
if (data == null) {
  throw Exception("User missing in login response");
}
return UserModel.fromMap(data);

}catch(e){
  print(e);
};




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
  final dio = Dio();

  final res = await dio.post(
    'http://10.185.91.196:3000/login',
    data: {
      'emailId': email,
      'name': name,
    },
  );

  return UserModel.fromMap(res.data['user']);
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
    final dio = Dio();

  final res = await dio.patch(
    'http://10.185.91.196:3000/complete-profile',
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
  }catch(err){
    print("ERROR upadting: $err");
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
