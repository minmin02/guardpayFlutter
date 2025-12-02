import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:guardpayfront/core/services/storage.dart';
import '../../auth/widgets/bottom_nav.dart';
import '../models/transfer_models.dart';
import '../services/transfer_service.dart';
import 'mock_transfer_screen.dart';

class AccountSelectionScreen extends StatefulWidget {
  const AccountSelectionScreen({super.key});

  @override
  State<AccountSelectionScreen> createState() => _AccountSelectionScreenState();
}

class _AccountSelectionScreenState extends State<AccountSelectionScreen> {
  final TransferService _service = TransferService();
  final _storage = AppStorage.storage;

  String? _accessToken;
  bool _isLoadingToken = true;

  // 내 계좌 정보
  MyAccount? _myAccount;
  bool _isLoadingAccount = true;

  // 수취인 목록
  List<Beneficiary> _beneficiaries = [];
  bool _isLoadingBeneficiaries = true;

  // 송금 완료된 ID 집합
  final Set<int> _completedBeneficiaryIds = {};

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    final token = await _storage.read(key: 'accessToken');

    if (token == null) {
      if (mounted) setState(() => _isLoadingToken = false);
      return;
    }

    if (mounted) {
      setState(() {
        _accessToken = token;
        _isLoadingToken = false;
      });
    }

    await _fetchMyAccount();
    if (_myAccount == null) return;

    final String currentUserId = _myAccount!.myId;
    final String? savedUserId = await _storage.read(key: 'last_user_id');

    final String cacheKey = 'cached_beneficiaries_$currentUserId';
    final String dateKey = 'last_update_date_$currentUserId';
    final String completedKey = 'completed_ids_$currentUserId';

    if (savedUserId != null && savedUserId != currentUserId) {
      print("사용자가 변경되었습니다. ($savedUserId -> $currentUserId) 데이터를 초기화합니다.");
      _completedBeneficiaryIds.clear();
    }

    // 현재 사용자 ID를 저장소에 업데이트 (다음번 비교를 위해)
    await _storage.write(key: 'last_user_id', value: currentUserId);

    // 날짜 확인: 오늘 날짜 vs 저장된 날짜
    final String todayStr = DateTime.now().toString().split(' ')[0];
    final String? lastDate = await _storage.read(key: dateKey);

    // 날짜가 다르면(새로운 하루) 캐시 삭제
    if (lastDate != todayStr) {
      await _storage.delete(key: cacheKey);
      await _storage.delete(key: completedKey);
      _completedBeneficiaryIds.clear();
      print("날짜가 변경되어 목록을 갱신합니다.");
    }

    // 완료된 ID 목록 로드
    final String? savedIds = await _storage.read(key: completedKey);
    if (savedIds != null && savedIds.isNotEmpty) {
      final List<int> ids = savedIds
          .split(',')
          .where((e) => e.isNotEmpty)
          .map((e) => int.parse(e))
          .toList();
      _completedBeneficiaryIds.addAll(ids);
    }

