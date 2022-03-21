import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/chat_model.dart'; 
import '../../models/message_model.dart'; 

import '../../shared/shared_logic.dart' as shared_logic; 

final db = FirebaseFirestore.instance; 
final storage = FirebaseStorage.instance; 

void deleteChat(ChatModel chat) async {
  final ref = db.collection("chats").doc(chat.id); 
  if (chat.isGroup) {
    ref.update({
      'members': FieldValue.arrayRemove([shared_logic.getUserId()]), 
      'admins': FieldValue.arrayRemove([shared_logic.getUserId()])
    }); 
  } else {
    ref.delete(); 
  }
}



Future<int> newMsgCount(String chatId) {
  return db.collection("chats") 
    .doc(chatId).collection("messages")
    .orderBy("createdAt", descending: true)
    .limit(11)
    .withConverter<MessageModel>(
    toFirestore: (message, _) => message.toJson(), 
    fromFirestore: (snapshot, _)  => MessageModel.fromJson({
      'ref': snapshot.reference, 
      ...snapshot.data()!
    }))
    .get()
    .then((snapshot) => 
      snapshot.docs.where((msg) => msg.data().isNew()).length
    ); 
}







Stream<MessageModel?> lastMessage(String chatId) {
  return db.collection("chats").doc(chatId)
    .collection('messages')
    .orderBy('createdAt', descending: true)
    .limit(1) 
    .withConverter<MessageModel>(
    toFirestore: (message, _) => message.toJson(), 
    fromFirestore: (snapshot, _)  => MessageModel.fromJson({
      'ref': snapshot.reference, 
      ...snapshot.data()!
    })
    )
    .snapshots()
    .map((snapshot) => snapshot.docs.isEmpty ? null : snapshot.docs.first.data()); 
}
