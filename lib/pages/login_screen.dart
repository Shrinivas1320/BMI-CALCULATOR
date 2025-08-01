import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final Function(String) onLogin;

  const LoginScreen({Key? key, required this.onLogin}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool showLogin = true;
  bool _showLoginPassword = false;
  bool _showSignupPassword = false;

  // Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupUsernameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) return 'Enter email';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) return 'Invalid email format';
    return null;
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Enter password';
    final passRegex = RegExp(r'^(?=(?:[^A-Za-z]*[A-Za-z]){4})(?=(?:[^0-9]*[0-9]){2})(?=.*[!@#\$&*~]).{7,}$');
    if (!passRegex.hasMatch(value)) {
      return 'Password: 4 letters, 1 special, 2 digits';
    }
    return null;
  }

  String? usernameValidator(String? value) {
    if (value == null || value.isEmpty) return 'Enter username';
    return null;
  }

  Future<void> handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = prefs.getString('email');
      final storedPassword = prefs.getString('password');
      final storedUsername = prefs.getString('username');
      if (_loginEmailController.text == storedEmail &&
          _loginPasswordController.text == storedPassword) {
        widget.onLogin(storedUsername ?? _loginEmailController.text.split('@')[0]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password')),
        );
      }
    }
  }

  Future<void> handleSignup() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', _signupEmailController.text);
      await prefs.setString('password', _signupPasswordController.text);
      await prefs.setString('username', _signupUsernameController.text);
      widget.onLogin(_signupUsernameController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://tse1.mm.bing.net/th?id=OIP.lduLUy65c5b9jutf-5_AeQHaHa&pid=Api&P=0&h=180',
            fit: BoxFit.cover,
          ),
          Center(
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black26)],
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        showLogin ? 'Login' : 'Sign Up',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      if (showLogin) ...[
                        TextFormField(
                          controller: _loginEmailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: emailValidator,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _loginPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(_showLoginPassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _showLoginPassword = !_showLoginPassword;
                                });
                              },
                            ),
                          ),
                          obscureText: !_showLoginPassword,
                          validator: passwordValidator,
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _signupUsernameController,
                          decoration: const InputDecoration(labelText: 'Username'),
                          validator: usernameValidator,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _signupEmailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: emailValidator,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _signupPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(_showSignupPassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _showSignupPassword = !_showSignupPassword;
                                });
                              },
                            ),
                          ),
                          obscureText: !_showSignupPassword,
                          validator: passwordValidator,
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: showLogin ? handleLogin : handleSignup,
                        child: Text(showLogin ? 'Login' : 'Sign Up'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            showLogin = !showLogin;
                          });
                        },
                        child: Text(showLogin
                            ? "Don't have an account? Sign Up"
                            : "Already have an account? Login"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}