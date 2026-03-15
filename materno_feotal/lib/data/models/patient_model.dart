// lib/data/models/patient_model.dart

class PatientModel {
  final int id;
  final String prenom;
  final String nom;
  final String telephone;
  final String? genre; // 'F' ou 'M'
  final int? motherId; // ID de la mère si c'est un enfant
  final String? deviceToken;
  final String? userId; // Lien vers le compte utilisateur
  final String? contactUrgenceNom;
  final String? contactUrgenceTelephone;
  final String? statutDossier; // Ajoutez ceci

  final DateTime? createdAt; // Ajoutez cette ligne
    final String? createdBy; // Ajoutez ceci

  PatientModel({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.telephone,
    this.genre,
    this.motherId,
    this.deviceToken,
    this.userId,
     this.contactUrgenceNom, // Ajouter ici
    this.contactUrgenceTelephone, // Ajouter ici
    this.statutDossier, // Ajoutez ceci
        this.createdAt, // Ajoutez cette ligne
            this.createdBy, // Ajoutez ceci
  });

  // Factory pour créer un objet Patient à partir du JSON de Supabase
  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'],
      prenom: json['prenom'] ?? '',
      nom: json['nom'] ?? '',
      telephone: json['telephone'] ?? '',
      genre: json['genre'],
      motherId: json['mother_id'],
      deviceToken: json['device_token'],
      userId: json['user_id'],
      contactUrgenceNom: json['contact_urgence_nom'],
      contactUrgenceTelephone: json['contact_urgence_telephone'],
      statutDossier: json['statut_dossier'], // Ajoutez ceci
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null, // Ajoutez cette ligne
            createdBy: json['created_by'], // Ajoutez ceci
    );
  }

  // Méthode pour convertir l'objet en JSON (pour l'envoi vers Supabase)
  Map<String, dynamic> toJson() {
    return {
      'prenom': prenom,
      'nom': nom,
      'telephone': telephone,
      'genre': genre,
      'mother_id': motherId,
      'device_token': deviceToken,
    };
  }
}