import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/dropdown_controller.dart';

class ApiMultiSelectField extends StatefulWidget {
  final String label;
  final String placeholder;
  final String tableName;
  final DropdownController controller;
  final List<String> selectedValues;
  final String? Function(List<String>?)? validator;
  final void Function(List<String>)? onChanged;
  final int limit;
  final String Function(DropdownItem)? itemTextBuilder;
  final bool disabled;

  const ApiMultiSelectField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.tableName,
    required this.controller,
    required this.selectedValues,
    this.validator,
    this.onChanged,
    this.limit = 100,
    this.itemTextBuilder,
    this.disabled = false,
  });

  @override
  State<ApiMultiSelectField> createState() => _ApiMultiSelectFieldState();
}

class _ApiMultiSelectFieldState extends State<ApiMultiSelectField> {
  void _openSelector(FormFieldState<List<String>> fieldState) {
    final items = widget.controller.items.toList();
    final initialSelected = List<String>.from(widget.selectedValues);
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                final filtered = items.where((it) {
                  final text = (widget.itemTextBuilder != null
                          ? widget.itemTextBuilder!(it)
                          : it.deskripsi)
                      .toLowerCase();
                  return text.contains(query.toLowerCase()) ||
                      it.kode.toLowerCase().contains(query.toLowerCase());
                }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Cari opsi',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) {
                          setModalState(() => query = v.trim());
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final it = filtered[index];
                          final text = widget.itemTextBuilder != null
                              ? widget.itemTextBuilder!(it)
                              : it.deskripsi;
                          final selected = initialSelected.contains(it.kode);
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  if (!initialSelected.contains(it.kode)) {
                                    initialSelected.add(it.kode);
                                  }
                                } else {
                                  initialSelected.remove(it.kode);
                                }
                              });
                            },
                            title: Text(text),
                            subtitle: Text(it.keterangan ?? ''),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                fieldState.didChange(initialSelected);
                                widget.onChanged?.call(initialSelected);
                                Navigator.of(context).pop();
                                setState(() {});
                              },
                              child: const Text('Pilih'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Obx(() {
          if (widget.controller.items.isEmpty &&
              !widget.controller.isLoading.value) {
            widget.controller.loadTable(widget.tableName, limit: widget.limit);
          }

          if (widget.controller.isLoading.value &&
              widget.controller.items.isEmpty) {
            return const SizedBox(
              height: 56,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (widget.controller.error.isNotEmpty) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
              ),
              child: Text(
                widget.controller.error.value,
                style: const TextStyle(color: AppTheme.errorColor),
              ),
            );
          }

          return FormField<List<String>>(
            initialValue: widget.selectedValues,
            validator: widget.validator,
            builder: (state) {
              final selectedItems = widget.controller.items
                  .where((it) => state.value?.contains(it.kode) ?? false)
                  .toList();

              return InkWell(
                onTap: widget.disabled ? null : () => _openSelector(state),
                child: InputDecorator(
                  decoration: InputDecoration(
                    hintText: widget.placeholder,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.list_alt_outlined),
                    errorText: state.errorText,
                    enabled: !widget.disabled,
                  ),
                  isEmpty: selectedItems.isEmpty,
                  child: selectedItems.isEmpty
                      ? Text(
                          widget.placeholder,
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedItems
                              .map(
                                (it) => InputChip(
                                  label: Text(
                                    widget.itemTextBuilder != null
                                        ? widget.itemTextBuilder!(it)
                                        : it.deskripsi,
                                  ),
                                  onDeleted: widget.disabled
                                      ? null
                                      : () {
                                          final next = List<String>.from(
                                              state.value ?? <String>[]);
                                          next.remove(it.kode);
                                          state.didChange(next);
                                          widget.onChanged?.call(next);
                                          setState(() {});
                                        },
                                ),
                              )
                              .toList(),
                        ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}