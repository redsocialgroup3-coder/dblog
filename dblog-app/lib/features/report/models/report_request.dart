/// Modelo que representa la solicitud de generación de un informe PDF.
class ReportRequest {
  /// IDs de las grabaciones a incluir en el informe.
  final List<String> recordingIds;

  /// Dirección del inmueble.
  final String address;

  /// Piso y puerta (opcional).
  final String? floorDoor;

  /// Tipo de zona: residencial, industrial, sanitario, educativo, etc.
  final String zoneType;

  /// Nombre del denunciante (opcional).
  final String? reporterName;

  const ReportRequest({
    required this.recordingIds,
    required this.address,
    this.floorDoor,
    required this.zoneType,
    this.reporterName,
  });

  /// Convierte a mapa JSON para enviar al API.
  Map<String, dynamic> toJson() => {
        'recording_ids': recordingIds,
        'address': address,
        if (floorDoor != null && floorDoor!.isNotEmpty) 'floor_door': floorDoor,
        'zone_type': zoneType,
        if (reporterName != null && reporterName!.isNotEmpty)
          'reporter_name': reporterName,
      };
}
