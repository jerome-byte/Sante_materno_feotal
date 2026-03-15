// lib/presentation/screens/rdv/add_rdv_screen.dart

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
  String _typeRdv = 'CPN';
  bool _isLoading = false;

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
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      setState(() => _isLoading = true);
      
      final success = await Provider.of<PatientProvider>(context, listen: false).addRendezVous(
        patientId: widget.patient.id,
        dateHeure: _selectedDate!,
        typeRdv: _typeRdv,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        Navigator.pop(context); // Retour au détail patient
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rendez-vous planifié avec succès")),
        );
      }
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner une date")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("RDV pour ${widget.patient.prenom}"),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("Patient : ${widget.patient.prenom} ${widget.patient.nom}"),
              const SizedBox(height: 20),
              
              // Sélection Date
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Date et Heure",
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

              // Sélection Type
              DropdownButtonFormField<String>(
                value: _typeRdv,
                decoration: const InputDecoration(
                  labelText: "Type de RDV",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'CPN', child: Text("Consultation Prénatale")),
                  DropdownMenuItem(value: 'VACCINATION', child: Text("Vaccination")),
                  DropdownMenuItem(value: 'AUTRE', child: Text("Autre")),
                ],
                onChanged: (val) => setState(() => _typeRdv = val!),
              ),
              
              const SizedBox(height: 30),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _saveRdv,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("ENREGISTRER LE RENDEZ-VOUS", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}