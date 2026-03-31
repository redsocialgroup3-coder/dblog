/// Modelo del perfil de usuario.
class UserProfile {
  final String? id;
  final String? email;
  final String? displayName;
  final String? address;
  final String? floorDoor;
  final String? municipality;
  final double calibrationOffset;
  final double dbThreshold;

  UserProfile({
    this.id,
    this.email,
    this.displayName,
    this.address,
    this.floorDoor,
    this.municipality,
    this.calibrationOffset = 0.0,
    this.dbThreshold = 65.0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String?,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      address: json['address'] as String?,
      floorDoor: json['floor_door'] as String?,
      municipality: json['municipality'] as String?,
      calibrationOffset:
          (json['calibration_offset'] as num?)?.toDouble() ?? 0.0,
      dbThreshold: (json['db_threshold'] as num?)?.toDouble() ?? 65.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (displayName != null) 'display_name': displayName,
      if (address != null) 'address': address,
      if (floorDoor != null) 'floor_door': floorDoor,
      if (municipality != null) 'municipality': municipality,
      'calibration_offset': calibrationOffset,
      'db_threshold': dbThreshold,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? address,
    String? floorDoor,
    String? municipality,
    double? calibrationOffset,
    double? dbThreshold,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      address: address ?? this.address,
      floorDoor: floorDoor ?? this.floorDoor,
      municipality: municipality ?? this.municipality,
      calibrationOffset: calibrationOffset ?? this.calibrationOffset,
      dbThreshold: dbThreshold ?? this.dbThreshold,
    );
  }
}
