// lib/presentation/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:materno_feotal/data/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false; // L'utilisateur est-il connecté ?

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  // Vérifier l'état de connexion au démarrage
  AuthProvider() {
    _checkSession();
  }

  void _checkSession() {
    final session = SupabaseService.client.auth.currentSession;
    _isAuthenticated = session != null;
    notifyListeners();
  }

  // Fonction de connexion pour l'Agent (Email + Mot de passe)
  Future<void> loginAgent(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _isAuthenticated = true;
        // Note: Ici on pourrait vérifier si l'utilisateur existe dans la table 'agents'
      } else {
        _errorMessage = "Aucun utilisateur trouvé.";
      }
    } catch (e) {
      _errorMessage = "Erreur de connexion : Vérifiez vos identifiants.";
      debugPrint(e.toString());
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fonction de déconnexion
  Future<void> logout() async {
    await SupabaseService.client.auth.signOut();
    _isAuthenticated = false;
    notifyListeners();
  }

    // Fonction d'inscription pour l'Agent
    Future<String?> signUpAgent({
    required String email,
    required String password,
    required String fullName,
    required String hospitalName,
    required String address,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Créer le compte utilisateur avec la méthode native de Supabase
      final AuthResponse response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
      );

      final User? user = response.user;

      if (user != null) {
        // 2. Insérer les données dans la table 'agents'
        // Utilisation de la méthode .insert() standard
        await SupabaseService.client.from('agents').insert({
          'id': user.id,
          'full_name': fullName,
          'centre_sante': hospitalName,
          'adresse': address,
          'role': 'sage_femme',
        });
        // Dans signUpAgent, après l'insert
if (response.session != null) {
  _isAuthenticated = true;
  notifyListeners();
}
        
        // 3. Connecter automatiquement l'utilisateur (Supabase le fait souvent automatiquement après le signUp, mais on s'assure)
        _isAuthenticated = true;
        
      } else {
        _errorMessage = "Erreur lors de la création du compte : Aucun utilisateur retourné.";
      }
    } on AuthException catch (e) {
        // Gestion spécifique des erreurs Supabase
      _errorMessage = "Erreur d'inscription : ${e.message}";
    } catch (e) {
      _errorMessage = "Erreur d'inscription : ${e.toString()}";
    }

    _isLoading = false;
    notifyListeners();
    return _errorMessage;
  }

  // Fonction de réinitialisation de mot de passe
  Future<bool> resetPassword(String email) async {
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      _errorMessage = "Erreur lors de l'envoi de l'email.";
      notifyListeners();
      return false;
    }
  }
}