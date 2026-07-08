import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:amazon_track_data/presentation/providers/auth_provider.dart';
import 'package:amazon_track_data/presentation/providers/chat_provider.dart';
import 'package:amazon_track_data/presentation/screens/boat_chat_screen.dart';

class BarqueiroInboxScreen extends ConsumerWidget {
  const BarqueiroInboxScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(currentUserIdProvider) ?? '';
    final inboxAsync = ref.watch(barqueiroChatInboxProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensagens'),
      ),
      body: inboxAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Erro ao carregar mensagens:\n$e',
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(barqueiroChatInboxProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma conversa ainda.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Os passageiros poderão entrar em contato\npelo perfil da sua embarcação.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final otherName = conv.otherName(myId);
              final otherId = conv.otherId(myId);
              final isLastFromMe = conv.lastSenderId == myId;

              final dt = DateTime.fromMillisecondsSinceEpoch(
                  conv.lastTimestamp);
              final now = DateTime.now();
              final timeLabel = now.difference(dt).inHours < 24
                  ? DateFormat('HH:mm').format(dt)
                  : DateFormat('dd/MM').format(dt);

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.15),
                  child: Text(
                    otherName.isNotEmpty
                        ? otherName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                title: Text(
                  otherName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isLastFromMe
                      ? 'Você: ${conv.lastMessage}'
                      : conv.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                trailing: Text(
                  timeLabel,
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 12),
                ),
                onTap: () {
                  final myUser = ref.read(userSessionProvider);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BoatChatScreen(
                        boatName: 'Conversa',
                        ownerName: otherName,
                        ownerId: otherId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
