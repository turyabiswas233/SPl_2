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
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
      deptName: json['deptName'] ?? '',
      hallName: json['hallName'] ?? '',
      gender: json['gender'] ?? '',
      verificationStatus: json['verificationStatus'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'registrationNumber': registrationNumber,
      'deptName': deptName,
      'hallName': hallName,
      'gender': gender,
      'verificationStatus': verificationStatus,
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
