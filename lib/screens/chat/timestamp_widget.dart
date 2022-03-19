import 'package:flutter/material.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../../shared/shared_logic.dart' show monthNames; 


class TimestampWidget extends StatelessWidget {
  late final String formattedDate; 
  TimestampWidget({ 
    required Timestamp timestamp, 
    Key? key 
  }) : super(key: key) {
    formattedDate = formatDate(timestamp); 
  }
  static String formatDate(Timestamp timestamp) {
    final day = timestamp.toDate().day; 
    final month = monthNames[timestamp.toDate().month-1]; 
    return "$month, $day"; 
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Chip(
        label: Text(formattedDate) 
      )
    ); 
  }
}