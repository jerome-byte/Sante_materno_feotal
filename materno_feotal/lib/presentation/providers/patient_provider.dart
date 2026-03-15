// lib/presentation/providers/patient_provider.dart

import 'package:flutter/material.dart';
import '../../data/models/rendez_vous_model.dart';
import '../../data/services/supabase_service.dart';
import '../../data/models/patient_model.dart';


class PatientProvider with ChangeNotifier {
  List<RendezVousModel> _rdvDuJour = [];
  // Ajoutez ces variables en haut de la classe PatientProvider
  List<PatientModel> _patients = [];
  List<PatientModel> get patients => _patients;

  String? _errorMessage; // Ajoutez ceci
  String? get errorMessage => _errorMessage; // Ajoutez ceci
    // Variables pour les stats détaillées
  int _rdvEffectues = 0;
  int _rdvPlanifies = 0;
  int _rdvManques = 0;
  
  int get rdvEffectues => _rdvEffectues;
  int get rdvPlanifies => _rdvPlanifies;
  int get rdvManques => _rdvManques;

// Ajoutez cette nouvelle fonction
    Future<void> fetchPatients() async {
    _isLoading = true;
    notifyListeners();
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      
      final response = await SupabaseService.client
          .from('patients')
          .select('*')
          .eq('created_by', userId ?? '') // Ajout du filtre
          .order('created_at', ascending: false);

      _patients = response.map<PatientModel>((json) => PatientModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Erreur chargement patients: $e");
    }
    _isLoading = false;
    notifyListeners();
  }


    // Marquer un RDV comme effectué
  Future<void> markRdvAsDone(int rdvId) async {
    try {
      await SupabaseService.client
          .from('rendez_vous')
          .update({'statut': 'EFFECTUE'})
          .eq('id', rdvId);
      
      // Très important : Recharger les données pour mettre à jour l'UI
      fetchDashboardData();
    } catch (e) {
      debugPrint("Erreur maj RDV: $e");
    }
  }

