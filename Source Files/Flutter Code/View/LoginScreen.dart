import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:final_project/Controller/firebase.dart';
import 'package:final_project/View/RecScreen.dart';
import 'package:final_project/View/InitialRecScreen.dart';
import 'Widgets/CustomDialog.dart';
import 'package:loader_overlay/loader_overlay.dart';

// login screen for already registered users to log in
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // text controllers for text fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordResetController = TextEditingController();
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.help,
              size: 30.0,
              color: Colors.black,
            ),
            onPressed: () {
              ShowDialog(context, "Help",
                  "If you have already registered, please enter your email address and password. Otherwise, return to the registration screen.");
            },
          )
        ],
      ),
      body: LoaderOverlay(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // logo
            Image.asset("graphics/big_logo.png", height: 50),
            // email text field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 30),
              child: TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter Your Email Address',
                ),
              ),
            ),
            // password text field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter Your Password',
                ),
              ),
            ),
            // login button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
              child: ElevatedButton(
                  child: const Text('Log In'),
                  style:
                      ElevatedButton.styleFrom(fixedSize: const Size(150, 40)),
                  onPressed: () async {
                    // if connected to internet and has entered email and password, try to login,
                    // if login fails, catch error and display message,
                    // if user has ratings, move to rec screen, else go to initial ratings screen
                    if (emailController.text.isEmpty) {
                      ShowDialog(
                          context, "Error", "Please enter an Email Address");
                    } else if (passwordController.text.isEmpty) {
                      ShowDialog(context, "Error", "Please enter a Password");
                    } else if (await CheckConnection()) {
                      context.loaderOverlay.show();
                      try {
                        UserCredential result =
                            await instance.signInWithEmailAndPassword(
                                email: emailController.text,
                                password: passwordController.text);
                        user = result.user;
                        if (await hasRatings()) {
                          movieRecs = generateRecs();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RecScreen()),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const InitialRatingScreen()),
                          );
                        }
                      } on FirebaseAuthException catch (error) {
                        switch (error.code) {
                          case "invalid-email":
                            errorMessage =
                                "Your email address is not formatted correctly";
                            break;
                          case "weak-password":
                            errorMessage =
                                "Password must be at least 6 characters long";
                            break;
                          case "user-not-found":
                            errorMessage =
                                "User does not exist, please check email address and password and try again.";
                            break;
                          case "wrong-password":
                            errorMessage =
                                "Password or Email Address is incorrect.";
                            break;
                          case "too-many-requests":
                            errorMessage =
                                "Too many requests, please try again later.";
                            break;
                          default:
                            errorMessage = "An undefined Error happened.";
                        }
                      }
                      context.loaderOverlay.hide();
                      if (errorMessage != null) {
                        ShowDialog(context, "Error", errorMessage!);
                      }

                      errorMessage = null;
                    } else {
                      ShowDialog(context, "Error",
                          "You are not connected to the internet.");
                    }
                  }),
            ),
            // return to register screen
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: GestureDetector(
                  child: const Text(
                    "Return To Register Screen",
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  }),
            ),
            // reset password feature
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
              child: GestureDetector(
                  child: const Text(
                    "Forgot Your Password?",
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTap: () async {
                    return showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Reset Password'),
                          content: TextField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter Your Email Address',
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Send Reset Email'),
                              onPressed: () async {
                                if (passwordResetController.text.isNotEmpty) {
                                  await instance.sendPasswordResetEmail(
                                      email: passwordResetController.text);
                                }
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
