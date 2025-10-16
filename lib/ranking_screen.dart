import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'agenda_provider.dart';
import 'theme_provider.dart';

class RankingScreen extends StatefulWidget {
  final String userEmail;

  const RankingScreen({super.key, required this.userEmail});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  String? grupoSeleccionado;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final agendaProvider = Provider.of<AgendaProvider>(context);
        final grupos = agendaProvider.getGruposUsuario(widget.userEmail);

        return Scaffold(
          appBar: AppBar(
            title: Text('Rankings'),
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
                      'Selecciona un grupo:',
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
                        'Selecciona un grupo para ver su ranking',
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                      dropdownColor: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.white,
                      items: grupos.map((grupo) {
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
                      onChanged: (value) {
                        setState(() {
                          grupoSeleccionado = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Lista de ranking
              Expanded(
                child: grupoSeleccionado == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events, 
                              size: 80, 
                              color: themeProvider.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Selecciona un grupo para ver el ranking',
                              style: TextStyle(
                                fontSize: 18, 
                                color: themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildRanking(agendaProvider, grupoSeleccionado!, themeProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRanking(AgendaProvider agendaProvider, String grupoId, ThemeProvider themeProvider) {
    final ranking = agendaProvider.getRankingGrupo(grupoId);

    if (ranking.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty, 
              size: 80, 
              color: themeProvider.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400
            ),
            SizedBox(height: 16),
            Text(
              'No hay actividades completadas aún',
              style: TextStyle(
                fontSize: 18, 
                color: themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Completa actividades para aparecer en el ranking',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: ranking.length,
      itemBuilder: (context, index) {
        final item = ranking[index];
        final usuarioEmail = item['usuarioEmail'] as String;
        final puntos = item['puntos'] as int;
        final actividades = item['actividades'] as int;
        final posicion = index + 1;
        final esUsuarioActual = usuarioEmail == widget.userEmail;

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: esUsuarioActual ? 6 : 2,
          color: esUsuarioActual 
              ? (themeProvider.isDarkMode ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50)
              : null,
          child: Container(
            decoration: esUsuarioActual
                ? BoxDecoration(
                    border: Border.all(
                      color: themeProvider.isDarkMode ? Colors.blue.shade300 : Colors.blue, 
                      width: 2
                    ),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: _buildMedalla(posicion),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      usuarioEmail.split('@')[0],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: esUsuarioActual ? FontWeight.bold : FontWeight.normal,
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  if (esUsuarioActual)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode ? Colors.blue.shade700 : Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Tú',
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
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.stars, size: 16, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        '$puntos puntos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode ? Colors.amber.shade400 : Colors.amber.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        '$actividades actividades completadas',
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Text(
                '#$posicion',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMedalla(int posicion) {
    Color color;
    String emoji;

    switch (posicion) {
      case 1:
        color = Colors.amber;
        emoji = '🥇';
        break;
      case 2:
        color = Colors.grey;
        emoji = '🥈';
        break;
      case 3:
        color = Colors.brown;
        emoji = '🥉';
        break;
      default:
        color = Colors.blue.shade200;
        emoji = '👤';
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}
