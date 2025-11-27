import 'package:flutter/material.dart';

// 가정된 파일 경로 (프로젝트 구조에 맞게 경로 확인 필요)
import '../../auth/widgets/bottom_nav.dart';
import '../data/shop_data.dart';
import '../models/shop_models.dart';

// ShopScreen을 StatefulWidget으로 변경하여 상태 관리가 가능하도록 합니다.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  // 현재 선택된 카테고리의 인덱스 (초기값: 0, "카페/음료")
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 배경 색상을 상수로 사용하거나 직접 입력합니다.
      backgroundColor: const Color(0xfffaf7ef),
      // BottomNav 위젯이 정의된 경로에 따라 import 경로를 확인하세요.
      bottomNavigationBar: const BottomNav(selectedIndex: 2),
      body: SafeArea( // 상단 노치 영역을 피하기 위해 SafeArea를 추가
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20), // 상단 여백
            // 1. 타이틀
            const Center(
              child: Text(
                "GuardPay 쇼핑",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 33,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ⭐ 2. 흰색 배경 정보 컨테이너 시작: 포인트, 멘트, 카테고리 포함 ⭐
            Container(
              width: double.infinity,
              color: Colors.white, // 배경색을 흰색으로 지정
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10), // 포인트 박스 위 여백

                  // 2-1. 포인트 박스
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                        )
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.monetization_on, color: Colors.amber),
                        SizedBox(width: 6),
                        Text(
                          "1300P",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2-2. 안내 멘트
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "금융 퀴즈 풀고\n모바일 상품권으로 교환하세요!",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const SizedBox(height: 10), // 카테고리 아래 여백
                ],
              ),
            ),
            // ⭐ 흰색 배경 정보 컨테이너 끝 ⭐

            // 2-3. 카테고리 메뉴
            SizedBox(
              height: 40,
              child: Row(
                // allCategories 리스트를 순회하며 동적으로 카테고리 위젯 생성
                children: List.generate(allCategories.length, (index) {
                  return _category(
                    allCategories[index].name, // 카테고리 이름
                    _selectedIndex == index,   // 선택 여부
                        () { // 탭 이벤트 시 상태 업데이트
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  );
                }),
              ),
            ),

            // 3. 상품 목록 (선택된 카테고리의 상품 리스트를 가져와 표시)
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
                children: allCategories[_selectedIndex].products.map((product) {
                  return _itemCard(product); // Product 모델을 인수로 전달
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // category 위젯 (밑줄이 있는 탭 메뉴)
  Widget _category(String text, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell( // 탭 영역을 지정하고 상호작용성 추가
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: selected ? 16 : 15,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: selected ? 35 : 0,
              color: selected ? Colors.black : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  // itemCard 위젯 (개별 상품 카드)
  Widget _itemCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        // ⭐ 텍스트 왼쪽 정렬 적용
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지를 가운데에 두기 위해 Center로 감쌉니다.
          Expanded(
            child: Center(
                child: Image.network(product.imgUrl, fit: BoxFit.contain)
            ),
          ),
          const SizedBox(height: 6),
          Text(product.brand, style: const TextStyle(color: Colors.grey, fontSize: 15)),
          Text(product.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            // Row가 필요한 최소한의 너비만 차지하도록 설정합니다. (옵션)
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘 크기를 텍스트 크기(20)에 맞게 설정
              const Icon(Icons.monetization_on, color: Colors.amber, size: 20.0),
              const SizedBox(width: 6), // 아이콘과 텍스트 사이의 간격
              Text(
                  product.price,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
              ),
            ],
          ),
        ],
      ),
    );
  }
}