import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home_screen.dart';

const Color kGold = Color(0xFFC9A84C);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _senhaController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _senhaVisivel = false;
  bool _carregando = false;
  String? _erro;

  // Senha padrão da empresa — troque aqui
  static const String _senhaCorreta = 'trynt2025';

  Future<void> _login() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (_senhaController.text == _senhaCorreta) {
      await _storage.write(key: 'autenticado', value: 'true');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      setState(() {
        _erro = 'Senha incorreta.';
        _carregando = false;
      });
    }
  }

  @override
  void dispose() {
    _senhaController.dispose();
    super.dispose();
  }

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
              Image.asset('assets/logo.png', width: 90),
              const SizedBox(height: 20),
              const Text(
                'TRYNT GROUP',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: kGold,
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
              Container(width: 40, height: 1, color: kGold),
              const SizedBox(height: 32),
              TextField(
                controller: _senhaController,
                obscureText: !_senhaVisivel,
                onSubmitted: (_) => _login(),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Senha de acesso',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFBBBBBB),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: kGold),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  errorText: _erro,
                  errorStyle: const TextStyle(fontSize: 10, letterSpacing: 0.3),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _senhaVisivel = !_senhaVisivel),
                    child: Icon(
                      _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: const Color(0xFFAAAAAA),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGold,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                    onPressed: _carregando ? null : _login,
                    child: _carregando
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('ENTRAR'),
                  ),
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