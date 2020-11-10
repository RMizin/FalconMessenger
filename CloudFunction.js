'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp ({
    credential: admin.credential.applicationDefault(),
    databaseURL: 'https://your-DB-URL.firebaseio.com'
});


exports.fetchContacts = functions.https.onRequest((request, response) => {

    const preparedNumbers = request.body.data.preparedNumbers;
    var users = [];

   return Promise.all(preparedNumbers.map(preparedNumber => {
        return admin.database().ref('/users').orderByChild("phoneNumber").equalTo(preparedNumber).once('value').then(snapshot => {
            if (snapshot.exists()) {
                return snapshot.forEach((childSnap) => {
                    const uid = childSnap.key;
                    var userData = childSnap.val();
                    userData.id = uid;
                    users.push(userData);
                })
            }return null;
        })
    })).then(() => { 
        return Promise.all([response.send({data: users})]);
    }); 
});

exports.sendGroupMessage = functions.database.ref('/groupChats/{chatID}/userMessages/{messageID}').onCreate((snap, context) => {

    const chatID = context.params.chatID;
    const messageID = context.params.messageID;
    var lastMessageID = "";
    const senderID = snap.val();

    return admin.database().ref(`/groupChats/${chatID}/userMessages`).orderByKey().limitToLast(1).once('child_added').then(snapshot => {
      
        lastMessageID = snapshot.key;

       return admin.database().ref(`/groupChats/${chatID}/metaData/chatParticipantsIDs`).once('value').then(snapshot => {
            let members = Object.keys(snapshot.val());
           return members.forEach(function(memberID) {
              if (memberID !== senderID) {
                sendMessageToMember(memberID);
                incrementBadge(memberID);
                updateChatLastMessage(memberID);
              }
            });
        });
    });

    function sendMessageToMember(memberID) {
        let userMessagesReference = admin.database().ref(`/user-messages/${memberID}/${chatID}/userMessages`)
        userMessagesReference.update({
           [messageID] : senderID
        });
    }

    function updateChatLastMessage(memberID) {
        let userMessagesReference = admin.database().ref(`/user-messages/${memberID}/${chatID}/metaData`)
        userMessagesReference.update({
            "lastMessageID": lastMessageID
        });
    }

    function incrementBadge(memberID) {
        let badgeReference = admin.database().ref(`/user-messages/${memberID}/${chatID}/metaData/badge`)
        badgeReference.transaction(function (currentValue) {
            return (currentValue || 0) + 1;
        });
    }
});
