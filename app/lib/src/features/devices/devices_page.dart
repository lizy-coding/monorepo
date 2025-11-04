import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ble_chat_flutter/src/core/ble/core_ble.dart';
import 'package:ble_chat_flutter/src/core/domain/core_domain.dart';
import 'package:ble_chat_flutter/src/core/storage/storage.dart';

class DevicesPage extends ConsumerStatefulWidget {
  const DevicesPage({super.key});

  @override
  ConsumerState<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends ConsumerState<DevicesPage> {
  final List<String> _devices = <String>[];
  late final ProviderSubscription<AsyncValue<BleEventDto>> _bleSubscription;

  String _formatTimestamp(DateTime ts) {
    final local = ts.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  @override
  void initState() {
    super.initState();
    _bleSubscription = ref.listenManual<AsyncValue<BleEventDto>>(
      bleEventsProvider,
      (previous, next) {
        next.whenData((event) {
          if (event.type == 'scan_result' && !_devices.contains(event.deviceId)) {
            if (!mounted) return;
            setState(() {
              _devices.add(event.deviceId);
            });
          }
        });
      },
    );
    ref.read(bleControllerProvider.notifier).scan();
  }

  @override
  void dispose() {
    _bleSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final conversations = conversationsAsync.value ?? const <ConversationDto>[];

    return Scaffold(
      appBar: AppBar(title: const Text('BLE 璁惧')),
      body: ListView(
        children: [
          if (conversationsAsync.isLoading)
            const LinearProgressIndicator(
              minHeight: 2,
            ),
          if (conversationsAsync.hasError)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '鍔犺浇浼氳瘽澶辫触锛?{conversationsAsync.error}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ),
          if (conversations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '鏈€杩戜細璇?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          for (final conversation in conversations)
            ListTile(
              title: Text(conversation.title ?? conversation.peerId),
              subtitle: Text(
                '涓婃鏇存柊锛?{_formatTimestamp(conversation.updatedAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: conversation.unread > 0
                  ? CircleAvatar(
                      radius: 12,
                      child: Text(
                        '${conversation.unread}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white),
                      ),
                    )
                  : null,
              onTap: () {
                context.go('/chat?peer=${conversation.peerId}');
              },
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              '鎵弿鍒扮殑璁惧',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (_devices.isEmpty)
            const ListTile(
              title: Text('鏆傛棤璁惧'),
              subtitle: Text('姝ｅ湪鎵弿闄勮繎鐨勮摑鐗欒澶?..'),
            ),
          for (final deviceId in _devices)
            ListTile(
              title: Text(deviceId),
              onTap: () async {
                await ref.read(bleControllerProvider.notifier).connect(deviceId);
                if (!mounted) return;
                context.go('/chat?peer=$deviceId');
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

  