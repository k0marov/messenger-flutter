import 'package:flutter/material.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger/screens/login/name_page.dart';
import 'package:messenger/screens/login/signin_screen.dart';
import '../home/home_page.dart'; 

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(), 
      builder: (context, userSnapshot) {
        if (userSnapshot.hasData) {
          final displayName = userSnapshot.data!.displayName; 
          if (displayName == null || displayName == "") {
            return const NamePage();
          } else {
            return const HomePage(); 
          }
        } else {
          return const SignInScreen(); 
        }
      }
    ); 
  }
}