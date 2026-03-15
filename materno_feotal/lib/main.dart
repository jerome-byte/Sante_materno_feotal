// lib/main.dart

import 'package:flutter/material.dart';
import 'package:materno_feotal/data/services/supabase_service.dart';
import 'package:materno_feotal/presentation/providers/auth_provider.dart';
import 'package:materno_feotal/presentation/screens/splash_screen.dart'; // Nous le créerons après
import 'package:provider/provider.dart';
import 'presentation/providers/patient_provider.dart'; // Ajoutez cet import
import 'presentation/screens/patients/add_patient_screen.dart';
import 'presentation/screens/rdv/add_rdv_screen.dart';
import 'data/models/patient_model.dart';
import 'presentation/screens/auth/patient_login_screen.dart';
import 'presentation/screens/patient_dashboard.dart';

void main() async {
  // Nécessaire pour les plugins natifs (Supabase/SQLite)
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Supabase
  await SupabaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Nous enregistrerons nos providers ici plus tard
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()), // Ajoutez cette ligne
      ],
      child: MaterialApp(
        title: 'SANTE+ ',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true, // Design moderne
          fontFamily: 'Poppins', // Vous pourrez ajouter cette police plus tard
        ),
        home: const SplashScreen(), // Écran de chargement initial
         routes: {
        '/add-patient': (context) => const AddPatientScreen(),
         '/add-rdv': (context) => AddRdvScreen(patient: ModalRoute.of(context)!.settings.arguments as PatientModel), // Ajoutez ceci
         '/patient-login': (context) => const PatientLoginScreen(), // Ajout
        '/patient-dashboard': (context) => const PatientDashboard(), 
      },
      ),
    );
  }
}