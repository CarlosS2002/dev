import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'menu_screen.dart';
import 'theme_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isRegistered = false;
  bool isLoggedIn = false;
  String? registeredEmail;
  String? registeredPassword;
  String? currentUserEmail; // Para pasar al MenuScreen

  // Usuarios de prueba pre-cargados
  final Map<String, String> testUsers = {
    'carlos@test.com': '123456',  // Usuario hombre
    'maria@test.com': '123456',    // Usuario mujer
  };

  void register() async {
    final result = await Navigator.pushNamed(context, '/register');
    if (result != null && result is Map<String, String>) {
      setState(() {
        isRegistered = true;
        registeredEmail = result['email'];
        registeredPassword = result['password'];
      });
    }
  }

  void login() {
    final enteredEmail = emailController.text;
    final enteredPassword = passwordController.text;

    // Verificar usuarios de prueba primero
    if (testUsers.containsKey(enteredEmail) && testUsers[enteredEmail] == enteredPassword) {
      setState(() {
        isLoggedIn = true;
        currentUserEmail = enteredEmail;
      });
      return;
    }

    // Verificar usuario registrado
    if (isRegistered) {
      if (enteredEmail == registeredEmail && enteredPassword == registeredPassword) {
        setState(() {
          isLoggedIn = true;
          currentUserEmail = enteredEmail;
        });
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error de inicio de sesión'),
              content: Text('Correo o contraseña incorrectos.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cerrar'),
                ),
              ],
            );
          },
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error de inicio de sesión'),
            content: Text('Correo o contraseña incorrectos.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cerrar'),
              ),
            ],
          );
        },
      );
    }
  }

  void logout() {
    setState(() {
      isLoggedIn = false;
      currentUserEmail = null;
      emailController.clear();
      passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        if (isLoggedIn) {
          return MenuScreen(
            userEmail: currentUserEmail ?? '',
            onLogout: logout,
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text('Inicio de Sesión o Registro'),
            ),
            body: SingleChildScrollView(
              child: Container(
                height: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                  // Logo usando Image.asset
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
                  controller: emailController,
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
                  controller: passwordController,
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
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Iniciar Sesión',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              TextButton(
                onPressed: register,
                child: Text(
                  '¿No tienes una cuenta? Regístrate aquí.',
                  style: TextStyle(color: Colors.blue.shade600),
                ),
              ),
            ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
