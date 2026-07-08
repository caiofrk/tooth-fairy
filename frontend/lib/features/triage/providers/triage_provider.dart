import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class TriageState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  TriageState({this.isLoading = false, this.data, this.error});
}

class TriageNotifier extends Notifier<TriageState> {
  @override
  TriageState build() => TriageState();

  Future<void> submitPatientScan(String imagePath, String patientId) async {
    state = TriageState(isLoading: true);
    try {
      final uri = Uri.parse('http://10.0.2.2:8000/api/v1/triage/analyze?patient_id=$patientId');
      var request = http.MultipartRequest('POST', uri);
      
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        request.headers['Authorization'] = 'Bearer ${session.accessToken}';
      }

      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        state = TriageState(isLoading: false, data: jsonDecode(respStr));
      } else {
        state = TriageState(isLoading: false, error: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      state = TriageState(isLoading: false, error: e.toString());
    }
  }
}

final triageProvider = NotifierProvider<TriageNotifier, TriageState>(() => TriageNotifier());
