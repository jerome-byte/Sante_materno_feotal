// lib/presentation/screens/patients/patients_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/patient_provider.dart';
import '../../../data/models/patient_model.dart';
import 'patient_detail_screen.dart'; // Nous allons le créer ensuite

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PatientModel> _filteredPatients = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Charger les patients au démarrage
    Provider.of<PatientProvider>(context, listen: false).fetchPatients();
  }

  void _filterPatients(String query, List<PatientModel> allPatients) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredPatients = allPatients;
      });
    } else {
      setState(() {
        _isSearching = true;
        _filteredPatients = allPatients
            .where((p) =>
                p.prenom.toLowerCase().contains(query.toLowerCase()) ||
                p.nom.toLowerCase().contains(query.toLowerCase()) ||
                p.telephone.contains(query))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Liste des Patients", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Rechercher (Nom, Prénom, Tél)...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                final provider = Provider.of<PatientProvider>(context, listen: false);
                _filterPatients(value, provider.patients);
              },
            ),
          ),
          
          // Liste des patients
          Expanded(
            child: Consumer<PatientProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final displayList = _isSearching ? _filteredPatients : provider.patients;

                if (displayList.isEmpty) {
                  return const Center(child: Text("Aucun patient trouvé."));
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchPatients(),
                  child: ListView.builder(
                    itemCount: displayList.length,
                    itemBuilder: (ctx, index) {
                      final patient = displayList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: patient.genre == 'F' 
                                ? Colors.pink[100] 
                                : Colors.blue[100],
                            child: Icon(
                              patient.genre == 'F' ? Icons.pregnant_woman : Icons.child_care,
                              color: patient.genre == 'F' ? Colors.pink : Colors.blue,
                            ),
                          ),
                          title: Text("${patient.prenom} ${patient.nom}"),
                          subtitle: Text(patient.telephone),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Naviguer vers le détail patient
                            Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (_) => PatientDetailScreen(patient: patient)
                              )
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Naviguer vers l'ajout patient
           Navigator.pushNamed(context, '/add-patient');
        },
        backgroundColor: const Color(0xFF1E88E5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}