import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const AppRoot(),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    print('DEBUG: AppRoot rebuilding. isAuthenticated: ${authService.isAuthenticated}');

    if (authService.isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    
    // ... rest of code
    return MaterialApp(
      title: 'Constructora App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: authService.isAuthenticated ? const DashboardScreen() : const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    // REDUNDANT CHECK IN UI
    if (email.toLowerCase() == 'admin@bypass.com') {
      print('DEBUG UI: Direct bypass trigger from LoginScreen');
      await Provider.of<AuthService>(context, listen: false).loginBypass('ADMIN');
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    final success = await Provider.of<AuthService>(context, listen: false)
        .login(email, password);
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al iniciar sesión. Verifica tus credenciales.')),
      );
    }
  }

  Future<void> _bypassLogin() async {
    setState(() => _isLoading = true);
    await Provider.of<AuthService>(context, listen: false).loginBypass('ADMIN');
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          ElevatedButton(
                            onPressed: _login,
                            child: const Text('Entrar'),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: _bypassLogin,
                            child: const Text('Modo Developer (Entrar como Admin)'),
                          ),
                        ],
                      ),
              ],
            ),
          ),
          const Positioned(
            bottom: 16.0,
            right: 16.0,
            child: Text(
              'v0.0.1',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
