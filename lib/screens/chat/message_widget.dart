import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:messenger/screens/chat/author_widget.dart';
import 'package:messenger/screens/chat/forward_dialog.dart';
import 'package:messenger/screens/chat/fullscreen_image.dart'; 
import '../../models/message_model.dart'; 
import 'package:swipeable_tile/swipeable_tile.dart'; 
import 'replied_message.dart'; 
import 'dart:math' show pi; 
import 'voice_message.dart'; 
import 'logic.dart' as logic; 
import '../../shared/shared_logic.dart' as shared_logic; 


enum MessageAction {
  reply, 
  forward, 
  delete, 
}



class MessageWidget extends StatefulWidget {
  final MessageModel msg; 
  final void Function() attachReplied; 
  final void Function() repliedTapped; 
  final bool isFromGroup; 
  const MessageWidget({ 
    required this.msg, 
    required this.isFromGroup, 
    required this.attachReplied, 
    required this.repliedTapped, 
    Key? key 
  }) : super(key: key); 

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
    late bool isMine; 
    bool isDelivered = false; 
    late String formattedTime; 
    late final StreamSubscription statusSubscription; 
     
    @override 
    void initState() {
      isMine = shared_logic.getUserId() == widget.msg.sentBy; 
      statusSubscription = logic.messageStatus(widget.msg.ref).listen((status) {
        setState(() {
          isDelivered = status == logic.MessageStatus.sent || status == logic.MessageStatus.seen; 
        }); 
      }); 
      formattedTime = formatDate(widget.msg.createdAt.toDate()); 
      super.initState(); 
    }

    @override 
    void dispose() {
      statusSubscription.cancel(); 
      super.dispose(); 
    }

  String formatDate(DateTime date) {
    final date = widget.msg.createdAt.toDate().toLocal(); 
    final hour = date.hour.toString().padLeft(2, '0'); 
    final minute = date.minute.toString().padLeft(2, '0'); 
    return "$hour:$minute"; 
  }

