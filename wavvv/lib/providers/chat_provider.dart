import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';

class ChatNotifier extends StateNotifier<List<MessageModel>> {
  ChatNotifier() : super([]);

  void addMessage(MessageModel msg) {
    state = [...state, msg];
  }

  void addMessages(List<MessageModel> msgs) {
    state = [...msgs];
  }

  void clear() => state = [];
}

final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, List<MessageModel>>(
        (ref) => ChatNotifier());
