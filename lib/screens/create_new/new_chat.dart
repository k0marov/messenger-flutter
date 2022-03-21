import 'package:flutter/material.dart';
import 'package:messenger/screens/chat/chat_screen.dart';

import '../../shared/contacts_list.dart'; 
import 'package:messenger/screens/create_new/new_group.dart'; 
import '../../shared/shared_logic.dart' as shared_logic; 


class NewChat extends StatelessWidget {
  const NewChat({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Chat") 
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            child: const Text("Create a group"), 
            onPressed: () {
              Navigator.push(context, 
                MaterialPageRoute(
                  builder: (ctx) => const NewGroup()
                ) 
              ); 
            }
          ), 
          // Text(
          //   "Select contact: ", 
          //   textAlign: TextAlign.center,
          //   style: Theme.of(context).textTheme.headlineSmall
          // ), 
          Expanded(
            child: ContactsList(
              onChosen: (userId) async {
                final newChat = await shared_logic.newChat(userId); 
                Navigator.pushReplacement(context, 
                  MaterialPageRoute(
                    builder: (ctx) => ChatPage(chat: newChat) 
                  )
                ); 
              }
            ),
          ),
        ],
      )
    ); 
  }
}
