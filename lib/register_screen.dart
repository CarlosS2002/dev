import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'models.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController registerEmailController = TextEditingController();
  final TextEditingController registerPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  DateTime? fechaNacimiento;
  String sexoSeleccionado = 'Masculino';
  RolUsuario rolSeleccionado = RolUsuario.atleta;
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  final _formKey = GlobalKey<FormState>();

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fechaNacimiento ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Selecciona tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    
    if (picked != null) {
      setState(() {
        fechaNacimiento = picked;
      });
    }
  }

  void _registrar() {
    if (_formKey.currentState!.validate()) {
      // Validaciones adicionales
      if (fechaNacimiento == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor selecciona tu fecha de nacimiento'),
            backgroundColor: Colors.red.shade600,
          ),
        );
        return;
      }

      // Si todo está bien, retornar los datos
      final result = {
        'nombre': nombreController.text,
        'email': registerEmailController.text,
        'password': registerPasswordController.text,
        'fechaNacimiento': fechaNacimiento,
        'sexo': sexoSeleccionado,
        'rol': rolSeleccionado,
      };
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Registro'),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(bottom: 30),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset(
                          'assets/images/Icon.jpg',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
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
                              child: Icon(Icons.person_add, size: 60, color: Colors.white),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Nombre Completo
                  Text(
                    'Nombre Completo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: nombreController,
                    style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Ingresa tu nombre completo',
                      hintStyle: TextStyle(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                      ),
                      prefixIcon: Icon(Icons.person, color: Colors.blue.shade600),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu nombre';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 20),

                  // Correo Electrónico
                  Text(
                    'Correo Electrónico',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: registerEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'ejemplo@correo.com',
                      hintStyle: TextStyle(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                      ),
                      prefixIcon: Icon(Icons.email, color: Colors.blue.shade600),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu correo';
                      }
                      if (!value.contains('@')) {
                        return 'Ingresa un correo válido';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 20),

                  // Contraseña
                  Text(
                    'Contraseña',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: registerPasswordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Mínimo 8 caracteres',
                      hintStyle: TextStyle(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                      ),
                      prefixIcon: Icon(Icons.lock, color: Colors.blue.shade600),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa una contraseña';
                      }
                      if (value.length < 8) {
                        return 'La contraseña debe tener mínimo 8 caracteres';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 20),

                  // Confirmar Contraseña
                  Text(
                    'Confirmar Contraseña',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Repite tu contraseña',
                      hintStyle: TextStyle(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                      ),
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.blue.shade600),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor confirma tu contraseña';
                      }
                      if (value != registerPasswordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 20),

                  // Fecha de Nacimiento
                  Text(
                    'Fecha de Nacimiento',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: _seleccionarFecha,
                    child: Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: themeProvider.isDarkMode ? Colors.white38 : Colors.grey.shade400
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cake, color: Colors.blue.shade600),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              fechaNacimiento != null
                                  ? _formatearFecha(fechaNacimiento!)
                                  : 'Selecciona tu fecha de nacimiento',
                              style: TextStyle(
                                fontSize: 16,
                                color: fechaNacimiento != null
                                    ? (themeProvider.isDarkMode ? Colors.white : Colors.black87)
                                    : (themeProvider.isDarkMode ? Colors.white54 : Colors.grey.shade600),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.calendar_today,
                            color: themeProvider.isDarkMode ? Colors.white54 : Colors.grey.shade600,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Sexo
                  Text(
                    'Sexo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: themeProvider.isDarkMode ? Colors.white38 : Colors.grey.shade400
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: Text('Masculino'),
                          value: 'Masculino',
                          groupValue: sexoSeleccionado,
                          activeColor: Colors.blue.shade600,
                          secondary: Icon(Icons.male, color: Colors.blue.shade600),
                          onChanged: (value) {
                            setState(() {
                              sexoSeleccionado = value!;
                            });
                          },
                        ),
                        Divider(height: 1),
                        RadioListTile<String>(
                          title: Text('Femenino'),
                          value: 'Femenino',
                          groupValue: sexoSeleccionado,
                          activeColor: Colors.pink.shade400,
                          secondary: Icon(Icons.female, color: Colors.pink.shade400),
                          onChanged: (value) {
                            setState(() {
                              sexoSeleccionado = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Rol
                  Text(
                    'Rol en la Aplicación',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: themeProvider.isDarkMode ? Colors.white38 : Colors.grey.shade400
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<RolUsuario>(
                          title: Text('Atleta / Usuario'),
                          subtitle: Text('Puedo unirme a grupos y completar actividades'),
                          value: RolUsuario.atleta,
                          groupValue: rolSeleccionado,
                          activeColor: Colors.blue.shade600,
                          secondary: Text('🏃', style: TextStyle(fontSize: 30)),
                          onChanged: (value) {
                            setState(() {
                              rolSeleccionado = value!;
                            });
                          },
                        ),
                        Divider(height: 1),
                        RadioListTile<RolUsuario>(
                          title: Text('Entrenador'),
                          subtitle: Text('Puedo crear grupos y asignar actividades'),
                          value: RolUsuario.entrenador,
                          groupValue: rolSeleccionado,
                          activeColor: Colors.orange.shade600,
                          secondary: Text('👨‍🏫', style: TextStyle(fontSize: 30)),
                          onChanged: (value) {
                            setState(() {
                              rolSeleccionado = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 40),

                  // Botón Registrarse
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _registrar,
                      icon: Icon(Icons.person_add),
                      label: Text(
                        'Registrarse',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    registerEmailController.dispose();
    registerPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
