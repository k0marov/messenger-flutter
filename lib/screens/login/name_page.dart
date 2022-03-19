import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger/shared/name_input.dart'; 
import '../../shared/shared_logic.dart' as shared_logic; 

class NamePage extends StatelessWidget {
  const NamePage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Name")
      ), 
      body: Center(
        child: FutureBuilder<String>(
          future: shared_logic.getDisplayName(shared_logic.getUserId()),
          builder:(context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator(); 
            return Padding(
              padding: const EdgeInsets.all(50),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Enter your name"), 
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: NameInput(
                      allowSameValue: true,
                      initialValue: snapshot.data!,
                      isRow: false,
                      onCompleted: (name) async {
                        await shared_logic.updateUserData({'displayName': name}); 
                        await FirebaseAuth.instance.currentUser?.updateDisplayName(name); 
                        Navigator.of(context).popUntil(
                          (route) => route.isFirst
                        ); 
                        return true; 
                      },
                    ),
                  ),
                ],
              ),
            ); 
          },
        )
      )
    ); 
  }

}