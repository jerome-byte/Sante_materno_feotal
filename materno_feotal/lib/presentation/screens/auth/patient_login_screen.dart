import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    try {
      // Supabase envoie un SMS (nécessite configuration Twilio/sms provider dans Supabase)
      await Supabase.instance.client.auth.signInWithOtp(
        phone: _phoneController.text.trim(),
      );
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code OTP envoyé !")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
    setState(() => _isLoading = false);
  }

    Future<void> _verifyOtp() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        phone: _phoneController.text.trim(),
        token: _otpController.text.trim(),
        type: OtpType.sms,
      );

      if (response.user != null) {
        // --- NOUVEAU : LIAISON AUTOMATIQUE ---
        // On cherche si ce numéro existe dans la table 'patients' créé par la sage-femme
        final patientData = await Supabase.instance.client
            .from('patients')
            .select('id')
            .eq('telephone', _phoneController.text.trim())
            .maybeSingle(); // maybeSingle pour éviter erreur si non trouvé

        if (patientData != null) {
          // Si trouvé, on met à jour le user_id dans le dossier patient
          await Supabase.instance.client
              .from('patients')
              .update({'user_id': response.user!.id})
              .eq('id', patientData['id']);
        }
        // -------------------------------------

        Navigator.pushReplacementNamed(context, '/patient-dashboard');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: Code invalide ou expiré.")),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Espace Patiente")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pregnant_woman, size: 80, color: Color(0xFF1E88E5)),
            const SizedBox(height: 20),
            const Text("Entrez votre numéro de téléphone pour voir vos rendez-vous"),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Téléphone (ex: +22890000000)"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            if (_otpSent)
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: "Code de vérification (OTP)"),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _otpSent ? _verifyOtp() : _sendOtp(),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_otpSent ? "Valider le code" : "Recevoir le code"),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login-agent'), 
              child: const Text("Vous êtes Agent de Santé ? Cliquez ici")
            )
          ],
        ),
      ),
    );
  }
}