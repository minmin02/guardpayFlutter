import 'package:flutter/material.dart';

class PurchaseDialog extends StatelessWidget {
  final String title;
  final String content;
  final Function() onConfirm;

  const PurchaseDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),

      content: Text(
        content,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Colors.red,
          height: 1.5,
        ),
      ),

      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 취소 버튼
            SizedBox(
              width: 135,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                ),
                child: const Text('취소', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 8),

            // 교환하기 버튼
            SizedBox(
              width: 135,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBBDAB4),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                ),
                child: const Text('교환하기', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                onPressed: () { onConfirm(); Navigator.of(context).pop(); },
              ),
            ),
          ],
        ),
      ],
      actionsPadding: const EdgeInsets.only(
          left: 0,
          right: 0,
          top: 10,
          bottom: 20
      ),
    );
  }
}

Future<void> showPurchaseDialog(
    BuildContext context, {
      required String title,
      required String content,
      required Function() onConfirm,
    }) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PurchaseDialog(
        title: title,
        content: content,
        onConfirm: onConfirm,
      );
    },
  );
}