import 'package:flutter/material.dart'; 
import 'package:intl_phone_field/phone_number.dart';
import 'package:messenger/screens/login/input_code_page.dart';
import '../../shared/shared_logic.dart' as shared_logic;
import 'package:intl_phone_field/intl_phone_field.dart'; 

class SignInScreen extends StatefulWidget {
  const SignInScreen({ Key? key }) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final formKey = GlobalKey<FormState>(); 
  String phoneNumber = ""; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In') 
      ), 
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 6, 
              child: Icon(Icons.phone_sharp, size: 75, color: Theme.of(context).primaryColor) 
            ), 
            const Expanded(
              flex: 1, 
              child: Text("Enter your phone number: ")
            ), 
            Expanded(
              flex: 12, 
              child: Form(
                key: formKey, 
                child: 
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IntlPhoneField(
                        onChanged: (PhoneNumber phone) => 
                          setState(()=>phoneNumber = shared_logic.formatPhone(phone.completeNumber))
                      ), 
                      ElevatedButton(
                        child: const Text("Send SMS Code"), 
                        onPressed: phoneNumber.isNotEmpty && formKey.currentState!.validate() ? 
                            () => Navigator.push(context, 
                            MaterialPageRoute(builder: (context) => InputCodePage(phone: phoneNumber)))
                          : null 
                      ), 
                    ]
                  )
              ),
            ),
          ],
        ),
      )
    ); 
  }
}
