import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map_rounded, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Radar Jentik',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // DUMMY: Bypass login langsung ke Kader
                  Navigator.pushReplacementNamed(context, '/cadre');
                },
                child: const Text('Login Kader'),
              ),
              TextButton(
                onPressed: () {
                  // DUMMY: Bypass login langsung ke Petugas
                  Navigator.pushReplacementNamed(context, '/officer');
                },
                child: const Text('Login Petugas Puskesmas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
