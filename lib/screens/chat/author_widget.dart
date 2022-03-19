import 'package:flutter/material.dart';
import '../../shared/shared_logic.dart' as shared_logic; 

class AuthorWidget extends StatelessWidget {
  final String authorId; 
  // final bool withColor; 
  const AuthorWidget({
    required this.authorId, 
    // required this.withColor, 
    Key? key 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => 
    FutureBuilder<String>(
      future: shared_logic.getDisplayNameWithYou(authorId), 
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Text(""); 
        final displayName = snapshot.data!; 
        return Text(displayName); 
      }
    ); 
}