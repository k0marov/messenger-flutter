import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/chat_model.dart'; 
import '../../shared/shared_logic.dart' as shared_logic;  


final db = FirebaseFirestore.instance; 

Future<ChatModel> newGroup(List<String> membersIds, String title) async {
  final ref = await db.collection('chats').add({
    'members': membersIds, 
    'isGroup': true, 
    'title': title, 
    'color': shared_logic.getRandomColorIndex(), 
    'admins': [shared_logic.getUserId()], 
    'lastActivityAt': FieldValue.serverTimestamp(), 
  }); 
  return shared_logic.getChat(ref.id); 
}