      // Ajoutez cette fonction dans la classe PatientProvider
  Future<List<RendezVousModel>> fetchPatientRdvs(int patientId) async {
    try {
      final response = await SupabaseService.client
          .from('rendez_vous')
          .select('id, date_heure, type_rdv, statut, nom_vaccin, patients(prenom, nom, telephone)')
          .eq('patient_id', patientId)
          .order('date_heure', ascending: false);
      
      return response.map<RendezVousModel>((json) => RendezVousModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Erreur fetch patient rdvs: $e");
      return [];
    }
  }

  bool _isLoading = false;
  
  // Statistiques
  int _totalPatients = 0;
  int _rdvAujourdhui = 0;
  int _perdusDeVue = 0;

  List<RendezVousModel> get rdvDuJour => _rdvDuJour;
  bool get isLoading => _isLoading;
  int get totalPatients => _totalPatients;
  int get rdvAujourdhui => _rdvAujourdhui;
  int get perdusDeVue => _perdusDeVue;

  // Récupérer les données du tableau de bord
     Future<void> fetchDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Récupérer l'ID de l'agent connecté
      final userId = SupabaseService.client.auth.currentUser?.id;
      
      // DEBUG: Affiche l'ID de l'utilisateur connecté
      debugPrint("========================================");
      debugPrint("DEBUG: ID Utilisateur Connecté = $userId");
      debugPrint("========================================");

      if (userId == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      // 1. Total Patients (Filtré)
      final patientsResponse = await SupabaseService.client
          .from('patients')
          .select('id')
          .eq('created_by', userId); // IMPORTANT : Filtrer par created_by
      _totalPatients = patientsResponse.length;

      // 2. Récupérer les RDV (Filtré grâce à la relation patient)
      // On demande les RDV où le patient appartient à l'agent actuel
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
      final endDate = DateTime(today.year, today.month, today.day , 23, 59, 59).toIso8601String();

      // Note: Supabase va automatiquement appliquer la règle RLS, 
      // mais on peut aussi filtrer par relation si besoin.
      // Ici on fait confiance au RLS configuré dans l'Étape 1.
            final rdvTodayResponse = await SupabaseService.client
          .from('rendez_vous')
          // On ajoute prenom et nom dans la sélection
          .select('id, patient_id, date_heure, type_rdv, statut, nom_vaccin, patients(id, prenom, nom, created_by)')          .gte('date_heure', startOfDay)
          .lte('date_heure', endDate)
          // AJOUT IMPORTANT : Exclure les RDV déjà effectués
          .neq('statut', 'EFFECTUE') 
          .order('date_heure', ascending: true);

      // Filtrage côté client (double sécurité) : on ne garde que si patients.created_by == userId
      // Mais avec le RLS activé, rdvTodayResponse ne contiendra déjà plus les autres.
      
            // Filtrage FORCÉ côté client :
      // On ne garde le RDV que SI le patient existe ET qu'il appartient à l'agent connecté
      final filteredList = rdvTodayResponse.where((json) {
        final patientData = json['patients'];
        // Si le patient est null (cas orphelin) ou n'appartient pas à l'agent -> On jette
        return patientData != null && patientData['created_by'] == userId;
      }).toList();

      _rdvDuJour = filteredList.map<RendezVousModel>((json) => RendezVousModel.fromJson(json)).toList();
      _rdvAujourdhui = _rdvDuJour.length;
            // 3. Statistiques Globales (FILTRÉES)
      // On récupère les RDV en joignant la table patient pour vérifier le owner
            final allRdvResponse = await SupabaseService.client
          .from('rendez_vous')
          .select('statut, patients(created_by)');

      _rdvEffectues = 0;
      _rdvPlanifies = 0;
      _rdvManques = 0;

      final currentUserId = SupabaseService.client.auth.currentUser?.id;

      for (var rdv in allRdvResponse) {
        // On vérifie si le patient appartient à l'agent connecté
        final patientData = rdv['patients'];
        if (patientData != null && patientData['created_by'] == currentUserId) {
          if (rdv['statut'] == 'EFFECTUE') {
            _rdvEffectues++;
          } else if (rdv['statut'] == 'PLANIFIE') {
            _rdvPlanifies++;
          } else if (rdv['statut'] == 'MANQUE') {
            _rdvManques++;
          }
        }
      }
      
      // Recalcul des perdus de vue (La requête est automatiquement filtrée par RLS)
      final perdusResponse = await SupabaseService.client
          .from('rendez_vous')
          .select('id')
          .eq('statut', 'PLANIFIE')
          .lt('date_heure', DateTime.now().toIso8601String());
      
      _perdusDeVue = perdusResponse.length; // Grace au RLS, ça ne compte que les siens
      _rdvAujourdhui = _rdvDuJour.length;
    } catch (e) {
      debugPrint("Erreur chargement dashboard: $e");
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

    // ... suite de patient_provider.dart
  Future<int?> addPatient({
    required String prenom,
    required String nom,
    required String telephone,
    required String genre,
    int? motherId,
    String? contactUrgenceNom,
    String? contactUrgenceTel,
  }) async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      
      final response = await SupabaseService.client
          .from('patients')
          .insert({
            'prenom': prenom,
            'nom': nom,
            'telephone': telephone,
            'genre': genre,
            'mother_id': motherId,
            'contact_urgence_nom': contactUrgenceNom,
            'contact_urgence_telephone': contactUrgenceTel,
            'created_by': userId,
          })
          .select('id')
          .single();

      fetchDashboardData();
      
      // Envoi SMS (non bloquant)
      try {
         await SupabaseService.client.functions.invoke('send-invite', body: {
           'telephone': telephone,
           'prenom': prenom
         });
      } catch (e) {
         debugPrint("Erreur envoi invitation: $e");
      }
      
      return response['id'] as int;
    } catch (e) {
      // AFFICHAGE CLAIR DE L'ERREUR DANS LA CONSOLE
      debugPrint("!!!!!!!! ERREUR SUPABASE Ajout Patient: $e"); 
      return null;
    }
  }

