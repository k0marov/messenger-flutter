"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
exports.__esModule = true;
var admin = require("firebase-admin");
var serviceAccount = require("./serviceAccountKey.json");
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket: "messenger-in-flutter.appspot.com",
    databaseURL: "https://messenger-in-flutter-default-rtdb.firebaseio.com"
});
var fcm = admin.messaging();
var db = admin.firestore();
var storageBucket = admin.storage().bucket();
var auth = admin.auth();
// add user phone on account creation 
db.collection("users").onSnapshot(function (snapshot) {
    snapshot.docChanges().filter(function (docChange) { return docChange.type == "added"; })
        .forEach(function (docChange) { return __awaiter(void 0, void 0, void 0, function () {
        var newUserId, phone;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    newUserId = docChange.doc.id;
                    return [4 /*yield*/, auth.getUser(newUserId)];
                case 1:
                    phone = (_a.sent()).phoneNumber;
                    docChange.doc.ref.update({
                        'phone': phone
                    });
                    return [2 /*return*/];
            }
        });
    }); });
});
// delete messages, media and avatar of deleted chats 
db.collection("chats").onSnapshot(function (snapshot) {
    snapshot.docChanges().filter(function (docChange) { return docChange.type == "removed"; })
        .map(function (docChange) { return __awaiter(void 0, void 0, void 0, function () {
        var messages, batch;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    console.log("deleting messages of chat: " + docChange.doc.id);
                    return [4 /*yield*/, docChange.doc.ref.collection("messages").listDocuments()];
                case 1:
                    messages = _a.sent();
                    batch = db.batch();
                    messages.forEach(function (doc) { return batch["delete"](doc); });
                    return [4 /*yield*/, batch.commit()];
                case 2:
                    _a.sent();
                    console.log("deleting chatMedia of chat: " + docChange.doc.id);
                    try {
                        storageBucket.deleteFiles({
                            prefix: "chatMedia/" + docChange.doc.id
                        });
                    }
                    catch (e) {
                        console.log("chatMedia not deleted");
                    }
                    console.log("deleting avatars of chat: " + docChange.doc.id);
                    try {
                        storageBucket.deleteFiles({
                            prefix: "avatars/" + docChange.doc.id
                        });
                    }
                    catch (e) {
                        console.log("avatars not deleted");
                    }
                    return [2 /*return*/];
            }
        });
    }); });
});
// delete groups that everyone left 
db.collection("chats").onSnapshot(function (snapshot) {
    snapshot.docs.forEach(function (chatDoc) { return __awaiter(void 0, void 0, void 0, function () {
        var chat, members, admins;
        return __generator(this, function (_a) {
            chat = chatDoc.data();
            if (!chat['isGroup'])
                return [2 /*return*/];
            members = chat['members'];
            admins = chat['admins'];
            if (members.length == 0 || admins.length == 0) {
                console.log("deleting group: " + chatDoc.id);
                chatDoc.ref["delete"]();
            }
            return [2 /*return*/];
        });
    }); });
});
// set userId on new contacts 
db.collection("users").onSnapshot(function (snapshot) {
    snapshot.docs.forEach(function (userDoc) {
        userDoc.ref.collection("contacts").onSnapshot(function (contactsSnapshot) {
            contactsSnapshot.docChanges().filter(function (docChange) { return docChange.type != "removed"; })
                .forEach(function (docChange) { return __awaiter(void 0, void 0, void 0, function () {
                var phone, userId, e_1;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0:
                            phone = docChange.doc.id;
                            _a.label = 1;
                        case 1:
                            _a.trys.push([1, 3, , 4]);
                            return [4 /*yield*/, auth.getUserByPhoneNumber(phone)];
                        case 2:
                            userId = (_a.sent()).uid;
                            return [3 /*break*/, 4];
                        case 3:
                            e_1 = _a.sent();
                            userId = null;
                            return [3 /*break*/, 4];
                        case 4:
                            docChange.doc.ref.update({
                                userId: userId
                            });
                            return [2 /*return*/];
                    }
                });
            }); });
        });
    });
});
// send notificatons for new messages 
var subscribedChats = new Set();
db.collection("chats").onSnapshot(function (chatSnapshot) {
    chatSnapshot.docs.forEach(function (chatDoc) {
        if (subscribedChats.has(chatDoc.id))
            return;
        var messagesRef = chatDoc.ref.collection("messages");
        messagesRef.onSnapshot(function (messagesSnapshot) {
            messagesSnapshot.docChanges().filter(function (docChange) { return docChange.type == "added"; })
                .map(function (docChange) { return sendNotificationsForMessage(chatDoc.ref, docChange.doc.ref); });
        });
        subscribedChats.add(chatDoc.id);
    });
});
/* HELPER FUNCTIONS */
function getDisplayName(author, recipient) {
    return __awaiter(this, void 0, void 0, function () {
        var fromContacts;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, db.collection("users").doc(recipient).collection("contacts")
                        .where("userId", "==", author)
                        .get()];
                case 1:
                    fromContacts = _a.sent();
                    if (!fromContacts.empty) return [3 /*break*/, 3];
                    return [4 /*yield*/, db.collection("users").doc(author).get()];
                case 2: return [2 /*return*/, (_a.sent()).data()['displayName']];
                case 3: return [2 /*return*/, fromContacts.docs.at(0).data()['name']];
            }
        });
    });
}
function deleteToken(userId, token) {
    return __awaiter(this, void 0, void 0, function () {
        return __generator(this, function (_a) {
            console.log("deleting token: " + token + " for user: " + userId);
            return [2 /*return*/, db.collection("users").doc(userId).collection("tokens").doc(token)["delete"]()];
        });
    });
}
function sendNotificationsForMessage(chatRef, msgRef) {
    return __awaiter(this, void 0, void 0, function () {
        var msg, text, author, seenBy, chat, chatMembers, recipients;
        var _this = this;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, msgRef.get()];
                case 1:
                    msg = (_a.sent()).data();
                    text = msg['text'];
                    author = msg['sentBy'];
                    seenBy = msg['seenBy'];
                    return [4 /*yield*/, chatRef.get()];
                case 2:
                    chat = (_a.sent()).data();
                    chatMembers = chat['members'];
                    recipients = chatMembers.filter(function (member) { return member != author && !seenBy.includes(member); });
                    recipients.forEach(function (user) { return __awaiter(_this, void 0, void 0, function () {
                        var tokenRefs, tokens, title, _a, message, response, responses, i, code;
                        var _b, _c;
                        return __generator(this, function (_d) {
                            switch (_d.label) {
                                case 0: return [4 /*yield*/, db.collection("users").doc(user).collection("tokens").listDocuments()];
                                case 1:
                                    tokenRefs = _d.sent();
                                    tokens = tokenRefs.map(function (tokenRef) {
                                        return tokenRef.id;
                                    });
                                    if (!tokens.length)
                                        return [2 /*return*/];
                                    if (!((_b = chat['title']) !== null && _b !== void 0)) return [3 /*break*/, 2];
                                    _a = _b;
                                    return [3 /*break*/, 4];
                                case 2: return [4 /*yield*/, getDisplayName(author, user)];
                                case 3:
                                    _a = _d.sent();
                                    _d.label = 4;
                                case 4:
                                    title = _a;
                                    message = {
                                        data: {
                                            chatId: chatRef.id
                                        },
                                        notification: {
                                            body: text,
                                            title: title
                                        },
                                        tokens: tokens
                                    };
                                    return [4 /*yield*/, fcm.sendMulticast(message)];
                                case 5:
                                    response = _d.sent();
                                    responses = response.responses;
                                    for (i = 0; i < responses.length; ++i) {
                                        code = (_c = responses[i].error) === null || _c === void 0 ? void 0 : _c.code;
                                        console.log(code);
                                        if (code == 'messaging/registration-token-not-registered') {
                                            deleteToken(user, tokens[i]);
                                        }
                                    }
                                    if (response.successCount > 0)
                                        console.log("sent new notification to user: " + user);
                                    return [2 /*return*/];
                            }
                        });
                    }); });
                    return [2 /*return*/];
            }
        });
    });
}
