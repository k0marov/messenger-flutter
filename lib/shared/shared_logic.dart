import '../models/chat_model.dart'; 
import '../models/contact_model.dart'; 
import '../models/status_model.dart'; 
import '../models/user_model.dart'; 
import 'package:flutter/material.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; 
import 'package:flutter_image_compress/flutter_image_compress.dart'; 
import 'package:flutter_contacts/flutter_contacts.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'dart:io'; 
import 'dart:typed_data'; 
import 'dart:math' as math; 
import 'dart:async'; 
import 'package:firebase_database/firebase_database.dart'; 
import 'package:uuid/uuid.dart'; 

const kStorageUrl = "gs://messenger-in-flutter.appspot.com/"; 

final storage = FirebaseStorage.instance; 
final db = FirebaseFirestore.instance; 

Stream<String> usernameStream() {
  return db.collection("users").doc(getUserId()).snapshots()
    .map((snapshot) => snapshot.data()?['username'] ?? ""); 
}
Future<List<UserModel>> getUsersWithUsernameStarting(String username) async {
  if (username.isEmpty) return []; 
  final strFrontCode = username.substring(0, username.length - 1);
  final strEndCode = username.characters.last;
  final limit =
    strFrontCode + String.fromCharCode(strEndCode.codeUnitAt(0) + 1);

  return await FirebaseFirestore.instance
    .collection('users')
    .where('username', isGreaterThanOrEqualTo: username)
    .where('username', isLessThan: limit)
    .where('username', isNotEqualTo: await usernameStream().first)
    .withConverter<UserModel>(
      fromFirestore: ((snapshot, options) => UserModel.fromJson(snapshot.data()!, snapshot.id)), 
      toFirestore: (userModel, _) => userModel.toJson(), 
    ) 
    .limit(10)
    .get()
    .then((snapshot) => snapshot.docs.map((doc) => doc.data()).toList()); 
}

Future<Uint8List?> selectImage(bool cropAsAvatar) async {
  XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery); 
  if (pickedImage == null) return null; 
  File? croppedImage = await ImageCropper().cropImage(
    compressFormat: ImageCompressFormat.jpg,
    sourcePath: pickedImage.path, 
    aspectRatio: cropAsAvatar ? const CropAspectRatio(ratioX: 1, ratioY: 1) : null, 
    cropStyle: cropAsAvatar ? CropStyle.circle : CropStyle.rectangle, 
  ); 
  if (croppedImage == null) return null; 
  final compressedImage = await FlutterImageCompress.compressWithFile(
    croppedImage.absolute.path, 
    quality: 80, 
  ); 
  return compressedImage ?? croppedImage.readAsBytesSync(); 
}


Future<Map<String, String>> getLocalContacts() async {
  bool allowed = await FlutterContacts.requestPermission(); 
  if (!allowed) {
    showException("Contacts not allowed!\nPlease allow contacts in settings"); 
    return {}; 
  }
  final contacts = await FlutterContacts.getContacts(sorted: true, withProperties: true); 
  Map<String, String> formattedContacts = {}; 
  for (var contact in contacts) {
    if (contact.phones.isEmpty) continue; 
    final phone = formatPhone(contact.phones.first.number); 
    if (phone == FirebaseAuth.instance.currentUser?.phoneNumber) continue; 

    final name = contact.displayName; 
    formattedContacts[phone] = name; 
  } 
  return formattedContacts; 
}
Future mergeContactsWithServer() async {
  final batch = db.batch(); 
  final contactsRef = db.collection("users").doc(getUserId()).collection("contacts"); 

  final localContacts = await getLocalContacts(); 
  localContacts.forEach((phone, name) {
    final data = {
      // 'userId': getUserByNumber(phone), will be set on the server-side 
      'name': name, 
    }; 
    batch.set(contactsRef.doc(phone), data, SetOptions(merge: true)); 
  }); 
  return batch.commit(); 
}


Future<ChatModel> newChat(String otherUserId) async {
  // if (otherUserId == getUserId()) throw Exception("new chat has two identical contacts"); 

  final members = [getUserId(), otherUserId]; 
  members.sort(); 

  final maybeExistingChat = await db.collection("chats")
            .where('members', isEqualTo: members) 
            .where('isGroup', isEqualTo: false)
            .get(); 
  if (maybeExistingChat.docs.isNotEmpty) {
    return ChatModel.fromJson({
      'id': maybeExistingChat.docs.first.id, 
      ...maybeExistingChat.docs.first.data()
    }); 
  }
  final newId = getRandomId(); 
  await db.collection("chats").doc(newId).set({
    'members': members, 
    'isGroup': false, 
    'lastActivityAt': FieldValue.serverTimestamp(), 
  }); 
  return getChat(newId); 
}




Future updateUserData(Map<String, dynamic> newData) async {
  final user = FirebaseAuth.instance.currentUser; 
  if (user == null) return; 

  final userRef = db.collection("users").doc(user.uid); 
  if (newData['displayName'] != null) { 
    await user.updateDisplayName(newData['displayName']); 
  }
  return userRef.set(newData, SetOptions(merge: true)); 
}
 



