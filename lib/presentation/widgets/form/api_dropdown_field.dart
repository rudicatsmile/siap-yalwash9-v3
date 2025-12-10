import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/dropdown_controller.dart';

class ApiDropdownField extends StatelessWidget {
  final String label;
  final String placeholder;
  final String tableName;
  final DropdownController controller;
  final String? Function(String?)? validator;
  final void Function(String?)? onChanged;
  final int limit;
  final String Function(DropdownItem)? itemTextBuilder;

  const ApiDropdownField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.tableName,
    required this.controller,
    this.validator,
    this.onChanged,
    this.limit = 100,
    this.itemTextBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.isLoading.value && controller.items.isEmpty) {
            return const SizedBox(
              height: 56,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (controller.error.isNotEmpty) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
              ),
              child: Text(
                controller.error.value,
                style: const TextStyle(color: AppTheme.errorColor),
              ),
            );
          }

          return DropdownButtonFormField<String>(
            value: controller.selectedKode.value.isEmpty
                ? null
                : controller.selectedKode.value,
            isExpanded: true,
            selectedItemBuilder: (context) => controller.items
                .map(
                  (it) => Text(
                    itemTextBuilder != null
                        ? itemTextBuilder!(it)
                        : it.deskripsi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                )
                .toList(),
            items: controller.items
                .map(
                  (it) => DropdownMenuItem<String>(
                    value: it.kode,
                    child: Text(
                      itemTextBuilder != null
                          ? itemTextBuilder!(it)
                          : it.deskripsi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              controller.select(val);
              if (onChanged != null) onChanged!(val);
            },
            validator: validator,
            decoration: InputDecoration(
              hintText: placeholder,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.category_outlined),
            ),
          );
        }),
      ],
    );
  }
}
