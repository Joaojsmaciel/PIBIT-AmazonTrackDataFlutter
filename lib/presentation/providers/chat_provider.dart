import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amazon_track_data/data/models/chat_message.dart';
import 'package:amazon_track_data/data/models/chat_conversation.dart';
import 'package:amazon_track_data/presentation/providers/service_provider.dart';
import 'package:amazon_track_data/presentation/providers/auth_provider.dart';

/// Stream de mensagens de um chat identificado por [chatId].
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  final ds = ref.watch(firestoreDatasourceProvider);
  return ds.watchChatMessages(chatId);
});

/// Envia uma mensagem. Recebe ({chatId, text, senderName}).
final sendChatMessageProvider = FutureProvider.family<void,
    ({String chatId, String text, String senderName})>((ref, params) async {
  final ds = ref.read(firestoreDatasourceProvider);
  final uid = ref.read(currentUserIdProvider);
  if (uid == null) throw Exception('Usuário não autenticado');

  final msg = ChatMessage(
    id: '${uid}_${DateTime.now().millisecondsSinceEpoch}',
    chatId: params.chatId,
    senderId: uid,
    senderName: params.senderName,
    text: params.text.trim(),
    timestamp: DateTime.now().millisecondsSinceEpoch,
  );
  await ds.sendChatMessage(msg);
});

/// Stream da caixa de entrada do barqueiro — todas as conversas em que ele é participante.
final barqueiroChatInboxProvider =
    StreamProvider<List<ChatConversation>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const Stream.empty();
  final ds = ref.watch(firestoreDatasourceProvider);
  return ds.watchBarqueiroChatInbox(uid);
});
