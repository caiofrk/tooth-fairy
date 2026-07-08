import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
  int _mobileSelectedIndex = 0; // 0 for Voice, 1 for Dashboard

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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildTabletLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Painel do Dentista', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: Colors.indigo.shade800,
        elevation: 0,
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(24),
              child: _buildDashboardContent(),
            ),
          ),
          Container(width: 1, color: Colors.grey.shade300),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: _buildVoiceContent(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _mobileSelectedIndex == 0 ? 'Prontuário de Voz' : 'Odontograma e Triagem',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.indigo.shade800,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey.shade50,
        padding: const EdgeInsets.all(16),
        child: _mobileSelectedIndex == 0 ? _buildVoiceContent() : _buildDashboardContent(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _mobileSelectedIndex,
        selectedItemColor: Colors.indigo.shade700,
        unselectedItemColor: Colors.grey.shade500,
        onTap: (index) {
          setState(() {
            _mobileSelectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Voz'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    final voiceState = ref.watch(voiceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Triagens Pendentes', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
        const SizedBox(height: 8),
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Center(
              child: Text(
                'Aguardando conexão com banco de dados...',
                style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Odontograma Visual', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
        const SizedBox(height: 8),
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: OdontogramWidget(
              findings: voiceState.chartingData?['findings'] ?? [],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceContent() {
    final voiceState = ref.watch(voiceProvider);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (voiceState.isProcessing)
          Column(
            children: [
              const CircularProgressIndicator(color: Colors.indigo),
              const SizedBox(height: 24),
              Text(
                'IA processando áudio...',
                style: GoogleFonts.outfit(color: Colors.indigo.shade700, fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ],
          )
        else ...[
          GestureDetector(
            onTapDown: (_) => _startRecording(),
            onTapUp: (_) => _stopRecording(),
            onTapCancel: () => _stopRecording(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: voiceState.isRecording ? 170 : 150,
              height: voiceState.isRecording ? 170 : 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: voiceState.isRecording
                      ? [Colors.red.shade400, Colors.red.shade700]
                      : [Colors.indigo.shade400, Colors.indigo.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: voiceState.isRecording ? Colors.red.withOpacity(0.4) : Colors.indigo.withOpacity(0.3),
                    blurRadius: voiceState.isRecording ? 30 : 20,
                    spreadRadius: voiceState.isRecording ? 10 : 5,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic,
                color: Colors.white,
                size: 64,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            voiceState.isRecording ? 'Solte para Enviar' : 'Segure para Falar',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: voiceState.isRecording ? Colors.red.shade700 : Colors.indigo.shade900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ex: "Cárie na face oclusal do dente 36"',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
          if (voiceState.error != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                voiceState.error!,
                style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ]
        ],
      ],
    );
  }
}
