import 'package:flutter/material.dart';
import 'package:messenger/models/chat_model.dart';
import 'package:messenger/shared/profile_image.dart'; 
import '../../shared/shared_logic.dart' as shared_logic; 

class ForwardDialog extends StatefulWidget {
  const ForwardDialog({ Key? key }) : super(key: key);

  @override
  _ForwardDialogState createState() => _ForwardDialogState();
}

class _ForwardDialogState extends State<ForwardDialog> {
  List<String> _selected = []; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close), 
          onPressed: () => Navigator.of(context).pop(null) 
        ), 
        title: const Text("Forward Message"), 
        actions: [
          TextButton(
            child: const Text("Forward"), 
            onPressed: () => Navigator.of(context).pop(_selected) 
          )
        ], 
      ), 
      body: FutureBuilder<List<ChatModel>>(
        future: shared_logic.getChats().first, 
        builder:(context, snapshot) { 
          if (!snapshot.hasData) {
            return const CircularProgressIndicator(); 
          } else {
            final chats = snapshot.data!; 
            return ChatCheckBoxList(
              chats: chats.map((docSnapshot) => docSnapshot).toList(), 
              updateSelected: (newSelected) => _selected = newSelected 
            ); 
          }
        },
      )
    ); 
  }
}


class ChatCheckBoxList extends StatefulWidget {
  final List<ChatModel> chats; 
  final void Function(List<String>) updateSelected; 
  const ChatCheckBoxList({ 
    required this.chats, 
    required this.updateSelected, 
    Key? key 
  }) : super(key: key);

  @override
  _ChatCheckBoxListState createState() => _ChatCheckBoxListState();
}

class _ChatCheckBoxListState extends State<ChatCheckBoxList> {
  final List<String> _selected = []; 
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: widget.chats.map((chat) {
        final wasChecked = _selected.contains(chat.id); 
        return CheckboxListTile(
          title: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ClipOval(
              child: ProfileImage(
                avatarId: chat.getAvatarId(),
                isGroup: chat.isGroup,
              )
            ), 
            title: FutureBuilder<String>(
              future: chat.getName(), 
              initialData: "",
              builder:(context, snapshot) => Text(snapshot.data!),
            )
          ), 
          activeColor: Colors.blue,
          value: wasChecked, 
          onChanged: (value) => 
            setState(() {
              wasChecked ?
                _selected.remove(chat.id) 
              : _selected.add(chat.id); 
              widget.updateSelected(_selected); 
            })
        ); 
      }).toList() 
    ); 
  }
}