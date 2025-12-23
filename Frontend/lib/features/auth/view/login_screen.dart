import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/features/auth/auth_controller.dart';
import 'package:unisync/features/auth/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'How to Sign In?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Use your JNTU Number or College Email registered on CampX along with your password to sign in.\n\nyour password is the one you set during your CampX registration.\n\nIf you face any issues, please contact hello.unisync@gmail.com',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            Container(
              child: TextButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(Colors.black),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Okay',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.amber.shade600,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: constraints.maxHeight),
              child: Column(
                children: [


                    Spacer(),


                   Lottie.asset(
                      'assets/animations/login_lottie.json',
                      height: 250,
                    ),

                    SizedBox(height: 40,),

              
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                        child: Padding(
                            padding: const EdgeInsets.only(
                              top: 40,
                              left: 30,
                              right: 30,
                              bottom: 30,
                            ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                               Text(
                                  'One Tap, Infinite Possibilities',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
    
                                 SizedBox(height:10),


                                 Text(
                                  'Sign In with google and & dive into the future of tech.No hassle, just Innovation!',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),

                                SizedBox(height: 30,),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async{
                                      setState(() {
                                        isLoading = true;
                                      });

                                      
                                    //  final dio = Dio();
                                    //  final res = await dio.get('http://10.185.91.196:3000/');
                                    //  print(res);

                                    //  final dio = await ref.read(dioProvider);
                                    //  dio.get('http://10.185.91.196:3000/');
                                      final user = await ref.read(authControllerProvider).signInWithGoogle();
                                     if(user != null){ setState(() {
                                        isLoading = false;
                                      });}
                                      // final user = AuthRepository().signInWithGoogle();
                                      print(user);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      elevation: 3,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    
                                    icon: isLoading?
                                    SizedBox():
                                    Icon(Icons.rocket_launch, color: Colors.white,size: 20,),
                                    label: 
                                    isLoading?
                                    Center(child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(backgroundColor: Colors.white,valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
                                        SizedBox(width: 10,),
                                        Text('Signing you securely...')
                                      ],
                                    ),):
                                    Text(
                                      "Continue With Google",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                            
                            ],
                          ),
                        ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
