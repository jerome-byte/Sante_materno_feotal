// lib/presentation/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:materno_feotal/presentation/screens/auth/login_screen.dart';
import 'main_container.dart';
import '../../data/services/supabase_service.dart';
import 'patient_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

    void _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    final session = SupabaseService.client.auth.currentSession;
    
    if (session != null) {
      // L'utilisateur est connecté. Est-ce un Agent ou une Patiente ?
      // On vérifie si son ID existe dans la table 'agents'
      try {
        final response = await SupabaseService.client
            .from('agents')
            .select('id')
            .eq('id', session.user.id)
            .maybeSingle();

        if (mounted) {
          if (response != null) {
            // C'est un Agent
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainContainer()));
          } else {
            // Ce n'est pas un agent, donc c'est une Patiente
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientDashboard()));
          }
        }
      } catch (e) {
        // En cas d'erreur, on va vers login agent par défaut
        if (mounted) {
           Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      }
    } else {
      // Pas connecté : On va vers login Agent par défaut
      // (La patiente cliquera sur un lien pour aller vers son login)
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Chargement...", style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}