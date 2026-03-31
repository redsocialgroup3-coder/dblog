/// Tipo de veredicto legal.
enum VerdictType {
  /// El promedio supera el limite legal.
  supera,

  /// El promedio no supera el limite legal.
  noSupera,

  /// El promedio esta cercano al limite (dentro de 5 dB).
  cercano,
}

/// Resultado del veredicto legal tras una medicion.
class VerdictResult {
  final double limitDb;
  final double measuredDb;
  final double differenceDb;
  final VerdictType verdict;
  final String regulationName;
  final String? article;
  final String timePeriod;
  final String municipality;

  const VerdictResult({
    required this.limitDb,
    required this.measuredDb,
    required this.differenceDb,
    required this.verdict,
    required this.regulationName,
    this.article,
    required this.timePeriod,
    required this.municipality,
  });

  factory VerdictResult.fromJson(Map<String, dynamic> json) {
    return VerdictResult(
      limitDb: (json['limit_db'] as num).toDouble(),
      measuredDb: (json['measured_db'] as num).toDouble(),
      differenceDb: (json['difference_db'] as num).toDouble(),
      verdict: _parseVerdict(json['verdict'] as String),
      regulationName: json['regulation_name'] as String? ?? 'Normativa aplicable',
      article: json['article'] as String?,
      timePeriod: json['time_period_detected'] as String,
      municipality: json['municipality'] as String,
    );
  }

  static VerdictType _parseVerdict(String value) {
    switch (value) {
      case 'SUPERA':
        return VerdictType.supera;
      case 'CERCANO':
        return VerdictType.cercano;
      default:
        return VerdictType.noSupera;
    }
  }
}
