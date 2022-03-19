import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger/shared/name_input.dart';
import 'package:messenger/shared/profile_image.dart'; 
import 'logic.dart' as logic; 
import '../../shared/shared_logic.dart' as shared_logic; 

class MyProfilePage extends StatelessWidget {
  const MyProfilePage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: Center(
        child: ListView(
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ProfileImage(
                    isGroup: false, 
                    avatarId: shared_logic.getUserId()
                  )
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(
                      Icons.change_circle, 
                      size: 40, 
                      color: Colors.white
                    ),
                    onPressed: () => 
                      logic.selectNewAvatar(shared_logic.getUserId(), false), 
                  )
                )
              ]
            ), 
            StreamBuilder<String>(
              stream: logic.displayNameStream(), 
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Container(); 
                final displayName = snapshot.data!; 
                return Padding(
                  padding: const EdgeInsets.all(10),
                  child: NameInput(
                    allowSameValue: false,
                    isRow: true, 
                    initialValue: displayName, 
                    onCompleted: (newName) async {
                      await shared_logic.updateUserData({'displayName': newName}); 
                      FirebaseAuth.instance.currentUser?.updateDisplayName(newName); 
                      // Navigator.of(context).pushReplacement(
                      //   MaterialPageRoute(
                      //     builder: (context) {
                      //       return const MyProfilePage(); 
                      //     }
                      //   )
                      // ); 
                      return true; 
                    }
                  ),
                ); 
              }
            ), 
            StreamBuilder<String>(
              stream: shared_logic.usernameStream(), 
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Container(); 
                final username = snapshot.data ?? ""; 
                return Padding(
                  padding: const EdgeInsets.all(10),
                  child: NameInput(
                    allowSameValue: false,
                    isRow: true, 
                    initialValue: username, 
                    prefixText: "@",
                    errorText: "This username is already taken", 
                    maxLength: 15,
                    label: "Username",
                    onCompleted: (newUsername) async {
                      if (!(await logic.checkUsername(newUsername))) return false; 
                      await shared_logic.updateUserData({'username': newUsername}); 
                      // Navigator.of(context).pushReplacement(
                      //   MaterialPageRoute(
                      //     builder: (context) {
                      //       return const MyProfilePage(); 
                      //     }
                      //   )
                      // ); 
                      return true; 
                    }
                  ),
                ); 
              }
            ), 
            TextButton(
              // style: ElevatedButton.styleFrom(
              //   primary: Colors.red, 
              // ), 
              onPressed: () async {
                await logic.logout(); 
                Navigator.of(context).pop(); 
              }, 
              child: const Text("Logout", style: TextStyle(color: Colors.red)), 
            ), 
          ],  
        )
      )
    );
  }
}