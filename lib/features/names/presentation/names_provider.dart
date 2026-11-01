import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/names_repository.dart';
import '../domain/allah_name_model.dart';

final namesRepositoryProvider = Provider<NamesRepository>((ref) {
  return NamesRepository();
});

final allNamesProvider = FutureProvider<List<AllahName>>((ref) async {
  final repo = ref.watch(namesRepositoryProvider);
  return repo.loadNames();
});

/// autoDispose so the query resets together with the screen's
/// TextEditingController when the user leaves /names.
final namesSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final filteredNamesProvider = Provider.autoDispose<AsyncValue<List<AllahName>>>(
  (ref) {
    final allNamesAsync = ref.watch(allNamesProvider);
    final query = ref.watch(namesSearchQueryProvider);
    final repo = ref.watch(namesRepositoryProvider);

    return allNamesAsync.whenData((names) {
      if (query.trim().isEmpty) return names;
      return repo.searchNames(names, query);
    });
  },
);