  Widget _buildImage(Widget image) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(8.0)),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FullScreenImage(
              image: image, 
              heroTag: "image_${widget.msg.createdAt}", 
              appBarTitle: AuthorWidget(authorId: widget.msg.sentBy)
            ),
          )
        ), 
        child: Hero(
          tag: "image_${widget.msg.createdAt}", 
          child: image
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    Widget? placeholder = widget.msg.isImage() ? 
      AspectRatio(
        aspectRatio: widget.msg.imgAspectRatio!,
        child: const Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: CircularProgressIndicator(color: Colors.white)
          )
        )
      ) 
    : null; 

    if (widget.msg.isUploadedImage()) {
      return _buildImage(
        AspectRatio(
          aspectRatio: widget.msg.imgAspectRatio!,
          child: CachedNetworkImage(
            imageUrl: widget.msg.imageDlUrl!, 
            placeholder: (_, __) => placeholder!,
            errorWidget: (context, _, tmp) {
              return const Center(
                child: Text("Sorry, this image was deleted. :(") 
              );
            },
            fit: BoxFit.fitWidth, 
          ),
        )
      ); 
    } else if (widget.msg.isImage() && widget.msg.isUploadingMedia()) { 
      return _buildImage(placeholder!); 
    } else if (widget.msg.text.isNotEmpty) {
      return Text(widget.msg.text); 
    } 
    // then it is a voice message, either uploading or already uploaded 
    return VoiceMessage(
      url: widget.msg.voiceDlUrl, 
      duration: widget.msg.voiceDuration!, 
    ); 
  }

  Widget _buildMainMessage() {
    return Padding(
      padding: const EdgeInsets.all(4.0), 
      child: Stack(
          children: [
            if (widget.isFromGroup && !isMine) 
              Container(
                margin: widget.msg.isForwarded ? const EdgeInsets.only(right: 80.0) : EdgeInsets.zero,
                child: AuthorWidget(authorId: widget.msg.sentBy), 
              ), 
            if (widget.msg.isForwarded) 
              Positioned(
                top: 0, right: 0, 
                child: ForwardedWidget(context: context)
              ), 
            Padding(
              padding: EdgeInsets.only(bottom: 20, right: 10, left: 5, 
                top: widget.isFromGroup && !isMine || widget.msg.isForwarded ? 20 : 5, 
              ), 
              child: _buildMessageContent()
            ), 
            Positioned(
              right: 2, bottom: 2, 
              child: Row(
                children: [
                  Text(formattedTime, textScaleFactor: 0.8,),
                  if (isMine) 
                    StreamBuilder(
                      initialData: logic.MessageStatus.loading, 
                      stream: logic.messageStatus(widget.msg.ref), 
                      builder:(context, AsyncSnapshot<logic.MessageStatus>snapshot) {
                        switch (snapshot.data!) {
                          case logic.MessageStatus.error: 
                            return const Icon(Icons.error, size: 15.0); 
                          case logic.MessageStatus.seen: 
                            return const Icon(Icons.done_all, size: 15.0); 
                          case logic.MessageStatus.sent: 
                            return const Icon(Icons.done, size: 15.0); 
                          case logic.MessageStatus.loading: 
                            return const SizedBox(
                              width: 13, 
                              height: 13, 
                              child: CircularProgressIndicator(
                                color: Colors.white, 
                                strokeWidth: 1,
                              )
                            ); 
                        }
                      }
                    )
                ],
              )
            )
          ]
        ),
    );

  }
  Widget _buildCard() {
    final mainMessage = _buildMainMessage(); 
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: _getMaxWidth(context), 
      ),
      child: Card(
        color: isMine ? Theme.of(context).primaryColor : Theme.of(context).cardColor, 
        margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 3), 
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.msg.replyTo == null ? 85 : 100
          ), 
          child: widget.msg.replyTo == null 
            ? mainMessage 
            : IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: widget.repliedTapped, 
                    child: RepliedMessage(
                      replied: widget.msg.replyToLoaded!
                    ),
                  ), 
                  mainMessage
                ],
              ),
            ),
        )
      ),
    );
  }

  double _getMaxWidth(BuildContext context) => 
    MediaQuery.of(context).size.width * 
      (widget.msg.isImage() ? 0.8 : 0.6); 

  Offset? _tapPosition; 

  void rememberTapDetails(TapDownDetails details) {
    _tapPosition = details.globalPosition; 
  }

  void showMessageMenu(context) async {
    if (_tapPosition == null) return; 
    final screenSize = MediaQuery.of(context).size; 
    final result = await showMenu<MessageAction>(
      context: context, 
      position: RelativeRect.fromLTRB(
        _tapPosition!.dx, 
        _tapPosition!.dy, 
        screenSize.width - _tapPosition!.dx, 
        screenSize.height - _tapPosition!.dy, 
      ), 
      items: [
        if (isDelivered)
          const PopupMenuItem(
            value: MessageAction.reply, 
            child: Text("Reply"), 
          ), 
        if (isDelivered)
          const PopupMenuItem(
            value: MessageAction.forward, 
            child: Text("Forward"), 
          ), 
        if (isMine)
          const PopupMenuItem(
            value: MessageAction.delete, 
            child: Text("Delete", style: TextStyle(color: Colors.red)), 
          ), 
      ]
    ); 
    if (result == null) return; 
    if (result == MessageAction.forward) {
      final selected = await showGeneralDialog<List<String>>(
        context: context, 
        barrierDismissible: true, 
        barrierLabel: "Barrier",
        pageBuilder:(context, animation, secondaryAnimation) => 
          const ForwardDialog()
      ); 
      if (selected == null) return; 
      logic.forwardMessage(widget.msg, selected); 
    } else if (result == MessageAction.reply) {
      widget.attachReplied(); 
    } else if (result == MessageAction.delete) {
      logic.deleteMsg(widget.msg); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft, 
      child: GestureDetector(
        onLongPress: () => showMessageMenu(context),
        onTapDown: rememberTapDetails,
        child: SwipeableTile.swipeToTigger(
          key: Key(widget.msg.ref.id), 
          direction: isMine ? SwipeDirection.endToStart : SwipeDirection.startToEnd,
          color: Colors.transparent, 
          backgroundBuilder: (context, direction, progress) => Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft, 
            child: Padding(
              padding: isMine ? const EdgeInsets.only(right: 8.0) : const EdgeInsets.only(left: 8.0), 
              child: const Icon(Icons.reply),
            )
          ), 
          movementDuration: const Duration(milliseconds: 50),
          onSwiped: (direction) => isDelivered ? widget.attachReplied() : null, 
          child: _buildCard()
        ),
      ), 
    );
  }
}

class ForwardedWidget extends StatelessWidget {
  const ForwardedWidget({
    Key? key,
    required this.context,
  }) : super(key: key);

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(pi),
          child: const Icon(Icons.reply, size: 16, color: Colors.white38, ), 
        ),
        Text("Forwarded", style: Theme.of(context).textTheme.caption),
      ],
    );
  }
}
