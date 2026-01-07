class UserModel {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? displayName;

  UserModel({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.displayName,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      displayName: map['displayName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
    };
  }
}
