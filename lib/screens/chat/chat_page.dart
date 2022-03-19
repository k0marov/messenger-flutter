import 'dart:async';

import 'package:keyboard_attachable/keyboard_attachable.dart';
import 'package:messenger/screens/chat/author_widget.dart';
import 'package:messenger/screens/profile/group_page.dart';
import 'package:messenger/shared/last_seen.dart';
import 'package:messenger/shared/message_preview.dart';
import 'package:messenger/models/chat_model.dart';
import 'package:messenger/screens/profile/profile_page.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'messenger_input.dart'; 
import '../../models/message_model.dart'; 
import 'message_widget.dart'; 
import 'dart:io' show File; 
import 'timestamp_widget.dart'; 

import 'logic.dart' as logic; 
import '../../shared/shared_logic.dart' as shared_logic; 

class ChatPage extends StatefulWidget {
  final ChatModel chat; 
  const ChatPage(
    { 
      required this.chat, 
      Key? key 
  }) : 
    super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ItemScrollController scrollController; 
  MessageModel? currentlyReplied; 
  int messagesLength = 0; 

  @override 
  void initState() {
    scrollController = ItemScrollController(); 
    super.initState();
  }

  void _scrollToEnd() {
    scrollController.scrollTo(
      index: messagesLength == 0 ? 0 : messagesLength - 1, 
      duration: const Duration(milliseconds: 100), 
      alignment: 0, 
    ); 
  }

  void _sendText(String text) async {
    final chosenReply = currentlyReplied?.ref; 
    setState(() {currentlyReplied = null;}); 
    logic.sendMessage(
      chatId: widget.chat.id, 
      text: text, 
      replyTo: chosenReply, 
      isForwarded: false, 
    ); 
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        _scrollToEnd(); 
      }
    }); 
  }

  void _sendAudio(File audio) async {
    logic.sendMessage(
      chatId: widget.chat.id, 
      text: "", 
      voiceMessage: audio,
      voiceDuration: await logic.getDuration(audio),
      replyTo: currentlyReplied?.ref, 
      isForwarded: false, 
    ); 
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        _scrollToEnd(); 
      }
    }); 
    setState(() {currentlyReplied = null;}); 
  }

  void _attachReplied(MessageModel replied) {
    setState(() {
      currentlyReplied = replied; 
    }); 
  }
  void _repliedTapped(int indexOfReplied) {
    scrollController.scrollTo(
      index: indexOfReplied, 
      duration: const Duration(milliseconds: 100), 
      alignment: 0, 
    ); 
  }

  void _sendFile() async {
    final image = await shared_logic.selectImage(false); 
    if (image == null) return;
    logic.sendMessage(
      chatId: widget.chat.id, 
      text: "", 
      image: image, 
      imgAspectRatio: await logic.getAspectRatioOfImage(image), 
      replyTo: currentlyReplied?.ref, 
      isForwarded: false, 
    ); 
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        _scrollToEnd(); 
      }
    }); 
    setState(() {currentlyReplied = null;}); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder:(context) => widget.chat.isGroup ? 
                GroupPage(chat: widget.chat)
              : ProfilePage(
                  userId: widget.chat.getOtherUser()
                )
            )
          ),
          child: SizedBox(
            width: 250, 
            child: Padding(
              padding: const EdgeInsets.all(8.0), 
              child: FutureBuilder(
                future: widget.chat.getName(), 
                initialData: "", 
                builder: (ctx, displayNameSnapshot) => 
                  Column(
                    children: [
                      Text(displayNameSnapshot.data.toString()),
                      if (widget.chat.isGroup) 
                        StreamBuilder(
                          stream: shared_logic.membersStream(widget.chat.id), 
                          initialData: 0, 
                          builder:(context, snapshot) => 
                            Text("${snapshot.data} members", 
                              style: Theme.of(context).textTheme.caption, 
                            )
                        )
                      else 
                        LastSeen(
                          userId: widget.chat.getOtherUser(), 
                          textStyle: Theme.of(context).textTheme.caption, 
                          asStream: true, 
                        )
                    ],
                  ) 
              ),
            ),
          ),
        )
      ),
      body: FooterLayout(
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: logic.getMessages(widget.chat.id), 
                  builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                    // print(snapshot.data); 
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator()); 
                    } else {
                      final messagesAndTimestamps = snapshot.data!; 
                      messagesLength = messagesAndTimestamps.length; 
                      return ScrollablePositionedList.builder(
                        itemScrollController: scrollController,
                        semanticChildCount: messagesAndTimestamps.length,
                        itemCount: messagesAndTimestamps.length, 
                        physics: const ClampingScrollPhysics(), 
                        initialScrollIndex: messagesAndTimestamps.isEmpty ? 0 :  messagesAndTimestamps.length - 1, 
                        itemBuilder: (context, index) {
                          final elem = messagesAndTimestamps[index]; 
                          return elem.runtimeType == Timestamp 
                            ? TimestampWidget(timestamp: elem) 
                            : MessageWidget(
                              msg: elem, 
                              isFromGroup: widget.chat.isGroup, 
                              attachReplied: () => _attachReplied(elem),
                              repliedTapped: (elem as MessageModel).replyTo != null ? 
                                () => _repliedTapped((elem).replyToIndex!)
                              : () {} 
                            ); 
                        }
                      ); 
                    }
                  },
                ),
              ),
              if (currentlyReplied != null)  
                ListTile(
                  style: ListTileStyle.drawer, 
                  tileColor: Theme.of(context).cardColor, 
                  leading: const Icon(Icons.reply), 
                  title: AuthorWidget(authorId: currentlyReplied!.sentBy), 
                  subtitle: MessagePreview(
                    msg: currentlyReplied!, 
                  ), 
                  trailing: IconButton(
                    icon: const Icon(Icons.close), 
                    onPressed: () => setState(() => currentlyReplied = null), 
                  )
                )
            ],
          ),
        ), 
        footer: MessengerInput(
          sendText: _sendText, 
          sendAudio: _sendAudio, 
          sendFile: _sendFile, 
        ), 
      )
    );
  }
}
