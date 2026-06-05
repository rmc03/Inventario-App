import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(Connectivity());
});

final connectivityStatusProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).watchConnection();
});

class ConnectivityService {
  const ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  Stream<bool> watchConnection() {
    return _connectivity.onConnectivityChanged.map(_hasConnection);
  }

  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return _hasConnection(result);
  }

  bool _hasConnection(List<ConnectivityResult> result) {
    return result.any((item) => item != ConnectivityResult.none);
  }
}
