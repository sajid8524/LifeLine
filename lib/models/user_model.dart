class UserModel {
  const UserModel({
    required this.userId,
    required this.displayName,
    required this.isRescueNode,
  });

  final String userId;
  final String displayName;
  final bool isRescueNode;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'isRescueNode': isRescueNode,
    };
  }
}
