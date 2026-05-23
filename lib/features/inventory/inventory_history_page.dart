import 'package:flutter/material.dart';

import '../../data/models/inventory_item_model.dart';
import 'inventory_detail_page.dart';

class InventoryHistoryPage extends StatelessWidget {
  const InventoryHistoryPage({
    super.key,
    required this.product,
  });

  final InventoryItemModel product;

  @override
  Widget build(BuildContext context) {
    return InventoryDetailPage(itemId: product.id);
  }
}
