class Device {
  final String id;
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final bool isMaster;
  final DateTime? lastActive;
  final DateTime createdAt;

  Device({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    this.isMaster = false,
    this.lastActive,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  String toString() {
    return 'Device{id: $id, deviceId: $deviceId, deviceName: $deviceName, deviceType: $deviceType, isMaster: $isMaster, lastActive: $lastActive, createdAt: $createdAt}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'device_name': deviceName,
      'device_type': deviceType,
      'is_master': isMaster ? 1 : 0,
      'last_active': lastActive?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      id: map['id'] as String,
      deviceId: map['device_id'] as String,
      deviceName: map['device_name'] as String,
      deviceType: map['device_type'] as String,
      isMaster: map['is_master'] == 1,
      lastActive: map['last_active'] != null
          ? DateTime.parse(map['last_active'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
