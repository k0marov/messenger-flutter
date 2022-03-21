import 'package:flutter/material.dart';
import 'package:messenger/screens/login/name_page.dart'; 
import 'dart:async'; 
import 'package:pin_code_fields/pin_code_fields.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 

enum CodeState {
  codeSending, 
  codeSent, 
  fatalError, 
}

class InputCodePage extends StatefulWidget {
  final String phone; 
  const InputCodePage({ 
    required this.phone, 
    Key? key 
  }) : super(key: key);

  @override
  _InputCodePageState createState() => _InputCodePageState();
}

class _InputCodePageState extends State<InputCodePage> {
  CodeState _state = CodeState.codeSending; 
  String? _verificationId; 
  final errorController = StreamController<ErrorAnimationType>(); 

  void _onSuccess() { 
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return const NamePage(); 
    })); 
  }
  void _onFatalError() {
    if (mounted) {
      setState(() {
        _state = CodeState.fatalError; 
      });
    }
  }
  void _onCodeSent(String verificationId) {
    if (mounted) {
      setState(() {
        _state = CodeState.codeSent; 
        _verificationId = verificationId; 
      }); 
    }
  }
  
  Future<bool> _checkCode(String code) async {
    if (_verificationId == null) return false; 
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!, smsCode: code
    ); 
    try {
      await FirebaseAuth.instance.signInWithCredential(credential); 
      return true; 
    } catch (e) {
      return false; 
    }
  }

  @override
  void initState() {
    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phone, 
      verificationCompleted: (_) => _onSuccess(), 
      verificationFailed: (_) {
        print(_); 
        _onFatalError();
      }, 
      codeSent: (verificationId, _) => _onCodeSent(verificationId), 
      codeAutoRetrievalTimeout: (_) => _onFatalError(), 
      timeout: const Duration(minutes: 2), 
    ); 
    super.initState();
  }

  Widget _buildCodeField(BuildContext context) {
    return PinCodeTextField(
      enabled: _state == CodeState.codeSent, 
      appContext: context, 
      length: 6, 
      mainAxisAlignment: MainAxisAlignment.center,
      errorAnimationController: errorController,
      keyboardType: TextInputType.number,
      onCompleted: (code) async {
        final res = await _checkCode(code); 
        if (res) {
          _onSuccess(); 
        } else {
          errorController.add(ErrorAnimationType.shake);  
        }
      }, 
      // backgroundColor: Theme.of(context).cardColor, 
      // enableActiveFill: true,
      pinTheme: const PinTheme.defaults(
        inactiveColor: Colors.white,
        fieldOuterPadding: EdgeInsets.all(3.0),
        shape: PinCodeFieldShape.box
      ),
      onChanged: (value) {}
    ); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Input Code"), 
      ), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_state == CodeState.codeSending)
              const Text("The code will be sent soon..."), 
            if (_state == CodeState.codeSent)
              const Text("Input the code that was sent to your device"), 
            if (_state == CodeState.fatalError)
              const Text("There was an unknown error."), 
            if (_state != CodeState.fatalError)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildCodeField(context),
              ),
            if (_state == CodeState.fatalError) 
              ElevatedButton(
                child: const Text("Try again"), 
                onPressed: () {
                    Navigator.of(context).pop();  
                },
              )
          ],
        ),
      )
    ); 
  }
}