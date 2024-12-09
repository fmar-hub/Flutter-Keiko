const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

exports.dailyHabitReminderFlutter7 = functions.pubsub.schedule('every day 07:00')
  .onRun(async (context) => {
    console.log("Función de recordatorio de hábitos ejecutada...");

    const motivationalMessages = [
      "¡No olvides por qué empezaste!",
      "¡Sigamos con el buen ritmo!",
      "¡Vamos que se puede!",
      "Cada pequeño esfuerzo cuenta.",
      "¡Hoy es un gran día para avanzar!",
      "¡No te detengas, estás haciendo un gran trabajo!",
      "¡Recuerda que eres capaz de lograrlo!",
      "Un hábito a la vez, ¡tú puedes hacerlo!",
      "¡La constancia te llevará lejos!",
      "¡Eres más fuerte de lo que crees!"
    ];

    const usersSnapshot = await admin.firestore().collection("usuarios").get();

    if (usersSnapshot.empty) {
      console.log("No hay usuarios registrados.");
      return null;
    }

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userDocData = await admin.firestore().doc(`usuarios/${userId}`).get();
      const userData = userDocData.data();

      if (userData && userData.token) { // Verificamos que el usuario tenga token
        const userHabitsSnapshot = await admin.firestore()
          .collection("users_habits")
          .doc(userId)
          .collection("habits")
          .get();

        const habitNames = userHabitsSnapshot.docs.map(habitDoc => habitDoc.data().name).filter(name => name);

        if (habitNames.length > 0) {
          const randomMessage = motivationalMessages[Math.floor(Math.random() * motivationalMessages.length)];
          const habitList = habitNames.join(', ');
          const timestamp = Date.now(); // UTC Timestamp en milisegundos

          // Generamos una hora aleatoria en el día (entre las 00:00 y las 23:59)
          const randomHour = Math.floor(Math.random() * 24); // Aleatorio entre 0 y 23 (horas)
          const randomMinute = Math.floor(Math.random() * 60); // Aleatorio entre 0 y 59 (minutos)

          // Creamos la hora aleatoria
          const notificationTime = new Date();
          notificationTime.setHours(randomHour);
          notificationTime.setMinutes(randomMinute);
          notificationTime.setSeconds(0); // Para eliminar segundos y tener una hora exacta

          const message = {
            notification: {
              title: randomMessage,
              body: `No olvides realizar tus hábitos: ${habitList}.`,
            },
            data: {
              timestamp: timestamp.toString(), // Enviar como string
              userId: userId,
              notificationTime: notificationTime.toISOString(), // La hora aleatoria en formato ISO
            },
            token: userData.token,
          };

          try {
            await admin.messaging().send(message);
            console.log(`Notificación enviada a ${userId} para las ${notificationTime.toISOString()}`);
          } catch (error) {
            console.error(`Error enviando la notificación a ${userId}:`, error);
          }
        }
      }
    }

    console.log("Función de recordatorio de hábitos completada.");
    return null;
  });
