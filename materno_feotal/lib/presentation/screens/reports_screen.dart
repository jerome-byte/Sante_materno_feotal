import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../presentation/providers/patient_provider.dart';
import '../../data/models/patient_model.dart';


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

  // Fonction de génération du PDF
    // Fonction de génération du PDF
  Future<void> _generatePdf(List<PatientModel> patients, String title) async {
    try {
      // 1. Vérifier qu'il y a des données
      if (patients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aucune donnée à exporter.")),
        );
        return;
      }

      // 2. Créer le document PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Text(title, 
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)
                )
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // En-tête du tableau
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Nom Prénom')),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Téléphone')),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Genre')),
                    ]
                  ),
                  // Lignes de données
                  ...patients.map((p) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${p.nom} ${p.prenom}')),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(p.telephone)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(p.genre ?? '')),
                    ]
                  ))
                ]
              )
            ];
          },
        ),
      );

      // 3. Sauvegarder le fichier
      final output = await getApplicationDocumentsDirectory();
      final fileName = "Rapport_${title}_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File("${output.path}/$fileName");
      
      await file.writeAsBytes(await pdf.save());

      // 4. Confirmation et Ouverture
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF créé avec succès ! Cliquez pour ouvrir.")),
      );

      // Tenter d'ouvrir le fichier
      final result = await OpenFile.open(file.path);
      
      if (result.type != ResultType.done) {
        // Si l'ouverture échoue (ex: pas de lecteur PDF), on affiche le chemin
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fichier sauvegardé dans: ${file.path}")),
        );
      }

    } catch (e) {
      // Afficher l'erreur exacte si ça plante
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la création du PDF: $e")),
      );
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
            Tab(text: "Dossiers Terminés"),
            Tab(text: "Dossiers Abandonnés"),
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
                label: const Text("Télécharger PDF"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  _generatePdf(
                    list,
                    status == 'TERMINE'
                        ? "Dossiers_Termines"
                        : "Dossiers_Abandons",
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text("Aucun dossier dans cette catégorie."))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (ctx, index) {
                    final patient = list[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.archive,
                          color: status == 'TERMINE'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        title: Text("${patient.prenom} ${patient.nom}"),
                        subtitle: Text(
                          "Enregistré le ${patient.createdAt?.toString().substring(0, 10) ?? ''}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            _showDeleteConfirmation(patient);
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(PatientModel patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text(
          "Voulez-vous vraiment supprimer ${patient.prenom} de l'application ?\n\nATTENTION : Assurez-vous d'avoir téléchargé le PDF avant de supprimer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await Provider.of<PatientProvider>(
                context,
                listen: false,
              ).deletePatient(patient.id);
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text("SUPPRIMER DEFINITIVEMENT"),
          ),
        ],
      ),
    );
  }
}