    // 저장된 '계좌 목록' 불러오기
    final String? cachedListJson = await _storage.read(key: cacheKey);
    List<Beneficiary> cachedList = [];
    if (cachedListJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedListJson);
        cachedList = decoded.map((e) => Beneficiary.fromJson(e)).toList();
      } catch (e) {
        print("캐시 파싱 에러: $e");
      }
    }

    if (mounted) {
      setState(() {
        if (cachedList.isNotEmpty) {
          _beneficiaries = cachedList;
          _isLoadingBeneficiaries = false;
        }
      });

      // 캐시가 없으면(사용자 변경됨 or 날짜 변경됨 or 최초 실행) 서버 요청
      if (cachedList.isEmpty) {
        _fetchAndSaveBeneficiaries(currentUserId);
      }
    }
  }

  Future<void> _fetchMyAccount() async {
    if (_accessToken == null) return;
    try {
      final account = await _service.getMyAccount(_accessToken!);
      if (mounted) {
        setState(() {
          _myAccount = account;
          _isLoadingAccount = false;
        });
      }
    } catch (e) {
      print("내 계좌 조회 실패: $e");
      if (mounted) setState(() => _isLoadingAccount = false);
    }
  }

  Future<void> _fetchAndSaveBeneficiaries(String myId) async {
    if (_accessToken == null) return;
    try {
      setState(() => _isLoadingBeneficiaries = true);

      // 1. 서버에서 목록 가져오기 (서버가 이미 랜덤으로 섞어서 줌)
      final list = await _service.getBeneficiaries(_accessToken!);

      if (mounted) {
        setState(() {
          _beneficiaries = list;
          _isLoadingBeneficiaries = false;
        });

        final String cacheKey = 'cached_beneficiaries_$myId';
        final String dateKey = 'last_update_date_$myId';

        // 2. 목록 저장 (캐싱)
        final jsonString = jsonEncode(list.map((b) => {
          'id': b.beneficiaryId,
          'bankName': b.bankName,
          'accountNumber': b.accountNumber,
          'accountHolderName': b.accountHolderName,
          'nickname': b.nickname,
        }).toList());
        await _storage.write(key: cacheKey, value: jsonString);

        // [추가된 로직 2] 오늘 날짜 저장 (내일 비교하기 위해)
        final String todayStr = DateTime.now().toString().split(' ')[0];
        await _storage.write(key: dateKey, value: todayStr);
      }
    } catch (e) {
      print("목록 불러오기 실패: $e");
      if (mounted) setState(() => _isLoadingBeneficiaries = false);
    }
  }

  Future<void> _saveCompletedId(int id) async {
    if (_myAccount == null) return;

    final String myId = _myAccount!.myId;
    final String completedKey = 'completed_ids_$myId';

    setState(() {
      _completedBeneficiaryIds.add(id);
    });

    await _storage.write(
      key: completedKey,
      value: _completedBeneficiaryIds.join(','),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingToken) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F5E8),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_accessToken == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F5E8),
        body: Center(child: Text("로그인 정보가 없습니다. 다시 로그인해주세요.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F5E8),
      bottomNavigationBar: const BottomNav(selectedIndex: 3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "GuardPay",
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF49A65E)),
                ),
              ),
              const SizedBox(height: 25),

              _isLoadingAccount
                  ? const Center(child: CircularProgressIndicator())
                  : _myAccount != null
                  ? _myAccountCard(_myAccount!)
                  : const Text("계좌 정보를 불러올 수 없습니다."),

              const SizedBox(height: 35),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "송금할 계좌를 선택해주세요",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 15),

              _isLoadingBeneficiaries
                  ? const Center(child: CircularProgressIndicator())
                  : _beneficiaries.isEmpty
                  ? const Text("표시할 계좌가 없습니다.")
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _beneficiaries.length,
                itemBuilder: (context, index) {
                  return _accountItem(context, _beneficiaries[index]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [수정됨] 디자인 적용된 카드
  Widget _myAccountCard(MyAccount account) {
    // 3자리 콤마 포맷터
    String formatCurrency(int amount) {
      return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "GuardPay 안심 포인트",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF59D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFFBC02D),
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Text(
                "${formatCurrency(account.balance)}원",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _accountItem(BuildContext context, Beneficiary beneficiary) {
    bool isCompleted = _completedBeneficiaryIds.contains(beneficiary.beneficiaryId);

    return Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.grey[200] : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: isCompleted ? 0.5 : 1.0,
            child: _buildBankLogo(beneficiary.bankName),
          ),
          const SizedBox(width: 15),

          Expanded(
            child: Opacity(
              opacity: isCompleted ? 0.5 : 1.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    beneficiary.accountHolderName.isNotEmpty
                        ? "${beneficiary.accountHolderName} (${beneficiary.bankName})"
                        : beneficiary.bankName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    beneficiary.accountNumber,
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          InkWell(
            onTap: isCompleted
                ? null
                : () async {
              if (_accessToken != null) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MockTransferScreen(
                      beneficiary: beneficiary,
                      accessToken: _accessToken!,

                      // [핵심 수정] 여기에 myBalance를 꼭 넣어줘야 합니다!
                      // 아직 로딩 안됐으면(null이면) 0원을 넘겨서 에러 방지
                      myBalance: _myAccount?.balance ?? 0,
                    ),
                  ),
                );

                if (result != null && result is int) {
                  await _saveCompletedId(result);
                  _fetchMyAccount();
                  setState(() {});
                }
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.grey : const Color(0xFF49A65E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isCompleted ? "완료" : "선택",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildBankLogo(String bankName) {
  String imagePath = 'assets/images/default_bank.png';

  if (bankName.contains('토스')) {
    imagePath = 'assets/images/toss_logo.png';
  } else if (bankName.contains('카카오')) {
    imagePath = 'assets/images/kakaobank_logo.jpg';
  } else if (bankName.contains('신한')) {
    imagePath = 'assets/images/shinhan_logo.png';
  } else if (bankName.contains('국민')) {
    imagePath = 'assets/images/kb_logo.png';
  } else if (bankName.contains('우리')) {
    imagePath = 'assets/images/woori_logo.png';
  } else if (bankName.contains('하나')) {
    imagePath = 'assets/images/hana_logo.png';
  } else if (bankName.contains('농협')) {
    imagePath = 'assets/images/nh_logo.png';
  } else if (bankName.contains('기업')) {
    imagePath = 'assets/images/ibk_logo.png';
  }

  return CircleAvatar(
    radius: 26,
    backgroundColor: Colors.transparent,
    backgroundImage: AssetImage(imagePath),
    onBackgroundImageError: (exception, stackTrace) {
      print("이미지 로드 실패: $imagePath");
    },
  );
}