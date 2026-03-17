import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/patient_model.dart';
import '../../providers/patient_provider.dart';

class AddRdvScreen extends StatefulWidget {
  final PatientModel patient;
  const AddRdvScreen({super.key, required this.patient});

  @override
  State<AddRdvScreen> createState() => _AddRdvScreenState();
}

class _AddRdvScreenState extends State<AddRdvScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  bool _isLoading = false;

  // Contrôleurs pour les champs modifiables
  final _typeRdvController = TextEditingController();
  final _vaccineController = TextEditingController();

  // Données des vaccins et alertes
  final Map<String, Map<String, String>> _vaccines = {
    'BCG': {'name': 'BCG (Tuberculose)', 'risk': 'Protège contre la tuberculose, une maladie grave des poumons.'},
    'PENTA': {'name': 'Pentavalent (DTP+Hib+HepB)', 'risk': 'Protège contre 5 maladies : Diphtérie, Tétanos, Coqueluche, Hépatite B, Méningite.'},
    'POLIO': {'name': 'Polio (Poliomyélite)', 'risk': 'Protège contre la paralysie définitive des membres.'},
    'ROUGEOLE': {'name': 'Rougeole', 'risk': 'Protège contre la rougeole, maladie très contagieuse et mortelle.'},
    'FIÈVRE JAUNE': {'name': 'Fièvre Jaune', 'risk': 'Protège contre la fièvre hémorragique mortelle.'},
    'ROR': {'name': 'ROR (Rougeole-Oreillons-Rubéole)', 'risk': 'Protège contre la rougeole, les oreillons et la rubéole.'},
  };

  @override
  void initState() {
    super.initState();
    // Initialisation selon le type de patient
    if (widget.patient.genre == 'F') {
      // Mère : Défaut CPN
      _typeRdvController.text = "Consultation Prénatale (CPN)";
    } else {
      // Enfant : Défaut Vaccination
      _typeRdvController.text = "Vaccination";
      _vaccineController.text = "BCG"; // Vaccin par défaut
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1E88E5)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
              picked.year, picked.month, picked.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _saveRdv() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner une date et heure.")),
      );
      return;
    }

    // Récupération des textes saisis
    final typeRdvText = _typeRdvController.text.trim();
    final vaccineText = _vaccineController.text.trim();

    // Validation : Si enfant et vaccination, le champ vaccin doit être rempli
    if (widget.patient.genre == 'M' && typeRdvText.toLowerCase().contains('vaccination') && vaccineText.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez saisir ou choisir un vaccin.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = Provider.of<PatientProvider>(context, listen: false);
    
    final success = await provider.addRendezVous(
      patientId: widget.patient.id,
      dateHeure: _selectedDate!,
      typeRdv: typeRdvText, // Utilise le texte exact saisi
      nomVaccin: vaccineText.isNotEmpty ? vaccineText : null,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rendez-vous planifié avec succès")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Détermine le mode : Mère (F) ou Enfant (M)
    final bool isChild = widget.patient.genre == 'M';

     String? activeAlertKey;
    _vaccines.forEach((key, value) {
      if (_vaccineController.text.toUpperCase().contains(key)) {
        activeAlertKey = key;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text("RDV pour ${widget.patient.prenom}"),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Patient : ${widget.patient.prenom} ${widget.patient.nom}", 
                   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              // --- DATE ET HEURE ---
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Date et Heure *",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? "Sélectionner"
                        : DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate!),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- TYPE DE RENDEZ-VOUS (MODIFIABLE) ---
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _typeRdvController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  // Options selon le type de patient
                  List<String> options;
                  if (isChild) {
                    // ENFANT : Vaccination et Autre
                    options = ['Vaccination', 'Autre'];
                  } else {
                    // MÈRE : CPN et Autre
                    options = ['Consultation Prénatale (CPN)', 'Autre'];
                  }

                  if (textEditingValue.text.isEmpty) {
                    return options;
                  }
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
                      // Mise à jour temps réel pour afficher/masquer le champ vaccin
                      setState(() {
                         _typeRdvController.text = value;
                      });
                    },
                    validator: (v) => v!.isEmpty ? "Requis" : null,
                  );
                },
              ),

              // --- SÉLECTEUR DE VACCIN (SEULEMENT POUR ENFANT + VACCINATION) ---
              if (isChild && _typeRdvController.text.toLowerCase().contains('vaccination')) ...[
                const SizedBox(height: 20),
                const Text("Choix du Vaccin :", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _vaccineController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final options = _vaccines.keys.toList();
                    if (textEditingValue.text.isEmpty) {
                      return options;
                    }
                    return options.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _vaccineController.text = selection;
                    });
                  },
                  fieldViewBuilder: (BuildContext context, TextEditingController fieldController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
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
                        setState(() {
                           _vaccineController.text = value;
                        });
                      },
                    );
                  },
                ),

                                // ALERTE DYNAMIQUE (Corrigé)
                // On vérifie si le texte SAISI contient une clé connue (ex: "BCG")
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

              const SizedBox(height: 30),

              // --- BOUTON ENREGISTRER ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                  ),
                  onPressed: _isLoading ? null : _saveRdv,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ENREGISTRER", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}