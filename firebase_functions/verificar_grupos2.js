const os = require('os');
const fs = require('fs');
const path = require('path');
const https = require('https');

const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const token = config.tokens?.access_token || config.user?.tokens?.access_token;

const email = 'cardasalo@gmail.com';

// 1. Buscar grupos donde es entrenador (campo correcto: entrenadorId)
const req1 = https.request({
  hostname: 'firestore.googleapis.com',
  path: '/v1/projects/autenticacionlingogym/databases/(default)/documents:runQuery',
  method: 'POST',
  headers: { 
    'Authorization': 'Bearer ' + token,
    'Content-Type': 'application/json'
  }
}, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log('=== GRUPOS donde ' + email + ' es ENTRENADOR (entrenadorId) ===');
    try {
      const results = JSON.parse(data);
      if (Array.isArray(results)) {
        let found = false;
        results.forEach(r => {
          if (r.document) {
            found = true;
            const doc = r.document;
            const codigo = doc.name.split('/').pop();
            const nombre = doc.fields?.nombre?.stringValue || 'Sin nombre';
            const entrenador = doc.fields?.entrenadorId?.stringValue || 'N/A';
            console.log(`  - Código: ${codigo}, Nombre: ${nombre}, Entrenador: ${entrenador}`);
          }
        });
        if (!found) {
          console.log('  (No se encontraron grupos)');
        }
      }
    } catch(e) {
      console.log('Error:', e.message, data.substring(0, 200));
    }
  });
});
req1.write(JSON.stringify({
  structuredQuery: {
    from: [{ collectionId: 'grupos' }],
    where: {
      fieldFilter: {
        field: { fieldPath: 'entrenadorId' },
        op: 'EQUAL',
        value: { stringValue: email }
      }
    }
  }
}));
req1.end();

// 2. Listar TODOS los grupos
const req3 = https.request({
  hostname: 'firestore.googleapis.com',
  path: '/v1/projects/autenticacionlingogym/databases/(default)/documents/grupos?pageSize=50',
  method: 'GET',
  headers: { 
    'Authorization': 'Bearer ' + token
  }
}, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log('\n=== TODOS LOS GRUPOS EN LA BD ===');
    try {
      const result = JSON.parse(data);
      if (result.documents && result.documents.length > 0) {
        result.documents.forEach(doc => {
          const codigo = doc.name.split('/').pop();
          const nombre = doc.fields?.nombre?.stringValue || 'Sin nombre';
          const entrenador = doc.fields?.entrenadorId?.stringValue || 'N/A';
          const miembros = doc.fields?.miembrosIds?.arrayValue?.values?.map(v => v.stringValue) || [];
          console.log(`  - Código: ${codigo}`);
          console.log(`    Nombre: ${nombre}`);
          console.log(`    Entrenador: ${entrenador}`);
          console.log(`    Miembros: ${miembros.join(', ') || 'ninguno'}`);
          console.log('');
        });
      } else {
        console.log('  (No hay grupos en la BD)');
        console.log('  Respuesta:', JSON.stringify(result, null, 2).substring(0, 500));
      }
    } catch(e) {
      console.log('Error:', e.message, data.substring(0, 500));
    }
  });
});
req3.end();
