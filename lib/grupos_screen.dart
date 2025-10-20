import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'agenda_provider.dart';
import 'models.dart';
import 'theme_provider.dart';
import 'dart:math';

class GruposScreen extends StatefulWidget {
  final String userEmail;

  const GruposScreen({super.key, required this.userEmail});

  @override
  State<GruposScreen> createState() => _GruposScreenState();
}

class _GruposScreenState extends State<GruposScreen> {
  // Generar código corto con letras y números (6 caracteres)
  String _generarCodigoGrupo() {
    const caracteres = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => caracteres[random.nextInt(caracteres.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final agendaProvider = Provider.of<AgendaProvider>(context);
        final rol = agendaProvider.getRol(widget.userEmail);
        final gruposComoEntrenador = agendaProvider.getGruposComoEntrenador(widget.userEmail);
        // Si es entrenador, solo mostrar grupos que administra
        // Si es atleta, mostrar grupos donde participa
        final gruposParaMostrar = rol == RolUsuario.entrenador 
            ? gruposComoEntrenador 
            : agendaProvider.getGruposUsuario(widget.userEmail);

        return Scaffold(
          appBar: AppBar(
            title: Text('Mis Grupos'),
          ),
          body: ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Título según el rol
              Row(
                children: [
                  Icon(
                    rol == RolUsuario.entrenador ? Icons.star : Icons.group, 
                    color: rol == RolUsuario.entrenador ? Colors.amber : Colors.blue
                  ),
                  SizedBox(width: 8),
                  Text(
                    rol == RolUsuario.entrenador ? 'Grupos que administro' : 'Grupos donde participo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 12),
              
              // Lista de grupos o mensaje vacío
              if (gruposParaMostrar.isEmpty)
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.group_off, 
                          size: 60, 
                          color: themeProvider.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400
                        ),
                        SizedBox(height: 12),
                        Text(
                          rol == RolUsuario.entrenador 
                              ? 'No administras ningún grupo aún'
                              : 'No perteneces a ningún grupo aún',
                          style: TextStyle(
                            fontSize: 16, 
                            color: themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          rol == RolUsuario.entrenador
                              ? 'Crea tu primer grupo'
                              : 'Únete a un grupo para empezar',
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...gruposParaMostrar.map((grupo) {
                  final esEntrenador = grupo.entrenadorId == widget.userEmail;
                  return _buildGrupoCard(grupo, esEntrenador, agendaProvider);
                }).toList(),
            ],
          ),
          floatingActionButton: _buildBotonAccion(context, agendaProvider, rol),
        );
      },
    );
  }

  Widget _buildGrupoCard(Grupo grupo, bool esEntrenador, AgendaProvider agendaProvider) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: esEntrenador ? Colors.orange.shade100 : Colors.blue.shade100,
          child: Text(
            esEntrenador ? '👨‍🏫' : '🏃',
            style: TextStyle(fontSize: 30),
          ),
        ),
        title: Text(
          grupo.nombre,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (grupo.descripcion.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(grupo.descripcion),
            ],
            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Text(
                    '${grupo.miembrosIds.length} miembros',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Text(
                    '${agendaProvider.getActividadesGrupo(grupo.id).length} actividades',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (esEntrenador)
              Icon(Icons.admin_panel_settings, color: Colors.orange)
            else
              Icon(Icons.check_circle, color: Colors.green),
            SizedBox(height: 4),
            Text(
              esEntrenador ? 'Admin' : 'Miembro',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        onTap: () => _navegarADetallesGrupo(context, grupo, esEntrenador, agendaProvider),
      ),
    );
  }

  Widget? _buildBotonAccion(BuildContext context, AgendaProvider agendaProvider, RolUsuario rol) {
    return SpeedDial(
      rol: rol,
      onCrearGrupo: () => _mostrarDialogoCrearGrupo(context, agendaProvider),
      onUnirseGrupo: () => _mostrarDialogoUnirseGrupo(context, agendaProvider),
    );
  }

  void _navegarADetallesGrupo(BuildContext context, Grupo grupo, bool esEntrenador, AgendaProvider agendaProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleGrupoScreen(
          grupo: grupo,
          userEmail: widget.userEmail,
          esEntrenador: esEntrenador,
        ),
      ),
    );
  }

