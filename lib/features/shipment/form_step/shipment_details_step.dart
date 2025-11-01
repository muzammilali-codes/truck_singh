import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ShipmentDetailsStep extends StatelessWidget {
  final TextEditingController itemController;
  final TextEditingController weightController;
  final TextEditingController unitController;
  final VoidCallback onChanged;
  final Widget progressBar;

  const ShipmentDetailsStep({
    Key? key,
    required this.itemController,
    required this.weightController,
    required this.unitController,
    required this.onChanged,
    required this.progressBar,
  }) : super(key: key);

  Widget _requiredTextField(TextEditingController controller, String labelKey,
      {bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "${labelKey.tr()}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: "enter Field".tr(namedArgs: {"field": labelKey.tr()}),
          ),
          validator: (val) => val == null || val.trim().isEmpty
              ? "enter Field".tr(namedArgs: {"field": labelKey.tr()})
              : null,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        progressBar,
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "shipmentDetails".tr(),
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        _requiredTextField(itemController, "shippingItem"),
        const SizedBox(height: 16),
        _requiredTextField(weightController, "weightTon", isNumeric: true),
        const SizedBox(height: 16),
        _requiredTextField(unitController, "unit", isNumeric: true),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.info,
                    color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  "weightGuidelines".tr(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800),
                ),
              ]),
              const SizedBox(height: 8),
              Text(
                "weightGuidelinesDesc".tr(),
                style: TextStyle(
                    color: Colors.amber.shade700, fontSize: 14),
              ),
            ],
          ),
        )
      ]),
    );
  }
}
