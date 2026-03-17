import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/patient_model.dart';
import '../../providers/patient_provider.dart';

class AddPatientScreen extends StatefulWidget {
  final PatientModel? mother; // Optionnel : Si fourni, c'est un enfant
  const AddPatientScreen({super.key, this.mother});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  // Contrôleurs pour le garant
  final _garantNomController = TextEditingController();
  final _garantTelephoneController = TextEditingController();
  // Ajoutez ces deux contrôleurs
  final _typeRdvController = TextEditingController();
  final _vaccineController = TextEditingController();

  late String _genre;
  DateTime? _selectedDateRdv;
  String _typeRdv = 'CPN';

  // Nouveaux champs pour la vaccination
  String? _selectedVaccineKey; // Clé du vaccin sélectionné
  final Map<String, Map<String, String>> _vaccines = {
    'BCG': {
      'name': 'BCG (Tuberculose)',
      'risk': 'Protège contre la tuberculose, une maladie grave des poumons.',
    },
    'PENTA': {
      'name': 'Pentavalent (DTP+Hib+HepB)',
      'risk':
          'Protège contre 5 maladies : Diphtérie, Tétanos, Coqueluche, Hépatite B, Méningite.',
    },
    'POLIO': {
      'name': 'Polio (Poliomyélite)',
      'risk': 'Protège contre la paralysie définitive des membres.',
    },
    'ROUGEOLE': {
      'name': 'Rougeole',
      'risk':
          'Protège contre la rougeole, maladie très contagieuse et mortelle.',
    },
    'FIÈVRE JAUNE': {
      'name': 'Fièvre Jaune',
      'risk': 'Protège contre la fièvre hémorragique mortelle.',
    },
    'ROR': {
      'name': 'ROR (Rougeole-Oreillons-Rubéole)',
      'risk': 'Protège contre la rougeole, les oreillons et la rubéole.',
    },
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _genre = widget.mother != null ? 'M' : 'F';

    if (widget.mother != null) {
      // MODE ENFANT
      _nomController.text = widget.mother!.nom;
      _telephoneController.text = widget.mother!.telephone;
      _typeRdvController.text = "Vaccination"; // Défaut Enfant
      _vaccineController.text = "BCG"; // Défaut Vaccin
    } else {
      // MODE MÈRE
      _typeRdvController.text = "Consultation Prénatale (CPN)"; // Défaut Mère
    }
  }

  // Fonction de date corrigée (sans blocage)
  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();