  void _mostrarDialogoCrearGrupo(BuildContext context, AgendaProvider agendaProvider) {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    bool entrenadorParticipa = true; // Por defecto sí participa

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Crear Nuevo Grupo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Nombre del grupo',
                    labelStyle: TextStyle(color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                    ),
                    prefixIcon: Icon(Icons.group),
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
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: themeProvider.isDarkMode ? Colors.white38 : Colors.grey.shade400
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      'Participar en este grupo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      entrenadorParticipa 
                          ? 'Aparecerás en el ranking y podrás completar actividades'
                          : 'Solo administrarás el grupo sin participar en actividades',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: entrenadorParticipa,
                    activeColor: Colors.blue.shade600,
                    onChanged: (value) {
                      setState(() {
                        entrenadorParticipa = value ?? true;
                      });
                    },
                  ),
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
                if (nombreController.text.isNotEmpty) {
                  final grupo = Grupo(
                    id: _generarCodigoGrupo(),
                    nombre: nombreController.text,
                    descripcion: descripcionController.text,
                    entrenadorId: widget.userEmail,
                    entrenadorNombre: widget.userEmail.split('@')[0],
                    // Solo agregar al entrenador si decidió participar
                    miembrosIds: entrenadorParticipa ? [widget.userEmail] : [],
                    fechaCreacion: DateTime.now(),
                  );
                  agendaProvider.agregarGrupo(grupo);
                  Navigator.pop(context);
                  
                  // Mostrar diálogo con el código del grupo
                  _mostrarDialogoCodigoGrupo(context, grupo.id);
                }
              },
              child: Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoCodigoGrupo(BuildContext context, String codigo) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('¡Grupo Creado!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Comparte este código con los miembros:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    codigo,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                      letterSpacing: 4,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: codigo));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Código copiado al portapapeles'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: Icon(Icons.copy),
                    label: Text('Copiar Código'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoUnirseGrupo(BuildContext context, AgendaProvider agendaProvider) {
    final codigoController = TextEditingController();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unirse a un Grupo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ingresa el código del grupo al que deseas unirte'),
            SizedBox(height: 16),
            TextField(
              controller: codigoController,
              style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Código del grupo',
                labelStyle: TextStyle(color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                ),
                prefixIcon: Icon(Icons.vpn_key),
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
              if (codigoController.text.isNotEmpty) {
                final exito = agendaProvider.unirseAGrupo(
                  codigoController.text,
                  widget.userEmail,
                );
                Navigator.pop(context);
                if (exito) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Te has unido al grupo exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Código de grupo inválido'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Unirse'),
          ),
        ],
      ),
    );
  }
}

class SpeedDial extends StatefulWidget {
  final RolUsuario rol;
  final VoidCallback onCrearGrupo;
  final VoidCallback onUnirseGrupo;

  const SpeedDial({
    super.key,
    required this.rol,
    required this.onCrearGrupo,
    required this.onUnirseGrupo,
  });

  @override
  State<SpeedDial> createState() => _SpeedDialState();
}

class _SpeedDialState extends State<SpeedDial> with SingleTickerProviderStateMixin {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isOpen) ...[
          if (widget.rol == RolUsuario.entrenador)
            FloatingActionButton.extended(
              heroTag: 'crear',
              onPressed: () {
                setState(() => _isOpen = false);
                widget.onCrearGrupo();
              },
              icon: Icon(Icons.add),
              label: Text('Crear Grupo'),
              backgroundColor: Colors.orange,
            ),
          SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'unirse',
            onPressed: () {
              setState(() => _isOpen = false);
              widget.onUnirseGrupo();
            },
            icon: Icon(Icons.group_add),
            label: Text('Unirse a Grupo'),
            backgroundColor: Colors.blue,
          ),
          SizedBox(height: 12),
        ],
        FloatingActionButton(
          onPressed: () {
            setState(() => _isOpen = !_isOpen);
          },
          child: Icon(_isOpen ? Icons.close : Icons.menu),
        ),
      ],
    );
  }
}

