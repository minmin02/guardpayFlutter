import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/shop_models.dart';

class CouponScreen extends StatelessWidget {
  final ExchangeHistoryItemModel coupon;
  static const String _BASE_URL = 'http://10.0.2.2:8080';

  CouponScreen({super.key, required this.coupon});

  // YYYY년 MM월 DD일 형식으로 날짜를 포맷팅하는 유틸리티 함수
  String _formatDate(String? isoDateString) {
    if (isoDateString == null) return "정보 없음";
    try {
      // YYYY-MM-DDTHH:mm:ss.SSSZ 형식일 경우 T 이전까지만 파싱
      final datePart = isoDateString.split('T')[0];
      final parts = datePart.split('-');
      if (parts.length == 3) {
        return '${parts[0]}년 ${parts[1]}월 ${parts[2]}일';
      }
      return isoDateString;
    } catch (e) {
      return "날짜 오류";
    }
  }

  String _generateMockOrderNumber(int exchangeId) {
    return (100000000 + exchangeId * 13 % 900000000).toString().substring(0, 9);
  }

  // 이미지 URL 조합 함수 추가
  String _buildImageUrl(String? thumbnail) {
    if (thumbnail == null) {
      return 'https://placehold.co/150x150/eeeeee/333333?text=NO+IMAGE';
    }
    final relativePath = thumbnail.replaceFirst('.', '');
    final fullUrl = _BASE_URL + relativePath;

    return Uri.encodeFull(fullUrl);
  }


  @override
  Widget build(BuildContext context) {
    // 쿠폰 정보 추출

    // 상품명을 분리하지 않고, 서버에서 받은 정확한 brandName을 사용합니다.
    final brandDisplay = coupon.brandName.isNotEmpty
        ? coupon.brandName
        : coupon.productName.split(' - ')[0]; // brandName이 비어있다면, 기존 로직으로 분리 시도

    final productName = coupon.productName; // 상품명은 그대로 사용

    // couponCode가 null이면 임의의 바코드 값을 사용
    final barcodeValue = coupon.couponCode ?? '614141999996';

    // validUntil이 null이면 임시 유효 기간을 사용
    final validUntilDate = _formatDate(coupon.validUntil ?? '2025-12-31T00:00:00Z');

    // 이미지 URL 생성
    final imageUrl = _buildImageUrl(coupon.thumbnail);


    return Scaffold(
      backgroundColor: const Color(0xfff7f2e9), // 배경색
      appBar: AppBar(
        backgroundColor: const Color(0xfff7f2e9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
            width: 360,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. 상품 이미지
                Container(
                  height: 150,
                  width: 150,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                          child: Text(
                              brandDisplay,
                              style: const TextStyle(fontSize: 30, color: Colors.grey)
                          )
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // 2. 브랜드 및 상품명
                Text(
                  brandDisplay,
                  style: const TextStyle(fontSize: 17, color: Colors.grey),
                ),
                Text(
                  productName,
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 45),

                // 3. 바코드
                BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: barcodeValue,
                  width: double.infinity,
                  height: 80,
                  style: const TextStyle(letterSpacing: 2),
                ),
                const SizedBox(height: 35),

                // 4. 상세 정보 표
                _buildInfoRow('교환처', brandDisplay),
                _buildInfoRow('유효 기간', validUntilDate),
                _buildInfoRow('주문 번호', _generateMockOrderNumber(coupon.exchangeId)),

                const SizedBox(height: 30),

                // 5. 사용 버튼
                ElevatedButton(
                  onPressed: () {
                    // 쿠폰 코드 복사 기능
                    Clipboard.setData(ClipboardData(text: barcodeValue));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('쿠폰 코드가 클립보드에 복사되었습니다!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('쿠폰 코드 복사', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 상세 정보 표 Row 위젯
  Widget _buildInfoRow(String title, String value) {
    return Column(
      children: [
        Divider(color: Colors.grey[200], height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}