import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/patient_provider.dart';
import '../../data/models/rendez_vous_model.dart';

class PerdusDeVueScreen extends StatefulWidget {
  const PerdusDeVueScreen({super.key});

  @override
  State<PerdusDeVueScreen> createState() => _PerdusDeVueScreenState();
}

class _PerdusDeVueScreenState extends State<PerdusDeVueScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Patients Perdus de Vue",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
      body: FutureBuilder<List<RendezVousModel>>(
        future: Provider.of<PatientProvider>(
          context,
          listen: false,
        ).fetchPerdusDeVueDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Aucun patient perdu de vue actuellement !"),
            );
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
                  subtitle: Text(
                    "RDV prévu le ${DateFormat('dd/MM/yyyy').format(rdv.dateHeure)}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bouton Appel
                      IconButton(
                        icon: const Icon(
                          Icons.phone_in_talk,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          _showCallOptions(rdv);
                        },
                      ),
                      // Bouton Valider
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        onPressed: () async {
                          await Provider.of<PatientProvider>(
                            context,
                            listen: false,
                          ).markRdvAsDone(rdv.id);
                          // Rafraîchir
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PerdusDeVueScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- FONCTIONS D'APPEL (À L'INTÉRIEUR DE LA CLASSE) ---

  void _showCallOptions(RendezVousModel rdv) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Qui souhaitez-vous appeler ?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.pink),
                title: Text(rdv.patientPrenom),
                subtitle: Text(rdv.patientTelephone),
                onTap: () => _makeCall(rdv.patientTelephone),
              ),
              if (rdv.patientContactUrgenceTel != null &&
                  rdv.patientContactUrgenceTel!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.people, color: Colors.orange),
                  title: Text(rdv.patientContactUrgenceNom ?? "Garant"),
                  subtitle: Text(rdv.patientContactUrgenceTel!),
                  onTap: () => _makeCall(rdv.patientContactUrgenceTel!),
                ),
            ],
          ),
        );
      },
    );
  }

  void _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // 'mounted' et 'context' sont maintenant reconnus car cette fonction est DANS la classe State
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Impossible d'appeler $phoneNumber")),
        );
      }
    }
    // Fermer le menu après le clic
    if (mounted) Navigator.pop(context);
  }
}
