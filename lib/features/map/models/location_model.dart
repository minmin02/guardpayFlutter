class LocationModel {
  final String address;
  final String? roadAddress;
  final double latitude;
  final double longitude;
  final String? placeName;
  final String? addressType;

  LocationModel({
    required this.address,
    this.roadAddress,
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.addressType,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      address: json['address'],
      roadAddress: json['roadAddress'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      placeName: json['placeName'],
      addressType: json['addressType'],
    );
  }

  // 표시할 주소 (도로명 우선)
  String get displayAddress => roadAddress ?? address;
}