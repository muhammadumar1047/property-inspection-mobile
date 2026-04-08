class LoginResponse {
  final bool success;
  final String message;
  final LoginData data;

  LoginResponse({required this.success, required this.message, required this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        success: json['success'],
        message: json['message'],
        data: LoginData.fromJson(json['data']),
      );
}

class LoginData {
  final String token;
  final UserModel user;

  LoginData({required this.token, required this.user});

  factory LoginData.fromJson(Map<String, dynamic> json) => LoginData(
        token: json['token'],
        user: UserModel.fromJson(json['user']),
      );
}

class UserModel {
  final String identityUserId;
  final String domainUserId;
  final String email;
  final String fullName;
  final String firstName;
  final String lastName;
  final bool isSuperAdmin;
  final bool isAgencyAdmin;
  final List<String> roles;
  final String agencyId;
  final String agencyName;
  final String? profileImage;

  UserModel({
    required this.identityUserId,
    required this.domainUserId,
    required this.email,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.isSuperAdmin,
    required this.isAgencyAdmin,
    required this.roles,
    required this.agencyId,
    required this.agencyName,
    this.profileImage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        identityUserId: json['identityUserId'],
        domainUserId: json['domainUserId'],
        email: json['email'],
        fullName: json['fullName'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        isSuperAdmin: json['isSuperAdmin'],
        isAgencyAdmin: json['isAgencyAdmin'],
        roles: List<String>.from(json['roles']),
        agencyId: json['agencyId'],
        agencyName: json['agencyName'],
        profileImage: json['profileImage'],
      );

  Map<String, dynamic> toJson() => {
        'identityUserId': identityUserId,
        'domainUserId': domainUserId,
        'email': email,
        'fullName': fullName,
        'firstName': firstName,
        'lastName': lastName,
        'isSuperAdmin': isSuperAdmin,
        'isAgencyAdmin': isAgencyAdmin,
        'roles': roles,
        'agencyId': agencyId,
        'agencyName': agencyName,
        'profileImage': profileImage,
      };
}
