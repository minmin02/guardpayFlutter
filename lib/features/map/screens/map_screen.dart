import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:guardpayfront/features/auth/widgets/bottom_nav.dart';
import 'package:guardpayfront/features/map/services/map_service.dart';
import 'package:guardpayfront/features/map/models/bank_model.dart';
import 'package:guardpayfront/features/map/widgets/IntegratedSearchBar.dart';
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapService _mapService = MapService();
  late WebViewController _webViewController;

  String _selectedBank = '신한은행';
  double? _myLat;
  double? _myLon;
  String? _myAddress;
  bool _isMapLoaded = false;
  bool _isSearching = false;
  int _foundBanksCount = 0;

  static const String _webViewUrl = 'http://10.0.2.2:8080/kakao-map.html';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => _checkMapLoaded(),
      ))
      ..loadRequest(Uri.parse(_webViewUrl));
  }

  Future<void> _checkMapLoaded() async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final result = await _webViewController.runJavaScriptReturningResult('typeof kakao !== "undefined"');
      if (result.toString() == 'true') setState(() => _isMapLoaded = true);
    } catch (e) {
      print('❌ Error checking Kakao SDK: $e');
    }
  }

  // ==================== ✅ 통합 검색 핸들러 ====================
  // IntegratedSearchBar에서 은행과 위치를 한 번에 받아서 처리
  Future<void> _handleIntegratedSearch(String bank, double lat, double lon, String address) async {
    if (!_isMapLoaded) {
      _showSnackBar('지도 로딩 중입니다.');
      return;
    }

    setState(() {
      _selectedBank = bank;
      _myLat = lat;
      _myLon = lon;
      _myAddress = address;
      _foundBanksCount = 0;
    });

    // 1. 지도 이동
    await _moveMapToLocation(lat, lon);

    // 2. 이동한 위치 주변의 은행 검색
    await _searchBanks();

    _showSnackBar('📍 $address ($bank) 검색 완료', isSuccess: true);
  }

  Future<void> _moveMapToLocation(double lat, double lon) async {
    await _webViewController.runJavaScript('''
      if (typeof map !== 'undefined') {
        var moveLatLon = new kakao.maps.LatLng($lat, $lon);
        map.setCenter(moveLatLon);
        if (typeof setMyLocation === 'function') setMyLocation($lat, $lon);
      }
    ''');
  }

  Future<void> _searchBanks() async {
    if (_myLat == null || _myLon == null) return;
    _setSearchingState(true);
    try {
      final banks = await _mapService.searchBanks(_selectedBank, _myLat!, _myLon!);
      _handleBankSearchResult(banks);
    } catch (e) {
      _showSnackBar('은행 정보 로딩 실패', isError: true);
    } finally {
      _setSearchingState(false);
    }
  }

  void _handleBankSearchResult(List<BankModel> banks) {
    setState(() => _foundBanksCount = banks.length);
    _webViewController.runJavaScript('if(typeof clearBankMarkers === "function") clearBankMarkers();');

    if (banks.isEmpty) {
      _showSnackBar('주변 5km 이내에 $_selectedBank 지점이 없습니다.', isWarning: true);
    } else {
      for (var bank in banks) {
        final jsCode = '''
          if(typeof addBankMarker === "function") {
            addBankMarker(${bank.lat}, ${bank.lon}, "${bank.fullName}", "${bank.roadAddress ?? bank.address}");
          }
        ''';
        _webViewController.runJavaScript(jsCode);
      }
    }
  }

  void _setSearchingState(bool isSearching) => setState(() => _isSearching = isSearching);

  void _showSnackBar(String message, {bool isSuccess = false, bool isWarning = false, bool isError = false}) {
    if (!mounted) return;
    Color color = Colors.grey[800]!;
    if (isSuccess) color = Colors.green;
    if (isWarning) color = Colors.orange;
    if (isError) color = Colors.red;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (!_isMapLoaded) const Center(child: CircularProgressIndicator()),
          if (_isSearching)
            Container(
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator())
            ),

          // ✅ [수정됨] 통합 검색바 하나만 배치
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: IntegratedSearchBar(
              initialBank: _selectedBank,
              onSearchCompleted: _handleIntegratedSearch,
            ),
          ),

          // 하단 정보 카드
          if (_myLat != null && _myLon != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(children: [
                        const Icon(Icons.location_on, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_myAddress ?? '', overflow: TextOverflow.ellipsis)),
                      ]),
                      if (_foundBanksCount > 0) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.account_balance, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text('$_selectedBank: $_foundBanksCount개 발견', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                      ]
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const BottomNav(selectedIndex: 4),
    );
  }
}