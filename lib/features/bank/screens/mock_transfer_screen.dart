import 'package:flutter/material.dart';
import '../models/transfer_models.dart';
import '../services/transfer_service.dart';
import 'transfer_success_screen.dart';

class MockTransferScreen extends StatefulWidget {
  final Beneficiary beneficiary;
  final String accessToken;
  final int myBalance; // 내 잔액 정보

  const MockTransferScreen({
    super.key,
    required this.beneficiary,
    required this.accessToken,
    required this.myBalance,
  });

  @override
  State<MockTransferScreen> createState() => _MockTransferScreenState();
}

class _MockTransferScreenState extends State<MockTransferScreen> {
  // 입력 컨트롤러
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final TransferService _service = TransferService();

  // 은행 선택 드롭다운
  String? _selectedBank;
  final List<String> _bankList = [
    '국민은행', '신한은행', '하나은행', '우리은행', 'NH농협은행',
    'IBK기업은행', '카카오뱅크', '토스뱅크'
  ];

  bool isTransferReady = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _accountNumberController.addListener(_checkValidity);
    _amountController.addListener(_checkValidity);
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // 버튼 활성화 여부 체크
  void _checkValidity() {
    setState(() {
      isTransferReady = _accountNumberController.text.isNotEmpty &&
          _selectedBank != null &&
          _amountController.text.isNotEmpty;
    });
  }

  Future<void> _performTransfer() async {
    if (!isTransferReady) return;

    // 키보드 내리기
    FocusScope.of(context).unfocus();

    // 1. 입력값 가져오기
    String inputNumber = _accountNumberController.text.replaceAll('-', '').replaceAll(' ', '');
    String targetNumber = widget.beneficiary.accountNumber.replaceAll('-', '').replaceAll(' ', '');
    String selectedBankName = (_selectedBank ?? '').trim();
    String targetBankName = widget.beneficiary.bankName.trim();

    // 금액 숫자로 변환
    int transferAmount = int.tryParse(_amountController.text) ?? 0;

    // 2. 계좌 정보 일치 여부 확인
    bool isAccountMatch = (inputNumber == targetNumber);
    bool isBankMatch = (selectedBankName == targetBankName);

    if (!isAccountMatch || !isBankMatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("계좌번호와 은행 정보가 일치하지 않습니다."),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 3. [추가된 로직] 잔액 초과 확인
    if (transferAmount > widget.myBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("잔액을 초과했습니다. (현재 잔액: ${widget.myBalance}원)"),
          backgroundColor: Colors.red, // 빨간색 경고
          duration: const Duration(seconds: 2),
        ),
      );
      return; // 여기서 함수를 끝내서 송금을 막음!
    }

    // 4. 모든 검사 통과 -> 송금 진행
    setState(() => isLoading = true);

    try {
      await _service.postTransfer(
        accessToken: widget.accessToken,
        toBeneficiaryId: widget.beneficiary.beneficiaryId,
        amount: transferAmount,
      );

      if (!mounted) return;

      // 성공 화면으로 이동
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransferSuccessScreen(
            completedBeneficiaryId: widget.beneficiary.beneficiaryId,
          ),
        ),
      );

      // 성공 후 복귀 시 처리
      if (result != null) {
        if (!mounted) return;
        Navigator.pop(context, result);
      }

    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString().replaceAll("Exception: ", "");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("송금 실패: $errorMsg")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F5E8),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 18.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "선택한 계좌로 송금하세요!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 15),

              _selectedAccountCard(),

              const SizedBox(height: 40),

              const Text(
                "어떤 계좌로 돈을 보낼까요?",
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // 계좌번호 입력
              TextField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18, color: Colors.black),
                decoration: const InputDecoration(
                  labelText: "계좌번호 입력",
                  labelStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF49A65E), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 은행 선택
              DropdownButtonFormField<String>(
                value: _selectedBank,
                hint: const Text("은행 선택", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.grey)),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                style: const TextStyle(fontSize: 18, color: Colors.black),
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF49A65E), width: 2),
                  ),
                ),
                items: _bankList.map((String bank) {
                  return DropdownMenuItem<String>(
                    value: bank,
                    child: Text(bank),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedBank = newValue;
                    _checkValidity();
                  });
                },
              ),

              const SizedBox(height: 50),

              const Text(
                "얼마를 보낼까요?",
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 금액 입력
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  hintText: "금액",
                  hintStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF49A65E), width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 100),

              // 송금 버튼
              GestureDetector(
                onTap: (isTransferReady && !isLoading) ? _performTransfer : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isTransferReady ? const Color(0xFF49A65E) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text(
                    "송금하기",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // 상단 계좌 정보 카드 (UI 유지)
  Widget _selectedAccountCard() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildBankLogo(widget.beneficiary.bankName),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.beneficiary.accountHolderName.isNotEmpty
                      ? "${widget.beneficiary.accountHolderName} (${widget.beneficiary.bankName})"
                      : widget.beneficiary.bankName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.beneficiary.accountNumber,
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
}