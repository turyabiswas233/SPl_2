import 'package:dromos/utils/colors.dart';
import 'package:flutter/material.dart';

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

  bool get isVerified => verificationStatus.toLowerCase() == 'verified';
  bool get isEmpty => userId.isEmpty;  

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

  CircleAvatar avatar({double? size = 50}) {
    String initials = fullName.isNotEmpty
        ? fullName.trim().split(' ').map((e) => e[0]).take(2).join()
        : '?';

    const Color maleColor = ConstColor.maleColor;
    const Color femaleColor = ConstColor.femaleColor;
    Color genderColor = gender.toLowerCase() == 'male'
        ? maleColor
        : femaleColor;
    return CircleAvatar(
      radius: size!,
      backgroundColor: genderColor.withAlpha(150),
      child: Text(
        initials,
        style: TextStyle(fontSize: size * 0.9, color: Colors.white),
      ),
    );
  }

  Widget get verificationTag {
    bool isVerified = verificationStatus.toLowerCase() == 'verified';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isVerified
            ? Colors.greenAccent.withAlpha(50)
            : Colors.orange.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isVerified ? 'Verified' : 'Unverified',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isVerified ? Colors.green: Colors.orange.shade700,
        ),
      ),
    );
  }


  @override
  String toString() {
    // implement toString
    return '{ \n\tuserId: $userId,\n\tfullName: $fullName,\n\temail: $email,\n\tphoneNumber: $phoneNumber,\n\tregistrationNumber: $registrationNumber,\n\tdeptName: $deptName,\n\thallName: $hallName,\n\tgender: $gender,\n\tverificationStatus: $verificationStatus\n}';
  }
}
