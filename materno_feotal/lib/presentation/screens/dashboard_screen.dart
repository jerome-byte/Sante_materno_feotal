

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import 'patients/add_patient_screen.dart';
import 'perdus_de_vue_screen.dart';
import 'reports_screen.dart';
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
    @override
  void initState() {
    super.initState();
    // Nettoyer les anciennes données immédiatement pour éviter le flash
    Future.microtask(() {
       Provider.of<PatientProvider>(context, listen: false).reset();
       // Puis charger les nouvelles données
       Provider.of<PatientProvider>(context, listen: false).fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tableau de Bord", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E88E5),
        actions: [
                     IconButton(
            icon: const Icon(Icons.folder_special, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
            },
          ),

          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
            body: Consumer<PatientProvider>(
        builder: (context, provider, child) {
          
          // AFFICHAGE DE L'ERREUR
          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      "Erreur de chargement",
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    ),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    ElevatedButton(
                      onPressed: () => provider.fetchDashboardData(),
                      child: Text("Réessayer"),
                    )
                  ],
                ),
              ),
            );
          }

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // ... suite du code normal ...

          return RefreshIndicator(
            onRefresh: () => provider.fetchDashboardData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Section Titre (Dynamique)
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bonjour, ${auth.agentName ?? 'Agent'}",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            auth.hospitalName ?? "Centre de Santé",
                            style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 95, 94, 94)),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Ligne de Statistiques
                  Row(
                    children: [
                      _buildStatCard(
                        context,
                        title: "Total Patients",
                        count: provider.totalPatients.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        context,
                        title: "RDV Aujourd'hui",
                        count: provider.rdvAujourdhui.toString(),
                        icon: Icons.calendar_today,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                                    Row(
                    children: [
                      Expanded(
                        child: InkWell( // Rend la carte cliquable
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PerdusDeVueScreen()));
                          },
                          child: _buildStatCard(
                            context,
                            title: "Perdus de vue",
                            count: provider.perdusDeVue.toString(),
                            icon: Icons.warning,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Section RDV
                  const Text(
                    "Rendez-vous à venir",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  if (provider.rdvDuJour.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("Aucun rendez-vous prévu pour les prochains jours."),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.rdvDuJour.length,
                      itemBuilder: (ctx, index) {
                        final rdv = provider.rdvDuJour[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Partie Gauche : Infos
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${rdv.patientPrenom} ${rdv.patientNom}",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                                                            Text(
                                        "${rdv.typeRdv} - ${DateFormat('dd/MM HH:mm').format(rdv.dateHeure)}",
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      // Affichage du nom du vaccin si renseigné
                                      if (rdv.nomVaccin != null && rdv.nomVaccin!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            "Vaccin: ${rdv.nomVaccin}",
                                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Partie Droite : Action ou Statut
                                if (rdv.statut == 'PLANIFIE')
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                                    onPressed: () async {
                                      // On appelle la fonction du provider
                                      await Provider.of<PatientProvider>(context, listen: false)
                                          .markRdvAsDone(rdv.id);
                                    },
                                  )
                                else
                                  const Chip(
                                    label: Text("Fait", style: TextStyle(color: Colors.white)),
                                    backgroundColor: Colors.green,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPatientScreen()));
        },
        backgroundColor: const Color(0xFF1E88E5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required String title, 
    required String count, 
    required IconData icon, 
    required Color color
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              count,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}