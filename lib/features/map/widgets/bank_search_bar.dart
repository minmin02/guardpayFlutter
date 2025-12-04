// import 'package:flutter/material.dart';
//
// class BankSearchBar extends StatelessWidget {
//   final String initialBank;
//   final Function(String) onBankSelected;
//
//   const BankSearchBar({
//     super.key,
//     required this.initialBank,
//     required this.onBankSelected,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         child: Row(
//           children: [
//             const Icon(Icons.account_balance, color: Colors.green),
//             const SizedBox(width: 8),
//             Expanded(
//               child: DropdownButton<String>(
//                 value: initialBank,
//                 isExpanded: true,
//                 underline: const SizedBox(),
//                 items: [
//                   '신한은행',
//                   '국민은행',
//                   '우리은행',
//                   '하나은행',
//                   'NH농협은행',
//                   '기업은행',
//                   '부산은행',
//                   '대구은행',
//                   '경남은행',
//                   '광주은행',
//                   '전북은행',
//                   '제주은행',
//                   '카카오뱅크',
//                   '케이뱅크',
//                   '토스뱅크',
//                 ].map((String bank) {
//                   return DropdownMenuItem<String>(
//                     value: bank,
//                     child: Text(bank),
//                   );
//                 }).toList(),
//                 onChanged: (String? newBank) {
//                   if (newBank != null) {
//                     onBankSelected(newBank);
//                   }
//                 },
//               ),
//             ),
//             const Icon(Icons.arrow_drop_down, color: Colors.grey),
//           ],
//         ),
//       ),
//     );
//   }
// }