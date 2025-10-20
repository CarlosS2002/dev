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
                    fillColor: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: Text(
                    'Selecciona un grupo',
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54
                    ),
                  ),
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                  dropdownColor: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.white,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(
                        'Mis actividades individuales',
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    ...grupos.map((grupo) {
                      return DropdownMenuItem(
                        value: grupo.id,
                        child: Text(
                          grupo.nombre,
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Si no hay grupo seleccionado, mostrar actividades personales generadas por IA
    final actividades = grupoSeleccionado == null
        ? agendaProvider.getActividadesPersonales(widget.userEmail)
        : agendaProvider
            .getActividadesGrupo(grupoSeleccionado!)
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
            Icon(
              grupoSeleccionado == null ? Icons.auto_awesome : Icons.event_busy, 
              size: 80, 
              color: grupoSeleccionado == null ? Colors.deepPurple.shade300 : (themeProvider.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400)
            ),
            SizedBox(height: 16),
            Text(
              grupoSeleccionado == null 
                  ? 'No tienes actividades personales' 
                  : 'No hay actividades para esta fecha',
              style: TextStyle(
                fontSize: 18, 
                color: themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600
              ),
            ),
            if (grupoSeleccionado == null) ...[
              SizedBox(height: 12),
              Text(
                'Genera rutinas personalizadas con IA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.deepPurple.shade300,
                ),
              ),
            ],
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
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: Checkbox(
                      value: completada,
                      activeColor: Colors.green,
                      onChanged: (value) {
                        // Limpiar SnackBars previos para evitar spam
                        ScaffoldMessenger.of(context).clearSnackBars();
                        
                        if (value == true) {
                          final resultado = agendaProvider.completarActividad(actividad.id, widget.userEmail);
                          if (resultado) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('¡Actividad completada! +${actividad.puntosBase} puntos'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('No puedes completar esta actividad. Tu rol cambió desde que te uniste al grupo.'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        } else {
                          // Desmarcar actividad
                          agendaProvider.descompletarActividad(actividad.id, widget.userEmail);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Actividad desmarcada'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          actividad.nombre,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: completada ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (actividad.creadoPor == 'Gemini AI') ...[
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.deepPurple, Colors.purple.shade300],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'IA',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
                // Mostrar estado de todos los miembros (para entrenadores y atletas)
                if (grupoSeleccionado != null && grupoSeleccionado!.isNotEmpty)
                  Builder(
                    builder: (context) {
                      final grupos = agendaProvider.getGruposUsuario(widget.userEmail);
                      final grupo = grupos.firstWhere(
                        (g) => g.id == grupoSeleccionado,
                        orElse: () => grupos.first,
                      );
                      
                      // Solo mostrar si hay más de 1 miembro
                      if (grupo.miembrosIds.length <= 1) {
                        return SizedBox.shrink();
                      }
                      
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.people, size: 16, color: Colors.blue),
                                SizedBox(width: 4),
                                Text(
                                  'Estado del equipo:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  '${actividad.completadoPor.length}/${grupo.miembrosIds.length} completaron',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: grupo.miembrosIds.map((email) {
                                final completado = actividad.completadoPor.contains(email);
                                return Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: completado 
                                        ? Colors.green.shade100 
                                        : (themeProvider.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: completado ? Colors.green : Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        completado ? Icons.check_circle : Icons.radio_button_unchecked,
                                        size: 16,
                                        color: completado ? Colors.green.shade700 : Colors.grey.shade500,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        email.split('@')[0],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: completado ? FontWeight.bold : FontWeight.normal,
                                          color: completado 
                                              ? Colors.green.shade900 
                                              : (themeProvider.isDarkMode ? Colors.white70 : Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget? _buildBotonAccion(BuildContext context, AgendaProvider agendaProvider, RolUsuario rol) {
    if (rol == RolUsuario.entrenador && grupoSeleccionado != null) {
      // Botón para entrenador: crear actividad manual
      return FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoCrearActividad(context, agendaProvider),
        icon: Icon(Icons.add),
        label: Text('Crear Actividad'),
      );
    } else if (grupoSeleccionado == null) {
      // Botón para generar actividades con IA cuando no hay grupo seleccionado
      return FloatingActionButton.extended(
        onPressed: agendaProvider.generandoActividades 
            ? null 
            : () => _generarActividadesConIA(context, agendaProvider),
        icon: agendaProvider.generandoActividades
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Icon(Icons.auto_awesome),
        label: Text(agendaProvider.generandoActividades ? 'Generando...' : 'Generar con IA'),
        backgroundColor: Colors.deepPurple,
      );
    }
    return null;
  }

  // Genera actividades personalizadas con Gemini AI
  Future<void> _generarActividadesConIA(BuildContext context, AgendaProvider agendaProvider) async {
    try {
      final actividades = await agendaProvider.generarActividadesConIA(
        usuarioEmail: widget.userEmail,
      );

      if (actividades.isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '¡${actividades.length} actividades generadas con IA!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.deepPurple,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  grupoSeleccionado = null; // Asegurar que se vean las actividades personales
                });
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar actividades: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
