import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'agenda_provider.dart';
import 'theme_provider.dart';

class PerfilScreen extends StatefulWidget {
  final String userEmail;

  const PerfilScreen({super.key, required this.userEmail});

  @override
  _PerfilScreenState createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final TextEditingController nombreController = TextEditingController();
  DateTime? fechaNacimiento;
  String sexoSeleccionado = 'Masculino';
  RolUsuario rolSeleccionado = RolUsuario.atleta;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    final agendaProvider = Provider.of<AgendaProvider>(context, listen: false);
    rolSeleccionado = agendaProvider.getRol(widget.userEmail);
    
    // Cargar datos guardados si existen
    if (widget.userEmail == 'carlos@test.com') {
      nombreController.text = 'Carlos Martínez';
      fechaNacimiento = DateTime(1999, 5, 15);
      sexoSeleccionado = 'Masculino';
    } else if (widget.userEmail == 'maria@test.com') {
      nombreController.text = 'María González';
      fechaNacimiento = DateTime(1996, 8, 20);
      sexoSeleccionado = 'Femenino';
    }
  }

  int _calcularEdad() {
    if (fechaNacimiento == null) return 0;
    
    final hoy = DateTime.now();
    int edad = hoy.year - fechaNacimiento!.year;
    
    if (hoy.month < fechaNacimiento!.month || 
        (hoy.month == fechaNacimiento!.month && hoy.day < fechaNacimiento!.day)) {
      edad--;
    }
    
    return edad;
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

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }

  void _guardarPerfil() {
    if (nombreController.text.isEmpty || fechaNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    // Guardar el rol
    final agendaProvider = Provider.of<AgendaProvider>(context, listen: false);
    agendaProvider.setRol(widget.userEmail, rolSeleccionado);

    // Aquí guardarías los datos (SharedPreferences, base de datos, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Perfil guardado exitosamente'),
        backgroundColor: Colors.green.shade600,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Mi Perfil'),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Center(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 30),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue.shade600,
                      child: Icon(
                    sexoSeleccionado == 'Masculino' 
                        ? Icons.person 
                        : Icons.person_outline,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Email (solo lectura)
            Text(
              'Correo Electrónico',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: Colors.grey.shade600),
                  SizedBox(width: 10),
                  Text(
                    widget.userEmail,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 25),

            // Nombre
            Text(
              'Nombre Completo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: nombreController,
              style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Ingresa tu nombre',
                hintStyle: TextStyle(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                ),
                prefixIcon: Icon(Icons.person, color: Colors.blue.shade600),
              ),
            ),

            SizedBox(height: 25),

            // Fecha de Nacimiento
            Text(
              'Fecha de Nacimiento',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            InkWell(
              onTap: _seleccionarFecha,
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
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
                              ? Colors.black87
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    if (fechaNacimiento != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_calcularEdad()} años',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 25),

            // Sexo
            Text(
              'Sexo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
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

            SizedBox(height: 25),

            // Rol
            Text(
              'Rol en la Aplicación',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
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
                    secondary: Text(
                      '🏃',
                      style: TextStyle(fontSize: 30),
                    ),
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
                    secondary: Text(
                      '👨‍🏫',
                      style: TextStyle(fontSize: 30),
                    ),
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

            // Botón Guardar
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _guardarPerfil,
                icon: Icon(Icons.save),
                label: Text(
                  'Guardar Perfil',
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
          ],
        ),
      ),
        );
      },
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    super.dispose();
  }
}
