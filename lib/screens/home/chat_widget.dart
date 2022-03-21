import 'package:flutter/material.dart';
import 'package:messenger/screens/chat/chat_screen.dart';
import 'package:messenger/shared/message_preview.dart';
import 'package:messenger/models/chat_model.dart';
import 'package:messenger/models/message_model.dart';
import 'package:messenger/shared/profile_image.dart'; 
import 'logic.dart' as logic; 

enum ChatAction {
  delete 
}

class ChatWidget extends StatefulWidget {
  final ChatModel chat; 
  const ChatWidget({ 
    required this.chat, 
    Key? key 
  }) : super(key: key);

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  Offset? _tapPosition; 

  void _rememberTapDetails(TapDownDetails details) {
    _tapPosition = details.globalPosition; 
  }

  void _showChatMenu(context) async {
    if (_tapPosition == null) return; 
    final screenSize = MediaQuery.of(context).size; 
    final result = await showMenu<ChatAction>(
      context: context, 
      position: RelativeRect.fromLTRB(
        _tapPosition!.dx, 
        _tapPosition!.dy, 
        screenSize.width - _tapPosition!.dx, 
        screenSize.height - _tapPosition!.dy, 
      ), 
      items: [
        const PopupMenuItem(
          value: ChatAction.delete, 
          child: Text("Delete", style: TextStyle(color: Colors.red)), 
        ), 
      ]
    ); 
    if (result == ChatAction.delete) {
      _onDeleteTry(); 
    }
  }

  Future<bool> _showDeleteDialog() {
    return showDialog<bool>(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text("Are you sure you want to delete this chat?"), 
        actions: [
          ElevatedButton(
            child: const Text("No"), 
            onPressed: () => Navigator.pop(context, false)
          ), 
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Colors.red, 
            ), 
            child: const Text("Yes"), 
            onPressed: () => Navigator.pop(context, true),
          )
        ]
      )
    ).then((res) {
      return res ?? false; 
    }); 
  }

  void _onDeleteTry() async {
    if (await _showDeleteDialog()) {
      logic.deleteChat(widget.chat); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MessageModel?>(
      stream: logic.lastMessage(widget.chat.id), 
      builder: (context, snapshot) {
        final lastMsg = snapshot.data; 
        return Dismissible(
          direction: DismissDirection.endToStart, 
          dismissThresholds: const {
            DismissDirection.endToStart: 0.2
          },
          confirmDismiss: (direction) => _showDeleteDialog(), 
          background: Container(
            color: Colors.red, 
            child: const Align(
              alignment: Alignment.centerRight, 
              child: Padding(
                padding: EdgeInsets.only(right: 15),
                child: Icon(
                  Icons.delete, 
                  size: 25, 
                ),
              )
            ),
          ), 
          onDismissed: (_) => logic.deleteChat(widget.chat),
          key: Key(widget.chat.id), 
          child: ListTile(
            leading: ClipOval(
              child: ProfileImage(
                isGroup: widget.chat.isGroup, 
                avatarId: widget.chat.getAvatarId(), 
              ), 
            ), 
            title: FutureBuilder(
              future: widget.chat.getName(), 
              initialData: "",
              builder: (context, snapshot) => 
                Text(snapshot.data.toString())
            ), 
            subtitle: lastMsg == null ? 
              const Text("")
              : MessagePreview(
                msg: lastMsg, 
              ),
            trailing: lastMsg?.isNew() ?? false ? 
              FutureBuilder<int>(
                future: logic.newMsgCount(widget.chat.id), 
                builder: (context, snapshot) {
                  final count = snapshot.data; 
                  if (count == null || count == 0) return const SizedBox(); 
                  return AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.all(12), 
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle, 
                        color: Colors.blue, 
                      ),
                      child: Center(
                        child: Text(count > 9 ? "9+" : "$count")
                      ),
                    ),
                  ); 
                }
              )
            : InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              onTapDown: _rememberTapDetails,
              onTap: () => _showChatMenu(context),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.more_horiz),
              ),
            ), 
            onTap: () {
              Navigator.push(context, 
                MaterialPageRoute(
                  builder: (ctx) => ChatPage(chat: widget.chat),  
                )
              ); 
            }
          ),
        );
      }
    ); 
  }
}