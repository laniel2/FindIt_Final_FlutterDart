class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String passwordHash;
  final String salt;
  final String studentId;
  final String course;
  final String phone;
  final String? avatarPath;
  final bool profileComplete;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.salt,
    this.studentId = '',
    this.course = '',
    this.phone = '',
    this.avatarPath,
    this.profileComplete = false,
  });

  AppUser copyWith({
    String? fullName,
    String? studentId,
    String? course,
    String? phone,
    String? avatarPath,
    bool? profileComplete,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      passwordHash: passwordHash,
      salt: salt,
      studentId: studentId ?? this.studentId,
      course: course ?? this.course,
      phone: phone ?? this.phone,
      avatarPath: avatarPath ?? this.avatarPath,
      profileComplete: profileComplete ?? this.profileComplete,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'passwordHash': passwordHash,
        'salt': salt,
        'studentId': studentId,
        'course': course,
        'phone': phone,
        'avatarPath': avatarPath,
        'profileComplete': profileComplete,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        fullName: j['fullName'] as String,
        email: j['email'] as String,
        passwordHash: j['passwordHash'] as String,
        salt: j['salt'] as String,
        studentId: (j['studentId'] ?? '') as String,
        course: (j['course'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        avatarPath: j['avatarPath'] as String?,
        profileComplete: (j['profileComplete'] ?? false) as bool,
      );
}
