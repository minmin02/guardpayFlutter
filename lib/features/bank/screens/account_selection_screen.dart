import 'package:flutter/material.dart';
import 'package:guardpayfront/core/services/storage.dart'; // AppStorage import 확인
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
  final _storage = AppStorage.storage; // 저장소 인스턴스

  // 토큰을 저장할 변수 (처음엔 null)
  String? _accessToken;
  bool _isLoadingToken = true; // 토큰 로딩 상태

  Future<MyAccount>? _myAccountFuture;
  Future<List<Beneficiary>>? _beneficiariesFuture;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  // [중요] 저장소에서 토큰을 꺼내고 데이터 로딩 시작
  Future<void> _initializeScreen() async {
    // 1. 저장된 토큰 읽기
    final token = await _storage.read(key: 'accessToken');

    if (mounted) {
      setState(() {
        _accessToken = token; // 읽어온 토큰 저장
        _isLoadingToken = false; // 로딩 끝
      });

      // 2. 토큰이 있으면 API 호출 시작
      if (_accessToken != null) {
        _myAccountFuture = _service.getMyAccount(_accessToken!);
        _beneficiariesFuture = _service.getBeneficiaries(_accessToken!);
      } else {
        // 토큰이 없으면 로그인 화면으로 보내거나 에러 처리
        print("⚠️ 저장된 토큰이 없습니다. 로그인이 필요합니다.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 토큰을 불러오는 중이면 로딩 표시
    if (_isLoadingToken) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F5E8),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 토큰이 없으면 로그인 유도 (간단한 예외처리)
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

              // [1] 내 계좌 정보
              FutureBuilder<MyAccount>(
                future: _myAccountFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return _myAccountCard(snapshot.data!);
                  } else if (snapshot.hasError) {
                    return const Text("계좌 정보를 불러올 수 없습니다.");
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),

              const SizedBox(height: 35),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "송금할 계좌를 선택해주세요",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 15),

              // [2] 송금 대상 목록
              FutureBuilder<List<Beneficiary>>(
                future: _beneficiariesFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final list = snapshot.data!;
                    if (list.isEmpty) return const Text("표시할 계좌가 없습니다.");

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        return _accountItem(context, list[index]);
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Text("오류 발생: ${snapshot.error}");
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _myAccountCard(MyAccount account) {
    return Container(
      height: 135,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.money, color: Color(0xFFFFC93C), size: 40),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("내 계좌", style: TextStyle(fontSize: 17, color: Colors.black54)),
              const SizedBox(height: 6),
              Text("${account.balance}원", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(account.accountName, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
          )
        ],
      ),
    );
  }

  Widget _accountItem(BuildContext context, Beneficiary beneficiary) {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildBankLogo(beneficiary.bankName),
          const SizedBox(width: 15),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙 정렬
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. [수정] 예금주 (은행이름) 순서로 표시
                Text(
                  beneficiary.accountHolderName.isNotEmpty
                      ? "${beneficiary.accountHolderName} (${beneficiary.bankName})"
                      : beneficiary.bankName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // 2. 계좌 번호
                Text(
                  beneficiary.accountNumber,
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          InkWell(
            onTap: () {
              // [중요] 저장소에서 꺼낸 진짜 토큰(_accessToken)을 다음 화면으로 넘깁니다.
              if (_accessToken != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MockTransferScreen(
                      beneficiary: beneficiary,
                      accessToken: _accessToken!,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("오류: 토큰이 없습니다.")),
                );
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF49A65E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text("선택", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// [추가] 은행 이름에 따라 로고 이미지를 반환하는 함수
Widget _buildBankLogo(String bankName) {
  String imagePath = 'assets/images/default_bank.png'; // 기본 이미지

  // 은행 이름에 따라 이미지 경로 설정 (이미지 파일명은 본인이 저장한 대로 수정 필요)
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
    backgroundColor: Colors.transparent, // 배경 투명하게
    // 이미지 파일이 있다면 AssetImage, 없다면(네트워크) NetworkImage 사용
    // 여기서는 로컬 에셋을 사용한다고 가정합니다.
    backgroundImage: AssetImage(imagePath),

    // 만약 이미지가 없을 때 깨지는 걸 방지하려면 아래처럼 에러 처리가 가능한 위젯을 써야 함
    onBackgroundImageError: (exception, stackTrace) {
      print("이미지 로드 실패: $imagePath");
    },
  );
}