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

    // 1. 완료된 ID 목록 로드
    final String? savedIds = await _storage.read(key: 'completed_ids');
    if (savedIds != null && savedIds.isNotEmpty) {
      final List<int> ids = savedIds
          .split(',')
          .where((e) => e.isNotEmpty)
          .map((e) => int.parse(e))
          .toList();
      _completedBeneficiaryIds.addAll(ids);
    }

    // 2. 저장된 '계좌 목록' 불러오기 (캐싱)
    final String? cachedListJson = await _storage.read(key: 'cached_beneficiaries');
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
        _accessToken = token;
        _isLoadingToken = false;

        if (cachedList.isNotEmpty) {
          _beneficiaries = cachedList;
          _isLoadingBeneficiaries = false;
        }
      });

      if (_accessToken != null) {
        _fetchMyAccount();

        if (cachedList.isEmpty) {
          _fetchAndSaveBeneficiaries();
        }
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

  Future<void> _fetchAndSaveBeneficiaries() async {
    if (_accessToken == null) return;
    try {
      setState(() => _isLoadingBeneficiaries = true);
      final list = await _service.getBeneficiaries(_accessToken!);

      if (mounted) {
        setState(() {
          _beneficiaries = list;
          _isLoadingBeneficiaries = false;
        });

        final jsonString = jsonEncode(list.map((b) => {
          'id': b.beneficiaryId,
          'bankName': b.bankName,
          'accountNumber': b.accountNumber,
          'accountHolderName': b.accountHolderName,
          'nickname': b.nickname,
        }).toList());
        await _storage.write(key: 'cached_beneficiaries', value: jsonString);
      }
    } catch (e) {
      print("목록 불러오기 실패: $e");
      if (mounted) setState(() => _isLoadingBeneficiaries = false);
    }
  }

  Future<void> _saveCompletedId(int id) async {
    setState(() {
      _completedBeneficiaryIds.add(id);
    });
    await _storage.write(
      key: 'completed_ids',
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