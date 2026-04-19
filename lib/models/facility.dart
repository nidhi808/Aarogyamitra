class Facility {
  final String id;
  final String nameEn;
  final String nameHi;
  final String nameMr;
  final double lat;
  final double lng;
  final String type;

  Facility({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.nameMr,
    required this.lat,
    required this.lng,
    required this.type,
  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      id: json['id'],
      nameEn: json['name_en'],
      nameHi: json['name_hi'],
      nameMr: json['name_mr'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      type: json['type'],
    );
  }

  String getName(String lang) {
    if (lang == 'hi') return nameHi;
    if (lang == 'mr') return nameMr;
    return nameEn;
  }
}
