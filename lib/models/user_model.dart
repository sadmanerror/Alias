import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends Equatable {
  final String uid;
  final String username;
  final String email;
  final String? photoUrl;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final bool isOnline;

  const UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl,
    this.fcmToken,
    required this.createdAt,
    this.lastSeen,
    required this.isOnline,
  });

  factory UserModel.empty() {
    return UserModel(
      uid: '',
      username: '',
      email: '',
      createdAt: DateTime.now(),
      isOnline: false,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserModel(
      uid: data['uid'] as String? ?? doc.id,
      username: data['username'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      fcmToken: data['fcmToken'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      isOnline: data['isOnline'] as bool? ?? false,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String? ?? '',
      username: data['username'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      fcmToken: data['fcmToken'] as String?,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      lastSeen: data['lastSeen'] is Timestamp 
          ? (data['lastSeen'] as Timestamp).toDate() 
          : null,
      isOnline: data['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isOnline': isOnline,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel.fromMap(json);

  Map<String, dynamic> toMap() => toFirestore();

  String get id => uid;
  String? get profileUrl => photoUrl;
  String? get profilePicUrl => photoUrl;

  UserModel copyWith({
    String? uid,
    String? username,
    String? email,
    String? photoUrl,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        username,
        email,
        photoUrl,
        fcmToken,
        createdAt,
        lastSeen,
        isOnline,
      ];
}
