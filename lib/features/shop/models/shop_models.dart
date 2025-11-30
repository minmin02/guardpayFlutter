class ProductModel {
  final int id;
  final String brand;
  final String name;
  final String category;
  final int pricePoint;
  final String thumbnail;

  ProductModel({
    required this.id,
    required this.brand,
    required this.name,
    required this.category,
    required this.pricePoint,
    required this.thumbnail,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] as num).toInt(),
      brand: json['brand'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      pricePoint: (json['pricePoint'] as num).toInt(),
      thumbnail: json['thumbnail'] as String,
    );
  }
}

// 1. ProfileModel (상세 모델)
class ProfileModel {
  final int points;
  final String? profileImageUrl;
  final String? grade;
  final String? status;
  final String? provider;

  ProfileModel({
    required this.points,
    this.profileImageUrl,
    this.grade,
    this.status,
    this.provider,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      points: (json['points'] as num).toInt(),
      profileImageUrl: json['profileImageUrl'] as String?,
      grade: json['grade'] as String?,
      status: json['status'] as String?,
      provider: json['provider'] as String?,
    );
  }
}

// 2. ExchangeResponseModel (상품 교환 응답)
class ExchangeResponseModel {
  final int productId;
  final String brand;
  final String name;
  final String thumbnail;
  final String couponCode;
  final String validUntil;

  ExchangeResponseModel({
    required this.productId,
    required this.brand,
    required this.name,
    required this.thumbnail,
    required this.couponCode,
    required this.validUntil,
  });

  factory ExchangeResponseModel.fromJson(Map<String, dynamic> json) {
    return ExchangeResponseModel(
      productId: (json['productId'] as num).toInt(),
      brand: json['brand'] as String,
      name: json['name'] as String,
      thumbnail: json['thumbnail'] as String,
      couponCode: json['couponCode'] as String,
      validUntil: json['validUntil'] as String,
    );
  }
}

// 3. ExchangeHistoryItemModel (교환 내역 조회 항목)
class ExchangeHistoryItemModel {
  final int exchangeId;
  final String productName;
  final String brandName;
  final int pointsUsed;
  final String status;
  final String exchangedAt;
  final String? couponCode;
  final String? validUntil;
  final String? thumbnail;

  ExchangeHistoryItemModel({
    required this.exchangeId,
    required this.productName,
    required this.brandName,
    required this.pointsUsed,
    required this.status,
    required this.exchangedAt,
    this.couponCode,
    this.validUntil,
    this.thumbnail,
  });

  factory ExchangeHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return ExchangeHistoryItemModel(
      exchangeId: (json['exchangeId'] as num).toInt(),
      productName: json['productName'] as String? ?? '상품명 정보 없음',
      brandName: json['brandName'] as String? ?? '브랜드 정보 없음',
      pointsUsed: (json['pointsUsed'] as num).toInt(),
      status: json['status'] as String,
      exchangedAt: json['exchangedAt'] as String,
      couponCode: json['couponCode'] as String?,
      validUntil: json['validUntil'] as String?,
      thumbnail: json['thumbnail'] as String?,
    );
  }
}