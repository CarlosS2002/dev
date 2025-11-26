import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'agenda_screen.dart';
import 'grupos_screen.dart';
import 'ranking_screen.dart';
import 'theme_provider.dart';
import 'perfil_screen.dart';
import 'mapa_screen.dart';
import 'agenda_provider.dart';
import 'fcm_service.dart';

class MenuScreen extends StatefulWidget {
  final String userEmail;
  final VoidCallback onLogout;
  
  const MenuScreen({
    super.key, 
    required this.userEmail,
    required this.onLogout,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _currentIndex = 2; // Agenda en el medio (índice 2)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FCMService _fcmService = FCMService();

  @override
  void initState() {
    super.initState();
    // Inicializar datos del usuario desde Firebase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarServicios();
    });
  }

  Future<void> _inicializarServicios() async {
    final agendaProvider = Provider.of<AgendaProvider>(context, listen: false);
    
    // Inicializar datos del usuario
    await agendaProvider.inicializarUsuario(widget.userEmail);
    
    // Inicializar Firebase Cloud Messaging para notificaciones push
    try {
      await _fcmService.initialize(widget.userEmail);
      print('✅ FCM inicializado para ${widget.userEmail}');
    } catch (e) {
      print('⚠️ Error inicializando FCM: $e');
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    // Lista de pantallas en orden: Grupos, Ranking, Agenda (HOME), Mapa, Perfil
    final List<Widget> _screens = [
      GruposScreen(userEmail: widget.userEmail, onOpenDrawer: _openDrawer),
      RankingScreen(userEmail: widget.userEmail, onOpenDrawer: _openDrawer),
      AgendaScreen(userEmail: widget.userEmail, onOpenDrawer: _openDrawer), // HOME en el medio
      MapaScreen(userEmail: widget.userEmail, onOpenDrawer: _openDrawer),
      PerfilScreen(userEmail: widget.userEmail, onOpenDrawer: _openDrawer),
    ];

    return Scaffold(
      key: _scaffoldKey,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue.shade600,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              activeIcon: Icon(Icons.group, size: 28),
              label: 'Grupos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events),
              activeIcon: Icon(Icons.emoji_events, size: 28),
              label: 'Ranking',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 2 ? Colors.blue.shade600 : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home,
                  color: _currentIndex == 2 ? Colors.white : Colors.grey.shade600,
                  size: 28,
                ),
              ),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              activeIcon: Icon(Icons.map, size: 28),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              activeIcon: Icon(Icons.person, size: 28),
              label: 'Perfil',
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(context),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade600,
                  Colors.blue.shade400,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Icon(
                    widget.userEmail == 'carlos@test.com' 
                        ? Icons.male 
                        : widget.userEmail == 'maria@test.com'
                            ? Icons.female
                            : Icons.person,
                    size: 40,
                    color: widget.userEmail == 'carlos@test.com'
                        ? Colors.blue.shade600
                        : widget.userEmail == 'maria@test.com'
                            ? Colors.pink.shade400
                            : Colors.blue.shade600,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  widget.userEmail == 'carlos@test.com' 
                      ? 'Carlos Martínez' 
                      : widget.userEmail == 'maria@test.com'
                          ? 'María González'
                          : 'Usuario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.userEmail,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: Colors.blue.shade600),
            title: Text('Inicio (Agenda)'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 2);
            },
          ),
          ListTile(
            leading: Icon(Icons.group, color: Colors.green.shade600),
            title: Text('Grupos'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            },
          ),
          ListTile(
            leading: Icon(Icons.emoji_events, color: Colors.amber.shade600),
            title: Text('Ranking'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 1);
            },
          ),
          ListTile(
            leading: Icon(Icons.map, color: Colors.teal.shade600),
            title: Text('Mapa'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 3);
            },
          ),
          ListTile(
            leading: Icon(Icons.person, color: Colors.purple.shade600),
            title: Text('Perfil'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 4);
            },
          ),
          Divider(),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ListTile(
                leading: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: Colors.orange.shade600,
                ),
                title: Text(
                  themeProvider.isDarkMode
                      ? 'Modo Claro'
                      : 'Modo Oscuro',
                ),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                  activeColor: Colors.orange.shade600,
                ),
                onTap: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade600),
            title: Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red.shade600),
            ),
            onTap: () {
              Navigator.pop(context);
              widget.onLogout();
            },
          ),
        ],
      ),
    );
  }
}
