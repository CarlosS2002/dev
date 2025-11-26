import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'agenda_provider.dart';
import 'models.dart';
import 'package:intl/intl.dart';
import 'theme_provider.dart';

class AgendaScreen extends StatefulWidget {
  final String userEmail;
  final VoidCallback? onOpenDrawer;

  const AgendaScreen({super.key, required this.userEmail, this.onOpenDrawer});

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
            leading: IconButton(
              icon: Icon(Icons.menu),
              onPressed: widget.onOpenDrawer,
            ),
            actions: [
              // Botón de notificaciones con badge
              Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () => _mostrarNotificaciones(context, agendaProvider),
                    tooltip: 'Notificaciones',
                  ),
                  if (agendaProvider.notificacionesNoLeidas > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${agendaProvider.notificacionesNoLeidas}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              // Botón de refrescar
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () async {
                  // Mostrar indicador de carga
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text('Actualizando...'),
                        ],
                      ),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  
                  // Recargar datos
                  await agendaProvider.recargarDatos(widget.userEmail);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Datos actualizados'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                tooltip: 'Actualizar',
              ),
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
            Icon(
              Icons.event_busy, 
              size: 80, 
              color: themeProvider.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400
            ),
            SizedBox(height: 16),
            Text(
              'No hay actividades para esta fecha',
              style: TextStyle(
                fontSize: 18, 
                color: themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600
              ),
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
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fila superior: Checkbox + Título + Acciones
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Checkbox
                          Checkbox(
                            value: completada,
                            activeColor: Colors.green,
                            onChanged: (value) {
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
                          // Título y descripción (expandido)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  actividad.nombre,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    decoration: completada ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                if (actividad.descripcion.isNotEmpty) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    actividad.descripcion,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Iconos de acción para entrenador
                          if (rol == RolUsuario.entrenador && grupoSeleccionado != null) ...[
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: () => _mostrarDialogoEditarActividad(
                                context, 
                                agendaProvider, 
                                actividad
                              ),
                              tooltip: 'Editar actividad',
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: () => _confirmarEliminarActividad(
                                context, 
                                agendaProvider, 
                                actividad
                              ),
                              tooltip: 'Eliminar actividad',
                            ),
                          ] else if (completada) ...[
                            Icon(Icons.check_circle, color: Colors.green, size: 24),
                          ],
                        ],
                      ),
                      // Fila inferior: Puntos y completadas
                      Padding(
                        padding: EdgeInsets.only(left: 40, top: 8),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
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
                              ],
                            ),
                            if (rol == RolUsuario.entrenador)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people, size: 16, color: Colors.blue),
                                  SizedBox(width: 4),
                                  Text(
                                    '${actividad.completadoPor.length} completadas',
                                    style: TextStyle(color: Colors.blue.shade700),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Mostrar estado de todos los miembros (SOLO para entrenadores)
                if (grupoSeleccionado != null && grupoSeleccionado!.isNotEmpty && rol == RolUsuario.entrenador)
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
                                        agendaProvider.getNombreUsuarioSync(email),
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
            onPressed: () async {
              if (nombreController.text.isNotEmpty &&
                  puntosController.text.isNotEmpty) {
                final puntos = int.tryParse(puntosController.text) ?? 0;
                if (puntos > 0) {
                  await agendaProvider.agregarActividad(
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

  // Diálogo para editar una actividad existente
  void _mostrarDialogoEditarActividad(BuildContext context, AgendaProvider agendaProvider, Actividad actividad) {
    final nombreController = TextEditingController(text: actividad.nombre);
    final descripcionController = TextEditingController(text: actividad.descripcion);
    final puntosController = TextEditingController(text: actividad.puntosBase.toString());
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Actividad'),
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
                  agendaProvider.editarActividad(
                    actividad.id,
                    nombreController.text,
                    descripcionController.text,
                    puntos,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Actividad actualizada exitosamente'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              }
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Confirmar eliminación de actividad
  void _confirmarEliminarActividad(BuildContext context, AgendaProvider agendaProvider, Actividad actividad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Confirmar eliminación'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas eliminar esta actividad?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    actividad.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red.shade900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${actividad.puntosBase} puntos',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  if (actividad.completadoPor.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      '⚠️ ${actividad.completadoPor.length} usuario(s) ya completaron esta actividad',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              agendaProvider.eliminarActividad(actividad.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Actividad eliminada'),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Mostrar diálogo de notificaciones
  void _mostrarNotificaciones(BuildContext context, AgendaProvider agendaProvider) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    // Cargar notificaciones
    final notificaciones = await agendaProvider.obtenerNotificaciones(widget.userEmail);
    
    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Título
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.notifications, color: Colors.blue, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Notificaciones',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  if (notificaciones.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        // Marcar todas como leídas
                        for (var notif in notificaciones) {
                          if (notif['leida'] == false) {
                            await agendaProvider.marcarNotificacionLeida(
                              widget.userEmail, 
                              notif['id']
                            );
                          }
                        }
                        Navigator.pop(context);
                      },
                      child: Text('Marcar leídas'),
                    ),
                ],
              ),
            ),
            Divider(height: 1),
            // Lista de notificaciones
            Expanded(
              child: notificaciones.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No tienes notificaciones',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: notificaciones.length,
                      itemBuilder: (context, index) {
                        final notif = notificaciones[index];
                        final leida = notif['leida'] == true;
                        
                        return Container(
                          color: leida 
                              ? null 
                              : (themeProvider.isDarkMode 
                                  ? Colors.blue.shade900.withOpacity(0.3) 
                                  : Colors.blue.shade50),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: leida ? Colors.grey : Colors.blue,
                              child: Icon(
                                Icons.assignment,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              notif['titulo'] ?? 'Nueva actividad',
                              style: TextStyle(
                                fontWeight: leida ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notif['mensaje'] ?? ''),
                                SizedBox(height: 4),
                                Text(
                                  notif['grupoNombre'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: !leida
                                ? Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                            onTap: () async {
                              // Marcar como leída
                              if (!leida) {
                                await agendaProvider.marcarNotificacionLeida(
                                  widget.userEmail, 
                                  notif['id']
                                );
                              }
                              
                              // Seleccionar el grupo de la notificación
                              if (notif['grupoId'] != null) {
                                setState(() {
                                  grupoSeleccionado = notif['grupoId'];
                                });
                              }
                              
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
