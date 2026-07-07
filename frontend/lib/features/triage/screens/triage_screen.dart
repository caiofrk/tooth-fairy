import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/triage_provider.dart';

class TriageScreen extends ConsumerWidget {
  const TriageScreen({Key? key}) : super(key: key);

  Future<void> _pickAndUploadImage(WidgetRef ref, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      // Hardcoded patientId for MVP testing, this should come from Auth
      final patientId = "patient-123";
      await ref.read(triageProvider.notifier).submitPatientScan(pickedFile.path, patientId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final triageState = ref.watch(triageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Asynchronous Triage'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (triageState.isLoading)
                const CircularProgressIndicator()
              else ...[
                if (triageState.error != null)
                  Text('Error: ${triageState.error}', style: const TextStyle(color: Colors.red)),
                if (triageState.data != null) ...[
                  // If image is blurry and not acceptable
                  if (triageState.data!['image_quality_acceptable'] == false)
                    const Text(
                      'Image quality is too low. Please retake the photo in better lighting.',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    )
                  else ...[
                    Text('Urgency: ${triageState.data!['urgency_level']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text('Recommendation: ${triageState.data!['recommendation']}'),
                    const SizedBox(height: 10),
                    Text('Findings: ${(triageState.data!['preliminary_findings'] as List).join(', ')}'),
                  ]
                ] else
                  const Text('Upload an intraoral photo for AI triage.'),
              ],
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                onPressed: () => _pickAndUploadImage(ref, ImageSource.camera),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Upload from Gallery'),
                onPressed: () => _pickAndUploadImage(ref, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
