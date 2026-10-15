import 'package:flutter/material.dart';

class CuisineFilterChips extends StatelessWidget {
  final String selectedCuisine;
  final ValueChanged<String> onSelected;

  static const List<String> cuisines = [
    'All',
    'Indian',
    'Italian',
    'American',
    'Chinese',
    'Japanese',
    'Mexican',
    'Desserts',
    'Beverages',
  ];

  const CuisineFilterChips({
    super.key,
    required this.selectedCuisine,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: cuisines.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cuisine = cuisines[index];
          final isSelected = selectedCuisine == cuisine;

          return FilterChip(
            label: Text(cuisine),
            selected: isSelected,
            onSelected: (_) => onSelected(cuisine),
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}
