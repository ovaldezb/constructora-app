import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
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
    
    return MaterialApp(
      title: 'LuViRex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFFFFD600),
          tertiary: const Color(0xFFFF4081),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        useMaterial3: true,
      ),
      home: authService.isAuthenticated ? const DashboardScreen() : const LoginScreen(),
    );
  }
}

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIconCol(Icons.emoji_objects, const Color(0xFFFFD600), 'Lu'),
          const SizedBox(width: 16),
          _buildIconCol(Icons.emoji_events, const Color(0xFFFF4081), 'Vi'),
          const SizedBox(width: 16),
          _buildIconCol(Icons.pets, const Color(0xFF2E7D32), 'Rex'),
        ],
      ),
    );
  }

  Widget _buildIconCol(IconData icon, Color color, String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 48),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
      ],
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
  final _newPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isNewPasswordRequired = false;

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

    try {
      final success = await Provider.of<AuthService>(context, listen: false)
          .login(email, password);
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al iniciar sesión. Verifica tus credenciales.')),
        );
      }
    } on CognitoUserNewPasswordRequiredException catch (_) {
      if (!mounted) return;
      setState(() {
         _isLoading = false;
         _isNewPasswordRequired = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: $e')),
      );
    }
  }

  Future<void> _submitNewPassword() async {
    final newPassword = _newPasswordController.text.trim();
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final success = await Provider.of<AuthService>(context, listen: false)
        .confirmNewPassword(newPassword);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada exitosamente')),
      );
      // Navigation will be handled by the Wrapper listening to auth state
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar contraseña')),
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
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AnimatedLogo(),
                    const SizedBox(height: 32),
                    const Text(
                      '¡Bienvenido a LuViRex!',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(height: 32),
                    _isNewPasswordRequired
                        ? _buildNewPasswordForm()
                        : _buildLoginForm(),
                  ],
                ),
              ),
            ),
            const Positioned(
              bottom: 16.0,
              right: 16.0,
              child: Text(
                'v0.0.1 - LuViRex',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Contraseña (Temporal o Definitiva)',
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 32),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _login,
                    child: const Text('Entrar', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _bypassLogin,
                    child: const Text('Modo Developer (Entrar como Admin)', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildNewPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '¡Hola! Es tu primer ingreso.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Por seguridad, debes crear tu propia contraseña definitiva para continuar.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _newPasswordController,
          decoration: InputDecoration(
            labelText: 'Nueva Contraseña',
            prefixIcon: const Icon(Icons.lock_reset),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 32),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4081),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitNewPassword,
                child: const Text('Guardar y Entrar', style: TextStyle(fontSize: 18)),
              ),
      ],
    );
  }
}