import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase/supabase_client.dart';
import '../utils/connectivity_service.dart';
import 'local_database.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    database: LocalDatabase.instance,
    connectivityService: ref.watch(connectivityServiceProvider),
    supabaseAvailable: ref.watch(supabaseClientProvider) != null,
  );
});

class SyncService {
  const SyncService({
    required this.database,
    required this.connectivityService,
    required this.supabaseAvailable,
  });

  final LocalDatabase database;
  final ConnectivityService connectivityService;
  final bool supabaseAvailable;

  Future<bool> syncPending() async {
    if (!supabaseAvailable || !await connectivityService.isConnected()) {
      return false;
    }

    await database.database;
    return true;
  }
}