// Nueva pantalla de detalles del grupo
class DetalleGrupoScreen extends StatelessWidget {
  final Grupo grupo;
  final String userEmail;
  final bool esEntrenador;

  const DetalleGrupoScreen({
    super.key,
    required this.grupo,
    required this.userEmail,
    required this.esEntrenador,
  });

  @override
  Widget build(BuildContext context) {
    final agendaProvider = Provider.of<AgendaProvider>(context);
    final hoy = DateTime.now();
    final actividadesHoy = agendaProvider
        .getActividadesGrupo(grupo.id)
        .where((act) =>
            act.fecha.year == hoy.year &&
            act.fecha.month == hoy.month &&
            act.fecha.day == hoy.day)
        .toList();

    return DefaultTabController(
      length: esEntrenador ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(grupo.nombre),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.event), text: 'Tareas de Hoy'),
              if (esEntrenador) Tab(icon: Icon(Icons.people), text: 'Miembros'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pestaña de Tareas de Hoy
            _buildTareasTab(context, agendaProvider, actividadesHoy),
            // Pestaña de Miembros (solo para entrenadores)
            if (esEntrenador) _buildMiembrosTab(context, agendaProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildTareasTab(BuildContext context, AgendaProvider agendaProvider, List<Actividad> actividadesHoy) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    if (actividadesHoy.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'No hay tareas para hoy',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            SizedBox(height: 8),
            Text(
              'Hoy es 19 de Octubre',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: actividadesHoy.length,
      itemBuilder: (context, index) {
        final actividad = actividadesHoy[index];
        final completada = actividad.completadoPor.contains(userEmail);

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
                          final resultado = agendaProvider.completarActividad(actividad.id, userEmail);
                          if (resultado) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('¡Tarea completada! +${actividad.puntosBase} puntos'),
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
                          agendaProvider.descompletarActividad(actividad.id, userEmail);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tarea desmarcada'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
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
                          if (esEntrenador) ...[
                            SizedBox(width: 16),
                            Icon(Icons.people, size: 16, color: Colors.blue),
                            SizedBox(width: 4),
                            Text(
                              '${actividad.completadoPor.length}/${grupo.miembrosIds.length} completaron',
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
                // Mostrar estado de todos los miembros (para todos)
                if (grupo.miembrosIds.length > 1)
                  Container(
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
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiembrosTab(BuildContext context, AgendaProvider agendaProvider) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Información del grupo
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Información del Grupo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                if (grupo.descripcion.isNotEmpty) ...[
                  Text(
                    'Descripción:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(grupo.descripcion),
                  SizedBox(height: 12),
                ],
                Text(
                  'Código del grupo:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: grupo.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Código copiado: ${grupo.id}'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          grupo.id,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 2,
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        Icon(Icons.copy, size: 24, color: Colors.green),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Toca para copiar - Comparte este código para que otros se unan',
                  style: TextStyle(
                    fontSize: 12, 
                    color: themeProvider.isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        // Lista de miembros
        Row(
          children: [
            Icon(Icons.people, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Miembros del Grupo (${grupo.miembrosIds.length})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 12),
        ...grupo.miembrosIds.map((miembroId) {
          final esEntrenador = miembroId == grupo.entrenadorId;
          final puntos = agendaProvider.getPuntosUsuarioEnGrupo(miembroId, grupo.id);
          final actividadesCompletadas = agendaProvider
              .getActividadesGrupo(grupo.id)
              .where((act) => act.completadoPor.contains(miembroId))
              .length;

          return Card(
            margin: EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: esEntrenador ? Colors.orange.shade100 : Colors.blue.shade100,
                child: Text(
                  esEntrenador ? '👨‍🏫' : '🏃',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      miembroId.split('@')[0],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (esEntrenador)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(miembroId, style: TextStyle(fontSize: 12)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.stars, size: 14, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        '$puntos puntos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text('$actividadesCompletadas completadas'),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
