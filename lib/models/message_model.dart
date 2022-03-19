import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/shared_logic.dart' as shared_logic; 

class MessageModel {
  final DocumentReference ref; 
  final String text; 
  final bool isForwarded; 
  final String sentBy; 
  final Timestamp createdAt; 
  List<String> seenBy; 

  final String? imageDlUrl; 
  final double? imgAspectRatio; 

  final String? voiceDlUrl; 
  final int? voiceDuration;  


  DocumentReference? replyTo; 

  // not in db
  // bool isPending; 
  MessageModel? replyToLoaded; 
  int? replyToIndex; 


  bool isNew() => !(sentBy == shared_logic.getUserId()) && !seenBy.contains(shared_logic.getUserId()); 

  MessageModel({
    required this.ref,

    required this.text, 
    required this.sentBy, 
    required this.createdAt, 
    required this.seenBy,
    required this.isForwarded, 

    this.imageDlUrl, 
    this.imgAspectRatio, 

    this.voiceDlUrl, 
    this.voiceDuration, 

    this.replyTo, 

    // this.isPending = false, 
    this.replyToLoaded, 
    this.replyToIndex, 

  }); 

  bool isUploadingMedia() {
    return (imageDlUrl == null && isImage()) || (voiceDlUrl == null && isVoice()); 
  }
  bool isUploadedImage() => imageDlUrl != null; 
  bool isUploadedVoice() => voiceDlUrl != null; 
  bool isImage() => imgAspectRatio != null; 
  bool isVoice() => voiceDuration != null; 

  MessageModel.fromJson(Map<String, dynamic> json) : this(
    ref: json['ref'] as DocumentReference, 

    text: json['text']! as String, 
    sentBy: json['sentBy']! as String, 
    seenBy: (json['seenBy']! as List).cast<String>(), 
    createdAt: json['createdAt'] == null ? Timestamp.now() : json['createdAt']! as Timestamp, 
    isForwarded: json['isForwarded'] as bool? ?? false, 

    replyTo: json['replyTo'], 

    imageDlUrl: json['imageDlUrl'] as String?, 
    imgAspectRatio: json['imgAspectRatio'] as double?, 

    voiceDlUrl: json['voiceDlUrl'] as String?, 
    voiceDuration: json['voiceDuration'] as int?, 
  ); 

  Map<String, dynamic> toJson() => {
    'text': text, 
    'sentBy': sentBy, 
    'createdAt': createdAt, 
    'seenBy': seenBy, 

    'imageDlUrl': imageDlUrl, 
    'imgAspectRatio': imgAspectRatio, 

    'voiceDlUrl': voiceDlUrl, 
    'voiceDuration': voiceDuration, 

    'replyTo': replyTo, 
    'isForwarded': isForwarded, 
  }; 
}