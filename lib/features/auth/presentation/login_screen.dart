import 'package:flutter/material.dart';
import 'package:smart_isp/features/collector/presentation/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  //Admin
  final String Email = "admin";
  final String Password = "123456";

  void _login() {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email == Email && password == Password) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CollectorHomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "❌ Invalid credentials!",
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
          backgroundColor: Colors.white,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/login.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              const Text(
                "Welcome!",
                style: TextStyle(
                  fontSize: 45,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 5),

              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text(
                  "Login to Continue",
                  style: TextStyle(
                      fontSize: 21,
                      fontFamily: 'Poppins',
                      color: Colors.white70,
                  ),
                ),
              ),

              const SizedBox(height: 50),

              Center(
                child: SizedBox(
                  height: 50,
                  width: 320,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _emailController,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Email",
                        isCollapsed: true,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Center(
                child: SizedBox(
                  height: 50,
                  width: 320,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: "Password",
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              const SizedBox(height: 30),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(320, 50),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              const Spacer(),
              const Center(
                child: Text(
                  "SMART TELECOM",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}