// 상품 데이터 모델
class Product {
  final String brand;
  final String name;
  final String price;
  final String imgUrl;

  const Product({
    required this.brand,
    required this.name,
    required this.price,
    required this.imgUrl,
  });
}

// 카테고리 데이터 모델
class ProductCategory {
  final String name;
  final List<Product> products;

  const ProductCategory({
    required this.name,
    required this.products,
  });
}