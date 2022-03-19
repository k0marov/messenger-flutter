import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/shared_logic.dart' as shared_logic; 

class ChatModel {
  String id; 
  List<String> members; 
  bool isGroup; 
  Timestamp lastActivityAt; 

  // for groups 
  String? title; 
  int? color; 
  List<String>? admins; 


  Future<String> getName() async {
    if (isGroup) return title!; 
    return shared_logic.getDisplayNameWithYou(getOtherUser()); 
  }

  String getOtherUser() {
    return members.firstWhere((user) => user != shared_logic.getUserId()); 
  }

  String getAvatarId() {
    if (isGroup) return id; 
    return getOtherUser(); 
  }

  ChatModel({
    required this.id, 
    required this.members, 
    required this.isGroup, 
    required this.lastActivityAt, 

    this.title, 
    this.color, 
    this.admins, 

  }); 

  ChatModel.fromJson(Map<String, dynamic> json) : this(
    id: json['id'] as String, 
    members: (json['members'] as List).map<String>((member) => member.toString()).toList(), 
    isGroup: json['isGroup'] as bool, 
    lastActivityAt: json['lastActivityAt'] as Timestamp? ?? Timestamp.now(), 

    title: json['title'] as String?, 
    color: json['color'] as int?, 
    admins: (json['admins'] as List?)?.cast<String>(), 
  );

  Map<String, dynamic> toJson() => {
    'members': members, 
    'isGroup': isGroup, 
    'lastActivityAt': lastActivityAt, 

    'title': title, 
    'color': color, 
    'admins': admins, 
  }; 
}