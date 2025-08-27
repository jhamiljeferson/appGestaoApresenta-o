import 'package:flutter/material.dart';

class AppBreadcrumbs extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final void Function(int)? onTap;

  const AppBreadcrumbs({Key? key, required this.items, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          GestureDetector(
            onTap: onTap != null && i < items.length - 1
                ? () => onTap!(i)
                : null,
            child: Text(
              items[i].label,
              style: TextStyle(
                color: i == items.length - 1
                    ? Colors.grey[700]
                    : Theme.of(context).primaryColor,
                fontWeight: i == items.length - 1
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          if (i < items.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ),
        ],
      ],
    );
  }
}

class BreadcrumbItem {
  final String label;
  const BreadcrumbItem(this.label);
}
