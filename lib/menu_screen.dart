import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'agenda_screen.dart';
import 'grupos_screen.dart';
import 'ranking_screen.dart';
import 'theme_provider.dart';
import 'perfil_screen.dart';
import 'mapa_screen.dart';

class MenuScreen extends StatelessWidget {
  final String userEmail;
  final VoidCallback onLogout;
  
  const MenuScreen({
    super.key, 
    required this.userEmail,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('menu'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: Drawer(
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
                      userEmail == 'carlos@test.com' 
                          ? Icons.male 
                          : userEmail == 'maria@test.com'
                              ? Icons.female
                              : Icons.person,
                      size: 40,
                      color: userEmail == 'carlos@test.com'
                          ? Colors.blue.shade600
                          : userEmail == 'maria@test.com'
                              ? Colors.pink.shade400
                              : Colors.blue.shade600,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    userEmail == 'carlos@test.com' 
                        ? 'Carlos Martínez' 
                        : userEmail == 'maria@test.com'
                            ? 'María González'
                            : 'Usuario',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userEmail,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.blue.shade600),
              title: Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PerfilScreen(userEmail: userEmail),
                  ),
                );
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
                Navigator.pop(context); // Cierra el drawer
                onLogout(); // Llama al callback para cerrar sesión
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Primera fila de botones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón Agenda
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AgendaScreen(userEmail: userEmail),
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        'assets/images/home1.jpg',
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error cargando imagen home1.jpg: $error');
                          return Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey.shade300,
                            child: Icon(
                              Icons.event,
                              size: 45,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Botón Grupos
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GruposScreen(userEmail: userEmail),
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        'assets/images/home2.jpg',
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error cargando imagen home2.jpg: $error');
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.group,
                              color: Colors.blue,
                              size: 45,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 30),
            
            // Segunda fila de botones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón Ranking
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RankingScreen(userEmail: userEmail),
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        'assets/images/home3.jpg',
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error cargando imagen home3.jpg: $error');
                          return Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey.shade300,
                            child: Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                              size: 45,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Botón 4 - Mapa
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapaScreen(userEmail: userEmail),
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        'assets/images/home4.jpg',
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error cargando imagen home4.jpg: $error');
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 45,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 50),
            
            // Botón de regreso
            Container(
              margin: EdgeInsets.symmetric(horizontal: 50),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Regresar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
