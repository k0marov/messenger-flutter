import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:messenger/screens/chat/playing_voice_message.dart'; 


class VoiceMessage extends StatefulWidget {
  final String? url; 
  final int duration; 
  const VoiceMessage({ 
    required this.url,
    required this.duration, 
    Key? key 
  }) : super(key: key);

  @override
  _VoiceMessageState createState() => _VoiceMessageState();
}

class _VoiceMessageState extends State<VoiceMessage> {
  AudioPlayer? _player; 
  StreamSubscription? _playingSubscription;
  StreamSubscription? _positionSubscription; 

  double _progress = 0.0; 
  bool _isSeeking = false; 

  @override 
  void initState() {
    super.initState();
  }
  @override 
  void dispose() {
    _player?.dispose(); 
    _playingSubscription?.cancel(); 
    _positionSubscription?.cancel(); 
    super.dispose();
  }

  void initPlayerWithUrl(String url) {
    _player = AudioPlayer(); 
    _player!.setUrl(url); 
    _playingSubscription = _player!.playingStream.listen((_) => setState((){})); 
    _positionSubscription = _player!.positionStream.listen((position) {
      if (_isSeeking) return; 
      if ((position.inMilliseconds - widget.duration).abs() <= 100) {
        _progress = 0; 
        _player!.stop(); 
        _player!.seek(const Duration()).then((_) {
          if (mounted) setState(() {}); 
        }); 
      } else {
        _progress = position.inMilliseconds / widget.duration; 
        setState(() {}); 
      }
    }); 
  }

  void _togglePlayer() {
    if (widget.url == null) return; 
    if (_player == null) initPlayerWithUrl(widget.url!); 
    if (_player!.playing) {
      _player!.pause(); 
    } else {
      PlayingVoiceMessage().startPlaying(() => mounted ? _player!.pause() : null); 
      _player!.play(); 
    }
  }


  @override
  Widget build(BuildContext context) {
    return Row(
      // mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: _player?.playing ?? false ? 
            const Icon(Icons.pause) 
          : const Icon(Icons.play_arrow), 
          onPressed: _togglePlayer, 
        ), 
        Expanded(
          child: SliderTheme(
            data: Theme.of(context).sliderTheme.copyWith(
              thumbColor: Colors.deepPurple,
              overlayColor: Colors.blueGrey, 
              inactiveTrackColor: Colors.blueGrey, 
              activeTrackColor: Colors.blueGrey, 
              trackShape: CustomTrackShape(), 
            ), 
            child: Container(
              margin: const EdgeInsets.only(left: 10.0, right: 15.0), 
              child: Slider(
                onChangeEnd: (_) {
                  if (!_isSeeking) return; 
                  _isSeeking = false; 
                  _player?.play(); 
                }, 
                onChangeStart: (_) {
                  if (!(_player?.playing ?? false)) return; 
                  _isSeeking = true; 
                  _player?.pause(); 
                }, 
                onChanged: widget.url == null ? 
                  (_) {}
                  : (value) {
                    if (value == 1) return; 
                    _player?.seek(Duration(milliseconds: (widget.duration * value).floor())); 
                    setState(() => _progress = value); 
                  },
                value: _progress, 
              ),
            ),
          ),
        ), 
        Text("${(widget.duration/1000/60).floor()}:${((widget.duration/1000).floor()%60).toString().padLeft(2, "0")}"), 
      ]
    ); 
  }
}



class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override 
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
    }) {
      final double trackHeight = sliderTheme.trackHeight ?? 0;
      final double trackLeft = offset.dx;
      final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
      final double trackWidth = parentBox.size.width;
      return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
    }
}