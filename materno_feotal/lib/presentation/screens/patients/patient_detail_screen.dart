import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/rendez_vous_model.dart';
import '../../providers/patient_provider.dart';
import 'add_patient_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final PatientModel patient;
  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  List<RendezVousModel> _patientRdvs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientRdvs();
  }

  Future<void> _loadPatientRdvs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final rdvs = await Provider.of<PatientProvider>(context, listen: false)
          .fetchPatientRdvs(widget.patient.id);
      
      if (mounted) {
        setState(() {
          _patientRdvs = rdvs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- FILTRAGE DES LISTES ---
    // 1. Rendez-vous Actifs (Planifiés ou Manqués) -> Restent dans le bloc "Rendez-vous"
    final activeRdvs = _patientRdvs.where((rdv) => 
        rdv.statut == 'PLANIFIE' || rdv.statut == 'MANQUE').toList();
        
    // 2. Historique (Effectués) -> Passent dans le bloc "Historique"
    final historyRdvs = _patientRdvs.where((rdv) => 
        rdv.statut == 'EFFECTUE').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.patient.prenom} ${widget.patient.nom}"),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- CARTE INFOS PATIENT ---
                  Card(
                    child: ListTile(
                      leading: Icon(
                        widget.patient.genre == 'F' ? Icons.pregnant_woman : Icons.child_care,
                        size: 40,
                        color: const Color(0xFF1E88E5),
                      ),
                      title: Text(
                        widget.patient.genre == 'F' ? "Femme Enceinte" : "Enfant",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Tél: ${widget.patient.telephone}"),
                    ),
                  ),
                  
                  // Affichage Garant
                  if (widget.patient.contactUrgenceNom != null && widget.patient.contactUrgenceNom!.isNotEmpty) ...[
                    const Divider(),
                    const Text("Personne de confiance (Garant)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text("${widget.patient.contactUrgenceNom}"),
                      ],
                    ),
                    if (widget.patient.contactUrgenceTelephone != null)
                      Row(
                        children: [
                          const Icon(Icons.phone_in_talk, size: 20, color: Colors.green),
                          const SizedBox(width: 8),
                          Text("${widget.patient.contactUrgenceTelephone}"),
                        ],
                      ),
                  ],
                  const SizedBox(height: 20),
                  
                  // --- BOUTONS ACTIONS ---
                  if (widget.patient.genre == 'F')
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.child_care),
                        label: const Text("Enregistrer un enfant (Naissance)"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                           Navigator.push(context, MaterialPageRoute(
                             builder: (_) => AddPatientScreen(mother: widget.patient)
                           ));
                        },
                      ),
                    ),

                  const SizedBox(height: 10),
                                    Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text("Terminer"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () async {
                            // Change le statut et retourne à la liste
                            await Provider.of<PatientProvider>(context, listen: false)
                                .updatePatientStatus(widget.patient.id, 'TERMINE');
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.block, color: Colors.white),
                          label: const Text("Abandon"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          onPressed: () async {
                            // Change le statut et retourne à la liste
                            await Provider.of<PatientProvider>(context, listen: false)
                                .updatePatientStatus(widget.patient.id, 'ABANDON');
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Planifier un RDV"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/add-rdv', arguments: widget.patient);
                      },
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- BLOC 1 : RENDEZ-VOUS (ACTIFS) ---
                  const Text(
                    "Rendez-vous",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  
                  if (activeRdvs.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("Aucun rendez-vous actif."),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeRdvs.length,
                      itemBuilder: (ctx, index) {
                        final rdv = activeRdvs[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: rdv.statut == 'MANQUE' ? Colors.red : Colors.orange,
                              child: Icon(
                                rdv.statut == 'MANQUE' ? Icons.warning : Icons.schedule,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              "${rdv.typeRdv}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "${DateFormat('dd/MM/yyyy HH:mm').format(rdv.dateHeure)}\n"
                              "Statut: ${rdv.statut}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                              onPressed: () async {
                                await Provider.of<PatientProvider>(context, listen: false)
                                    .markRdvAsDone(rdv.id);
                                _loadPatientRdvs();
                              },
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 30),

                  // --- BLOC 2 : HISTORIQUE (EFFECTUÉS) ---
                  const Text(
                    "Historique des rendez-vous",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),

                  if (historyRdvs.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("Aucun historique disponible."),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: historyRdvs.length,
                      itemBuilder: (ctx, index) {
                        final rdv = historyRdvs[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          color: Colors.green[50],
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.check, color: Colors.white),
                            ),
                            title: Text(
                              "${rdv.typeRdv}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Effectué le ${DateFormat('dd/MM/yyyy').format(rdv.dateHeure)}",
                            ),
                            trailing: const Chip(
                              label: Text("Effectué", style: TextStyle(color: Colors.green)),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}