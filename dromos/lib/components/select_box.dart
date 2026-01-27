import 'package:dromos/utils/colors.dart';
import 'package:flutter/material.dart';

class SelectBox extends StatefulWidget {
  final String id;
  final String label;
  final List<String> options;
  final void Function(String) onChange;
  final String? selectedOption;

  const SelectBox({
    super.key,
    required this.id,
    required this.label,
    required this.options,
    required this.onChange,
    this.selectedOption,
  });

  @override
  State<SelectBox> createState() => _SelectBoxState();
}

class _SelectBoxState extends State<SelectBox> {
  String? selectedOption;

  @override
  void initState() {
    super.initState();
    selectedOption = widget.options.contains(widget.selectedOption)
        ? widget.selectedOption
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: ConstColor.primaryColor,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: DropdownButton<String>(
              dropdownColor: ConstColor.primaryPurple,
              value: selectedOption,
              hint: Text(widget.label),
              isExpanded: true,
              underline: const SizedBox.shrink(),
              onChanged: (String? newValue) {
                setState(() => selectedOption = newValue);
                if (newValue != null) widget.onChange(newValue);
              },
              items: widget.options
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 12,
                          color: ConstColor.primaryColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              icon: Icon(Icons.keyboard_arrow_down),
              iconSize: 26,
            ),
          ),
        ],
      ),
    );
  }
}
