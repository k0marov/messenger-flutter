import 'package:flutter/material.dart';
import 'shared_logic.dart' as shared_logic;
import 'package:firebase_image/firebase_image.dart'; 

class ProfileImage extends StatelessWidget {
  final String? avatarId; 
  final bool isGroup; 
  const ProfileImage({ 
    required this.avatarId, 
    required this.isGroup, 
    Key? key 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: shared_logic.getAvatarLocation(avatarId, isGroup), 
      builder: (context, snapshot) {
        return AspectRatio(
          aspectRatio: 1,
          child: SizedBox(
            height: double.infinity,
            child: !snapshot.hasData || snapshot.data == null? 
              FutureBuilder(
                future: shared_logic.getUserColor(avatarId, isGroup), 
                initialData: 0, 
                builder:(context, AsyncSnapshot<int> snapshot) {
                  final color = shared_logic.userColors[snapshot.data ?? 0]; 
                  return Container(
                    color: color, 
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: FittedBox(
                        fit: BoxFit.fill, 
                        child: Icon(
                            isGroup ? Icons.group : Icons.person, 
                          ),
                      ),
                    ),
                  ); 
                },
              )
            : Image(
              fit: BoxFit.fill, 
              image: FirebaseImage(
                snapshot.data!.toString()
              ), 
              frameBuilder:(context, child, frame, wasSynchronouslyLoaded) => 
                frame != null ? 
                  child 
                : const CircularProgressIndicator() 
            ),
          ),
        ); 
      } 
    ); 
  }
}