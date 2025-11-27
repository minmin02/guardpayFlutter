import '../models/shop_models.dart';

// 상품 목록 데이터 정의
final List<Product> _cafeProducts = [
  const Product(brand: "스타벅스", name: "아메리카노(ice)", price: "20,000P", imgUrl: "https://i.ibb.co/0jF5yPt/coffee1.png"),
  const Product(brand: "컴포즈커피", name: "그린티라떼(ice)", price: "20,000P", imgUrl: "https://i.ibb.co/tJcZnfw/coffee2.png"),
  const Product(brand: "스타벅스", name: "콜드브루", price: "20,000P", imgUrl: "https://i.ibb.co/0jF5yPt/coffee1.png"),
  const Product(brand: "스타벅스", name: "라떼", price: "20,000P", imgUrl: "https://i.ibb.co/jfmVY2H/latte.png"),
];

final List<Product> _convenienceStoreProducts = [
  const Product(brand: "GS25", name: "바나나우유", price: "1,500P", imgUrl: "https://example.com/gs25.png"),
  const Product(brand: "CU", name: "삼각김밥", price: "1,200P", imgUrl: "https://example.com/cu.png"),
];

final List<Product> _lifeCultureProducts = [
  const Product(brand: "CGV", name: "영화 예매권", price: "12,000P", imgUrl: "https://example.com/cgv.png"),
  const Product(brand: "올리브영", name: "기프트카드", price: "10,000P", imgUrl: "https://example.com/oliveyoung.png"),
];

final List<Product> _dessertProducts = [
  const Product(brand: "베스킨라빈스", name: "파인트", price: "8,000P", imgUrl: "https://example.com/br.png"),
  const Product(brand: "파리바게뜨", name: "교환권", price: "5,000P", imgUrl: "https://example.com/pb.png"),
];

// 전체 카테고리 리스트 (ShopScreen에서 사용)
final List<ProductCategory> allCategories = [
  ProductCategory(name: "카페/음료", products: _cafeProducts),
  ProductCategory(name: "편의점", products: _convenienceStoreProducts),
  ProductCategory(name: "생활/문화", products: _lifeCultureProducts),
  ProductCategory(name: "디저트", products: _dessertProducts),
];