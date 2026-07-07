import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/ocr_provider.dart';

class OcrScreen extends ConsumerWidget {
  const OcrScreen({Key? key}) : super(key: key);

  Future<void> _pickAndUploadImage(WidgetRef ref, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      await ref.read(ocrProvider.notifier).submitHealthCard(pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocrState = ref.watch(ocrProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Convênio Scanner'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (ocrState.isLoading)
                const CircularProgressIndicator()
              else ...[
                if (ocrState.error != null)
                  Text('Error: ${ocrState.error}', style: const TextStyle(color: Colors.red)),
                if (ocrState.data != null) ...[
                  if (ocrState.data!['is_valid_card'] == false)
                    const Text(
                      'Invalid or blurry card. Please try again.',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    )
                  else ...[
                    const Icon(Icons.verified, color: Colors.green, size: 48),
                    const SizedBox(height: 10),
                    Text('Carrier: ${ocrState.data!['carrier_name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text('Registration ID: ${ocrState.data!['registration_number']}'),
                    const SizedBox(height: 10),
                    Text('Expiry: ${ocrState.data!['expiry_date']}'),
                  ]
                ] else
                  const Text('Scan your physical health insurance card.'),
              ],
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.document_scanner),
                label: const Text('Scan Card (Camera)'),
                onPressed: () => _pickAndUploadImage(ref, ImageSource.camera),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.photo),
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
