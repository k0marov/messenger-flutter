import '../../models/chat_model.dart'; 
import '../../models/status_model.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:stream_transform/stream_transform.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:flutter_contacts/flutter_contacts.dart'; 
import 'package:firebase_database/firebase_database.dart'; 
import 'dart:async'; 

import '../../shared/shared_logic.dart' as shared_logic; 

final db = FirebaseFirestore.instance; 
final storage = FirebaseStorage.instance; 



Stream<ChatModel> chatStream(String id) {
  return db.collection("chats").doc(id).withConverter<ChatModel>(
    toFirestore: (value, _) => value.toJson(), 
    fromFirestore: (snapshot, _) => ChatModel.fromJson({
        'id': snapshot.id, 
        ...(snapshot.data() as Map<String, dynamic>)
      })
    ) 
  .snapshots().map((snapshot) => snapshot.data()!); 
}


Future<bool> checkUsername(String username) {
  return db.collection("users").where('username', isEqualTo: username)
    .get()
    .then((snapshot) => snapshot.docs.isEmpty); 
}




class MemberWithStatus {
  final String userId; 
  final StatusModel status; 
  const MemberWithStatus({
    required this.userId, 
    required this.status, 
  }); 
} 

Stream<List<MemberWithStatus>> sortMembersByOnline(List<String> members) {
  final firstStream = shared_logic.getUserStatus(members[0])
    .map((status) => MemberWithStatus(
      status: status, 
      userId: members[0], 
    )); 
  return firstStream.combineLatestAll(
    members.sublist(1).map((userId) => 
      shared_logic.getUserStatus(userId).map((status) => MemberWithStatus(
        userId: userId, 
        status: status, 
      ))
    ) 
  )
  .map((list) {
    list.sort((first, second) => second.status.when.compareTo(first.status.when)); 
    return list; 
  }); 
}



Future logout() async {
  final isOnlineRef = FirebaseDatabase.instance
                      .ref("status/"+shared_logic.getUserId()); 
  isOnlineRef.set({
    'online': false, 
    'when': ServerValue.timestamp, 
  }); 
  await FirebaseMessaging.instance.deleteToken(); 
  return FirebaseAuth.instance.signOut();
}



void addContact(String phone, String displayName) async {
  final newContact = Contact() 
    ..name.first = displayName 
    ..phones = [Phone(phone)]; 
  final id = (await newContact.insert()).id; 
  await FlutterContacts.openExternalEdit(id); 
  shared_logic.mergeContactsWithServer(); 
}







Future selectNewAvatar(String id, bool isGroup) async {
  final image = await shared_logic.selectImage(true); 
  if (image == null) return; //throw "Image error"; 

  try {
    final ref = storage.ref("avatars/$id/"+shared_logic.getRandomId()); 
    await ref.putData(image); 
    final url = shared_logic.kStorageUrl + ref.fullPath; 

    final dbRef = isGroup ? db.collection("chats").doc(id) : db.collection("users").doc(id); 
    return dbRef.set({
      "avatarUrl": url, 
    }, SetOptions(merge: true)); 
  } catch (e) {
    shared_logic.showException("Image upload failed"); 
  }
}


Future addMember(String chatId, String userId) {
  return db.collection("chats").doc(chatId).update({
    'members': FieldValue.arrayUnion([userId])
  }); 
}

Future deleteMember(String chatId, String userId) {
  return db.collection("chats").doc(chatId).update({
    'members': FieldValue.arrayRemove([userId]), 
  }); 
}

Stream<String> displayNameStream() {
  return db.collection("users").doc(shared_logic.getUserId()).snapshots()
    .map((snapshot) => snapshot.data()?['displayName'] ?? ""); 
}