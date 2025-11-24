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

  factory MyAccount.fromJson(Map<String, dynamic> json) {
    return MyAccount(
      // 1. 이름: 서버에서 이름('nickname' 등)을 주면 쓰고, 안 주면 'GuardPay 머니'로 표시
      accountName: json['nickname'] ?? json['name'] ?? json['accountName'] ?? 'GuardPay 머니',

      // 2. 잔액: 'point', 'points', 'balance' 중 하나라도 있으면 가져오기
      balance: json['point'] ?? json['points'] ?? json['balance'] ?? 0,

      // 3. 통화: 없으면 원화(KRW)
      currency: json['currency'] ?? 'KRW',
    );
  }
}

// 2. 송금 대상(수취인) 모델 (기존 유지)
class Beneficiary {
  final int beneficiaryId;
  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final String? nickname;

  Beneficiary({
    required this.beneficiaryId,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    this.nickname,
  });

  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    return Beneficiary(
      beneficiaryId: json['id'] ?? 0,
      bankName: json['bankName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      accountHolderName: json['accountHolderName'] ?? '',
      nickname: json['nickname'],
    );
  }
}

// 3. 송금 결과 모델 (기존 유지)
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
      success: true,
      message: json['message'] ?? '송금 완료',
      rewardPoints: json['rewardPoints'],
    );
  }
}