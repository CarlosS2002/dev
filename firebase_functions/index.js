/**
 * Cloud Functions para LingoGym
 * 
 * Esta función escucha nuevas notificaciones en Firestore y envía
 * notificaciones push a los dispositivos de los atletas.
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Inicializar Firebase Admin
admin.initializeApp();

/**
 * Función que se ejecuta cuando se crea una nueva notificación en Firestore.
 * Ruta: /notificaciones/{userEmail}/lista/{notifId}
 * 
 * Flujo:
 * 1. Entrenador crea actividad en la app
 * 2. Se guarda notificación en Firestore para cada atleta
 * 3. Esta función detecta la nueva notificación
 * 4. Busca el token FCM del atleta
 * 5. Envía la notificación push al dispositivo
 */
exports.enviarNotificacionPush = functions.firestore
  .document('notificaciones/{userEmail}/lista/{notifId}')
  .onCreate(async (snap, context) => {
    const notificacion = snap.data();
    const userEmail = context.params.userEmail;
    const notifId = context.params.notifId;
    
    console.log(`📩 Nueva notificación para: ${userEmail}`);
    console.log(`   Título: ${notificacion.titulo}`);
    console.log(`   Mensaje: ${notificacion.mensaje}`);
    
    try {
      // Obtener el documento del usuario para conseguir su token FCM
      const userDoc = await admin.firestore()
        .collection('usuarios')
        .doc(userEmail)
        .get();
      
      if (!userDoc.exists) {
        console.log(`⚠️ Usuario no encontrado: ${userEmail}`);
        return null;
      }
      
      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;
      
      if (!fcmToken) {
        console.log(`⚠️ No hay token FCM para: ${userEmail}`);
        return null;
      }
      
      // Construir el mensaje de notificación
      const message = {
        notification: {
          title: notificacion.titulo || 'Nueva actividad',
          body: notificacion.mensaje || 'Tienes una nueva actividad asignada',
        },
        data: {
          // Datos adicionales para la app
          notificacionId: notifId,
          actividadId: notificacion.actividadId || '',
          grupoId: notificacion.grupoId || '',
          grupoNombre: notificacion.grupoNombre || '',
          tipo: 'nueva_actividad',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            icon: 'ic_notification',
            color: '#2196F3',
            sound: 'default',
            priority: 'high',
            channelId: 'lingo_gym_activities',
          },
          priority: 'high',
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
        token: fcmToken,
      };
      
      // Enviar la notificación push
      const response = await admin.messaging().send(message);
      console.log(`✅ Notificación enviada exitosamente: ${response}`);
      
      // Actualizar el documento para marcar que se envió la push
      await snap.ref.update({
        pushEnviado: true,
        pushEnviadoEn: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return response;
      
    } catch (error) {
      console.error(`❌ Error enviando notificación:`, error);
      
      // Si el token es inválido, eliminarlo
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {
        console.log(`🗑️ Eliminando token inválido para: ${userEmail}`);
        await admin.firestore()
          .collection('usuarios')
          .doc(userEmail)
          .update({
            fcmToken: admin.firestore.FieldValue.delete(),
          });
      }
      
      return null;
    }
  });

/**
 * Función opcional: Enviar notificación a todos los miembros de un grupo
 * Útil para anuncios grupales
 */
exports.enviarNotificacionGrupo = functions.firestore
  .document('grupos/{grupoId}/anuncios/{anuncioId}')
  .onCreate(async (snap, context) => {
    const anuncio = snap.data();
    const grupoId = context.params.grupoId;
    
    console.log(`📢 Nuevo anuncio en grupo: ${grupoId}`);
    
    try {
      // Obtener el grupo para saber quiénes son los miembros
      const grupoDoc = await admin.firestore()
        .collection('grupos')
        .doc(grupoId)
        .get();
      
      if (!grupoDoc.exists) {
        console.log(`⚠️ Grupo no encontrado: ${grupoId}`);
        return null;
      }
      
      const grupo = grupoDoc.data();
      const miembros = grupo.miembrosIds || [];
      
      // Obtener tokens FCM de todos los miembros
      const tokens = [];
      for (const email of miembros) {
        const userDoc = await admin.firestore()
          .collection('usuarios')
          .doc(email)
          .get();
        
        if (userDoc.exists && userDoc.data().fcmToken) {
          tokens.push(userDoc.data().fcmToken);
        }
      }
      
      if (tokens.length === 0) {
        console.log('⚠️ No hay tokens FCM para enviar');
        return null;
      }
      
      // Enviar a múltiples dispositivos
      const message = {
        notification: {
          title: `📢 ${grupo.nombre}`,
          body: anuncio.mensaje || 'Nuevo anuncio del grupo',
        },
        data: {
          tipo: 'anuncio_grupo',
          grupoId: grupoId,
          grupoNombre: grupo.nombre || '',
        },
        tokens: tokens,
      };
      
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`✅ Enviado a ${response.successCount}/${tokens.length} dispositivos`);
      
      return response;
      
    } catch (error) {
      console.error(`❌ Error enviando anuncio:`, error);
      return null;
    }
  });

/**
 * Función para limpiar notificaciones antiguas (más de 30 días)
 * Se ejecuta cada día a las 3:00 AM
 */
exports.limpiarNotificacionesAntiguas = functions.pubsub
  .schedule('0 3 * * *')
  .timeZone('America/Mexico_City')
  .onRun(async (context) => {
    console.log('🧹 Iniciando limpieza de notificaciones antiguas...');
    
    const hace30Dias = new Date();
    hace30Dias.setDate(hace30Dias.getDate() - 30);
    
    try {
      // Obtener todos los usuarios
      const usuariosSnapshot = await admin.firestore()
        .collection('notificaciones')
        .get();
      
      let eliminadas = 0;
      
      for (const userDoc of usuariosSnapshot.docs) {
        const notificacionesSnapshot = await userDoc.ref
          .collection('lista')
          .where('fecha', '<', hace30Dias)
          .get();
        
        const batch = admin.firestore().batch();
        notificacionesSnapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
          eliminadas++;
        });
        
        await batch.commit();
      }
      
      console.log(`✅ Limpieza completada: ${eliminadas} notificaciones eliminadas`);
      return null;
      
    } catch (error) {
      console.error('❌ Error en limpieza:', error);
      return null;
    }
  });
