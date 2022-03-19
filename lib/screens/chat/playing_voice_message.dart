typedef PausePlayer = void Function(); 
class PlayingVoiceMessage {
  PlayingVoiceMessage._privateConstructor(); 
  static final PlayingVoiceMessage _instance = PlayingVoiceMessage._privateConstructor(); 
  factory PlayingVoiceMessage() => _instance; 

  PausePlayer? _pauseCurrentPlayer; 

  void startPlaying(PausePlayer pauseNewPlayer) {
    if (_pauseCurrentPlayer != null) _pauseCurrentPlayer!(); 
    _pauseCurrentPlayer = pauseNewPlayer; 
  }
}