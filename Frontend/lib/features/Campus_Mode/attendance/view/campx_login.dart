import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/features/Campus_Mode/attendance/repository/attendance_repository.dart';

class CampxLoginScreen extends ConsumerStatefulWidget {
  const CampxLoginScreen({super.key});

  @override
  ConsumerState<CampxLoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<CampxLoginScreen> {
  bool _isloading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  } 

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    ref.listen(
      userProvider,
      (prev, next) {
        if(next!.cookie != null){
          Routemaster.of(context).push('/liveAttendance');
        }
      }
    );


    Future<void> _login() async {
      if (_formKey.currentState!.validate()) {
        print('Login button pressed');
        _isloading = true;

        ref.read(AttendanceRepositoryProvider).completeCampXLogin(emailController.text, passwordController.text);

        _isloading = false;



      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.amber.shade600,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () {
                                _showDialog(context);
                              },
                              icon: Icon(Icons.question_mark),
                              color: Colors.black,
                              tooltip: 'Need Help?',
                              enableFeedback: true,
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Lottie.asset(
                        'assets/animations/login_lottie.json',
                        height: 250,
                      ),

                      Expanded(
                        child: Container(
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
                              top: 50,
                              left: 30,
                              right: 30,
                              bottom: 30,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Your Campus, Your Vibe.',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  SizedBox(height: 20),

                                  Text(
                                    'Use your College Credentials to Sign in instantly. No hassle, Just vibes!',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),

                                  SizedBox(height: 40),

                                  TextFormField(
                                    controller: emailController,
                                    decoration: InputDecoration(
                                      labelText: 'Jntu No / Email',
                                      labelStyle: TextStyle(color: Colors.black),
                                      floatingLabelStyle: TextStyle(color: Colors.black),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.black),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.black, width: 2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.red),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.red, width: 2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Example 23341XXXXX';
                                      }
                                      // if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      //   return 'Please enter a valid email address';
                                      // }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: 20),

                                  TextFormField(
                                    controller: passwordController,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: TextStyle(color: Colors.black),
                                      floatingLabelStyle: TextStyle(color: Colors.black),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.black),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.black, width: 2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.red),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.red, width: 2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                    obscureText: !_isPasswordVisible,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Password? Brain go brrrrr';
                                      }
                                      if (value.length < 3) {
                                        return "Don't lie guys";
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: 30),

                                  ElevatedButton.icon(
                                    onPressed: _isloading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      elevation: 3,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    
                                    icon: _isloading?
                                    SizedBox():
                                    Icon(Icons.rocket_launch, color: Colors.white,size: 20,),
                                    label: _isloading?
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
                                      "Let's Go.....",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}