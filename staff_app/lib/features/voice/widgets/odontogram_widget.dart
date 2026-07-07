import 'package:flutter/material.dart';

class OdontogramWidget extends StatelessWidget {
  final List<dynamic> findings;

  const OdontogramWidget({Key? key, required this.findings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (findings.isEmpty) {
      return const Center(
        child: Text(
          'No findings charted yet.\nPress record and speak.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: findings.length,
      itemBuilder: (context, index) {
        final item = findings[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Text(
                '${item['tooth_number']}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              '${item['condition']}'.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Surface: ${item['surface']}'),
          ),
        );
      },
    );
  }
}
