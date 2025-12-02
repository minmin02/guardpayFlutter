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

  // ============================
  // 🚀 WebView 초기 설정
  // ============================
  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)

    // 🔥 핵심: kakaomap:// 앱 스킴 차단!
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;

            // 앱 스킴 차단
            if (url.startsWith("kakaomap://")) {
              print("🚫 카카오 앱 스킴 차단: $url");
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            await Future.delayed(const Duration(milliseconds: 300));
            setState(() => _isMapLoaded = true);
          },
        ),
      )
      ..loadRequest(Uri.parse(_webViewUrl));
  }

  // ============================
  // 🔎 통합 검색 완료 처리
  // ============================
  Future<void> _handleIntegratedSearch(String bank, double lat, double lon,
      String address) async {
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

    // 지도 이동
    await _moveMapToLocation(lat, lon);

    // 백엔드 검색 (기능 유지)
    await _searchBanks();

    // 카카오 키워드 검색 (선택 은행)
    await _webViewController.runJavaScript(
      "searchBankByKeyword('${bank}');",
    );

    _showSnackBar('📍 $address ($bank) 검색 완료', isSuccess: true);
  }

  // ============================
  // 지도 이동
  // ============================
  Future<void> _moveMapToLocation(double lat, double lon) async {
    await _webViewController.runJavaScript('''
      if (typeof map !== 'undefined') {
        var pos = new kakao.maps.LatLng($lat, $lon);
        map.setCenter(pos);
      }
    ''');
  }

  // ============================
  // 백엔드 은행 검색 (기존 기능 유지)
  // ============================
  Future<void> _searchBanks() async {
    if (_myLat == null || _myLon == null) return;

    _setSearchingState(true);
    try {
      final banks = await _mapService.searchBanks(
        _selectedBank,
        _myLat!,
        _myLon!,
      );
      _handleBankSearchResult(banks);
    } catch (e) {
      print('❌ 은행 검색 실패: $e');
    } finally {
      _setSearchingState(false);
    }
  }

  void _handleBankSearchResult(List<BankModel> banks) {
    setState(() => _foundBanksCount = banks.length);

    _webViewController.runJavaScript("""
       if (typeof clearBankMarkers === 'function') clearBankMarkers();
    """);

    for (var bank in banks) {
      final js = """
        if (typeof addBankMarker === 'function') {
          addBankMarker(${bank.lat}, ${bank.lon},
            "${bank.fullName}",
            "${bank.roadAddress ?? bank.address}");
        }
      """;
      _webViewController.runJavaScript(js);
    }
  }

  void _setSearchingState(bool isSearching) {
    setState(() => _isSearching = isSearching);
  }

  // SnackBar
  void _showSnackBar(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? Colors.green : Colors.black87,
      ),
    );
  }

  // ============================
  // UI
  // ============================
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // WebView 뒤로갈 페이지가 있으면 WebView에서 뒤로가기 실행
        if (await _webViewController.canGoBack()) {
          _webViewController.goBack();
          return false; // 앱 자체의 뒤로가기는 막음
        }
        return true; // 더 이상 뒤로갈 페이지 없으면 앱 뒤로가기
      },

      child: Scaffold(
        body: Stack(
          children: [
            WebViewWidget(controller: _webViewController),

            if (!_isMapLoaded)
              const Center(child: CircularProgressIndicator()),

            if (_isSearching)
              Container(
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),

            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: IntegratedSearchBar(
                initialBank: _selectedBank,
                onSearchCompleted: _handleIntegratedSearch,
              ),
            ),

            if (_myAddress != null)
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(children: [
                          const Icon(Icons.location_on, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_myAddress!)),
                        ]),
                        if (_foundBanksCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(children: [
                              const Icon(
                                  Icons.account_balance, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                "${_selectedBank}  $_foundBanksCount개 발견",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ]),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: const BottomNav(selectedIndex: 4),
      ),
    );
  }
}