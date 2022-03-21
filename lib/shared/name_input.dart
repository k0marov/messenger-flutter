import 'dart:async';

import 'package:flutter/material.dart'; 


class NameInput extends StatefulWidget {
  final String buttonText; 
  final String? prefixText; 
  final String? errorText; 
  final String label; 
  final int maxLength; 
  final bool isRow; 
  final String initialValue; 
  final bool allowSameValue; 
  final Future<bool> Function(String) onCompleted; 
  const NameInput({ 
    required this.initialValue, 
    required this.allowSameValue, 
    required this.isRow, 
    required this.onCompleted, 
    this.buttonText="Set", 
    this.label="Name", 
    this.errorText, 
    this.prefixText, 
    this.maxLength=20,
    Key? key 
  }) : super(key: key);

  @override
  _NameInputState createState() => _NameInputState();
}

class _NameInputState extends State<NameInput> {
  late final TextEditingController _controller; 
  bool _error = false; 

  @override
  void initState() {
    _controller = TextEditingController(text: widget.initialValue); 
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose(); 
    super.dispose();
  }

  void _onCompleted(String res) async {
    if (!(await widget.onCompleted(res))) {
      setState(() => _error = true); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final textField = TextField(
      maxLength: widget.maxLength,
      onChanged: (_) => setState(() {_error = false;}),
      onSubmitted: _controller.text.isEmpty ? 
        null
      : _onCompleted, 
      decoration: InputDecoration(
        prefixText: widget.prefixText, 
        border: const OutlineInputBorder(),
        label: Text(widget.label),
        errorText: _error ?  widget.errorText : null, 
      ),
      controller: _controller,
      autocorrect: false,
    ); 
    final children = [
      // if (widget.isRow) 
      //   Expanded(
      //     child: textField, 
      //   ), 
      // if (!widget.isRow) 
      //   textField, 
      Flexible(
        flex: 9, 
        child: textField
      ), 
      Flexible(
        flex: 4, 
        child: ElevatedButton(
          child: Text(widget.buttonText), 
          onPressed: _controller.text.isEmpty  || (
            !widget.allowSameValue && _controller.text == widget.initialValue)
          ? 
            null
          : () => _onCompleted(_controller.text)
        ),
      )
    ];
    return widget.isRow ? 
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        // mainAxisSize: MainAxisSize.min, 
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: children,
      )
    : Column(
        mainAxisSize: MainAxisSize.min, 
        children: children, 
    );   
  } 
}