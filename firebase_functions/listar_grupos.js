/**
 * Script para listar grupos en Firebase
 */

const https = require('https');
const os = require('os');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'autenticacionlingogym';

function getAccessToken() {
  const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  
  if (fs.existsSync(configPath)) {
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    if (config.tokens && config.tokens.access_token) {
      return config.tokens.access_token;
    } else if (config.user && config.user.tokens && config.user.tokens.access_token) {
      return config.user.tokens.access_token;
    }
  }
  return null;
}

async function listCollection(collection, accessToken) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collection}`,
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
  const token = getAccessToken();
  if (!token) {
    console.error('No se encontró token');
    process.exit(1);
  }
  
  console.log('Buscando grupos...\n');
  
  try {
    const result = await listCollection('grupos', token);
    
    if (!result.documents || result.documents.length === 0) {
      console.log('No hay grupos en Firebase');
      return;
    }
    
    console.log(`Encontrados ${result.documents.length} grupo(s):\n`);
    
    for (const doc of result.documents) {
      const id = doc.name.split('/').pop();
      const nombre = doc.fields?.nombre?.stringValue || 'Sin nombre';
      const miembros = doc.fields?.miembrosIds?.arrayValue?.values?.length || 0;
      
      console.log(`📁 ID: ${id}`);
      console.log(`   Nombre: ${nombre}`);
      console.log(`   Miembros: ${miembros}`);
      console.log('');
    }
  } catch (e) {
    console.error('Error:', e.message);
  }
}

main();
