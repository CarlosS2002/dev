/**
 * Script para crear actividades de prueba en Firebase
 * 
 * Ejecutar desde la carpeta firebase_functions:
 * node crear_actividades.js <CODIGO_GRUPO>
 * 
 * Ejemplo: node crear_actividades.js ABC123
 */

const { initializeApp, cert, applicationDefault } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

// Inicializar usando las credenciales del emulador o ADC
try {
  initializeApp({
    projectId: 'autenticacionlingogym',
    credential: applicationDefault(),
  });
} catch (e) {
  // Si falla, intentar sin credenciales explícitas (para emulador)
  initializeApp({
    projectId: 'autenticacionlingogym',
  });
}

const db = getFirestore();

async function crearActividades(grupoId) {
  if (!grupoId) {
    console.log('❌ Debes proporcionar el código del grupo');
    console.log('Uso: node crear_actividades.js <CODIGO_GRUPO>');
    process.exit(1);
  }

  console.log(`📋 Creando actividades para el grupo: ${grupoId}`);

  // Fechas: mañana (26), miércoles (27), jueves (28) de noviembre 2025
  const actividades = [
    // Mañana - 26 de Noviembre
    {
      id: `act_${Date.now()}_1`,
      nombre: 'Cardio Matutino',
      grupoId: grupoId,
      fecha: '2025-11-26T08:00:00.000Z',
      descripcion: 'Correr 5km a ritmo moderado. Calentar 5 minutos antes.',
      puntosBase: 50,
      creadoPor: 'sistema@lingogym.com',
      completadoPor: [],
    },
    {
      id: `act_${Date.now()}_2`,
      nombre: 'Flexibilidad y Estiramientos',
      grupoId: grupoId,
      fecha: '2025-11-26T18:00:00.000Z',
      descripcion: 'Sesión de estiramientos de 30 minutos. Enfocarse en piernas y espalda.',
      puntosBase: 30,
      creadoPor: 'sistema@lingogym.com',
      completadoPor: [],
    },
    
    // Miércoles - 27 de Noviembre
    {
      id: `act_${Date.now()}_3`,
      nombre: 'Entrenamiento de Fuerza',
      grupoId: grupoId,
      fecha: '2025-11-27T10:00:00.000Z',
      descripcion: 'Rutina de fuerza: 3 series de 12 sentadillas, 3 series de 10 flexiones, 3 series de 15 abdominales.',
      puntosBase: 80,
      creadoPor: 'sistema@lingogym.com',
      completadoPor: [],
    },
    {
      id: `act_${Date.now()}_4`,
      nombre: 'Caminata Activa',
      grupoId: grupoId,
      fecha: '2025-11-27T17:00:00.000Z',
      descripcion: 'Caminata de 45 minutos a paso rápido. Ideal para recuperación activa.',
      puntosBase: 40,
      creadoPor: 'sistema@lingogym.com',
      completadoPor: [],
    },
    
    // Jueves - 28 de Noviembre
    {
      id: `act_${Date.now()}_5`,
      nombre: 'HIIT Express',
      grupoId: grupoId,
      fecha: '2025-11-28T07:00:00.000Z',
      descripcion: 'Entrenamiento HIIT de 20 minutos: 30 segundos trabajo, 30 segundos descanso. Ejercicios: burpees, jumping jacks, mountain climbers.',
      puntosBase: 100,
      creadoPor: 'sistema@lingogym.com',
      completadoPor: [],
    },
    {
      id: `act_${Date.now()}_6`,
      nombre: 'Yoga Relajante',
      grupoId: grupoId,
      fecha: '2025-11-28T19:00:00.000Z',
      descripcion: 'Sesión de yoga de 40 minutos para terminar la semana. Enfoque en respiración y relajación.',
      puntosBase: 35,
      creadoPor: 'sistema@lingogym.com',
      completadoPor: [],
    },
  ];

  try {
    // Verificar que el grupo existe
    const grupoDoc = await db.collection('grupos').doc(grupoId).get();
    
    if (!grupoDoc.exists) {
      console.log(`❌ El grupo ${grupoId} no existe en Firebase`);
      console.log('Grupos disponibles:');
      const grupos = await db.collection('grupos').get();
      grupos.forEach(doc => {
        console.log(`  - ${doc.id}: ${doc.data().nombre || 'Sin nombre'}`);
      });
      process.exit(1);
    }

    console.log(`✅ Grupo encontrado: ${grupoDoc.data().nombre}`);

    // Crear las actividades
    for (const actividad of actividades) {
      await db.collection('actividades').doc(actividad.id).set({
        ...actividad,
        creadoEn: FieldValue.serverTimestamp(),
      });
      console.log(`  ✅ Creada: ${actividad.nombre} (${actividad.fecha.split('T')[0]})`);
    }

    console.log('\n🎉 ¡Todas las actividades fueron creadas exitosamente!');
    console.log(`\nResumen:`);
    console.log(`  📅 Mañana (26 Nov): 2 actividades`);
    console.log(`  📅 Miércoles (27 Nov): 2 actividades`);
    console.log(`  📅 Jueves (28 Nov): 2 actividades`);
    console.log(`  💯 Total de puntos disponibles: 335`);

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }

  process.exit(0);
}

// Obtener el código del grupo desde los argumentos
const grupoId = process.argv[2];
crearActividades(grupoId);
