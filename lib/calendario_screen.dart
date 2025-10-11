import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  _CalendarioScreenState createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime selectedDate = DateTime.now();
  Map<String, List<String>> actividadesPorFecha = {}; // Almacena actividades por fecha
  TextEditingController actividadController = TextEditingController();

  // Función para seleccionar fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Función para agregar actividad
  void _agregarActividad() {
    if (actividadController.text.isNotEmpty) {
      String fechaKey = "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
      setState(() {
        if (actividadesPorFecha[fechaKey] == null) {
          actividadesPorFecha[fechaKey] = [];
        }
        actividadesPorFecha[fechaKey]!.add(actividadController.text);
        actividadController.clear();
      });
      
      // Mostrar mensaje de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Actividad agregada exitosamente'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Función para eliminar actividad
  void _eliminarActividad(String fecha, int index) {
    setState(() {
      actividadesPorFecha[fecha]!.removeAt(index);
      if (actividadesPorFecha[fecha]!.isEmpty) {
        actividadesPorFecha.remove(fecha);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String fechaSeleccionada = "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
    List<String> actividadesHoy = actividadesPorFecha[fechaSeleccionada] ?? [];

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Calendario Deportivo'),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector de fecha
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Fecha Seleccionada',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        fechaSeleccionada,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () => _selectDate(context),
                        icon: Icon(Icons.calendar_today),
                        label: Text('Cambiar Fecha'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 20),
              
              // Formulario para agregar actividad
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agregar Actividad Deportiva',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: actividadController,
                        style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Nombre de la actividad',
                          labelStyle: TextStyle(color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87),
                          hintText: 'Ej: Fútbol, Natación, Gym...',
                          hintStyle: TextStyle(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                          ),
                          prefixIcon: Icon(Icons.sports_soccer),
                        ),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _agregarActividad,
                          icon: Icon(Icons.add),
                          label: Text('Agregar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 20),
              
              // Lista de actividades del día seleccionado
              Text(
                'Actividades del día',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade600,
                ),
              ),
              SizedBox(height: 10),
              
              actividadesHoy.isEmpty
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No hay actividades para este día',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: actividadesHoy.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade600,
                              child: Icon(
                                Icons.sports,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              actividadesHoy[index],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _eliminarActividad(fechaSeleccionada, index);
                              },
                            ),
                          ),
                        );
                      },
                    ),
              
              SizedBox(height: 20),
              
              // Resumen de todas las actividades
              if (actividadesPorFecha.isNotEmpty) ...[
                Divider(thickness: 2),
                Text(
                  'Todas las actividades programadas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade600,
                  ),
                ),
                SizedBox(height: 10),
                ...actividadesPorFecha.entries.map((entry) {
                  return Card(
                    margin: EdgeInsets.only(bottom: 10),
                    child: ExpansionTile(
                      leading: Icon(Icons.calendar_month, color: Colors.blue.shade600),
                      title: Text(
                        entry.key,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${entry.value.length} actividad(es)'),
                      children: entry.value.map((actividad) {
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.sports_soccer, size: 20),
                          title: Text(actividad),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
