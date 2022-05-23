import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:final_project/View/InitialRecScreen.dart';
import 'package:final_project/View/LoginScreen.dart';
import '../Controller/firebase.dart';
import 'Widgets/CustomDialog.dart';
import 'package:loader_overlay/loader_overlay.dart';

// Registration screen
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  RegisterScreen createState() => RegisterScreen();
}

class RegisterScreen extends State<MyApp> {
  // text controllers for text fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
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
                  "Welcome To Blindwatchr, the movie recommendation app. To get started, enter your email address and password to register.");
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
            // sign up button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
              child: ElevatedButton(
                  child: const Text('Sign Up'),
                  style:
                      ElevatedButton.styleFrom(fixedSize: const Size(150, 40)),
                  onPressed: () async {
                    // checks if connected to internet and has entered email and password,
                    // then tries to create new user,
                    // if failure, error is caught and displayed, otherwise navigates to initial rec screen
                    if (emailController.text.isEmpty) {
                      ShowDialog(
                          context, "Error", "Please enter an Email Address");
                    } else if (passwordController.text.isEmpty) {
                      ShowDialog(context, "Error", "Please enter a Password");
                    } else if (await CheckConnection()) {
                      context.loaderOverlay.show();
                      try {
                        UserCredential result =
                            await instance.createUserWithEmailAndPassword(
                                email: emailController.text,
                                password: passwordController.text);
                        user = result.user;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const InitialRatingScreen()),
                        );
                      } on FirebaseAuthException catch (error) {
                        switch (error.code) {
                          case "invalid-email":
                            errorMessage =
                                "Your email address is not formatted correctly.";
                            break;
                          case "weak-password":
                            errorMessage =
                                "Password must be at least 6 characters long.";
                            break;
                          case "email-already-in-use":
                            errorMessage = "This Email Address is taken.";
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
                    } else if (passwordController.text.isEmpty) {
                      ShowDialog(context, "Error", "Please enter a password");
                    } else if (emailController.text.isEmpty) {
                      ShowDialog(
                          context, "Error", "Please enter an email address");
                    } else {
                      ShowDialog(context, "Error",
                          "You are not connected to the internet.");
                    }

                    if (errorMessage != null) {
                      ShowDialog(context, "Error", errorMessage!);
                    }

                    errorMessage = null;
                  }),
            ),
            // moves to log in screen in case user doesn't need to register
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: GestureDetector(
                  child: const Text(
                    "Already A Member? Log In",
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  }),
            ),
            // terms & conditions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: GestureDetector(
                  child: const Text(
                    "Terms & Conditions",
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTap: () {
                    ShowDialog(context, "Terms & Conditions",
                        "By registering, you agree to let us use your movie rating data to generate movie recommendations.");
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
