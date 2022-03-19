import * as admin from 'firebase-admin'; 
import { storage } from 'firebase-admin';

var serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "messenger-in-flutter.appspot.com", 
  databaseURL: "https://messenger-in-flutter-default-rtdb.firebaseio.com"
});


const fcm = admin.messaging(); 
const db = admin.firestore(); 
const storageBucket = admin.storage().bucket()
const auth = admin.auth(); 


// add user phone on account creation 
db.collection("users").onSnapshot((snapshot) => {
  snapshot.docChanges().filter((docChange) => docChange.type == "added")
    .forEach(async (docChange) => {
      var newUserId = docChange.doc.id; 
      var phone = (await auth.getUser(newUserId)).phoneNumber!; 
      docChange.doc.ref.update({
        'phone': phone
      }); 
      // db.collection("phones").doc(phone).set({
      //   userId: newUserId
      // })
    }); 
}); 


// delete messages, media and avatar of deleted chats 
db.collection("chats").onSnapshot((snapshot) => {
  snapshot.docChanges().filter((docChange) => docChange.type == "removed")
    .map(async (docChange) => {
      console.log("deleting messages of chat: " + docChange.doc.id); 
      var messages = await docChange.doc.ref.collection("messages").listDocuments(); 
      var batch = db.batch(); 
      messages.forEach((doc) => batch.delete(doc)); 
      await batch.commit(); 

      console.log("deleting chatMedia of chat: " + docChange.doc.id); 
      try { 
        storageBucket.deleteFiles({
          prefix: "chatMedia/" + docChange.doc.id, 
        }); 
      } catch (e) {
        console.log("chatMedia not deleted"); 
      }
      console.log("deleting avatars of chat: " + docChange.doc.id); 
      try {
        storageBucket.deleteFiles({
          prefix: "avatars/" + docChange.doc.id, 
        }); 
      } catch (e) {
        console.log("avatars not deleted"); 
      }
    })
}); 

// delete groups that everyone left 
db.collection("chats").onSnapshot((snapshot) => {
  snapshot.docs.forEach(async (chatDoc) => {
    var chat = chatDoc.data(); 
    if (!(chat['isGroup'] as boolean)) return;

    var members = chat['members'] as string[]; 
    var admins = chat['admins'] as string[]; 
    if (members.length == 0 || admins.length == 0) {
      console.log("deleting group: " + chatDoc.id); 
      chatDoc.ref.delete(); 
    }
  }); 
})

// set userId on new contacts 
db.collection("users").onSnapshot((snapshot) => {
  snapshot.docs.forEach((userDoc) => {
    userDoc.ref.collection("contacts").onSnapshot((contactsSnapshot) => {
      contactsSnapshot.docChanges().filter((docChange) => docChange.type != "removed")
        .forEach(async (docChange) => {
          var phone = docChange.doc.id; 
          var userId; 
          try {
            userId = (await auth.getUserByPhoneNumber(phone)).uid; 
          } catch (e) {   // user does not exist 
            userId = null; 
          }
          docChange.doc.ref.update({
            userId: userId
          }); 
        }); 
    }); 
  });     
}); 


// send notificatons for new messages 
var subscribedChats = new Set(); 
db.collection("chats").onSnapshot((chatSnapshot) => {
  chatSnapshot.docs.forEach((chatDoc) => {
    if (subscribedChats.has(chatDoc.id)) return; 

    var messagesRef = chatDoc.ref.collection("messages"); 
    messagesRef.onSnapshot((messagesSnapshot) => {
      messagesSnapshot.docChanges().filter((docChange) => docChange.type == "added")
        .map((docChange) => sendNotificationsForMessage(chatDoc.ref, docChange.doc.ref)) 
    }); 
    subscribedChats.add(chatDoc.id); 
  })
}); 




/* HELPER FUNCTIONS */ 

async function getDisplayName(author: string, recipient: string) {
  var fromContacts = await db.collection("users").doc(recipient).collection("contacts")
    .where("userId", "==", author)
    .get(); 
  if (fromContacts.empty) {
    return (await db.collection("users").doc(author).get()).data()['displayName']; 
  } else {
    return fromContacts.docs.at(0).data()['name']; 
  }
}

async function deleteToken(userId: string, token: string) {
  console.log("deleting token: " + token + " for user: " + userId); 
  return db.collection("users").doc(userId).collection("tokens").doc(token).delete(); 
}

async function sendNotificationsForMessage(
    chatRef: admin.firestore.DocumentReference,
    msgRef: admin.firestore.DocumentReference, 
  ) {

  var msg = (await msgRef.get()).data();  
  var text = msg['text'] as string; 
  var author = msg['sentBy'] as string; 
  var seenBy = msg['seenBy'] as string[]; 

  var chat = (await chatRef.get()).data(); 
  var chatMembers = chat['members'] as string[]; 

  var recipients = chatMembers.filter((member) => member != author && !seenBy.includes(member)); 
  recipients.forEach(async (user) => {
    var tokenRefs = await db.collection("users").doc(user).collection("tokens").listDocuments(); 
    var tokens = tokenRefs.map((tokenRef) => {
      return tokenRef.id; 
    }); 
    if (!tokens.length) return; 
    var title = chat['title'] ?? await getDisplayName(author, user); 
    var message = {
      data: {
        chatId: chatRef.id, 
      }, 
      notification: {
        body: text, 
        title: title, 
      }, 
      tokens: tokens
    }; 
    var response = await fcm.sendMulticast(message); 
    var responses = response.responses; 
    for (var i = 0; i < responses.length; ++i) {
      var code = responses[i].error?.code; 
      console.log(code); 
      if (code == 'messaging/registration-token-not-registered') {
        deleteToken(user, tokens[i]); 
      }
    }
    if (response.successCount > 0) console.log("sent new notification to user: " + user); 
  }); 
}

