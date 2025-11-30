import 'package:flutter/material.dart';
import 'package:guardpayfront/core/services/storage.dart';
import '../../auth/widgets/bottom_nav.dart';
import '../services/shop_service.dart';
import '../models/shop_models.dart';
import '../widgets/purchase_dialog.dart';

const String kImageBaseUrl = 'http://10.0.2.2:8080';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ShopService _shopService = ShopService(); // 서비스 인스턴스
  final _storage = AppStorage.storage;

  String? _accessToken;
  bool _isLoadingToken = true;

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = true;
  String _errorMessage = '';

  int _userPoint = 0;

  final List<String> _categories = ["카페/음료", "편의점", "디저트", "외식"];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    final token = await _storage.read(key: 'accessToken');

    if (mounted) {
      setState(() {
        _accessToken = token;
        _isLoadingToken = false;
      });

      if (_accessToken != null) {
        _fetchData();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "로그인이 필요합니다.";
        });
      }
    }
  }

  Future<void> _fetchData() async {
    if (_accessToken == null) return;

    await Future.wait([
      _fetchProfile(),
      _fetchProducts(),
    ]);
  }

  Future<void> _fetchProfile() async {
    if (_accessToken == null) return; // 토큰 체크 추가
    try {
      final ProfileModel profile = await _shopService.getProfile(_accessToken!);

      if (mounted) {
        setState(() {
          _userPoint = profile.points;
        });
      }
    } catch (e) {
      print('프로필 로드 실패: ${e.toString()}');
    }
  }

  Future<void> _fetchProducts() async {
    if (_accessToken == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final List<ProductModel> fetchedProducts = await _shopService.getProducts();

      setState(() {
        _allProducts = fetchedProducts;
        _filterProductsByCategory(_selectedIndex);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '상품 로드 실패: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterProductsByCategory(int index) {
    final String selectedCategory = _categories[index];

    _filteredProducts = _allProducts
        .where((p) => p.category == selectedCategory)
        .toList();
  }

  Future<void> _exchangeProduct(int productId) async {
    if (_accessToken == null) return;

    try {
      final ExchangeResponseModel result =
      await _shopService.exchangeProduct(productId, _accessToken!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상품 교환 성공! 쿠폰 코드: ${result.couponCode}')),
      );
      _fetchData();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('교환 실패: ${e.toString().contains(':') ? e.toString().split(':')[1].trim() : '알 수 없는 오류'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingToken) {
      return const Scaffold(
        backgroundColor: Color(0xfffaf7ef),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_accessToken == null) {
      return const Scaffold(
        backgroundColor: Color(0xfffaf7ef),
        body: Center(
          child: Text(
            "GuardPay 쇼핑을 이용하려면 로그인이 필요합니다.",
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfffaf7ef),
      bottomNavigationBar: const BottomNav(selectedIndex: 2),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            // 1. 타이틀
            const Center(
              child: Text(
                "GuardPay 쇼핑",
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 33,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 15.0),
                  ),

                  Row(
                    children: [
                      const Spacer(),
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFFBBDAB4),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.amber),
                            const SizedBox(width: 10),
                            Text(
                              "$_userPoint",
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.only(left: 23),
                    child: Text(
                      "금융 퀴즈 풀고\n모바일 상품권으로 교환하세요!",
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ),


                  const SizedBox(height: 20),
                ],
              ),
            ),

            SizedBox(
              height: 40,
              child: Row(
                children: List.generate(_categories.length, (index) {
                  return _category(
                    _categories[index],
                    _selectedIndex == index,
                        () {
                      setState(() {
                        _selectedIndex = index;
                        _filterProductsByCategory(index);
                      });
                    },
                  );
                }),
              ),
            ),

            Expanded(
              child: _isLoading && _accessToken != null
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage))
                  : _filteredProducts.isEmpty
                  ? const Center(child: Text("현재 상품이 없습니다."))
                  : GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
                children: _filteredProducts.map((product) {
                  return _itemCard(product);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _category(String text, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                fontSize: selected ? 19 : 18,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 1.3,
              width: selected ? 70 : 0,
              color: selected ? Colors.black : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(ProductModel product) {
    String relativePath = product.thumbnail;
    if (relativePath.startsWith('./')) {
      relativePath = relativePath.substring(2);
    } else if (relativePath.startsWith('/')) {
      relativePath = relativePath.substring(1);
    }

    String fullImageUrl = '$kImageBaseUrl/$relativePath';
    String encodedUrl = Uri.encodeFull(fullImageUrl);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Image.network(
                encodedUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image_not_supported, size: 50, color: Colors.grey);
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(product.brand, style: const TextStyle(color: Colors.grey, fontSize: 15)),
          Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. 가격 표시
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 20.0),
                  const SizedBox(width: 6),
                  Text(
                      product.pricePoint.toString(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                ],
              ),

              // 2. 교환 버튼
              InkWell(
                onTap: () {
                  // 다이얼로그 띄우기
                  showPurchaseDialog(
                    context,
                    title: '상품을 교환할까요?',
                    content: '구매 후에는 환불 및 기간 연장이 불가합니다.',
                    onConfirm: () async {
                      await _exchangeProduct(product.id);
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "교환",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}