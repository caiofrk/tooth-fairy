import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/triage_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TriageScreen extends ConsumerWidget {
  const TriageScreen({Key? key}) : super(key: key);

  Future<void> _pickAndUploadImage(WidgetRef ref, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final user = Supabase.instance.client.auth.currentUser;
      final patientId = user?.id ?? "unknown-patient";
      await ref.read(triageProvider.notifier).submitPatientScan(pickedFile.path, patientId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final triageState = ref.watch(triageProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Consulta Virtual', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
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
              if (triageState.isLoading)
                const CircularProgressIndicator()
              else ...[
                if (triageState.error != null)
                  Text('Error: ${triageState.error}', style: const TextStyle(color: Colors.red)),
                if (triageState.data != null) ...[
                  // If image is blurry and not acceptable
                  if (triageState.data!['image_quality_acceptable'] == false)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'A qualidade da imagem está muito baixa. Por favor, tire outra foto em um local bem iluminado.',
                              style: TextStyle(color: Colors.deepOrange),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.analytics, color: Colors.teal.shade600),
                                const SizedBox(width: 10),
                                Text(
                                  'Análise da IA Concluída',
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const Divider(height: 30),
                            Text('Nível de Urgência', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            Text('${triageState.data!['urgency_level']}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                            const SizedBox(height: 16),
                            Text('Recomendação', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            Text('${triageState.data!['recommendation']}', style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                            Text('Achados Clínicos', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            Text('${(triageState.data!['preliminary_findings'] as List).join(', ')}', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    )
                  ]
                ] else
                  Text(
                    'Envie uma foto intraoral para que nossa IA inicie a análise.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
              ],
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: Text('Tirar Foto', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
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
                icon: const Icon(Icons.photo_library),
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
