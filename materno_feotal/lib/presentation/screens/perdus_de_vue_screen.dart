import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/patient_provider.dart';
import '../../data/models/rendez_vous_model.dart';

class PerdusDeVueScreen extends StatelessWidget {
  const PerdusDeVueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patients Perdus de Vue", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
      body: FutureBuilder<List<RendezVousModel>>(
        future: Provider.of<PatientProvider>(context, listen: false).fetchPerdusDeVueDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucun patient perdu de vue actuellement !"));
          }

          final perdus = snapshot.data!;

          return ListView.builder(
            itemCount: perdus.length,
            itemBuilder: (ctx, index) {
              final rdv = perdus[index];
              return Card(
                margin: const EdgeInsets.all(10),
                color: Colors.red[50],
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text("${rdv.patientPrenom} ${rdv.patientNom}"),
                  subtitle: Text("RDV prévu le ${DateFormat('dd/MM/yyyy').format(rdv.dateHeure)}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      // Marquer comme fait pour sortir de la liste
                      await Provider.of<PatientProvider>(context, listen: false).markRdvAsDone(rdv.id);
                      // Rafraîchir
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PerdusDeVueScreen()));
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}