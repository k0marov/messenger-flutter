import 'dart:async';

import 'package:flutter/material.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:messenger/screens/chat/chat_page.dart';
import 'package:messenger/screens/core/exception_gate.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../../shared/shared_logic.dart' as shared_logic; 

class MessengerApp extends StatefulWidget {
  const MessengerApp({Key? key}) : super(key: key);

  @override
  State<MessengerApp> createState() => _MessengerAppState();
}

class _MessengerAppState extends State<MessengerApp> {

  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) async {
    final chatId = message.data['chatId']; 
    if (chatId != null) {
      final chat = await shared_logic.getChat(chatId); 
      if (FirebaseAuth.instance.currentUser != null) {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return ChatPage(chat: chat); 
        })); 
      } 
    }
  }

  @override
  void initState() {
    setupInteractedMessage(); 
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.dark, 
        primaryColor: Colors.blue, 
        primarySwatch: Colors.blue,
      ),
      home: const ExceptionGate()
    );
  }
}
