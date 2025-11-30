import 'package:flutter/material.dart';
import 'package:guardpayfront/core/services/storage.dart';
import '../services/shop_service.dart';
import '../models/shop_models.dart';
import 'coupon_screen.dart';

class MyCouponScreen extends StatefulWidget {
  const MyCouponScreen({super.key});

  @override
  State<MyCouponScreen> createState() => _MyCouponScreenState();
}

class _MyCouponScreenState extends State<MyCouponScreen> {
  final ShopService _shopService = new ShopService();
  final _storage = AppStorage.storage;

  List<ExchangeHistoryItemModel> _history = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _accessToken;

  static const String _BASE_URL = 'http://10.0.2.2:8080';

  String _calculateDDay(String exchangedAt, String status, String? validUntil) {
    if (status == 'USED') {
      return '사용 완료';
    }
    if (status != 'USEABLE' || validUntil == null) {
      return '만료';
    }

    try {
      // 1. 유효 기간 파싱: 서버에서 받은 전체 문자열을 DateTime으로 파싱
      final expiryDateTime = DateTime.parse(validUntil);

      // 2. 날짜만 추출 (시간 정보를 00:00:00로 설정하여 UTC 기준으로 통일)
      // .toUtc()를 통해 시간대 영향을 제거하고, 날짜만 비교하도록 함
      final expiryDateOnly = DateTime.utc(expiryDateTime.year, expiryDateTime.month, expiryDateTime.day);

      // 3. 현재 날짜만 추출 (마찬가지로 UTC 기준 00:00:00로 통일)
      final now = DateTime.now().toUtc(); // 현재 시간을 UTC로 변환
      final todayDateOnly = DateTime.utc(now.year, now.month, now.day); // UTC 기준으로 날짜만 추출

      // 4. 날짜 차이 계산
      final remainingDays = expiryDateOnly.difference(todayDateOnly).inDays;

      if (remainingDays < 0) return '만료';

      // 유효 기간이 오늘까지라면 D-0으로 표시
      return 'D-$remainingDays';

    } catch (e) {
      print('날짜 파싱 오류: $e, validUntil: $validUntil');
      return '만료 (오류)'; // 파싱 오류 시 만료 처리
    }
  }

  void _navigateToDetail(ExchangeHistoryItemModel coupon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CouponScreen(coupon: coupon),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        setState(() {
          _errorMessage = '로그인 정보가 없습니다.';
          _isLoading = false;
        });
        return;
      }
      _accessToken = token;

      final fetchedHistory = await _shopService.getExchangeHistory(_accessToken!);

      if (mounted) {
        setState(() {

          _history = fetchedHistory.where((item) {
            if (item.status != 'USEABLE' || item.validUntil == null) {
              return false;
            }

            try {
              // D-Day 계산 로직과 동일하게 UTC 기반의 날짜만 비교
              final expiryDateTime = DateTime.parse(item.validUntil!);
              final expiryDateOnly = DateTime.utc(expiryDateTime.year, expiryDateTime.month, expiryDateTime.day);

              final now = DateTime.now().toUtc();
              final todayDateOnly = DateTime.utc(now.year, now.month, now.day);

              // 유효기간이 오늘(today)보다 같거나 미래여야 함
              return expiryDateOnly.isAfter(todayDateOnly) || expiryDateOnly.isAtSameMomentAs(todayDateOnly);

            } catch (e) {
              print('필터링 중 날짜 파싱 오류: $e');
              return false;
            }

          }).toList();

          // 만료일에 따라 정렬 (남은 일수가 적은 순)
          _history.sort((a, b) {
            final dDayA = int.tryParse(_calculateDDay(a.exchangedAt, a.status, a.validUntil).replaceFirst('D-', '')) ?? 999;
            final dDayB = int.tryParse(_calculateDDay(b.exchangedAt, b.status, b.validUntil).replaceFirst('D-', '')) ?? 999;
            return dDayA.compareTo(dDayB);
          });


          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          print('[log] >> [ERROR] 쿠폰 내역 조회 실패: ${e.toString()}');

          final errorDetail = e.toString().contains(':') ? e.toString().split(':')[1].trim() : e.toString();
          if (errorDetail.contains('type \'Null\'')) {
            _errorMessage = '내역 로드 실패: 서버 응답 데이터에 문제가 있습니다. (Null 값 오류)';
          } else {
            _errorMessage = '내역 로드 실패: $errorDetail';
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableCouponsCount = _history.length;

    return Scaffold(
      backgroundColor: const Color(0xfff7f2e9),
      appBar: AppBar(
        backgroundColor: const Color(0xfff7f2e9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- '내 쿠폰함' 제목 ---
            const SizedBox(height: 8),
            const Text(
              "내 쿠폰함",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "사용 가능한 쿠폰이 $availableCouponsCount개 있습니다.",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey,),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.redAccent),
          ),
        ),
      );
    }

    if (_history.isEmpty) {
      return const Center(
        child: Text("사용 가능한 교환 내역이 없습니다.", style: TextStyle(fontSize: 18, color: Colors.black54)),
      );
    }

    return GridView.builder(
      itemCount: _history.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemBuilder: (context, index) {
        final item = _history[index];
        return _buildHistoryItem(item);
      },
    );
  }

  Widget _buildHistoryItem(ExchangeHistoryItemModel item) {
    final dDay = _calculateDDay(item.exchangedAt, item.status, item.validUntil);
    final productName = item.productName;

    final String brandDisplay = item.brandName.isEmpty ? productName : item.brandName;

    final String imageUrl = item.thumbnail != null && !item.thumbnail!.startsWith('http')
        ? _BASE_URL + item.thumbnail!.replaceFirst('.', '') // './image' -> '/image'로 변환 후 결합
        : item.thumbnail ?? 'https://placehold.co/100x100/eeeeee/333333?text=NO+IMAGE';

    return GestureDetector(
      onTap: () => _navigateToDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: Align(
                alignment: Alignment.topRight, // 오른쪽 정렬로 변경
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: dDay.startsWith('D-') && int.tryParse(dDay.substring(2)) != null && int.parse(dDay.substring(2)) < 30
                        ? Colors.red[100] // 30일 미만
                        : const Color(0xffd9d9d9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dDay,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: dDay.startsWith('D-') && int.tryParse(dDay.substring(2)) != null && int.parse(dDay.substring(2)) < 30
                          ? Colors.red[900]
                          : Colors.black,
                    ),
                  ),
                ),
              ),
            ),

            // Image
            Expanded(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.redeem, size: 40, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                                brandDisplay,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
                            )
                          ]
                      )
                  );
                },
              ),
            ),

            const SizedBox(height: 4),

            // Brand (작은 글씨)
            Text(
              brandDisplay,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500),
            ),

            // Name (큰 글씨)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 2),
              child: Text(
                productName,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}