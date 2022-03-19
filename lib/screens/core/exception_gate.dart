import 'package:flutter/material.dart';
import 'package:messenger/screens/core/notification_gate.dart'; 
import 'dart:async'; 
import '../../shared/shared_logic.dart' as shared_logic; 

class ExceptionGate extends StatefulWidget {
  const ExceptionGate({ Key? key }) : super(key: key);

  @override
  _ExceptionGateState createState() => _ExceptionGateState();
}

class _ExceptionGateState extends State<ExceptionGate> {
  late StreamSubscription _subscription;

  void _showException(String text) {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text("Error!"), 
        content: Text(text), 
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); 
            }, 
            child: const Text("Ok"), 
          )
        ],
      )
    ); 
  }

  @override
  void initState() {
    super.initState();

    _subscription = shared_logic.getExceptionStream().listen((exceptionText) {
      _showException(exceptionText); 
    });

  }

  @override
  void dispose() {
    _subscription.cancel(); 
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return const NotificationGate(); 
  }
}