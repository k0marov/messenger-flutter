import 'package:flutter/material.dart';
import 'package:messenger/shared/contacts_list.dart';
import 'package:messenger/shared/last_seen.dart';
import 'package:messenger/models/chat_model.dart';
import 'package:messenger/screens/profile/my_profile_page.dart';
import 'package:messenger/shared/profile_image.dart';
import 'package:messenger/screens/profile/profile_page.dart'; 
import 'logic.dart' as logic; 
import '../../shared/shared_logic.dart' as shared_logic; 

class GroupPage extends StatelessWidget {
  final ChatModel chat; 
  const GroupPage({ 
    required this.chat, 
    Key? key 
  }) : super(key: key); 

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object>(
      stream: logic.chatStream(chat.id), 
      builder: (context, snapshot) {
        late ChatModel newChat; 
        if (!snapshot.hasData) {
          newChat = chat; 
        } else {
          newChat = snapshot.data! as ChatModel; 
        }
        final isAdmin = newChat.admins!.contains(shared_logic.getUserId()); 
        return Scaffold(
          appBar: AppBar(
            title: Text(newChat.title!),
          ), 
          body: ListView(
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ProfileImage(
                      isGroup: true, 
                      avatarId: newChat.id
                    )
                  ),
                  if (isAdmin)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.change_circle, 
                          size: 40, 
                          color: Colors.white
                        ),
                        onPressed: () => 
                          logic.selectNewAvatar(newChat.id, true), 
                      )
                    )
                ]
              ), 
              Center(
                child: Text("Members", 
                  style: Theme.of(context).textTheme.headlineSmall, 
                )
              ), 
              StreamBuilder<List<logic.MemberWithStatus>>(
                stream: logic.sortMembersByOnline(newChat.members), 
                builder:(context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator(); 
                  return Column(
                    children: 
                      [
                        for (final memberWithStatus in snapshot.data!)
                          ListTile(
                            onTap:() => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => memberWithStatus.userId == shared_logic.getUserId() ? 
                                  const MyProfilePage()
                                : ProfilePage(userId: memberWithStatus.userId),
                              )
                            ),
                            leading: ClipOval(
                              child: ProfileImage(
                                avatarId: memberWithStatus.userId,
                                isGroup: false, 
                              ),
                            ), 
                            title: FutureBuilder(
                              future: shared_logic.getDisplayNameWithYou(memberWithStatus.userId), 
                              initialData: "",
                              builder: (context, snapshot) => Text(snapshot.data?.toString() ?? "")
                            ), 
                            subtitle: LastSeenStatic(
                              status: memberWithStatus.status, 
                            ), 
                            trailing: !isAdmin || memberWithStatus.userId == shared_logic.getUserId() ? 
                              null
                            : IconButton(
                              icon: const Icon(Icons.close, color: Colors.red), 
                              onPressed: () async {
                                await logic.deleteMember(newChat.id, memberWithStatus.userId); 
                              }
                            )
                          )
                      ]
                  ); 
                },
              ), 
              if (isAdmin) 
                Center(
                  child: ElevatedButton(
                    child: const Text("Add"), 
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(
                              title: const Text("Choose new member"), 
                            ), 
                            body: ContactsList(
                              currentGroupMembers: newChat.members, 
                              onChosen: (userId) async {
                                await logic.addMember(newChat.id, userId); 
                                Navigator.of(context).pop(); 
                              }
                            ),
                          )
                        )
                      ); 
                    }
                  ),
                ), 
            ]
          )
        );
      }
    ); 
  }
}