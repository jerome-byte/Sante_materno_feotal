import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../providers/patient_provider.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/rendez_vous_model.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PatientModel> _terminatedList = [];
  List<PatientModel> _abandonedList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<PatientProvider>(context, listen: false);
    _terminatedList = await provider.fetchArchivedPatients('TERMINE');
    _abandonedList = await provider.fetchArchivedPatients('ABANDON');
    setState(() => _isLoading = false);
  }


  // --- FONCTION PDF LISTE ---
   // --- FONCTION PDF LISTE (AVEC HISTORIQUE COMPLET POUR TOUS) ---
  Future<void> _generateListPdf(List<PatientModel> patients, String title) async {
    try {
      if (patients.isEmpty) return;

      final provider = Provider.of<PatientProvider>(context, listen: false);
      final pdf = pw.Document();

      // Liste qui contiendra toutes les pages/widgets de tous les patients
      List<pw.Widget> allContent = [];

      // Titre général du rapport
      allContent.add(
        pw.Center(
          child: pw.Text("RAPPORT GLOBAL: $title", 
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)
          )
        )
      );
      allContent.add(pw.SizedBox(height: 30));

      // Boucle sur chaque patient pour ajouter sa fiche
      for (var patient in patients) {
        // 1. Récupérer l'historique du patient
        final rdvs = await provider.fetchPatientRdvs(patient.id);

        // 2. En-tête du patient (Nom + Statut en couleur)
        allContent.add(
          pw.Container(
            width: double.infinity,
            color: title == 'TERMINE' ? PdfColors.green : PdfColors.orange,
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              "${patient.prenom} ${patient.nom} - STATUT: $title",
              style: pw.TextStyle(fontSize: 16, color: PdfColors.white, fontWeight: pw.FontWeight.bold)
            ),
          )
        );
        allContent.add(pw.SizedBox(height: 10));

        // 3. Infos du patient
        allContent.add(pw.Text("Téléphone: ${patient.telephone}"));
        allContent.add(pw.Text("Genre: ${patient.genre == 'F' ? 'Femme' : 'Enfant'}"));
        if(patient.contactUrgenceNom != null) 
          allContent.add(pw.Text("Contact: ${patient.contactUrgenceNom} (${patient.contactUrgenceTelephone})"));
        
        allContent.add(pw.SizedBox(height: 15));

        // 4. Tableau de l'historique
        allContent.add(pw.Text("Historique des Rendez-vous:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
        allContent.add(pw.SizedBox(height: 5));

        if (rdvs.isEmpty) {
          allContent.add(pw.Text("Aucun rendez-vous enregistré."));
        } else {
          allContent.add(
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Date', style: pw.TextStyle(fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Type', style: pw.TextStyle(fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Statut', style: pw.TextStyle(fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Détails', style: pw.TextStyle(fontSize: 10))),
                  ]
                ),
                ...rdvs.map((rdv) => pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(DateFormat('dd/MM/yy HH:mm').format(rdv.dateHeure), style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(rdv.typeRdv, style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(rdv.statut, style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(rdv.nomVaccin ?? '-', style: const pw.TextStyle(fontSize: 9))),
                  ]
                ))
              ]
            )
          );
        }

        // Séparateur entre les patients
        allContent.add(pw.Divider(color: PdfColors.grey, thickness: 2.0));
        allContent.add(pw.SizedBox(height: 20));
      }

      // Génération du PDF final avec MultiPage
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return allContent;
          },
        ),
      );

      // Sauvegarde
      final output = await getApplicationDocumentsDirectory();
      final file = File("${output.path}/Rapport_Complet_$title.pdf");
      await file.writeAsBytes(await pdf.save());
      
      // Ouverture
      await OpenFile.open(file.path);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Archives & Rapports"),
        backgroundColor: const Color(0xFF1E88E5),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Terminés"),
            Tab(text: "Abandonnés"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_terminatedList, 'TERMINE'),
                _buildList(_abandonedList, 'ABANDON'),
              ],
            ),
    );
  }

  // --- WIDGET POUR CONSTRUIRE LA LISTE ---
  Widget _buildList(List<PatientModel> list, String status) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total: ${list.length} patients"),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("PDF Liste"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => _generateListPdf(list, status),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text("Aucun dossier."))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (ctx, index) {
                    final patient = list[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.archive, color: status == 'TERMINE' ? Colors.green : Colors.orange),
                        title: Text("${patient.prenom} ${patient.nom}"),
                        subtitle: Text("Statut: ${patient.statutDossier ?? status}"),
                        trailing: 
                            IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              onPressed: () => _showDeleteConfirmation(patient),
                            ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- DIALOGUE DE SUPPRESSION ---
  void _showDeleteConfirmation(PatientModel patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Suppression Définitive"),
        content: Text(
          "Supprimer ${patient.prenom} de l'application ?\n\n"
          "NOTE : Le fichier PDF reste sauvegardé sur votre téléphone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await Provider.of<PatientProvider>(context, listen: false)
                  .deletePatient(patient.id);
              if (mounted) {
                Navigator.pop(ctx);
                _loadData();
              }
            },
            child: const Text("SUPPRIMER"),
          ),
        ],
      ),
    );
  }
}