class IdCardInfo {
  final String? registrationNumber;
  final String? department;
  final String? hall;
  final String? name;
  final String? session;

  IdCardInfo({
    this.registrationNumber,
    this.name,
    this.department,
    this.hall,
    this.session,
  });

  bool get hasData =>
      registrationNumber != null ||
      name != null ||
      hall != null ||
      session != null;

  @override
  String toString() {
    return 'IdCardInfo(registration: $registrationNumber, department: $department, hall: $hall, name: $name, session: $session)';
  }
}
