const os = require('os');
const fs = require('fs');
const path = require('path');
const https = require('https');

const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const token = config.tokens?.access_token || config.user?.tokens?.access_token;

const email = 'cardasalo@gmail.com';

// Actualizar rol a entrenador
const updateData = {
  fields: {
    email: { stringValue: email },
    rol: { stringValue: 'entrenador' }
  }
};

const req = https.request({
  hostname: 'firestore.googleapis.com',
  path: '/v1/projects/autenticacionlingogym/databases/(default)/documents/usuarios/' + encodeURIComponent(email) + '?updateMask.fieldPaths=rol&updateMask.fieldPaths=email',
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
      console.log('✅ Rol actualizado a ENTRENADOR para ' + email);
      const doc = JSON.parse(data);
      console.log('Nuevo rol:', doc.fields?.rol?.stringValue);
    } else {
      console.log('❌ Error:', res.statusCode);
      console.log(data);
    }
  });
});
req.write(JSON.stringify(updateData));
req.end();
