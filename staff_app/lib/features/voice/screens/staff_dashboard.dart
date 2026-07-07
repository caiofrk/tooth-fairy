import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../providers/voice_provider.dart';
import '../widgets/odontogram_widget.dart';

class StaffDashboardScreen extends ConsumerStatefulWidget {
  const StaffDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends ConsumerState<StaffDashboardScreen> {
  late final AudioRecorder _audioRecorder;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        _audioPath = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _audioPath!,
        );
        ref.read(voiceProvider.notifier).setRecordingState(true);
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      ref.read(voiceProvider.notifier).setRecordingState(false);
      
      if (path != null) {
        await ref.read(voiceProvider.notifier).submitVoiceAudio(path);
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard - Voice Charting'),
        backgroundColor: Colors.indigo,
      ),
      body: Row(
        children: [
          // Left side: Triage Dashboard & Odontogram Visualization
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pending Triage Scans', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.white,
                      child: const Center(
                        child: Text(
                          'Waiting for Supabase realtime connection...',
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Visual Odontogram', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Expanded(
                    flex: 1,
                    child: OdontogramWidget(
                      findings: voiceState.chartingData?['findings'] ?? [],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right side: Audio controls and Status
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (voiceState.isProcessing)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('AI Processing Voice Note...', style: TextStyle(color: Colors.indigo)),
                      ],
                    )
                  else ...[
                    GestureDetector(
                      onTapDown: (_) => _startRecording(),
                      onTapUp: (_) => _stopRecording(),
                      onTapCancel: () => _stopRecording(),
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: voiceState.isRecording ? Colors.red : Colors.indigo,
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (voiceState.isRecording)
                              BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
                          ],
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 80,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      voiceState.isRecording ? 'Release to Send' : 'Hold to Speak',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (voiceState.error != null) ...[
                      const SizedBox(height: 16),
                      Text(voiceState.error!, style: const TextStyle(color: Colors.red)),
                    ]
                  ],
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
