// 1. 내 계좌 정보 모델
class MyAccount {
  final String accountName;
  final int balance;
  final String currency;

  MyAccount({
    required this.accountName,
    required this.balance,
    required this.currency,
  });

  // [추가] 서버 JSON 데이터를 객체로 변환하는 공장(Factory) 메서드
  factory MyAccount.fromJson(Map<String, dynamic> json) {
    return MyAccount(
      accountName: json['accountName'] ?? '알 수 없음',
      balance: json['point'] ?? 0,
      currency: json['currency'] ?? 'KRW',
    );
  }
}

// 2. 송금 대상(수취인) 모델
class Beneficiary {
  final int beneficiaryId;
  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final String? nickname; // 별칭은 없을 수도 있음

  Beneficiary({
    required this.beneficiaryId,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    this.nickname,
  });

  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    return Beneficiary(
      beneficiaryId: json['id'] ?? 0, // 서버 필드명 확인 필요 (id 혹은 beneficiaryId)
      bankName: json['bankName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      accountHolderName: json['accountHolderName'] ?? '',
      nickname: json['nickname'],
    );
  }
}

// 3. 송금 결과 모델 (성공 시 리워드 정보 등)
class TransferResult {
  final bool success;
  final String message;
  final int? rewardPoints;

  TransferResult({
    required this.success,
    required this.message,
    this.rewardPoints,
  });

  factory TransferResult.fromJson(Map<String, dynamic> json) {
    return TransferResult(
      success: true, // 200 OK로 왔다면 성공
      message: json['message'] ?? '송금 완료',
      rewardPoints: json['rewardPoints'], // 리워드가 있다면 매핑
    );
  }
}