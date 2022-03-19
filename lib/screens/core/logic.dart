import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../shared/shared_logic.dart' as shared_logic; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:firebase_database/firebase_database.dart'; // for realtime user presense


final db = FirebaseFirestore.instance; 



void updateStatus() async {
  final isOnlineRef = FirebaseDatabase.instance
                      .ref("status/"+shared_logic.getUserId()); 
  isOnlineRef.set({
    'online': true, 
    'when': ServerValue.timestamp, 
  }); 
  isOnlineRef.onDisconnect().set({
    'online': false, 
    'when': ServerValue.timestamp, 
  }); 
}




void initialize() async {
  FirebaseDatabase.instance.ref(".info/connected")
    .onValue.listen((snapshot) {
      if (snapshot.snapshot.value != false && FirebaseAuth.instance.currentUser!=null) {
        updateStatus(); 
      }
    }); 
  FirebaseAuth.instance.userChanges().listen((User? user) {
    if (user != null) {
      shared_logic.mergeContactsWithServer(); 
      updateStatus(); 
      updateUser(); 
    }
  }); 

}



void updateUser() async {
  final user = FirebaseAuth.instance.currentUser; 
  if (user == null) return; 

  final currentUserData = await shared_logic.getUser(user.uid); 
  final userRef = db.collection("users").doc(user.uid); 
  final newData = {
    // 'displayName': displayName, 
    'color': currentUserData?.color ?? shared_logic.getRandomColorIndex(), 
    //'phone': formatPhone(user.phoneNumber!),  set on server-side
  }; 
  userRef.set(newData, SetOptions(merge: true)); 

  final token = await FirebaseMessaging.instance.getToken(); 
  if (token != null) {
    userRef.collection("tokens").doc(token).set({
      'token': token
    }); 
  } 
}

