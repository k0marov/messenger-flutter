import 'package:flutter/material.dart';
import 'package:messenger/screens/home/chat_widget.dart';
import 'package:messenger/models/chat_model.dart';
import '../profile/my_profile_page.dart'; 
import '../../shared/profile_image.dart'; 
import '../create_new/new_chat.dart'; 

import '../../shared/shared_logic.dart' as shared_logic; 


class HomePage extends StatelessWidget {
  const HomePage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messenger"),
        actions: [
          IconButton(
            icon: ClipOval(
              child: ProfileImage(
                avatarId: shared_logic.getUserId(), 
                isGroup: false, 
              ), 
            ), 
            onPressed: () {
              Navigator.push(context, 
                MaterialPageRoute(
                  builder: (ctx) => const MyProfilePage(), 
                )   
              ); 
            }
          )
        ], 
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: shared_logic.getChats(), 
        initialData: const [],
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Container(); 
          return ListView(
            children: snapshot.data!.map<Widget>((chat) => ChatWidget(chat: chat)).toList()
          ); 
        } 
      ), 
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.create), 
        onPressed: () => 
          Navigator.push(context, 
            MaterialPageRoute(
              builder: (ctx) => const NewChat() 
            )
          )
      ), 
    );
  }
}