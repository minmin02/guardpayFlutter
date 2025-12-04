class BankModel {
  final int id;
  final String name;           // 은행명
  final String branchName;     // 지점명
  final String fullName;       // 전체명
  final String address;        // 지번 주소
  final String? roadAddress;   // 도로명 주소
  final double lat;
  final double lon;
  final String? phoneNumber;
  final String? businessHours;
  final double? distance;      // 거리(m)
  final String? distanceText;  // 거리 텍스트

  BankModel({
    required this.id,
    required this.name,
    required this.branchName,
    required this.fullName,
    required this.address,
    this.roadAddress,
    required this.lat,
    required this.lon,
    this.phoneNumber,
    this.businessHours,
    this.distance,
    this.distanceText,
  });

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      id: json['id'],
      name: json['name'],
      branchName: json['branchName'] ?? '',
      fullName: json['fullName'] ?? '${json['name']} ${json['branchName'] ?? ''}',
      address: json['address'],
      roadAddress: json['roadAddress'],
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      phoneNumber: json['phoneNumber'],
      businessHours: json['businessHours'],
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      distanceText: json['distanceText'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'branchName': branchName,
      'fullName': fullName,
      'address': address,
      'roadAddress': roadAddress,
      'lat': lat,
      'lon': lon,
      'phoneNumber': phoneNumber,
      'businessHours': businessHours,
      'distance': distance,
      'distanceText': distanceText,
    };
  }
}