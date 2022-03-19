class UserModel {
  final String displayName;
  final String? username; 
  final int color; 
  final String phone; 
  final String userId; 

  const UserModel({
    required this.displayName, 
    required this.color, 
    required this.phone, 
    required this.userId, 
    this.username, 
  }); 

  UserModel.fromJson(Map<String, dynamic> json, String userId) : this(
    userId: userId, 

    displayName: json['displayName'] as String, 
    color: json['color'] as int, 
    phone: json['phone'] as String, 
    username: json['username'] as String?, 
  ); 

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'color': color, 
    'phone': phone, 
    'username': username, 
  }; 
}