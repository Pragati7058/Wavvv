import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/queue_item_model.dart';

class QueueNotifier extends StateNotifier<List<QueueItemModel>> {
  QueueNotifier() : super([]);

  void setQueue(List<QueueItemModel> items) => state = items;

  void clear() => state = [];
}

final queueNotifierProvider =
    StateNotifierProvider<QueueNotifier, List<QueueItemModel>>(
        (ref) => QueueNotifier());
