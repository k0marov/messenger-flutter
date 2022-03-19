import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'screens/core/messenger_app.dart'; 
import 'package:flutter/foundation.dart'; 
import 'package:firebase_core/firebase_core.dart'; 
import 'firebase_options.dart'; 
import './screens/core/logic.dart' as logic; 

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized(); 
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // print(await FirebaseMessaging.instance.requestPermission()); 
    // print(await FirebaseMessaging.instance.getToken());
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true); 
    logic.initialize(); 
    runApp(const MessengerApp());
  }, (error, stack) {
    if (kDebugMode) {
      print(error);
    } 
  }); 
}
