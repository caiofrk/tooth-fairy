import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../voice/screens/staff_dashboard.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final session = snapshot.data?.session;
        if (session != null) {
          return const StaffDashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
