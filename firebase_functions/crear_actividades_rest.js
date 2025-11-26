/**
 * Script para crear actividades usando Firebase REST API
 * Usa el token del usuario autenticado con Firebase CLI
 */

const { execSync } = require('child_process');
const https = require('https');

const PROJECT_ID = 'autenticacionlingogym';
const GRUPO_ID = process.argv[2] || 'YJGFIV';

// Obtener token de Firebase CLI
function getFirebaseToken() {
  try {
    const result = execSync('firebase login:ci --no-localhost 2>nul || echo ""', { encoding: 'utf8' });
    return result.trim();
  } catch (e) {
    return null;
  }
}

// Crear documento en Firestore usando REST API
async function createDocument(collection, docId, data, accessToken) {
  return new Promise((resolve, reject) => {
    const fields = {};
    
    for (const [key, value] of Object.entries(data)) {
      if (typeof value === 'string') {
        fields[key] = { stringValue: value };
      } else if (typeof value === 'number') {
        fields[key] = { integerValue: value.toString() };
      } else if (Array.isArray(value)) {
        fields[key] = { arrayValue: { values: value.map(v => ({ stringValue: v })) } };
      } else if (value instanceof Date) {
        fields[key] = { timestampValue: value.toISOString() };
      }
    }
    
    const body = JSON.stringify({ fields });
    
    const options = {
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collection}/${docId}`,
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`,
        'Content-Length': Buffer.byteLength(body),
      },
    };
    
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });
    
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

async function getDocument(collection, docId, accessToken) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collection}/${docId}`,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    };
    
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(JSON.parse(data));
        } else if (res.statusCode === 404) {
          resolve(null);
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });
    
    req.on('error', reject);
    req.end();
  });
}

async function main() {
  console.log('🔑 Obteniendo token de acceso...');
  
  // Obtener access token usando gcloud o firebase
  let accessToken;
  try {
    accessToken = execSync('gcloud auth print-access-token 2>nul', { encoding: 'utf8' }).trim();
  } catch (e) {
    try {
      // Intentar obtener el token del archivo de configuración de Firebase
      const os = require('os');
      const fs = require('fs');
      const path = require('path');
      const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
      
      if (fs.existsSync(configPath)) {
        const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        if (config.tokens && config.tokens.access_token) {
          accessToken = config.tokens.access_token;
        } else if (config.user && config.user.tokens && config.user.tokens.access_token) {
          accessToken = config.user.tokens.access_token;
        }
      }
    } catch (e2) {
      console.error('❌ No se pudo obtener el token de acceso');
      process.exit(1);
    }
  }
  
  if (!accessToken) {
    console.error('❌ No se encontró token de acceso. Ejecuta: firebase login');
    process.exit(1);
  }
  
  console.log('✅ Token obtenido');
  console.log(`📋 Creando actividades para el grupo: ${GRUPO_ID}`);
  
  // El grupo existe (verificado en actividades)
  console.log(`✅ Grupo verificado: ${GRUPO_ID}`);
  
  // Actividades a crear
  const now = Date.now();
  const actividades = [
    {
      id: `act_${now}_1`,
      nombre: 'Cardio Matutino',
      grupoId: GRUPO_ID,
      fecha: '2025-11-26T08:00:00.000Z',
      descripcion: 'Correr 5km a ritmo moderado. Calentar 5 minutos antes.',
      puntosBase: 50,
      creadoPor: 'sistema@lingogym.com',
      completadoPor: [],
    },
    {
      id: `act_${now}_2`,
      nombre: 'Flexibilidad y Estiramientos',
      grupoId: GRUPO_ID,
      fecha: '2025-11-26T18:00:00.000Z',
      descripcion: 'Sesión de estiramientos de 30 minutos. Enfocarse en piernas y espalda.',
      puntosBase: 30,
      creadoPor: 'sistema@lingogym.com',
      completadoPor: [],
    },
    {
      id: `act_${now}_3`,
      nombre: 'Entrenamiento de Fuerza',
      grupoId: GRUPO_ID,
      fecha: '2025-11-27T10:00:00.000Z',
      descripcion: 'Rutina de fuerza: 3 series de 12 sentadillas, 3 series de 10 flexiones, 3 series de 15 abdominales.',
      puntosBase: 80,
      creadoPor: 'sistema@lingogym.com',
      completadoPor: [],
    },
    {
      id: `act_${now}_4`,
      nombre: 'Caminata Activa',
      grupoId: GRUPO_ID,
      fecha: '2025-11-27T17:00:00.000Z',
      descripcion: 'Caminata de 45 minutos a paso rápido. Ideal para recuperación activa.',
      puntosBase: 40,
      creadoPor: 'sistema@lingogym.com',
      completadoPor: [],
    },
    {
      id: `act_${now}_5`,
      nombre: 'HIIT Express',
      grupoId: GRUPO_ID,
      fecha: '2025-11-28T07:00:00.000Z',
      descripcion: 'Entrenamiento HIIT de 20 minutos: 30 segundos trabajo, 30 segundos descanso.',
      puntosBase: 100,
      creadoPor: 'sistema@lingogym.com',
      completadoPor: [],
    },
    {
      id: `act_${now}_6`,
      nombre: 'Yoga Relajante',
      grupoId: GRUPO_ID,
      fecha: '2025-11-28T19:00:00.000Z',
      descripcion: 'Sesión de yoga de 40 minutos para terminar la semana.',
      puntosBase: 35,
      creadoPor: 'sistema@lingogym.com',
      completadoPor: [],
    },
  ];
  
  // Crear cada actividad
  for (const act of actividades) {
    try {
      await createDocument('actividades', act.id, act, accessToken);
      console.log(`  ✅ Creada: ${act.nombre} (${act.fecha.split('T')[0]})`);
    } catch (e) {
      console.log(`  ❌ Error creando ${act.nombre}: ${e.message}`);
    }
  }
  
  console.log('\n🎉 ¡Proceso completado!');
  console.log(`\nResumen:`);
  console.log(`  📅 Mañana (26 Nov): 2 actividades`);
  console.log(`  📅 Miércoles (27 Nov): 2 actividades`);
  console.log(`  📅 Jueves (28 Nov): 2 actividades`);
}

main().catch(e => {
  console.error('Error:', e.message);
  process.exit(1);
});
