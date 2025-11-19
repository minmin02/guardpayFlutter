// import 'package:flutter/material.dart';
// import 'package:guardpayfront/features/map/services/map_service.dart';
// import 'package:guardpayfront/features/map/models/location_model.dart';
//
// class LocationSearchBar extends StatefulWidget {
//   final Function(double lat, double lon, String address) onLocationSelected;
//   final String? selectedBank; // ✅ 부모(MapScreen)로부터 은행 이름을 받습니다.
//
//   const LocationSearchBar({
//     super.key,
//     required this.onLocationSelected,
//     this.selectedBank,
//   });
//
//   @override
//   State<LocationSearchBar> createState() => _LocationSearchBarState();
// }
//
// class _LocationSearchBarState extends State<LocationSearchBar> {
//   final TextEditingController _searchController = TextEditingController();
//   final MapService _mapService = MapService();
//   final FocusNode _focusNode = FocusNode();
//
//   List<LocationModel> _searchResults = [];
//   bool _isSearching = false;
//   bool _showResults = false;
//
//   // ✅ 은행이 바뀌면 검색 로직을 다시 수행할 수 있도록 감지
//   @override
//   void didUpdateWidget(LocationSearchBar oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.selectedBank != widget.selectedBank) {
//       // 은행이 바뀌었고, 검색창에 텍스트가 있다면 즉시 재검색 수행
//       if (_searchController.text.isNotEmpty) {
//         _searchAddress(_searchController.text);
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     _focusNode.dispose();
//     super.dispose();
//   }
//
//   /// 주소 검색
//   Future<void> _searchAddress(String query) async {
//     if (query.trim().isEmpty) {
//       setState(() {
//         _searchResults = [];
//         _showResults = false;
//       });
//       return;
//     }
//
//     setState(() {
//       _isSearching = true;
//       _showResults = true;
//     });
//
//     try {
//       // ✅ [요구사항 1 해결] 검색어 조합 로직
//       // 입력값: "강남" + 선택된 은행: "국민은행" -> 최종검색어: "강남 국민은행"
//       // 이렇게 보내면 백엔드가 카카오 API에 "강남 국민은행" + "BK9(은행코드)"로 요청합니다.
//       String finalQuery = query;
//       if (widget.selectedBank != null && widget.selectedBank!.isNotEmpty) {
//         finalQuery = "$query ${widget.selectedBank}";
//       }
//
//       print("🔎 검색 요청(조합됨): $finalQuery");
//
//       final results = await _mapService.searchAddressList(finalQuery);
//
//       setState(() {
//         _searchResults = results;
//         _isSearching = false;
//       });
//     } catch (e) {
//       print('❌ 주소 검색 에러: $e');
//       setState(() {
//         _searchResults = [];
//         _isSearching = false;
//       });
//     }
//   }
//
//   /// 주소 선택
//   void _selectAddress(LocationModel location) {
//     // 선택 시 텍스트창은 깔끔하게 장소명으로 표시
//     _searchController.text = location.placeName ?? location.address;
//
//     setState(() {
//       _showResults = false;
//       _searchResults = [];
//     });
//
//     _focusNode.unfocus();
//
//     // ✅ [요구사항 2 해결] 부모(MapScreen)에게 좌표를 전달하여 지도 이동 트리거
//     widget.onLocationSelected(
//       location.latitude,
//       location.longitude,
//       location.displayAddress,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // 검색 입력 필드
//         Card(
//           elevation: 4,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             child: Row(
//               children: [
//                 const Icon(Icons.search, color: Colors.grey),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: TextField(
//                     controller: _searchController,
//                     focusNode: _focusNode,
//                     decoration: InputDecoration(
//                       // 힌트 텍스트를 동적으로 변경하여 현재 어떤 은행을 검색하는지 알려줌
//                       hintText: widget.selectedBank != null
//                           ? '${widget.selectedBank} 위치 검색 (예: 강남)'
//                           : '지역 검색 (예: 서울 강남구)',
//                       border: InputBorder.none,
//                     ),
//                     onChanged: (value) {
//                       if (value.length >= 2) {
//                         _searchAddress(value);
//                       } else {
//                         setState(() {
//                           _showResults = false;
//                           _searchResults = [];
//                         });
//                       }
//                     },
//                     onSubmitted: (value) {
//                       if (_searchResults.isNotEmpty) {
//                         _selectAddress(_searchResults[0]);
//                       }
//                     },
//                   ),
//                 ),
//                 if (_isSearching)
//                   const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
//                 else if (_searchController.text.isNotEmpty)
//                   IconButton(
//                     icon: const Icon(Icons.clear, size: 20),
//                     onPressed: () {
//                       _searchController.clear();
//                       setState(() {
//                         _showResults = false;
//                         _searchResults = [];
//                       });
//                     },
//                   ),
//               ],
//             ),
//           ),
//         ),
//
//         // 검색 결과 드롭다운 (기존 로직 유지)
//         if (_showResults && _searchResults.isNotEmpty)
//           Container(
//             margin: const EdgeInsets.only(top: 4),
//             constraints: const BoxConstraints(maxHeight: 300),
//             child: Card(
//               elevation: 4,
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: _searchResults.length,
//                 itemBuilder: (context, index) {
//                   final location = _searchResults[index];
//                   return ListTile(
//                     dense: true,
//                     leading: const Icon(Icons.location_on, color: Colors.blue, size: 20),
//                     title: Text(
//                       location.placeName ?? location.address,
//                       style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Text(
//                       location.address,
//                       style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                     ),
//                     onTap: () => _selectAddress(location),
//                   );
//                 },
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }