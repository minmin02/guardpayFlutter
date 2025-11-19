import 'package:flutter/material.dart';
import 'package:guardpayfront/features/map/services/map_service.dart';
import 'package:guardpayfront/features/map/models/location_model.dart';

class IntegratedSearchBar extends StatefulWidget {
  final String initialBank;
  final Function(String bank, double lat, double lon, String address) onSearchCompleted;

  const IntegratedSearchBar({
    super.key,
    required this.initialBank,
    required this.onSearchCompleted,
  });

  @override
  State<IntegratedSearchBar> createState() => _IntegratedSearchBarState();
}

class _IntegratedSearchBarState extends State<IntegratedSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final MapService _mapService = MapService();
  final FocusNode _focusNode = FocusNode();

  late String _selectedBank;
  List<LocationModel> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _selectedBank = widget.initialBank;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 주소 검색 API 호출
  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    try {
      // 입력된 지역명 + 선택된 은행명으로 검색 (예: "강남 신한은행")
      final finalQuery = "$query $_selectedBank";
      print("🔎 통합 검색 요청: $finalQuery");

      final results = await _mapService.searchAddressList(finalQuery);

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('❌ 검색 에러: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  /// 검색 결과 선택 시 처리
  void _selectLocation(LocationModel location) {
    _searchController.text = location.placeName ?? location.address;

    setState(() {
      _showResults = false;
      _searchResults = [];
    });
    _focusNode.unfocus();

    // ✅ 부모에게 [은행, 위도, 경도, 주소] 모두 전달
    widget.onSearchCompleted(
      _selectedBank,
      location.latitude,
      location.longitude,
      location.displayAddress,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔹 통합 검색바 (Card 하나에 Row로 배치)
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // 1. 은행 선택 드롭다운 (왼쪽)
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBank,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedBank = newValue;
                        });
                        // 은행을 바꾸면, 현재 입력된 주소로 즉시 재검색 가능
                        if (_searchController.text.isNotEmpty) {
                          _searchAddress(_searchController.text);
                        }
                      }
                    },
                    items: [
                      '신한은행', '국민은행', '우리은행', '하나은행', 'NH농협은행',
                      '기업은행', '부산은행', '대구은행', '경남은행', '광주은행',
                      '전북은행', '제주은행', '카카오뱅크', '케이뱅크', '토스뱅크'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),

                // 구분선
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),

                // 2. 주소 입력 필드 (오른쪽 확장)
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      hintText: '지역 검색 (예: 강남구)',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      if (value.length >= 2) _searchAddress(value);
                    },
                    onSubmitted: (value) {
                      if (_searchResults.isNotEmpty) {
                        _selectLocation(_searchResults[0]);
                      }
                    },
                  ),
                ),

                // 3. 검색 아이콘 또는 로딩바
                if (_isSearching)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.blue),
                    onPressed: () {
                      if (_searchController.text.isNotEmpty) {
                        _searchAddress(_searchController.text);
                      }
                    },
                  ),
              ],
            ),
          ),
        ),

        // 🔹 자동완성 결과 목록 (검색바 바로 아래 표시)
        if (_showResults && _searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 300),
            child: Card(
              elevation: 4,
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final location = _searchResults[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place, size: 18, color: Colors.grey),
                    title: Text(
                      location.placeName ?? location.address,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      location.address,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    onTap: () => _selectLocation(location),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}