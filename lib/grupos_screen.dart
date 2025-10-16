import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'agenda_provider.dart';
import 'models.dart';
import 'theme_provider.dart';

class GruposScreen extends StatefulWidget {
  final String userEmail;

  const GruposScreen({super.key, required this.userEmail});

  @override
  State<GruposScreen> createState() => _GruposScreenState();
}

class _GruposScreenState extends State<GruposScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final agendaProvider = Provider.of<AgendaProvider>(context);
        final rol = agendaProvider.getRol(widget.userEmail);
        final misGrupos = agendaProvider.getGruposUsuario(widget.userEmail);
        final gruposComoEntrenador = agendaProvider.getGruposComoEntrenador(widget.userEmail);

        return Scaffold(
          appBar: AppBar(
            title: Text('Mis Grupos'),
          ),
          body: ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Grupos como entrenador
              if (gruposComoEntrenador.isNotEmpty) ...[
                Row(
                  children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Grupos que administro',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...gruposComoEntrenador.map((grupo) => _buildGrupoCard(grupo, true, agendaProvider)).toList(),
            SizedBox(height: 24),
          ],

          // Grupos como miembro
          Row(
            children: [
              Icon(Icons.group, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Grupos donde participo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (misGrupos.isEmpty)
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
                      'No perteneces a ningún grupo aún',
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
            ...misGrupos.map((grupo) {
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  nombre: nombreController.text,
                  descripcion: descripcionController.text,
                  entrenadorId: widget.userEmail,
                  entrenadorNombre: widget.userEmail.split('@')[0],
                  miembrosIds: [widget.userEmail],
                  fechaCreacion: DateTime.now(),
                );
                agendaProvider.agregarGrupo(grupo);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Grupo creado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text('Crear'),
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
              'Hoy es 8 de Octubre',
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
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: esEntrenador
                  ? Icon(
                      completada ? Icons.check_circle : Icons.circle_outlined,
                      color: completada ? Colors.green : Colors.grey,
                      size: 32,
                    )
                  : Checkbox(
                      value: completada,
                      activeColor: Colors.green,
                      onChanged: completada
                          ? null
                          : (value) {
                              if (value == true) {
                                agendaProvider.completarActividad(actividad.id, userEmail);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('¡Tarea completada! +${actividad.puntosBase} puntos'),
                                    backgroundColor: Colors.green,
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
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 32),
                        Text(
                          '✓',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : null,
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
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        grupo.id,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Icon(Icons.copy, size: 20),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Comparte este código para que otros se unan',
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
