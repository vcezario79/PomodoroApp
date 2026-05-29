import 'dart:convert';
import 'package:http/http.dart' as http;

enum SyncStatus { idle, loading, synced, error }

class SyncService {
  final String baseUrl;
  static const timeout = Duration(seconds: 3);

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  DateTime? _lastSynced;
  DateTime? get lastSynced => _lastSynced;

  SyncService({required this.baseUrl});

  Future<Map<String, dynamic>?> fetchData({
    required void Function(SyncStatus) onStatus,
  }) async {
    onStatus(SyncStatus.loading);
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/data'))
          .timeout(timeout);
      if (response.statusCode == 200) {
        _lastSynced = DateTime.now();
        onStatus(SyncStatus.synced);
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Sync error: $e");
      onStatus(SyncStatus.error);
      return null;
    }
    onStatus(SyncStatus.error);
    return null;
  }

  Future<bool> pushData(
    Map<String, dynamic> data, {
    required void Function(SyncStatus) onStatus,
  }) async {
    onStatus(SyncStatus.loading);
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/data'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(timeout);
      if (response.statusCode == 200) {
        _lastSynced = DateTime.now();
        onStatus(SyncStatus.synced);
        return true;
      }
    } catch (e) {
      print("Sync error: $e");
      onStatus(SyncStatus.error);
      return false;
    }
    onStatus(SyncStatus.error);
    return false;
  }
}
