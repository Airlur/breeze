import 'package:flutter/material.dart';
import '../../utils/logger.dart';
import 'package:logger/logger.dart';
import 'dart:async';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // 每秒刷新一次日志显示
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = AppLogger.logs.where((log) {
      if (_searchQuery.isEmpty) return true;
      return log.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (log.error?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('运行日志'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                AppLogger.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索日志...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[logs.length - 1 - index]; // 倒序显示
                return _LogEntryItem(log: log);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LogEntryItem extends StatelessWidget {
  final LogEntry log;

  const _LogEntryItem({required this.log});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          log.message,
          style: TextStyle(
            color: _getLogColor(log.level),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatTimestamp(log.timestamp),
              style: const TextStyle(fontSize: 12),
            ),
            if (log.error != null)
              Text(
                log.error!,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Color _getLogColor(Level level) {
    switch (level) {
      case Level.verbose:
        return Colors.grey;
      case Level.debug:
        return Colors.blue;
      case Level.info:
        return Colors.black;
      case Level.warning:
        return Colors.orange;
      case Level.error:
        return Colors.red;
      case Level.wtf:
        return Colors.purple;
      default:
        return Colors.black;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }
}
