/// Representa o resumo de uma conversa para exibição na caixa de entrada.
class ChatConversation {
  final String chatId;

  /// UIDs dos dois participantes (extraídos do chatId).
  final List<String> participants;

  /// Mapa uid → nome de cada participante (populado à medida que enviam msgs).
  final Map<String, String> participantNames;

  final String lastMessage;
  final String lastSenderId;
  final String lastSenderName;
  final int lastTimestamp;

  const ChatConversation({
    required this.chatId,
    required this.participants,
    required this.participantNames,
    required this.lastMessage,
    required this.lastSenderId,
    required this.lastSenderName,
    required this.lastTimestamp,
  });

  /// Nome do outro participante (não é o [myId]).
  String otherName(String myId) {
    for (final uid in participants) {
      if (uid != myId) {
        return participantNames[uid] ?? 'Usuário';
      }
    }
    return participantNames.entries
        .firstWhere((e) => e.key != myId,
            orElse: () => const MapEntry('', 'Usuário'))
        .value;
  }

  /// UID do outro participante.
  String otherId(String myId) {
    for (final uid in participants) {
      if (uid != myId) return uid;
    }
    return '';
  }

  factory ChatConversation.fromMap(String chatId, Map<String, dynamic> map) {
    final rawParts = chatId.split('_');
    final rawNames = (map['participantNames'] as Map?)?.cast<String, String>() ?? {};
    return ChatConversation(
      chatId: chatId,
      participants: rawParts.length == 2 ? rawParts : List<String>.from(map['participants'] ?? []),
      participantNames: rawNames,
      lastMessage: map['lastMessage'] as String? ?? '',
      lastSenderId: map['lastSenderId'] as String? ?? '',
      lastSenderName: map['lastSenderName'] as String? ?? '',
      lastTimestamp: (map['lastTimestamp'] as int?) ?? 0,
    );
  }
}
