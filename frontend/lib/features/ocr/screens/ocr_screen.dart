import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/ocr_provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Escanear Convênio', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal.shade800,
        elevation: 0,
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
                      'Carteirinha inválida ou borrada. Por favor, tente novamente.',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    )
                  else ...[
                    const Icon(Icons.verified, color: Colors.green, size: 48),
                    const SizedBox(height: 10),
                    Text('Operadora: ${ocrState.data!['carrier_name']}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text('Matrícula: ${ocrState.data!['registration_number']}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text('Validade: ${ocrState.data!['expiry_date']}', style: const TextStyle(fontSize: 16)),
                  ]
                ] else
                  Text(
                    'Escaneie sua carteirinha física do convênio.',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
              ],
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.document_scanner),
                label: Text('Escanear (Câmera)', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _pickAndUploadImage(ref, ImageSource.camera),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.photo),
                label: Text('Enviar da Galeria', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.teal.shade700,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _pickAndUploadImage(ref, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
