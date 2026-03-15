import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../main_container.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false; // Variable pour gérer la visibilité

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer un compte Agent", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.person_add, size: 60, color: Color(0xFF1E88E5)),
              const SizedBox(height: 20),
              
              // Nom Complet
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nom Complet *",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),
              const SizedBox(height: 15),

              // Hôpital / Centre
              TextFormField(
                controller: _hospitalController,
                decoration: const InputDecoration(
                  labelText: "Nom du Centre de Santé *",
                  prefixIcon: Icon(Icons.local_hospital),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),
              const SizedBox(height: 15),

              // Adresse
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Adresse / Ville *",
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),
              const SizedBox(height: 15),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Adresse Email *",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),
              const SizedBox(height: 15),

              // Mot de passe
                        // Mot de passe
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible, // Utilise la variable
            decoration: InputDecoration(
              labelText: "Mot de passe *",
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
            validator: (v) => v!.length < 6 ? "6 caractères minimum" : null,
          ),
              const SizedBox(height: 30),

              // Bouton Inscription
              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  return Column(
                    children: [
                      if (auth.errorMessage != null)
                        Text(auth.errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                          ),
                          onPressed: auth.isLoading ? null : () async {
                            if (_formKey.currentState!.validate()) {
                              final error = await auth.signUpAgent(
                                email: _emailController.text.trim(),
                                password: _passwordController.text.trim(),
                                fullName: _nameController.text.trim(),
                                hospitalName: _hospitalController.text.trim(),
                                address: _addressController.text.trim(),
                              );

                              if (error == null && auth.isAuthenticated && mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MainContainer()),
                                );
                              }
                            }
                          },
                          child: auth.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("S'INSCRIRE", style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Déjà un compte ? Se connecter"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}