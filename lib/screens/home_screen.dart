import 'package:flutter/material.dart';
import 'scan_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Logo
              Image.asset(
                'assets/logo.png',
                width: 100,
              ),
              const SizedBox(height: 20),
              // Nome empresa
              const Text(
                'TRYNT GROUP',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: Color(0xFFC9A84C),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Recebimento de Estoque',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2,
                  color: Color(0xFF888888),
                ),
              ),
              const Spacer(flex: 2),
              // Divisor dourado
              Container(
                width: 40,
                height: 1,
                color: const Color(0xFFC9A84C),
              ),
              const SizedBox(height: 32),
              const Text(
                'Escaneie as caixas para registrar\no recebimento de mercadorias.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                  height: 1.8,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                    );
                  },
                  child: const Text('INICIAR RECEBIMENTO'),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}