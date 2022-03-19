import 'package:flutter/material.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:messenger/screens/core/auth_gate.dart'; 
import 'show_notifications.dart'; 

class NotificationGate extends StatefulWidget {
  const NotificationGate({ Key? key }) : super(key: key);

  @override
  State<NotificationGate> createState() => _NotificationGateState();
}

class _NotificationGateState extends State<NotificationGate> {

  void setupForegroundMessage() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return; 

      if (message.notification != null) {
        showMessageNotification(message, context); 
      }
    });
  }

  @override 
  void initState() {
    super.initState();
    setupForegroundMessage(); 
  }

  @override
  Widget build(BuildContext context) {
    return const AuthGate(); 
  }
}