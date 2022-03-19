import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp; 
import '../shared/shared_logic.dart' as shared_logic; 

class StatusModel {
  final bool online; 
  final Timestamp when; 
  StatusModel({
    required this.online, 
    required this.when, 
  }); 

  @override 
  String toString() => online ? 
    "Online" 
  : "Last seen " + shared_logic.getLastSeen(when); 


  StatusModel.fromJson(Map<String, dynamic> json) : this(
    online: json['online'], 
    when: Timestamp.fromMillisecondsSinceEpoch(json['when']), 
  ); 
  Map<String, dynamic> toJson() => {
    'online': online, 
    'when': when, 
  }; 
}