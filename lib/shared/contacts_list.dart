import 'package:flutter/material.dart';
import 'package:messenger/models/user_model.dart';
import 'package:messenger/shared/profile_image.dart'; 
import 'shared_logic.dart' as shared_logic; 
import '../models/contact_model.dart'; 

class ContactsList extends StatelessWidget {
  final void Function(String) onChosen; 
  final List<String>? currentGroupMembers;  
  const ContactsList({
    required this.onChosen, 
    this.currentGroupMembers, 
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: shared_logic.getContacts(), 
      builder: (context, AsyncSnapshot<List<ContactModel?>> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator.adaptive()); 
        }
        else {
          final contacts = snapshot.data!
            .where((elem) {
              return !(currentGroupMembers?.contains(elem?.userId) ?? false); 
            })
            .cast<ContactModel>()
            .toList(); 
          return contacts.isEmpty ? 
            const Center(child: Text("No contacts available"))
          : _InternalContactsList(onChosen: onChosen, contacts: contacts); 
        }
      }
    );
  }
}


class _InternalContactsList extends StatefulWidget {
  final void Function(String) onChosen; 
  final List<ContactModel> contacts; 
  const _InternalContactsList({ 
    required this.onChosen, 
    required this.contacts, 
    Key? key 
  }) : super(key: key);

  @override
  __InternalContactsListState createState() => __InternalContactsListState();
}

class __InternalContactsListState extends State<_InternalContactsList> {
  late List<dynamic> _filteredUsers;  // every elem is either ContactModel or UserModel

  @override
  void initState() {
    _filteredUsers = widget.contacts; 
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
                suffixIcon: Icon(Icons.search),
                labelText: "Search by username or contact name", 
              ),
            onChanged: (text) async {
              if (text.startsWith('@')) {
                final username = text.substring(1); 
                _filteredUsers = await shared_logic.getUsersWithUsernameStarting(username); 
                if (mounted) setState(() {}); 
              } else {
                setState(() {
                _filteredUsers = widget.contacts
                  .where((contact) => contact.contactsName.toLowerCase().contains(text.toLowerCase()))
                  .toList(); 
                }); 
              }
            },
          ),
        ), 
        Expanded(
          child: ListView( 
            children: 
              _filteredUsers
              .map((userOrContact) { 
                final name = (userOrContact is UserModel) ? 
                  userOrContact.displayName
                : (userOrContact as ContactModel).contactsName; 
                final username = (userOrContact is UserModel) ? 
                  userOrContact.username
                : null; 
                final userId = userOrContact.userId; 
                return ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ClipOval(
                      child: ProfileImage(
                        isGroup: false, 
                        avatarId: userId
                      ),
                    ),
                  ), 
                  trailing: userId == null ? 
                    null 
                  : const Icon(Icons.arrow_forward), 
                  title: Text(name), 
                  subtitle: username != null ? 
                    Text('@'+username) 
                  : userId == null ? 
                    const Text("Has not joined Messenger yet")
                  : null, 
                  onTap: userId == null ? 
                    null 
                  : () {
                    widget.onChosen(userId); 
                  }
                ); 
              }
              )
              .toList() 
          ),
        ),
      ],
    ); 
  }
}