    // 1. Sélection de la date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(
        const Duration(days: 30),
      ), // Autorise passé récent
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1E88E5)),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      // 2. Sélection de l'heure
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFF1E88E5)),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDateRdv = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _savePatientAndRdv() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDateRdv == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner une date de rendez-vous."),
        ),
      );
      return;
    }
    // On récupère directement le texte saisi
    final typeRdvText = _typeRdvController.text.trim();
    final vaccineText = _vaccineController.text.trim();
    final bool isChildMode = widget.mother != null;

    // Validation spécifique : Si c'est un enfant et que le type contient "vaccination", le champ vaccin doit être rempli
    if (isChildMode &&
        typeRdvText.toLowerCase().contains('vaccination') &&
        vaccineText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez saisir ou choisir un vaccin.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = Provider.of<PatientProvider>(context, listen: false);

    final patientId = await provider.addPatient(
      prenom: _prenomController.text.trim(),
      nom: _nomController.text.trim(),
      telephone: _telephoneController.text.trim(),
      genre: _genre,
      motherId: widget.mother?.id,
      // Ajoutez ces deux lignes dans les paramètres de addPatient
      contactUrgenceNom: _garantNomController.text.trim(),
      contactUrgenceTel: _garantTelephoneController.text.trim(),
    );

    if (patientId != null) {
      await provider.addRendezVous(
        patientId: patientId,
        dateHeure: _selectedDateRdv!,
        typeRdv:
            typeRdvText, // Utilise le texte saisi (ex: "Vaccination" ou "Autre...")
        nomVaccin: vaccineText.isNotEmpty
            ? vaccineText
            : null, // Ajoute le nom du vaccin si rempli
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _genre == 'M'
                  ? "Enfant enregistré avec succès !"
                  : "Patiente enregistrée !",
            ),
          ),
        );
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'enregistrement.")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isChildMode = widget.mother != null;

    // --- LOGIQUE DE L'ALERTE (Calculée avant l'affichage) ---
    // On cherche si le texte saisi contient un nom de vaccin connu
    String? activeAlertKey;
    _vaccines.forEach((key, value) {
      if (_vaccineController.text.toUpperCase().contains(key)) {
        activeAlertKey = key;
      }
    });


    return Scaffold(
      appBar: AppBar(
        title: Text(
          isChildMode ? "Enregistrer un Enfant" : "Nouvelle Patiente",
        ),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isChildMode)
                Card(
                  color: Colors.pink[50],
                  child: ListTile(
                    leading: const Icon(
                      Icons.pregnant_woman,
                      color: Colors.pink,
                    ),
                    title: Text(
                      "Mère : ${widget.mother!.prenom} ${widget.mother!.nom}",
                    ),
                  ),
                ),
              const SizedBox(height: 15),

              // Champs Nom / Prénom
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prenomController,
                      decoration: const InputDecoration(
                        labelText: "Prénom *",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Requis" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: "Nom *",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Requis" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Téléphone *",
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),
              const SizedBox(height: 15),
              // --- DEBUT BLOC GARANT ---
              const Divider(),
              const Text(
                "Personne à contacter en cas d'absence",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _garantNomController,
                decoration: const InputDecoration(
                  labelText: "Nom du garant (Mari, Parent...)",
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  // Rendre obligatoire seulement pour les femmes enceintes
                  if (_genre == 'F' && (v == null || v.isEmpty)) {
                    return "Ce Nom sera utilisé pour les relances";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _garantTelephoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Téléphone du garant",
                  prefixIcon: Icon(Icons.phone_in_talk),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (_genre == 'F' && (v == null || v.isEmpty)) {
                    return "Ce contact sera utilisé pour les relances";
                  }
                  return null;
                },
              ),

              // --- FIN BLOC GARANT ---
              const SizedBox(height: 15),
              // Sélection Type RDV
              // Sélection Type RDV (Modifiable avec suggestions)
              // Sélection Type RDV (Modifiable avec suggestions)
                            // Sélection Type RDV
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _typeRdvController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  // On définit les options EXACTES
                  List<String> options;
                  if (isChildMode) {
                    // Pour l'ENFANT : Vaccination et Autre
                    options = ['Vaccination', 'Autre'];
                  } else {
                    // Pour la MÈRE : CPN et Autre
                    options = ['Consultation Prénatale (CPN)', 'Autre'];
                  }

                  // Si le champ est vide, on montre tout
                  if (textEditingValue.text.isEmpty) {
                    return options;
                  }
                  
                  // Sinon on filtre
                  return options.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  setState(() {
                    _typeRdvController.text = selection;
                  });
                },
                fieldViewBuilder: (BuildContext context, TextEditingController fieldController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                  return TextFormField(
                    controller: fieldController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: "Type de Rendez-vous *",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (String value) {
                      setState(() {
                        _typeRdvController.text = value;
                      });
                    },
                    validator: (v) => v!.isEmpty ? "Requis" : null,
                  );
                },
              ),

              // SÉLECTEUR DE VACCIN AMÉLIORÉ
              // SÉLECTEUR DE VACCIN (Modifiable)
              // On affiche ce bloc SEULEMENT si c'est un enfant ET que le type contient "Vaccination"
              if (isChildMode &&
                  _typeRdvController.text.toLowerCase().contains(
                    'vaccination',
                  )) ...[
                const SizedBox(height: 15),
                const Text(
                  "Choix du Vaccin :",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),

                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _vaccineController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final options = _vaccines.keys
                        .toList(); // Liste des vaccins (BCG, POLIO...)
                    if (textEditingValue.text.isEmpty) {
                      return options;
                    }
                    return options.where((String option) {
                      return option.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    });
                  },
                  onSelected: (String selection) {
                    // CORRECTION ICI : Mise à jour de l'état pour afficher l'alerte
                    setState(() {
                      _vaccineController.text = selection;
                    });
                  },
                  fieldViewBuilder:
                      (
                        BuildContext context,
                        TextEditingController fieldController,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted,
                      ) {
                        return TextFormField(
                          controller: fieldController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: "Nom du vaccin",
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.blue[50],
                          ),
                          onChanged: (String value) {
                            // CORRECTION ICI : Mise à jour temps réel de l'alerte
                            setState(() {
                              _vaccineController.text = value;
                            });
                          },
                        );
                      },
                ),

                // Message d'alerte éducatif (Dynamique)
                // S'affiche si le texte correspond à une clé connue
                // Cela permet d'afficher l'alerte même si l'utilisateur ajoute du texte après (ex: "BCG dose 2"

                // Si une clé est trouvée, on affiche l'alerte correspondante
                if (activeAlertKey != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _vaccines[activeAlertKey]!['risk']!,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ],

              const SizedBox(height: 20),
              const Text(
                "Date du Rendez-vous",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),

              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedDateRdv == null
                        ? "Sélectionner date et heure"
                        : DateFormat(
                            'dd/MM/yyyy à HH:mm',
                          ).format(_selectedDateRdv!),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Bouton Enregistrer
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                  ),
                  onPressed: _isLoading ? null : _savePatientAndRdv,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "ENREGISTRER",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
