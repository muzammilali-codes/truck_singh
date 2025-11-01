import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class BlankPage extends StatelessWidget {
  const BlankPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('testPage'.tr()),
      ),
      body: Center(
        child: Text(
          'blankTestPage'.tr(),
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}