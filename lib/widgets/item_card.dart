import 'package:flutter/material.dart';
import '../models/item_model.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback? onTap;
  final bool showUserInfo;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.showUserInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    // BASIC card - just functional, not pretty
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.isLost ? Colors.red : Colors.green,
          child: Text(
            item.isLost ? 'L' : 'F',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(item.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description),
            Text('${item.category} • ${item.location}'),
            if (item.priority == PriorityLevel.high)
              const Text('⚠️ HIGH PRIORITY',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Text(item.status.toString().split('.').last),
        onTap: onTap,
      ),
    );
  }
}