const os = require('os');
const fs = require('fs');
const path = require('path');
const https = require('https');

const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const token = config.tokens?.access_token || config.user?.tokens?.access_token;

const grupoId = 'YJGFIV';
const email = 'cardasalo@gmail.com';

// Crear el grupo
const grupoData = {
  fields: {
    id: { stringValue: grupoId },
    nombre: { stringValue: 'Grupo de Entrenamiento' },
    descripcion: { stringValue: 'Grupo creado por entrenador' },
    entrenadorId: { stringValue: email },
    entrenadorNombre: { stringValue: 'cardasalo' },
    miembrosIds: { 
      arrayValue: { 
        values: [{ stringValue: email }] 
      } 
    },
    rolesAlUnirse: { 
      mapValue: { 
        fields: {
          [email]: { stringValue: 'entrenador' }
        }
      } 
    },
    fechaCreacion: { stringValue: new Date().toISOString() }
  }
};

const req = https.request({
  hostname: 'firestore.googleapis.com',
  path: '/v1/projects/autenticacionlingogym/databases/(default)/documents/grupos/' + grupoId,
  method: 'PATCH',
  headers: { 
    'Authorization': 'Bearer ' + token,
    'Content-Type': 'application/json'
  }
}, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    if (res.statusCode === 200) {
      console.log('✅ Grupo ' + grupoId + ' creado exitosamente');
      console.log('   Entrenador: ' + email);
    } else {
      console.log('❌ Error:', res.statusCode);
      console.log(data);
    }
  });
});
req.write(JSON.stringify(grupoData));
req.end();
