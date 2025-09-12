import 'package:flutter/material.dart';
import 'api_service.dart';

class QueueView extends StatefulWidget {
  const QueueView({Key? key}) : super(key: key);

  @override
  State<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView> {
  // No local state for queue; use global notifier

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: ApiService.instance.appData,
      builder: (context, data, _) {
        final queueItems = data['queue'] ?? [];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Queue'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ApiService.instance.refreshAll(),
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: queueItems.isEmpty
              ? const Center(child: Text('Queue is empty'))
              : ListView.separated(
                  itemCount: queueItems.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Text('${index + 1}'),
                      title: Text(queueItems[index] is String ? queueItems[index] : (queueItems[index]['name'] ?? '')),
                    );
                  },
                ),
        );
      },
    );
  }
}