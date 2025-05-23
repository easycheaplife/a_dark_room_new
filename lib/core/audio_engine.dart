import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

/// AudioEngine handles all sound effects and music in the game
class AudioEngine {
  static final AudioEngine _instance = AudioEngine._internal();
  
  factory AudioEngine() {
    return _instance;
  }
  
  AudioEngine._internal();
  
  // Audio players
  final AudioPlayer _musicPlayer = AudioPlayer();
  final Map<String, AudioPlayer> _soundPlayers = {};
  
  // Volume settings
  double _masterVolume = 1.0;
  bool _isAudioContextRunning = false;
  
  // Initialize the audio engine
  Future<void> init() async {
    try {
      _isAudioContextRunning = true;
      
      // Preload common sounds
      await loadAudioFile('fire_light');
      await loadAudioFile('fire_stoke');
      
      // Set up music player
      _musicPlayer.setLoopMode(LoopMode.one);
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing audio engine: $e');
      }
      _isAudioContextRunning = false;
    }
  }
  
  // Load an audio file
  Future<void> loadAudioFile(String name) async {
    try {
      final player = AudioPlayer();
      await player.setAsset('assets/audio/$name.mp3');
      _soundPlayers[name] = player;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading audio file $name: $e');
      }
    }
  }
  
  // Play a sound effect
  Future<void> playSound(String name) async {
    if (!_isAudioContextRunning || _masterVolume <= 0) return;
    
    try {
      if (!_soundPlayers.containsKey(name)) {
        await loadAudioFile(name);
      }
      
      final player = _soundPlayers[name];
      if (player != null) {
        await player.setVolume(_masterVolume);
        await player.seek(Duration.zero);
        await player.play();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing sound $name: $e');
      }
    }
  }
  
  // Play background music
  Future<void> playBackgroundMusic(String name) async {
    if (!_isAudioContextRunning || _masterVolume <= 0) return;
    
    try {
      // Stop current music if playing
      await _musicPlayer.stop();
      
      // Load and play new music
      await _musicPlayer.setAsset('assets/audio/$name.mp3');
      await _musicPlayer.setVolume(_masterVolume * 0.7); // Music slightly quieter than effects
      await _musicPlayer.play();
    } catch (e) {
      if (kDebugMode) {
        print('Error playing background music $name: $e');
      }
    }
  }
  
  // Set master volume
  Future<void> setMasterVolume(double volume, [int fadeTime = 500]) async {
    _masterVolume = volume.clamp(0.0, 1.0);
    
    try {
      // Fade music volume
      if (_musicPlayer.playing) {
        await _musicPlayer.setVolume(_masterVolume * 0.7);
      }
      
      // Update all sound players
      for (final player in _soundPlayers.values) {
        if (player.playing) {
          await player.setVolume(_masterVolume);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting master volume: $e');
      }
    }
  }
  
  // Check if audio context is running
  bool isAudioContextRunning() {
    return _isAudioContextRunning;
  }
  
  // Try to resume audio context (for mobile browsers)
  Future<void> tryResumingAudioContext() async {
    if (!_isAudioContextRunning) {
      try {
        await _musicPlayer.play();
        await _musicPlayer.pause();
        _isAudioContextRunning = true;
      } catch (e) {
        if (kDebugMode) {
          print('Error resuming audio context: $e');
        }
      }
    }
  }
  
  // Dispose all audio resources
  Future<void> dispose() async {
    try {
      await _musicPlayer.dispose();
      
      for (final player in _soundPlayers.values) {
        await player.dispose();
      }
      _soundPlayers.clear();
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing audio engine: $e');
      }
    }
  }
}
