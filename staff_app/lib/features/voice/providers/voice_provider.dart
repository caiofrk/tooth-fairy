import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VoiceState {
  final bool isRecording;
  final bool isProcessing;
  final Map<String, dynamic>? chartingData;
  final String? error;

  VoiceState({
    this.isRecording = false,
    this.isProcessing = false,
    this.chartingData,
    this.error,
  });
}

class VoiceNotifier extends Notifier<VoiceState> {
  @override
  VoiceState build() => VoiceState();

  void setRecordingState(bool isRecording) {
    state = VoiceState(
      isRecording: isRecording,
      isProcessing: state.isProcessing,
      chartingData: state.chartingData,
      error: state.error,
    );
  }

  Future<void> submitVoiceAudio(String audioPath) async {
    state = VoiceState(isRecording: false, isProcessing: true, chartingData: state.chartingData);
    
    try {
      final uri = Uri.parse('http://10.0.2.2:8000/api/v1/voice/chart');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('audio', audioPath));
      
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final Map<String, dynamic> newData = jsonDecode(respStr);
        
        List<dynamic> existingFindings = [];
        if (state.chartingData != null && state.chartingData!['findings'] != null) {
          existingFindings = List.from(state.chartingData!['findings']);
        }
        
        List<dynamic> newFindings = newData['findings'] ?? [];
        existingFindings.addAll(newFindings);
        
        state = VoiceState(
          isProcessing: false,
          chartingData: {'findings': existingFindings},
        );
      } else {
        state = VoiceState(isProcessing: false, error: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      state = VoiceState(isProcessing: false, error: e.toString());
    }
  }
}

final voiceProvider = NotifierProvider<VoiceNotifier, VoiceState>(() => VoiceNotifier());
