import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'agenda_provider.dart';
import 'models.dart';
import 'package:intl/intl.dart';
import 'theme_provider.dart';
import 'ai_service.dart';
import 'firebase_service.dart';

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
                    Builder(
                      builder: (context) {
                        // Validar que grupoSeleccionado existe en la lista
                        final grupoValido = grupoSeleccionado == null ||
                            grupos.any((g) => g.id == grupoSeleccionado);
                        if (!grupoValido) {
                          // Si el grupo no existe, resetear a null
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              grupoSeleccionado = null;
                            });
                          });
                        }
                        return DropdownButtonFormField<String>(
                  value: grupoValido ? grupoSeleccionado : null,
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
                );
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
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 150),
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
                          // Iconos de acción para entrenador en grupos
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
                          // Iconos de acción para actividades personales (sin grupo)
                          ] else if (grupoSeleccionado == null && actividad.creadoPor == widget.userEmail) ...[
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: () => _mostrarDialogoEditarActividadPersonal(
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
                      
                      return InkWell(
                        onTap: () {
                          // Mostrar modal con el estado completo del equipo
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => Container(
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height * 0.6,
                              ),
                              decoration: BoxDecoration(
                                color: themeProvider.isDarkMode ? Colors.grey.shade900 : Colors.white,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Handle del modal
                                  Container(
                                    margin: EdgeInsets.only(top: 12),
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  // Título
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Icon(Icons.people, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text(
                                          'Estado del equipo',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Spacer(),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            '${actividad.completadoPor.length}/${grupo.miembrosIds.length}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(height: 1),
                                  // Lista de miembros con scroll
                                  Flexible(
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      itemCount: grupo.miembrosIds.length,
                                      itemBuilder: (context, index) {
                                        final email = grupo.miembrosIds[index];
                                        final completado = actividad.completadoPor.contains(email);
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: completado ? Colors.green : Colors.grey.shade400,
                                            child: Icon(
                                              completado ? Icons.check : Icons.person,
                                              color: Colors.white,
                                            ),
                                          ),
                                          title: Text(
                                            agendaProvider.getNombreUsuarioSync(email),
                                            style: TextStyle(
                                              fontWeight: completado ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                          trailing: completado
                                              ? Icon(Icons.check_circle, color: Colors.green)
                                              : Icon(Icons.radio_button_unchecked, color: Colors.grey),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.people, size: 16, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Estado del equipo',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '${actividad.completadoPor.length}/${grupo.miembrosIds.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              Icon(Icons.keyboard_arrow_up, size: 18, color: Colors.grey),
                            ],
                          ),
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
    // Actividades personales (sin grupo seleccionado) - disponible para cualquier rol
    if (grupoSeleccionado == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón de generar con IA
          FloatingActionButton.extended(
            heroTag: 'btn_ia',
            onPressed: () => _mostrarDialogoGenerarConIA(context, agendaProvider),
            icon: Icon(Icons.auto_awesome),
            label: Text('Generar con IA'),
            backgroundColor: Colors.purple,
          ),
          SizedBox(height: 12),
          // Botón de crear manualmente
          FloatingActionButton.extended(
            heroTag: 'btn_crear',
            onPressed: () => _mostrarDialogoCrearActividadPersonal(context, agendaProvider),
            icon: Icon(Icons.add),
            label: Text('Crear Actividad'),
          ),
        ],
      );
    }
    
    // Actividades de grupo - solo para entrenadores
    if (rol == RolUsuario.entrenador && grupoSeleccionado != null) {
      return FloatingActionButton.extended(
        heroTag: 'btn_crear_grupo',
        onPressed: () => _mostrarDialogoCrearActividad(context, agendaProvider),
        icon: Icon(Icons.add),
        label: Text('Crear Actividad'),
      );
    }
    return null;
  }

  // Diálogo para crear actividad personal (sin grupo)
  void _mostrarDialogoCrearActividadPersonal(BuildContext context, AgendaProvider agendaProvider) {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final puntosController = TextEditingController();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Crear Actividad Personal'),
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
              if (nombreController.text.isNotEmpty && puntosController.text.isNotEmpty) {
                final puntos = int.tryParse(puntosController.text) ?? 0;
                if (puntos > 0) {
                  await agendaProvider.agregarActividad(
                    Actividad(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      nombre: nombreController.text,
                      grupoId: '', // Actividad personal - sin grupo
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
                      content: Text('✅ Actividad personal creada'),
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

  // Lista para guardar las actividades generadas por IA (para poder eliminarlas)
  List<String> _actividadesGeneradasIA = [];

  void _mostrarDialogoGenerarConIA(BuildContext context, AgendaProvider agendaProvider) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final firebaseService = FirebaseService();
    final aiService = AIService();
    
    // Variables de estado
    String? tipoSeleccionado;
    bool isLoading = false;
    List<Map<String, dynamic>> actividadesGeneradas = [];
    String? errorMessage;
    
    // Cargar datos del usuario
    String sexo = 'Masculino';
    int edad = 25;
    
    try {
      final perfilData = await firebaseService.cargarPerfil(widget.userEmail);
      if (perfilData != null) {
        sexo = perfilData['sexo'] ?? 'Masculino';
        if (perfilData['fechaNacimiento'] != null) {
          DateTime? fechaNac;
          if (perfilData['fechaNacimiento'] is String) {
            fechaNac = DateTime.tryParse(perfilData['fechaNacimiento']);
          }
          if (fechaNac != null) {
            edad = DateTime.now().year - fechaNac.year;
            if (DateTime.now().month < fechaNac.month ||
                (DateTime.now().month == fechaNac.month && DateTime.now().day < fechaNac.day)) {
              edad--;
            }
          }
        }
      }
    } catch (e) {
      print('Error cargando perfil: $e');
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple),
                SizedBox(width: 8),
                Expanded(child: Text('Generar con IA')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info del usuario
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.purple),
                        SizedBox(width: 8),
                        Text('$sexo, $edad años'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Selector de tipo de actividad
                  Text(
                    '¿Qué tipo de actividad deseas hoy?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tipoSeleccionado,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: Text('Selecciona un tipo'),
                    items: AIService.tiposActividad.map((tipo) {
                      return DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo, style: TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        tipoSeleccionado = value;
                        actividadesGeneradas = [];
                        errorMessage = null;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Botón generar
                  if (tipoSeleccionado != null && actividadesGeneradas.isEmpty && !isLoading)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          setDialogState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          
                          try {
                            final actividades = await aiService.generarActividades(
                              sexo: sexo,
                              edad: edad,
                              tipoActividad: tipoSeleccionado!,
                              cantidad: 3,
                            );
                            setDialogState(() {
                              actividadesGeneradas = actividades;
                              isLoading = false;
                            });
                          } catch (e) {
                            setDialogState(() {
                              errorMessage = 'Error al generar: $e';
                              isLoading = false;
                            });
                          }
                        },
                        icon: Icon(Icons.auto_awesome),
                        label: Text('Generar Actividades'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  
                  // Loading
                  if (isLoading)
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Colors.purple),
                          SizedBox(height: 12),
                          Text('Generando actividades personalizadas...'),
                        ],
                      ),
                    ),
                  
                  // Error
                  if (errorMessage != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(child: Text(errorMessage!, style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),
                  
                  // Lista de actividades generadas
                  if (actividadesGeneradas.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      'Actividades generadas:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    ...actividadesGeneradas.asMap().entries.map((entry) {
                      final index = entry.key;
                      final actividad = entry.value;
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple,
                            child: Text('${index + 1}', style: TextStyle(color: Colors.white)),
                          ),
                          title: Text(
                            actividad['nombre'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(actividad['descripcion'], maxLines: 2, overflow: TextOverflow.ellipsis),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.stars, size: 16, color: Colors.amber),
                                  SizedBox(width: 4),
                                  Text('${actividad['puntos']} puntos',
                                      style: TextStyle(color: Colors.amber.shade700, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    }).toList(),
                    
                    SizedBox(height: 12),
                    
                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              // Regenerar
                              setDialogState(() {
                                isLoading = true;
                                actividadesGeneradas = [];
                                errorMessage = null;
                              });
                              
                              try {
                                final actividades = await aiService.generarActividades(
                                  sexo: sexo,
                                  edad: edad,
                                  tipoActividad: tipoSeleccionado!,
                                  cantidad: 3,
                                );
                                setDialogState(() {
                                  actividadesGeneradas = actividades;
                                  isLoading = false;
                                });
                              } catch (e) {
                                setDialogState(() {
                                  errorMessage = 'Error al generar: $e';
                                  isLoading = false;
                                });
                              }
                            },
                            icon: Icon(Icons.refresh),
                            label: Text('Generar'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Guardar todas las actividades
                              final nuevasIds = <String>[];
                              for (var act in actividadesGeneradas) {
                                final id = DateTime.now().millisecondsSinceEpoch.toString() + '_${actividadesGeneradas.indexOf(act)}';
                                nuevasIds.add(id);
                                await agendaProvider.agregarActividad(
                                  Actividad(
                                    id: id,
                                    nombre: act['nombre'],
                                    grupoId: grupoSeleccionado ?? '',
                                    fecha: fechaSeleccionada,
                                    descripcion: act['descripcion'],
                                    puntosBase: act['puntos'],
                                    completadoPor: [],
                                    creadoPor: widget.userEmail,
                                  ),
                                );
                              }
                              
                              // Guardar IDs para poder eliminarlas después
                              setState(() {
                                _actividadesGeneradasIA.addAll(nuevasIds);
                              });
                              
                              Navigator.pop(dialogContext);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ ${actividadesGeneradas.length} actividades creadas con IA'),
                                  backgroundColor: Colors.green,
                                  action: SnackBarAction(
                                    label: 'Deshacer',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      // Eliminar las actividades recién creadas
                                      for (var id in nuevasIds) {
                                        agendaProvider.eliminarActividad(id);
                                      }
                                      setState(() {
                                        _actividadesGeneradasIA.removeWhere((id) => nuevasIds.contains(id));
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Actividades eliminadas'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                            icon: Icon(Icons.check),
                            label: Text('Guardar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Cancelar'),
              ),
            ],
          );
        },
      ),
    );
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

  // Diálogo para editar una actividad personal
  void _mostrarDialogoEditarActividadPersonal(BuildContext context, AgendaProvider agendaProvider, Actividad actividad) {
    final nombreController = TextEditingController(text: actividad.nombre);
    final descripcionController = TextEditingController(text: actividad.descripcion);
    final puntosController = TextEditingController(text: actividad.puntosBase.toString());
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue),
            SizedBox(width: 8),
            Text('Editar Actividad'),
          ],
        ),
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
                      content: Text('✅ Actividad actualizada'),
                      backgroundColor: Colors.green,
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
            Icon(Icons.warning, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Flexible(child: Text('Eliminar', style: TextStyle(fontSize: 18))),
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
