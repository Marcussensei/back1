import 'package:flutter/material.dart';

class ClientLoginPage extends StatefulWidget {
  const ClientLoginPage({super.key});

  @override
  State<ClientLoginPage> createState() => _ClientLoginPageState();
}

class _ClientLoginPageState extends State<ClientLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with logo
            _buildHeader(context),
            // Login form
            _buildLoginForm(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.shopping_bag,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ESSIVIVI',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Votre plateforme de livraison',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Bienvenue',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Connectez-vous à votre compte',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          // Email field
          _buildTextField(
            label: 'Email',
            controller: _emailController,
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            hint: 'example@email.com',
          ),
          const SizedBox(height: 16),
          // Password field
          _buildPasswordField(),
          const SizedBox(height: 12),
          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPasswordDialog(context),
              child: Text(
                'Mot de passe oublié?',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Login button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _handleLogin(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Se connecter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[300])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Ou', style: TextStyle(color: Colors.grey[600])),
              ),
              Expanded(child: Divider(color: Colors.grey[300])),
            ],
          ),
          const SizedBox(height: 16),
          // Social login buttons
          Row(
            children: [
              Expanded(
                child: _buildSocialButton(
                  icon: Icons.g_mobiledata,
                  label: 'Google',
                  onTap: () => _showSnackBar('Connexion Google'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialButton(
                  icon: Icons.phone_android,
                  label: 'Apple',
                  onTap: () => _showSnackBar('Connexion Apple'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Sign up link
          Center(
            child: RichText(
              text: TextSpan(
                text: 'Pas encore de compte? ',
                style: Theme.of(context).textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: 'S\'inscrire',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String hint = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mot de passe',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: Icon(Icons.lock, color: Colors.grey[600]),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() => _isPasswordVisible = !_isPasswordVisible);
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  void _handleLogin(BuildContext context) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs');
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      _showSnackBar('Connexion réussie!');
      // Navigate to home page
      // Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mot de passe oublié'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Entrez votre email pour réinitialiser votre mot de passe',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'example@email.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Email envoyé avec succès');
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
