import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'agenda_provider.dart';
import 'models.dart';
import 'package:intl/intl.dart';
import 'theme_provider.dart';

class AgendaScreen extends StatefulWidget {
  final String userEmail;

  const AgendaScreen({super.key, required this.userEmail});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  String? grupoSeleccionado;
  DateTime fechaSeleccionada = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final agendaProvider = Provider.of<AgendaProvider>(context);
        final rol = agendaProvider.getRol(widget.userEmail);
        final grupos = agendaProvider.getGruposUsuario(widget.userEmail);

        return Scaffold(
          appBar: AppBar(
            title: Text('Agenda de Actividades'),
            actions: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '${rol.icono} ${rol.nombre}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Selector de grupo
              Container(
                padding: EdgeInsets.all(16),
                color: themeProvider.currentTheme.primaryColor.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grupo:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                  value: grupoSeleccionado,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: Text('Selecciona un grupo'),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Mis actividades individuales'),
                    ),
                    ...grupos.map((grupo) {
                      return DropdownMenuItem(
                        value: grupo.id,
                        child: Text(grupo.nombre),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      grupoSeleccionado = value;
                    });
                  },
                ),
              ],
            ),
          ),

          // Selector de fecha
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fechaSeleccionada,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          fechaSeleccionada = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: themeProvider.currentTheme.primaryColor),
                          SizedBox(width: 12),
                          Text(
                            DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(fechaSeleccionada),
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de actividades
          Expanded(
            child: _buildListaActividades(agendaProvider, rol),
          ),
        ],
      ),
      floatingActionButton: _buildBotonAccion(context, agendaProvider, rol),
        );
      },
    );
  }

  Widget _buildListaActividades(AgendaProvider agendaProvider, RolUsuario rol) {
    final actividades = agendaProvider
        .getActividadesGrupo(grupoSeleccionado ?? '')
        .where((act) =>
            act.fecha.year == fechaSeleccionada.year &&
            act.fecha.month == fechaSeleccionada.month &&
            act.fecha.day == fechaSeleccionada.day)
        .toList();

    if (actividades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'No hay actividades para esta fecha',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: actividades.length,
      itemBuilder: (context, index) {
        final actividad = actividades[index];
        final completada = actividad.completadoPor.contains(widget.userEmail);

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: completada ? 1 : 3,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: completada
                  ? Border.all(color: Colors.green, width: 2)
                  : null,
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: rol == RolUsuario.atleta
                  ? Checkbox(
                      value: completada,
                      activeColor: Colors.green,
                      onChanged: (value) {
                        if (value == true) {
                          agendaProvider.completarActividad(actividad.id, widget.userEmail);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('¡Actividad completada! +${actividad.puntosBase} puntos'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    )
                  : Icon(
                      completada ? Icons.check_circle : Icons.circle_outlined,
                      color: completada ? Colors.green : Colors.grey,
                      size: 32,
                    ),
              title: Text(
                actividad.nombre,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decoration: completada ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (actividad.descripcion.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(actividad.descripcion),
                  ],
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.stars, size: 16, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        '${actividad.puntosBase} puntos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      SizedBox(width: 16),
                      if (rol == RolUsuario.entrenador) ...[
                        Icon(Icons.people, size: 16, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          '${actividad.completadoPor.length} completadas',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: completada
                  ? Icon(Icons.check_circle, color: Colors.green, size: 32)
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget? _buildBotonAccion(BuildContext context, AgendaProvider agendaProvider, RolUsuario rol) {
    if (rol == RolUsuario.entrenador && grupoSeleccionado != null) {
      return FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoCrearActividad(context, agendaProvider),
        icon: Icon(Icons.add),
        label: Text('Crear Actividad'),
      );
    }
    return null;
  }

  void _mostrarDialogoCrearActividad(BuildContext context, AgendaProvider agendaProvider) {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final puntosController = TextEditingController();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Crear Nueva Actividad'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Nombre de la actividad',
                  labelStyle: TextStyle(color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: descripcionController,
                style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  labelStyle: TextStyle(color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 12),
              TextField(
                controller: puntosController,
                style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Puntos base',
                  labelStyle: TextStyle(color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                  ),
                  suffixIcon: Icon(Icons.stars, color: Colors.amber),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nombreController.text.isNotEmpty &&
                  puntosController.text.isNotEmpty) {
                final puntos = int.tryParse(puntosController.text) ?? 0;
                if (puntos > 0) {
                  agendaProvider.agregarActividad(
                    Actividad(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      nombre: nombreController.text,
                      grupoId: grupoSeleccionado ?? '',
                      fecha: fechaSeleccionada,
                      descripcion: descripcionController.text,
                      puntosBase: puntos,
                      completadoPor: [],
                      creadoPor: widget.userEmail,
                    ),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Actividad creada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: Text('Crear'),
          ),
        ],
      ),
    );
  }
}
