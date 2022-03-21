import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:flutter/material.dart';
import 'package:messenger/screens/chat/chat_screen.dart'; 
import 'package:another_flushbar/flushbar.dart'; 
import '../../shared/shared_logic.dart' as shared_logic; 

void showMessageNotification(RemoteMessage message, BuildContext context) async {
  final text = message.notification?.body; 
  final chatId = message.data['chatId']; 
  if (text == null || chatId == null) return; 
  final chat = await shared_logic.getChat(chatId); 
  final senderName = await chat.getName(); 
  Flushbar(
    margin: const EdgeInsets.only(top: 20),
    borderRadius: const BorderRadius.all(Radius.circular(20)),
    backgroundColor: Colors.black, 
    isDismissible: true,
    flushbarPosition: FlushbarPosition.TOP,
    duration: const Duration(seconds: 5),
    animationDuration: const Duration(milliseconds: 200),
    title: senderName, 
    message: text,
    onTap: (flushbar) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return ChatPage(chat: chat); 
      })); 
      flushbar.dismiss(); 
    }
  ).show(context); 
}