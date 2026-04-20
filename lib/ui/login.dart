import 'package:flutter/material.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          height: 200,
          color: const Color.fromARGB(255, 14, 5, 57),
          child: const Center(
            child: Text(
              'Quiero salud',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Handle login logic here
                },
                child: const Text('Iniciar sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 5, 118, 97),
                  foregroundColor: const Color.fromARGB(255, 252, 252, 252),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
