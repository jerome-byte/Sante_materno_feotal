// lib/presentation/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:materno_feotal/presentation/providers/auth_provider.dart';
import '../main_container.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Dégradé de couleurs pro (Bleu médical)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo ou Titre
                      const Icon(Icons.local_hospital, size: 60, color: Color(0xFF1E88E5)),
                      const SizedBox(height: 16),
                      const Text(
                        "SANTE+ ",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Text("Espace Agent de Santé", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 32),

                      // Champ Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Adresse Email",
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value!.isEmpty ? "Email requis" : null,
                      ),
                      const SizedBox(height: 16),

                      // Champ Mot de passe
                                        TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible, // Utilise la variable
                    decoration: InputDecoration(
                      labelText: "Mot de passe",
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      // Ajout de l'icône Œil
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? "Mot de passe requis" : null,
                  ),
                      const SizedBox(height: 24),

                      // Bouton Connexion
                      Consumer<AuthProvider>(
                        builder: (context, auth, child) {
                          return Column(
                            children: [
                              if (auth.errorMessage != null)
                                Text(
                                  auth.errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E88E5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: auth.isLoading
                                      ? null
                                      : () async {
                                          if (_formKey.currentState!.validate()) {
                                            await auth.loginAgent(
                                              _emailController.text.trim(),
                                              _passwordController.text.trim(),
                                            );
                                            
                                            // Redirection si succès
                                            if (auth.isAuthenticated) {
                                               Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainContainer()));
                                            }
                                          }
                                        },
                                  child: auth.isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text("SE CONNECTER", style: TextStyle(color: Colors.white, fontSize: 16)),
                                ),
                              ),
                                            // ... Bouton SE CONNECTER existant ...
              const SizedBox(height: 10),
              
              // Lien Mot de passe oublié
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: const Text("Mot de passe oublié ?"),
                ),
              ),
              const SizedBox(height: 20),

              // Lien Créer un compte
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Pas encore de compte ?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen()));
                    },
                    child: const Text("S'inscrire", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                  ),
                ],
              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

    Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer votre email pour réinitialiser le mot de passe.")),
      );
      return;
    }

    final success = await Provider.of<AuthProvider>(context, listen: false).resetPassword(email);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email de réinitialisation envoyé ! Vérifiez votre boîte.")),
      );
    }
  }
}