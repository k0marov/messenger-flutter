import 'package:flutter/material.dart';
import 'package:messenger/screens/chat/chat_page.dart';
import 'package:messenger/shared/name_input.dart';
import 'package:messenger/shared/profile_image.dart'; 
import '../../models/contact_model.dart'; 
import 'logic.dart' as logic; 
import '../../shared/shared_logic.dart' as shared_logic; 

class NewGroup extends StatefulWidget {
  const NewGroup({ Key? key }) : super(key: key);

  @override
  State<NewGroup> createState() => _NewGroupState();
}

class _NewGroupState extends State<NewGroup> {
  final List<String> _selected = []; 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Group") 
      ), 
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: NameInput(
              isRow: true,
              initialValue: "",
              allowSameValue: false,
              maxLength: 30,
              buttonText: "Create", 
              onCompleted: (title) async {
                final members = _selected + [shared_logic.getUserId()]; 
                final newChat = await logic.newGroup(members, title); 
                Navigator.popUntil(context, (route) => route.isFirst); 
                Navigator.push(context, 
                  MaterialPageRoute(
                    builder: (ctx) => ChatPage(chat: newChat), 
                  )
                ); 
                return true; 
              }, 
            ),
          ), 
          Text(
            "Select members: ", 
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall, 
          ), 
          Expanded(
            child: StreamBuilder(
              stream: shared_logic.getContacts(), 
              builder: (context, AsyncSnapshot<List<ContactModel>> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: SizedBox(
                      width: 100, height: 100, 
                      child: CircularProgressIndicator(), 
                    )
                  ); 
                }
                else {
                  final contacts = snapshot.data!
                    .where((contact) => contact.userId != null).cast<ContactModel?>(); 
                  if (contacts.isEmpty) {
                    return const Center(
                      child: Text("No contacts available")
                    ); 
                  } else {
                    return ListView(
                      children: contacts
                        .cast<ContactModel>()
                        .map((contact) { 
                          return ContactCheckBox(
                            contact: contact, 
                            valueChanged: (value) {
                              if (value) {
                                _selected.add(contact.userId!); 
                              } else {
                                _selected.remove(contact.userId); 
                              }
                            }
                          ); 
                        }
                        ).toList()
                    ); 
                  }
                }
              } 
            ),
          ),
        ],
      )
    ); 
  }
}

class ContactCheckBox extends StatefulWidget {
  const ContactCheckBox({
    required this.contact, 
    required this.valueChanged, 
    Key? key,
  }) : super(key: key);

  final ContactModel contact; 
  final void Function(bool) valueChanged; 

  @override
  State<ContactCheckBox> createState() => _ContactCheckBoxState();
}

class _ContactCheckBoxState extends State<ContactCheckBox> {
  bool _value = false; 

  void _onValueChanged(bool? newValue) {
    widget.valueChanged(newValue ?? false); 
    setState(() => _value = newValue ?? false); 
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.contact.contactsName),
      onTap: () => _onValueChanged(!_value), 
      leading: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ClipOval(
          child: ProfileImage(
            isGroup: false, 
            avatarId: widget.contact.userId!
          )
        ),
      ), 
      trailing: Checkbox(
        value: _value, 
        activeColor: Colors.blue,
        onChanged: _onValueChanged
      )
    );
  }
}