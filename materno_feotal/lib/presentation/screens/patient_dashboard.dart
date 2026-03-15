import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../presentation/providers/patient_provider.dart';
import '../../data/models/rendez_vous_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../data/services/supabase_service.dart'; // Pour accéder à Supabase

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  List<RendezVousModel> _rdvs = [];
  bool _isLoading = true;
  String _patientName = "Patiente";

  @override
  void initState() {
    super.initState();
    _loadData();
    _saveDeviceToken(); // Important pour les notifications
  }

  // Fonction pour sauvegarder le token Firebase
  Future<void> _saveDeviceToken() async {
    try {
      // 1. Récupérer le token du téléphone
      final token = await FirebaseMessaging.instance.getToken();
      final userId = SupabaseService.client.auth.currentUser?.id;

      if (token != null && userId != null) {
        // 2. Mettre à jour le dossier patient dans Supabase
        await SupabaseService.client
            .from('patients')
            .update({'device_token': token})
            .eq('user_id', userId);
        
        print("Token enregistré avec succès");
      }
    } catch (e) {
      print("Erreur enregistrement token: $e");
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Récupérer les RDV
    final data = await Provider.of<PatientProvider>(context, listen: false).fetchMyRdvs();
    
    // Récupérer le nom de la patiente (optionnel, pour l'affichage)
    try {
      final user = SupabaseService.client.auth.currentUser;
      if(user != null) {
         final patientInfo = await SupabaseService.client
            .from('patients')
            .select('prenom')
            .eq('user_id', user.id)
            .single();
         if(mounted) {
           setState(() => _patientName = patientInfo['prenom'] ?? "Patiente");
         }
      }
    } catch(e) {
       // Erreur silencieuse
    }

    if (mounted) {
      setState(() {
        _rdvs = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bienvenue, $_patientName"),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SupabaseService.client.auth.signOut();
              Navigator.pushReplacementNamed(context, '/patient-login');
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rdvs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.calendar_today, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("Aucun rendez-vous programmé."),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _rdvs.length,
                  itemBuilder: (ctx, index) {
                    final rdv = _rdvs[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15),
                        leading: CircleAvatar(
                          backgroundColor: rdv.typeRdv == 'VACCINATION' ? Colors.green[100] : Colors.pink[100],
                          child: Icon(
                            rdv.typeRdv == 'VACCINATION' ? Icons.vaccines : Icons.pregnant_woman,
                            color: rdv.typeRdv == 'VACCINATION' ? Colors.green : Colors.pink,
                          ),
                        ),
                        title: Text(
                          rdv.typeRdv,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('dd/MM/yyyy à HH:mm').format(rdv.dateHeure)),
                            if (rdv.nomVaccin != null) 
                              Text("Vaccin: ${rdv.nomVaccin}", style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            rdv.statut == 'EFFECTUE' ? "Effectué" : "Planifié",
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: rdv.statut == 'EFFECTUE' ? Colors.green : Colors.orange,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}