String formatRepliedText(String text) {
  if (text.length >= 75) {
    return text.substring(0, 75) + "..."; 
  } else {
    return text; 
  }
}
final userColors = [
  Colors.black26, 
  Colors.red, 
  Colors.blue, 
  Colors.orange, 
  Colors.green, 
  Colors.yellow 
]; 
int getRandomColorIndex() {
  return math.Random().nextInt(userColors.length-1) + 1; 
}

Future<ChatModel> getChat(String chatId) {
  return db.collection("chats").doc(chatId).get()
    .then((snapshot) => ChatModel.fromJson({
      'id': snapshot.id, 
      ...snapshot.data()!
    })); 
}

Stream<List<ContactModel>> getContacts() {
  return db.collection("users").doc(getUserId()).collection("contacts").snapshots()
    .map((snapshot) => 
      snapshot.docs.map((doc) {
        final phone = doc.id; 
        final data = doc.data();
        final name = data['name'] as String; 
        final userId = data['userId'] as String?; 
        return ContactModel(
          contactsName: name, 
          userId: userId, 
          phone: phone, 
        ); 
      })
      .cast<ContactModel>()
      .toList()
    ); 
}


const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]; 


String getLastSeen(Timestamp whenTimestamp) {
  final when = whenTimestamp.toDate().toLocal(); 
  int minutesDiff = (1/1000/60 * 
    (Timestamp.now().millisecondsSinceEpoch - whenTimestamp.millisecondsSinceEpoch))
    .round(); 
  if (minutesDiff >= 365*24*60) return "in ${when.year}"; 
  if (minutesDiff >= 24*60) return "on ${when.day} ${monthNames[when.month-1]}"; 
  if (minutesDiff > 60) return "${(minutesDiff/60).round()} hours ago"; 
  if (minutesDiff == 60) minutesDiff = 59; // to ignore singulars 
  if (minutesDiff > 1) return "$minutesDiff minutes ago"; 
  return "seconds ago"; 
}




Stream<StatusModel> getUserStatus(String userId) {
  return FirebaseDatabase.instance.ref("status/$userId").onValue
    .map((event) {
      // if (event.snapshot.value == null) throw "No status for user $userId"; 
      final data = Map<String, dynamic>.from(event.snapshot.value as Map<Object?, Object?>); 
      final statusModel = StatusModel.fromJson(data); 
      return statusModel; 
    });
}


String getUserId() => FirebaseAuth.instance.currentUser!.uid; 




const uuid = Uuid(); 
String getRandomId() {
  return uuid.v1().substring(0,13); 
}




Map<String, String> namesCache = {}; 
Future<String> getDisplayName(String userId) async {
  if (userId == getUserId()) {
    return FirebaseAuth.instance.currentUser?.displayName ?? ""; 
  }
  final fromCache = namesCache[userId]; 
  if (fromCache != null) {
    return fromCache; 
  } else {
    try {
      final contacts = await getContacts().first; 
      String? fromContacts = contacts
        .firstWhere((contact) => contact.userId == userId)
        .contactsName; 
      namesCache[userId] = fromContacts;
      return fromContacts; 
    } catch (e) {
      return db.collection("users").doc(userId).get() 
             .then((doc) => doc.data()?['displayName'] ?? ""); 
    }
  }
}


Stream<List<ChatModel>> getChats() {
  return db.collection('chats')
    .orderBy("lastActivityAt", descending: true) 
    .where('members', arrayContains: getUserId())
    .withConverter<ChatModel>(
      toFirestore: (value, options) => value.toJson(),
      fromFirestore: (snapshot, options) => ChatModel.fromJson({
        'id': snapshot.id, 
        ...snapshot.data()!
      })
    )
    .snapshots()
    .map((snapshot) =>
      snapshot.docs.map((doc) => doc.data()).toList() 
    ); 
}


final _exceptionController = StreamController<String>(); 

void showException(String text) {
  _exceptionController.add(text); 
}

Stream<String> getExceptionStream() {
  return _exceptionController.stream; 
}

Stream<int> membersStream(String chatId) {
  return FirebaseFirestore.instance.collection("chats").doc(chatId).snapshots()
    .map((snapshot) => (snapshot.data()?['members'] as List).length); 
}


Future<String> getDisplayNameWithYou(String userId) async {
  if (userId == getUserId()) return "You"; 
  return getDisplayName(userId); 
}


String formatPhone(String phone) {
  return '+' + phone.characters.where((char) => "1234567890".contains(char)).string; 
}




Future<UserModel?> getUser(String userId) {
  return db.collection("users").doc(userId).get() 
    .then((snapshot) => snapshot.exists ? 
        UserModel.fromJson(snapshot.data()!, snapshot.id) 
      : null
    ); 
}


Future<int> getUserColor(String? id, bool isGroup) async {
  if (id == null) return 0; 
  String collection = isGroup ? "chats" : "users"; 
  return db.collection(collection).doc(id).get()
      .then((snapshot) => snapshot.data()?['color'] ?? 0); 
}



Stream<String?> getAvatarLocation(String? id, bool isGroup) {
  if (id == null) return const Stream.empty(); 
  final ref = db.collection(isGroup ? "chats" : "users").doc(id); 
  return ref
    .snapshots()
    .map((DocumentSnapshot<Map<String, dynamic>> snapshot) => 
      snapshot.data()?['avatarUrl']
    ); 
}