  // Ajouter un rendez-vous pour un patient
  Future<bool> addRendezVous({
    required int patientId,
    required DateTime dateHeure,
    required String typeRdv,
    String? nomVaccin,
  }) async {
    try {
      await SupabaseService.client.from('rendez_vous').insert({
        'patient_id': patientId,
        'date_heure': dateHeure.toIso8601String(),
        'type_rdv': typeRdv,
        'nom_vaccin': nomVaccin,
        'statut': 'PLANIFIE',
      });
      
      fetchDashboardData(); // Mettre à jour les compteurs
      return true;
    } catch (e) {
      debugPrint("Erreur ajout RDV: $e");
      return false;
    }
  }

    // Récupérer la liste des perdus de vue (RDV passés non effectués)
  Future<List<RendezVousModel>> fetchPerdusDeVueDetails() async {
    try {
      final response = await SupabaseService.client
          .from('rendez_vous')
          .select('id, patient_id, date_heure, type_rdv, statut, patients(prenom, nom, telephone)')
          .eq('statut', 'PLANIFIE')
          .lt('date_heure', DateTime.now().toIso8601String())
          .order('date_heure', ascending: true);
      
      return response.map<RendezVousModel>((json) => RendezVousModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Erreur fetch perdus de vue: $e");
      return [];
    }
  }

    // Marquer un dossier comme TERMINÉ ou ABANDONNÉ
  Future<void> updatePatientStatus(int patientId, String newStatus) async {
    try {
      await SupabaseService.client
          .from('patients')
          .update({'statut_dossier': newStatus})
          .eq('id', patientId);
      
      fetchDashboardData();
      fetchPatients(); // Rafraîchir les listes
    } catch (e) {
      debugPrint("Erreur maj statut: $e");
    }
  }

    // Supprimer un patient (après archivage PDF)
  Future<void> deletePatient(int patientId) async {
    try {
      // Supprimer d'abord les RDV liés (pour éviter les erreurs de clé étrangère)
      await SupabaseService.client
          .from('rendez_vous')
          .delete()
          .eq('patient_id', patientId);
          
      // Supprimer le patient
      await SupabaseService.client
          .from('patients')
          .delete()
          .eq('id', patientId);
          
      fetchDashboardData();
    } catch (e) {
      debugPrint("Erreur suppression: $e");
    }
  }

    // Récupérer les listes pour le PDF
  Future<List<PatientModel>> fetchArchivedPatients(String status) async {
    try {
      final response = await SupabaseService.client
          .from('patients')
          .select('*')
          .eq('statut_dossier', status);
      
      return response.map<PatientModel>((json) => PatientModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

    // Récupérer les RDV du patient connecté (via son user_id)
  Future<List<RendezVousModel>> fetchMyRdvs() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return [];

      // 1. Trouver le patient lié à ce user_id
      final patientData = await SupabaseService.client
          .from('patients')
          .select('id')
          .eq('user_id', userId)
          .single();
      
      final patientId = patientData['id'];

      // 2. Récupérer ses RDV
      final response = await SupabaseService.client
          .from('rendez_vous')
          .select('id, date_heure, type_rdv, statut, nom_vaccin')
          .eq('patient_id', patientId)
          .order('date_heure', ascending: true);

      return response.map<RendezVousModel>((json) => RendezVousModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Erreur fetch my rdvs: $e");
      return [];
    }
  }

  // Fonction pour vider les données (à appeler lors de la déconnexion/connexion)
  void reset() {
    _patients = [];
    _rdvDuJour = [];
    _totalPatients = 0;
    _rdvAujourdhui = 0;
    _perdusDeVue = 0;
    _rdvEffectues = 0;
    _rdvPlanifies = 0;
    _rdvManques = 0;
    notifyListeners();
  }

}