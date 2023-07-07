import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService{
  final String? uid;
  DatabaseService({this.uid});
//reference of the structure
final CollectionReference userCollection=FirebaseFirestore.instance.collection("users");
final CollectionReference groupCollection=FirebaseFirestore.instance.collection("groups");

  //updating the user data
  Future savingUserData(String fullname,String email) async{
    return await userCollection.doc(uid).set({
      "fullname":fullname,
      "email":email,
      "groups":[],
      "profilePic":"",
      "uid":uid,
    }
      
    );
  }
  Future gettingUserData(String email)async{
    QuerySnapshot snapshot=await userCollection.where("email",isEqualTo: email).get();
    return snapshot;  }
    //get a function to get user groups
    getUserGroups() async{
      return userCollection.doc(uid).snapshots();

    }
    //creating a group
    Future createGroup(String username,String id,String groupName) async{
      DocumentReference groupdocumentReference=await groupCollection.add({
        "groupName":groupName,
        "groupIcon":"",
        "admin":"${id}_$username",
        "members":[],
        "groupId":"",
        "recentMessage":"",
        "recentMessageSender":"",
      });
      await groupdocumentReference.update({
        "members":FieldValue.arrayUnion(["${uid}_$username"]),
        "groupId":groupdocumentReference.id,

      }
      );
      DocumentReference userDocumentReference=  userCollection.doc(uid);

      return userDocumentReference.update(
        {
          "groups":FieldValue.arrayUnion(["${groupdocumentReference.id}_$groupName"])
        }
      );


    }
    getChat(String groupId)async{
      return groupCollection.doc(groupId).collection("messages").orderBy("time").snapshots();
    }
    Future getGroupAdmin(String groupId)async
{
DocumentReference d=groupCollection.doc(groupId);
DocumentSnapshot documentSnapshot=await d.get();
return documentSnapshot["admin"];

}

getGroupMembers(String groupId)async{
  return groupCollection.doc(groupId).snapshots();
}

  // search
  searchByName(String groupName) {
    return groupCollection.where("groupName", isEqualTo: groupName).get();
  }
  Future<bool> isUserJoined(
      String groupName, String groupId, String userName) async {
    DocumentReference userDocumentReference = userCollection.doc(uid);
    DocumentSnapshot documentSnapshot = await userDocumentReference.get();

    List<dynamic> groups = await documentSnapshot['groups'];
    if (groups.contains("${groupId}_$groupName")) {
      return true;
    } else {
      return false;
    }
  }
 Future toggleGroupJoin(
      String groupId, String username, String groupName) async {
    // doc reference
    DocumentReference userDocumentReference = userCollection.doc(uid);
    DocumentReference groupDocumentReference = groupCollection.doc(groupId);

    DocumentSnapshot documentSnapshot = await userDocumentReference.get();
    List<dynamic> groups = await documentSnapshot['groups'];

    // if user has our groups -> then remove then or also in other part re join
    if (groups.contains("${groupId}_$groupName")) {
      await userDocumentReference.update({
        "groups": FieldValue.arrayRemove(["${groupId}_$groupName"])
      });
      await groupDocumentReference.update({
        "members": FieldValue.arrayRemove(["${uid}_$username"])
      });
    } else {
      await userDocumentReference.update({
        "groups": FieldValue.arrayUnion(["${groupId}_$groupName"])
      });
      await groupDocumentReference.update({
        "members": FieldValue.arrayUnion(["${uid}_$username"])
      });
    }
  }
  sendMessage(String groupId, Map<String, dynamic> chatMessageData) async {
    groupCollection.doc(groupId).collection("messages").add(chatMessageData);
    groupCollection.doc(groupId).update({
      "recentMessage": chatMessageData['message'],
      "recentMessageSender": chatMessageData['sender'],
      "recentMessageTime": chatMessageData['time'].toString(),
    });
  }
}

