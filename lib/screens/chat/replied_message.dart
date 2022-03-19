import 'package:flutter/material.dart';
import 'package:messenger/screens/chat/author_widget.dart';
import 'package:messenger/shared/message_preview.dart'; 
import '../../models/message_model.dart'; 
class RepliedMessage extends StatelessWidget {
  const RepliedMessage({
    Key? key,
    required this.replied,
  }) : super(key: key);

  final MessageModel replied;

  @override
  Widget build(BuildContext context) => 
    Container(
      padding: const EdgeInsets.all(2.0), 
      decoration: BoxDecoration(
        color: Theme.of(context).focusColor, 
        borderRadius: const BorderRadius.all(Radius.circular(8.0))
      ), 
      margin: const EdgeInsets.only(right: 4.0, top: 4.0, left: 4.0, ), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthorWidget(authorId: replied.sentBy), 
          MessagePreview(
            msg: replied
          ), 
        ],
      ) 
    );
}