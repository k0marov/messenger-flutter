import 'package:flutter/material.dart'; 
import '../models/status_model.dart'; 
import 'shared_logic.dart' as shared_logic; 




class LastSeenStatic extends StatelessWidget {
  final String text; 
  final TextStyle? textStyle; 
  static String _getText(StatusModel? status) => status == null ? 
    "" 
  : status.toString(); 

  LastSeenStatic({ 
    required StatusModel? status,
    this.textStyle, 
    Key? key 
  }) : text = _getText(status), super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(text, 
      style: textStyle, 
    ); 
  }
}

class LastSeen extends StatelessWidget {
  final String userId; 
  final bool asStream; 
  final TextStyle? textStyle; 
  const LastSeen({ 
    required this.userId, 
    required this.asStream, 
    this.textStyle, 
    Key? key 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget builder(context, AsyncSnapshot<StatusModel?> snapshot) => 
      LastSeenStatic(
        textStyle: textStyle,
        status: snapshot.data, 
      ); 
    return asStream ? 
      StreamBuilder<StatusModel?>(
        stream: shared_logic.getUserStatus(userId), 
        builder: builder    
      )
    : FutureBuilder(
      future: shared_logic.getUserStatus(userId).first, 
      builder: builder,  
    ); 
  }
}