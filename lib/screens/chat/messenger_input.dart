import 'dart:async';

import 'package:flutter/material.dart'; 
import 'dart:io' show File; 
import 'package:record/record.dart'; 


enum InputState {
  text, 
  audio, 
  audioStarted, 
  audioStopped, 
} 

class MessengerInput extends StatefulWidget {
  final void Function(String text) sendText; 
  final void Function() sendFile; 
  final void Function(File audio) sendAudio; 

  const MessengerInput({ 
    required this.sendText, 
    required this.sendFile, 
    required this.sendAudio, 
    Key? key 
  }) : super(key: key);

  @override
  _MessengerInputState createState() => _MessengerInputState();
}

class _MessengerInputState extends State<MessengerInput> {
  InputState _state = InputState.audio;

  final _controller = TextEditingController(); 
  final _recorder = Record(); 
  String? _filePath; 

  Timer? _timer; 
  int _audioLength = 0; 


  @override 
  void dispose() {
    _controller.dispose(); 
    _timer?.cancel(); 
    _recorder.dispose(); 
    super.dispose(); 
  }

  void timerCallback(_) {
    setState(() => _audioLength++); 
  }

  void _sendTextAndClear(String text) {
    if (text.trim().isEmpty) return; 
    widget.sendText(text.trim()); 
    _controller.clear(); 
    setState(() => _state = InputState.audio); 
  }

  void _startRecording() async {
    if (_state == InputState.audioStarted) return; 
    final permission = await _recorder.hasPermission(); 
    if (!permission) return; 
    setState(() => _state = InputState.audioStarted); 
    await _recorder.start(); 
    _audioLength = 0; 
    _timer = Timer.periodic(const Duration(seconds: 1), timerCallback); 
  }

  void _stopRecording() async {
    _timer?.cancel(); 
    _timer = null; 

    _filePath = await _recorder.stop(); 

    if (_filePath == null || _audioLength == 0) {
      setState(() => _state = InputState.audio); 
    }
    else {
      setState(() {
        _state = InputState.audioStopped; 
      }); 
    } 
  }

  Widget _buildAudioLength() {
    final minutes = (_audioLength / 60).floor().toString(); 
    final seconds = (_audioLength % 60).toString().padLeft(2, '0'); 
    return Text(
      "$minutes:$seconds"
    ); 
  }

  Widget _buildSuffix() {
    if (_state == InputState.audioStopped) {
      return Padding(
        padding: const EdgeInsets.only(right: 5.0), 
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildAudioLength(), 
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red), 
              onPressed: () {
                _filePath = ""; 
                setState(() => _state = InputState.audio); 
              }
            ), 
            IconButton(
              icon: const Icon(Icons.send), 
              onPressed: () {
                if (_filePath != null) {
                  widget.sendAudio(File.fromUri(Uri.parse(_filePath!))); 
                }
                setState(() => _state = InputState.audio); 
              }
            )
          ]
        ),
      ); 
    } else { 
      return 
        _state == InputState.text ? 
          IconButton(
            icon: const Icon(Icons.send), 
            onPressed: () => _sendTextAndClear(_controller.text), 
          )
        : Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_state == InputState.audioStarted) _buildAudioLength(), 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10), 
              child: GestureDetector(
                child: Container(
                  padding: const EdgeInsets.all(5.0), 
                  decoration: BoxDecoration(
                    color: _state == InputState.audioStarted ? 
                      Theme.of(context).cardColor
                    : null, 
                    shape: BoxShape.circle, 
                  ),
                  child: Icon(
                    Icons.mic, 
                    size: 30,
                    color: _state == InputState.audioStarted ? 
                      Colors.red 
                    : null, 
                  ),
                ), 
                // onTap: () => _stopRecording(), 
                // onTap: _state == InputState.audioStarted ? 
                //   _stopRecording
                // : null, 
                onLongPress: () => _startRecording(), 
                // onTapDown: (_) => _startRecording(), 
                onTapUp: (_) => _stopRecording(), 
                onLongPressEnd: (_) => _stopRecording()
              ),
            ),
          ],
      ); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => hasFocus && !(_state == InputState.audioStarted)? 
        setState(() => _state = InputState.text) 
      : _controller.text.isEmpty ? 
          setState(() => _state = InputState.audio)
        : null, 
      child: TextField(
        minLines: 1, 
        maxLines: 10, 
        // expands: true,
        controller: _controller, 
        onSubmitted: _sendTextAndClear, 
        onChanged: (value) {
          if (_state == InputState.audio && value.trim().isNotEmpty) {
            setState(() => _state = InputState.text); 
          } else if (_state == InputState.text && value.trim().isEmpty) {
            setState(() => _state = InputState.audio); 
          }
        }, 
        decoration: InputDecoration(
          border: const OutlineInputBorder(), 
          prefixIcon: IconButton(
            icon: const Icon(Icons.attach_file), 
            onPressed: widget.sendFile, 
          ), 
          suffixIcon: _buildSuffix(), 
        )
      ),
    ); 
  }
}