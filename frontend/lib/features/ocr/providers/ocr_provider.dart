import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OcrState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  OcrState({this.isLoading = false, this.data, this.error});
}

class OcrNotifier extends Notifier<OcrState> {
  @override
  OcrState build() => OcrState();

  Future<void> submitHealthCard(String imagePath) async {
    state = OcrState(isLoading: true);
    try {
      final uri = Uri.parse('http://10.0.2.2:8000/api/v1/ocr/validate');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        state = OcrState(isLoading: false, data: jsonDecode(respStr));
      } else {
        state = OcrState(isLoading: false, error: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      state = OcrState(isLoading: false, error: e.toString());
    }
  }
}

final ocrProvider = NotifierProvider<OcrNotifier, OcrState>(() => OcrNotifier());
