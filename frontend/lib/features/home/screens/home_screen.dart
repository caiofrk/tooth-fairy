import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../triage/screens/triage_instructions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // A soft teal gradient for the header
    final headerGradient = LinearGradient(
      colors: [Colors.teal.shade700, Colors.teal.shade300],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.teal.shade700,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Bom dia, Caio',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: headerGradient,
                ),
                child: Center(
                  child: Icon(
                    Icons.health_and_safety,
                    size: 80,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Como podemos ajudar hoje?',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildActionCard(
                    context,
                    title: 'Consulta Virtual',
                    subtitle: 'Triagem inteligente por IA',
                    icon: Icons.camera_front,
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TriageInstructionsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildActionCard(
                    context,
                    title: 'Escanear Convênio',
                    subtitle: 'Validação automática da carteirinha',
                    icon: Icons.credit_card,
                    color: Colors.deepPurpleAccent,
                    onTap: () {
                      // Navigate to OCR tab (index 1) handled via bottom nav, 
                      // but here we can just show a snackbar or use a global router.
                      // For now, we will leave it as is or show a message.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Use a aba do Scanner abaixo!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
