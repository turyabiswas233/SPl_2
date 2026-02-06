class UserModel {
  final String userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String registrationNumber;
  final String deptName;
  final String hallName;
  final String gender;
  final String verificationStatus;

  UserModel({
    this.userId = '',
    this.fullName = '',
    this.email = '',
    this.phoneNumber = '',
    this.registrationNumber = '',
    this.deptName = '',
    this.hallName = '',
    this.gender = '',
    this.verificationStatus = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      registrationNumber: json['registration_number'] ?? '',
      deptName: json['dept_name'] ?? '',
      hallName: json['hall_name'] ?? '',
      gender: json['gender'] ?? '',
      verificationStatus: json['verification_status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'registration_number': registrationNumber,
      'dept_name': deptName,
      'hall_name': hallName,
      'gender': gender,
      'verification_status': verificationStatus,
    };
  }

  bool get isEmpty => userId.isEmpty;

  @override
  String toString() {
    // TODO: implement toString
    return '{ \n\tuserId: $userId,\n\tfullName: $fullName,\n\temail: $email,\n\tphoneNumber: $phoneNumber,\n\tregistrationNumber: $registrationNumber,\n\tdeptName: $deptName,\n\thallName: $hallName,\n\tgender: $gender,\n\tverificationStatus: $verificationStatus\n}';
  }
}
