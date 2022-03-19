import 'package:flutter/material.dart';
import 'package:messenger/models/message_model.dart'; 

class MessagePreview extends StatelessWidget {
  final MessageModel? msg; 
  const MessagePreview({ 
    required this.msg, 
    Key? key 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (msg == null) {
      return const Text(""); 
    } else if (msg!.isImage()) {
      return const Align(
        alignment: Alignment.centerLeft, 
        child: Icon(Icons.image, size: 20), 
      ); 
    } else if (msg!.isVoice()) {
      return const Align(
        alignment: Alignment.centerLeft, 
        child: Icon(Icons.mic, size: 20), 
      );  
    } else {
      return Text(
        msg!.text, 
        maxLines: 1, 
        overflow: TextOverflow.ellipsis, 
      ); 
    }
  }
}