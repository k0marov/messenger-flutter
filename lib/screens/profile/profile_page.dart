import 'package:flutter/material.dart';
import 'package:messenger/screens/chat/chat_screen.dart';
import 'package:messenger/models/user_model.dart';
import '../../models/contact_model.dart'; 
import 'package:messenger/shared/last_seen.dart';
import 'package:messenger/shared/profile_image.dart'; 
import 'logic.dart' as logic; 
import '../../shared/shared_logic.dart' as shared_logic; 

class ProfilePage extends StatelessWidget {
  final String userId; 
  const ProfilePage({
    required this.userId, 
    Key? key 
  }) : super(key: key);

  void _addToContacts(UserModel user) async {
    logic.addContact(user.phone, user.displayName); 
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: shared_logic.getUser(userId), 
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: CircularProgressIndicator()); 
        }
        final user = snapshot.data!; 
        return Scaffold(
          appBar: AppBar(
            title: FutureBuilder<String>(
              future: shared_logic.getDisplayName(userId),
              builder: (context, snapshot) {
                return Text(snapshot.data ?? ""); 
              },
            ), 
            actions: [
              FutureBuilder<List<ContactModel>>(
                future: shared_logic.getContacts().first, 
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Container(); 
                  final contacts = snapshot.data!; 
                  final userInContacts = contacts.any((contact) => contact.userId == user.userId); 
                  if (userInContacts) {
                    return Container(); 
                  } else {
                    return IconButton(
                      icon: Icon(Icons.add, color: Theme.of(context).primaryColor), 
                      onPressed: () => _addToContacts(user), 
                    ); 
                  }
                },
              ), 
            ], 
          ), 
          body: Center(
            child: ListView(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      ProfileImage(
                        avatarId: userId, isGroup: false
                      ),
                      Positioned(
                        left: 0, 
                        right: 0,
                        bottom: 0,
                        child: Container(
                          color: Colors.black.withOpacity(0.5), 
                          child: FutureBuilder<String>(
                            future: shared_logic.getDisplayName(userId), 
                            initialData: "",
                            builder: (context, snapshot) {
                              final uniqueName = user.username == null ? 
                                user.phone 
                              : '@' + user.username!; 
                              return Text(
                                snapshot.data! + ', ' + uniqueName, 
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headline4
                              ); 
                            },
                          ),
                        ),
                      ), 
                    ],
                  ),
                ), 
                ElevatedButton(
                  child: const Text("Send Message"), 
                  onPressed: () async {
                    final chat = await shared_logic.newChat(userId); 
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return ChatPage(
                            chat: chat
                          ); 
                        }
                      )
                    ); 
                  }
                ),
                LastSeen(
                  userId: userId, 
                  asStream: false, 
                  textStyle: Theme.of(context).textTheme.headlineSmall,
                ), 
              ]
            ),
          )
        ); 
      }
    ); 
  }
}