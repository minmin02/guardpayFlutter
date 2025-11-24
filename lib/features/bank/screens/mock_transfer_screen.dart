import 'package:flutter/material.dart';
import '../models/transfer_models.dart';
import '../services/transfer_service.dart';
import 'transfer_success_screen.dart';

class MockTransferScreen extends StatefulWidget {
  final Beneficiary beneficiary;
  final String accessToken;

  const MockTransferScreen({
    super.key,
    required this.beneficiary,
    required this.accessToken,
  });

  @override
  State<MockTransferScreen> createState() => _MockTransferScreenState();
}

class _MockTransferScreenState extends State<MockTransferScreen> {
  // 입력 컨트롤러
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final TransferService _service = TransferService();

  // 은행 선택 드롭다운 상태 관리
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

  void _checkValidity() {
    setState(() {
      isTransferReady = _accountNumberController.text.isNotEmpty &&
          _selectedBank != null &&
          _amountController.text.isNotEmpty;
    });
  }

  Future<void> _performTransfer() async {
    if (!isTransferReady) return;

    String inputNumber = _accountNumberController.text.replaceAll('-', '');
    String targetNumber = widget.beneficiary.accountNumber.replaceAll('-', '');

    bool isBankMatch = _selectedBank == widget.beneficiary.bankName;
    bool isAccountMatch = inputNumber == targetNumber;

    if (!isBankMatch || !isAccountMatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("계좌 정보를 다시 확인해주세요"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await _service.postTransfer(
        accessToken: widget.accessToken,
        toBeneficiaryId: widget.beneficiary.beneficiaryId,
        amount: int.parse(_amountController.text),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TransferSuccessScreen()),
      );
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

              GestureDetector(
                //onTap: (isTransferReady && !isLoading) ? _performTransfer : null,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const TransferSuccessScreen()),
                  );
                },

                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    //color: isTransferReady ? const Color(0xFF49A65E) : Colors.grey[300],
                    color: const Color(0xFF49A65E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    //child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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

  // [수정됨] 이전 화면(_accountItem)과 동일한 디자인
  Widget _selectedAccountCard() {
    return Container(
      height: 100, // 이전 화면과 높이 비슷하게 맞춤
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // 로고 표시
          _buildBankLogo(widget.beneficiary.bankName),
          const SizedBox(width: 15),

          // 텍스트 정보
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
          // '선택' 버튼은 이미 선택되었으므로 제거함
        ],
      ),
    );
  }

  // [추가] 로고 이미지를 불러오기 위한 함수 (이전 화면에서 가져옴)
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