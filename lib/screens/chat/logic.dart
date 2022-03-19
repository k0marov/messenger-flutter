
import 'dart:io'; 
import 'dart:typed_data'; 
import 'package:flutter/material.dart'; 

import '../../models/message_model.dart'; 
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:just_audio/just_audio.dart'; 

import '../../shared/shared_logic.dart' as shared_logic; 

final storage = FirebaseStorage.instance; 
final db = FirebaseFirestore.instance; 

Future deleteMsg(MessageModel msg) {
  return msg.ref.delete(); 
}


enum MessageStatus {
  error, 
  loading, 
  sent, 
  seen 
} 
Stream<MessageStatus> messageStatus(DocumentReference msgRef) {
  return msgRef
    .snapshots(includeMetadataChanges: true)
    .map((snapshot) {
      if (!snapshot.exists) return MessageStatus.error; 

      final msg = MessageModel.fromJson({
        'ref': msgRef, 
        ...(snapshot.data()! as Map<String, dynamic>)
      }); 
      if (msg.isUploadingMedia() && 
        DateTime.now().difference(msg.createdAt.toDate().toLocal()).inMinutes >= 5) {
        return MessageStatus.error; 
      }
      if (snapshot.metadata.hasPendingWrites || msg.isUploadingMedia()) {
        return MessageStatus.loading; 
      } else if (msg.seenBy.isEmpty) {
        return MessageStatus.sent; 
      } else {
        return MessageStatus.seen; 
      }
    }); 
}



Stream<List<dynamic>> getMessages(String chatId) {
  return db.collection('chats')
            .doc(chatId).collection("messages")
            .orderBy("createdAt")
            .withConverter<MessageModel>(
            toFirestore: (message, _) => message.toJson(), 
            fromFirestore: (snapshot, _)  => MessageModel.fromJson({
              'ref': snapshot.reference, 
              ...snapshot.data()!
            })
            )
            .snapshots() 
            .map((snapshot) {
              final messages = snapshot.docs 
                .map((doc) => doc.data()) 
                .where((msg) => msg.sentBy == shared_logic.getUserId() || !msg.isUploadingMedia()) 
                .toList(); 
              messages.forEach(markAsSeen); 
              final withTimestamps = addTimestamps(messages); 
              final withReplies = addReplies(withTimestamps); 
              return withReplies; 
            })
            ; 
}

List<dynamic> addTimestamps(List<MessageModel> messages) {
  if (messages.isEmpty) return []; 
  List<dynamic> res = [messages[0].createdAt]; 
  for (MessageModel msg in messages) {
    final prevTime = res.last is Timestamp ? 
                     res.last : 
                     (res.last as MessageModel).createdAt; 
    if (isAnotherDay(prevTime, msg.createdAt)) {
      res.add(msg.createdAt); 
    }
    res.add(msg); 
  }
  return res; 
}

bool isAnotherDay(Timestamp first, Timestamp second) {
  DateTime firstDate = first.toDate(), secondDate = second.toDate(); 
  return  firstDate.day != secondDate.day || 
          firstDate.month != secondDate.month || 
          firstDate.year != secondDate.year; 
}

List<dynamic> addReplies(List<dynamic> messages) => 
  messages.map(
    (elem) {
      if (elem is Timestamp || (elem as MessageModel).replyTo == null) return elem; 
      elem.replyToIndex = messages.indexWhere((msg) => msg is MessageModel && msg.ref == elem.replyTo!); 
      if (elem.replyToIndex == -1) {
        elem.replyTo = null; 
        return elem; 
      } else {
        elem.replyToLoaded = messages[elem.replyToIndex!]; 
      }
      return elem; 
    } 
  )
  .toList();


void forwardMessage(MessageModel msg, List<String> recepients) {
  for (final chatId in recepients) {
    db.collection("chats").doc(chatId).collection("messages").add({
      'createdAt': FieldValue.serverTimestamp(), 
      'sentBy': shared_logic.getUserId(), 
      'seenBy': [], 
      'text': msg.text,  
      'imageDlUrl': msg.imageDlUrl, 
      'imgAspectRatio': msg.imgAspectRatio, 
      'voiceDlUrl': msg.voiceDlUrl, 
      'isForwarded': true, 
    }); 
  }
}


Future updateChatActivity(String chatId) {
  return db.collection("chats").doc(chatId).update({
    'lastActivityAt': FieldValue.serverTimestamp(), 
  }); 
}


Future uploadImage(DocumentReference msgRef, Uint8List image) {
  final msgId = msgRef.id; 
  final chatId = msgRef.parent.parent!.id;
  final imageRef = storage.ref("chatMedia/$chatId/${msgId}_image"); 
  return imageRef
    .putData(image) 
    .then((_) => imageRef.getDownloadURL())
    .then((url) => msgRef.update({
      'imageDlUrl': url 
    }))
    .then((_) => updateChatActivity(chatId)); 
}
Future uploadVoiceMessage(DocumentReference msgRef, File voice) {
  final msgId = msgRef.id; 
  final chatId = msgRef.parent.parent!.id;
  final voiceRef = storage.ref("chatMedia/$chatId/${msgId}_voice.m4a"); 
  return voiceRef
    .putFile(voice)
    .then((_) => voiceRef.getDownloadURL())
    .then((url) => msgRef.update({
      'voiceDlUrl': url 
    }))
    .then((_) => updateChatActivity(chatId)); 
}

Future<int> getDuration(File audio) async {
  final player = AudioPlayer(); 
  final duration = await player.setFilePath(audio.path); 
  player.dispose(); 
  return duration!.inMilliseconds; 
}

Future sendMessage({
  required String chatId, 
  required String text, 
  required bool isForwarded, 
  Uint8List? image, 
  double? imgAspectRatio, 
  File? voiceMessage, 
  int? voiceDuration, 
  DocumentReference? replyTo, 
}) {
  final String newId = shared_logic.getRandomId(); 
  final msgRef = db.collection("chats").doc(chatId).collection("messages").doc(newId); 
  return msgRef.set({
    'text': text, 
    'sentBy': shared_logic.getUserId(), 
    'createdAt': FieldValue.serverTimestamp(), 
    'seenBy': [], 
    'imgAspectRatio': imgAspectRatio, 
    'voiceDuration': voiceDuration, 
    'replyTo': replyTo, 
    'isForwarded': isForwarded, 
  })
  .then((_) {
    if (image == null && voiceMessage == null) updateChatActivity(chatId); 
    if (image != null) uploadImage(msgRef, image); 
    if (voiceMessage != null) uploadVoiceMessage(msgRef, voiceMessage); 
  }); 
}

void markAsSeen(MessageModel msg) {
  if (msg.sentBy != shared_logic.getUserId() && !msg.seenBy.contains(shared_logic.getUserId())) {
    msg.ref.update({
      'seenBy': FieldValue.arrayUnion([shared_logic.getUserId()]) 
    }); 
  }
}


Future<double> getAspectRatioOfImage(Uint8List image) {
  return decodeImageFromList(image).then((img) => img.width/img.height); 
}
