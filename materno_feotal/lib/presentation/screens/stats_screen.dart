// lib/presentation/screens/stats_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    // Rafraîchir les stats à l'ouverture
    Provider.of<PatientProvider>(context, listen: false).fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistiques & Performance", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: Consumer<PatientProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Calcul du total pour le graphique
          final totalRdv = provider.rdvEffectues + provider.rdvManques + provider.rdvPlanifies;
          
          // Données pour le graphique
          // Si tout est à 0, on met une valeur par défaut pour éviter le crash du graphique
          final chartData = [
            PieChartSectionData(
              value: provider.rdvEffectues.toDouble(),
              title: '${provider.rdvEffectues}',
              color: Colors.green,
              radius: 60,
              titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            PieChartSectionData(
              value: provider.rdvManques.toDouble(),
              title: '${provider.rdvManques}',
              color: Colors.red,
              radius: 60,
              titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
             PieChartSectionData(
              value: provider.rdvPlanifies.toDouble(),
              title: '${provider.rdvPlanifies}',
              color: Colors.orange,
              radius: 60,
              titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Carte du Taux de Réussite
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          "Taux de Réussite Global",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        if (totalRdv == 0)
                          const Text("Aucune donnée disponible")
                        else
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: chartData,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        
                        // Légende
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLegend(color: Colors.green, text: "Effectués"),
                            _buildLegend(color: Colors.red, text: "Manqués"),
                            _buildLegend(color: Colors.orange, text: "Planifiés"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Statistiques Rapides
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStatCard(
                        title: "Total RDV",
                        value: totalRdv.toString(),
                        icon: Icons.calendar_month,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMiniStatCard(
                        title: "Taux Réussite",
                        value: totalRdv > 0 
                            ? "${((provider.rdvEffectues / totalRdv) * 100).toStringAsFixed(0)}%" 
                            : "0%",
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend({required Color color, required String text}) {
    return Row(
      children: [
        Container(width: 15, height: 15, color: color),
        const SizedBox(width: 5),
        Text(text),
      ],
    );
  }

  Widget _buildMiniStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}