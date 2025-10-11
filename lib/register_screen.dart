import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController registerEmailController = TextEditingController();
    TextEditingController registerPasswordController = TextEditingController();

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Registro'),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                // Logo usando Image.asset (igual que en login)
                Container(
                  margin: EdgeInsets.only(bottom: 40),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.asset(
                      'assets/images/Icon.jpg',
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.shade600,
                                Colors.green.shade400,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Groww',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            
            Container(
              margin: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: TextField(
                controller: registerEmailController,
                style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  labelStyle: TextStyle(color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                  ),
                ),
              ),
            ),
            
            Container(
              margin: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: TextField(
                controller: registerPasswordController,
                style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: TextStyle(color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                  ),
                ),
                obscureText: true,
              ),
            ),
            
            Container(
              margin: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final registerEmail = registerEmailController.text;
                  final registerPassword = registerPasswordController.text;
                  final result = {'email': registerEmail, 'password': registerPassword};
                  Navigator.pop(context, result);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Registrarse',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
                ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
