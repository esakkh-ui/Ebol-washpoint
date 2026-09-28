import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk mengelola data lokal (fallback ketika offline)
class LocalStorageService {
  static const String _salesKey = 'sales';
  static const String _expensesKey = 'expenses';
  static const String _queueItemsKey = 'queueItems';
  static const String _lastSyncKey = 'lastSync';

  /// Simpan data ke lokal (SharedPreferences)
  static Future<void> saveData({
    required List<dynamic> sales,
    required List<dynamic> expenses,
    required List<dynamic> queueItems,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_salesKey, jsonEncode(sales));
      await prefs.setString(_expensesKey, jsonEncode(expenses));
      await prefs.setString(_queueItemsKey, jsonEncode(queueItems));
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      print('✅ Data berhasil disimpan lokal');
    } catch (e) {
      print('❌ Error saving local data: $e');
    }
  }

  /// Muat data dari lokal
  static Future<Map<String, dynamic>> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'sales': jsonDecode(prefs.getString(_salesKey) ?? '[]'),
        'expenses': jsonDecode(prefs.getString(_expensesKey) ?? '[]'),
        'queue_items': jsonDecode(prefs.getString(_queueItemsKey) ?? '[]'),
        'lastSync': prefs.getString(_lastSyncKey),
      };
    } catch (e) {
      print('❌ Error loading local data: $e');
      return {
        'sales': [],
        'expenses': [],
        'queue_items': [],
        'lastSync': null,
      };
    }
  }

  /// Hapus semua data lokal
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_salesKey);
      await prefs.remove(_expensesKey);
      await prefs.remove(_queueItemsKey);
      await prefs.remove(_lastSyncKey);
      print('✅ Data lokal berhasil dihapus');
    } catch (e) {
      print('❌ Error clearing local data: $e');
    }
  }
}
