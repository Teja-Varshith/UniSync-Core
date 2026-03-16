import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/models/user_model.dart';

final AuthRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.read(FirebaseAuthProvider),
    firestore: ref.read(firebaseFirestoreProvider),
    signIn: ref.read(googleSignInProvider),
  );
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required GoogleSignIn signIn,
  })  :  _auth = auth,
        _firestore = firestore,
        _googleSignIn = signIn;

  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return _firestore.collection('users');
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

  Future<UserModel?> _upsertUserFromFirebaseUser(User firebaseUser) async {
    final userRef = _usersCollection.doc(firebaseUser.uid);
    final userSnapshot = await userRef.get();
    final existing = userSnapshot.data() ?? <String, dynamic>{};

    final payload = <String, dynamic>{
      'id': firebaseUser.uid,
      'uid': firebaseUser.uid,
      'emailId': existing['emailId'] ?? firebaseUser.email ?? '',
      'name': existing['name'] ?? firebaseUser.displayName ?? '',
      'photoUrl': existing['photoUrl'] ?? firebaseUser.photoURL,
      'profileComplete': existing['profileComplete'] ?? false,
      'collegeName': existing['collegeName'],
      'tenantId': existing['tenantId'],
      'cookie': existing['cookie'],
      'institutionCode': existing['institutionCode'],
      'campXPassword': existing['campXPassword'],
      'campXUsername': existing['campXUsername'],
      'year': existing['year'],
      'semester': existing['semester'],
      'about': existing['about'],
      'coins': existing['coins'] ?? 100,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!userSnapshot.exists) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }

    await userRef.set(payload, SetOptions(merge: true));

    final latest = await userRef.get();
    final userData = latest.data();
    if (userData == null) return null;

    return UserModel.fromMap(userData);
  }

  Future<UserModel?> signInWithGoogle() async {


    // google will not give you signin prompt agai if your loggedin already
    // chck if loggedin then directly pass


    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userMeta = (await _auth.signInWithCredential(credential)).user;

      if (userMeta == null) {
        _showErrorSnackBar('Sign in failed. Please try again.');
        return null;
      }

      return _upsertUserFromFirebaseUser(userMeta);
    } catch (e) {
      _showErrorSnackBar('Sign in failed. Please try again.');
      print(e);
      return null;
    }




      // first time user?
    // get additional information
    // create the new userModel and add to mongoose

    // returning user?
    // find in mongoose and return usermodel44
    
  }



  Future<UserModel?> updateProfile() async {

  }



  Future<UserModel?> loadCurrentUserProfile() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;
      return _upsertUserFromFirebaseUser(firebaseUser);
    } catch (e) {
      _showErrorSnackBar('Unable to restore user profile. Please try again.');
      print(e);
      return null;
    }
  }





   Future<UserModel?> completeProfile({
  required String name,
  required String collegeName,
  required int semester,
  required int year,
  String? about,
}) async {
  try {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      _showErrorSnackBar('Session expired. Please sign in again.');
      return null;
    }

    final userRef = _usersCollection.doc(firebaseUser.uid);

    await userRef.set({
      'id': firebaseUser.uid,
      'uid': firebaseUser.uid,
      'emailId': firebaseUser.email ?? '',
      'photoUrl': firebaseUser.photoURL,
      'name': name,
      'collegeName': collegeName,
      'semester': semester,
      'year': year,
      'about': about,
      'profileComplete': true,
      'coins': FieldValue.increment(0),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final updated = await userRef.get();
    final data = updated.data();
    if (data == null) return null;

    return UserModel.fromMap(data);
  } catch (err) {
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
