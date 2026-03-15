class RendezVousModel {
  final int id;
  final int? patientId; // Rendu optionnel
  final DateTime dateHeure;
  final String typeRdv;
  final String statut;
  final String? nomVaccin;
  final String patientPrenom;
  final String patientNom;
  final String patientTelephone;

  RendezVousModel({
    required this.id,
    this.patientId, // Optionnel
    required this.dateHeure,
    required this.typeRdv,
    required this.statut,
    this.nomVaccin,
    required this.patientPrenom,
    required this.patientNom,
    required this.patientTelephone,
  });

  factory RendezVousModel.fromJson(Map<String, dynamic> json) {
    final patientData = json['patients'] as Map<String, dynamic>?;

    return RendezVousModel(
      id: json['id'],
      patientId: json['patient_id'], // Ne plantera plus si manquant
      dateHeure: DateTime.parse(json['date_heure']),
      typeRdv: json['type_rdv'] ?? 'Inconnu',
      statut: json['statut'] ?? 'PLANIFIE',
      nomVaccin: json['nom_vaccin'],
      patientPrenom: patientData?['prenom'] ?? 'Inconnu',
      patientNom: patientData?['nom'] ?? 'Inconnu',
      patientTelephone: patientData?['telephone'] ?? 'Inconnu',
    );
  }
}