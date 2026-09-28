import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service untuk mengelola data di Supabase Cloud.
/// Data yang disimpan: sales, expenses, queue_items.
class CloudStorageService {
  static const String _tableName = 'washpoint_data';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> saveData({
    required List<dynamic> sales,
    required List<dynamic> expenses,
    required List<dynamic> queueItems,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      print('⚠️ User belum login, cloud save dilewati');
      return;
    }

    try {
      final payload = {
        'user_id': user.id,
        'sales': jsonEncode(sales),
        'expenses': jsonEncode(expenses),
        'queue_items': jsonEncode(queueItems),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final existing = await client
          .from(_tableName)
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing == null) {
        await client.from(_tableName).insert(payload);
      } else {
        await client
            .from(_tableName)
            .update(payload)
            .eq('user_id', user.id);
      }

      print('✅ Data berhasil disimpan ke Supabase');
    } catch (e) {
      print('❌ Error save cloud: $e');
    }
  }

  static Future<Map<String, dynamic>> loadData() async {
    final user = client.auth.currentUser;
    if (user == null) {
      return {
        'sales': [],
        'expenses': [],
        'queue_items': [],
      };
    }

    try {
      final response = await client
          .from(_tableName)
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        return {
          'sales': [],
          'expenses': [],
          'queue_items': [],
        };
      }

      return {
        'sales': _decodeList(response['sales']),
        'expenses': _decodeList(response['expenses']),
        'queue_items': _decodeList(response['queue_items']),
      };
    } catch (e) {
      print('❌ Error load cloud: $e');
      return {
        'sales': [],
        'expenses': [],
        'queue_items': [],
      };
    }
  }

  static Future<Map<String, dynamic>> syncData({
    required List<dynamic> localSales,
    required List<dynamic> localExpenses,
    required List<dynamic> localQueueItems,
  }) async {
    final cloud = await loadData();

    final mergedSales = _mergeData(localSales, cloud['sales'] ?? []);
    final mergedExpenses = _mergeData(localExpenses, cloud['expenses'] ?? []);
    final mergedQueueItems = _mergeData(localQueueItems, cloud['queue_items'] ?? []);

    await saveData(
      sales: mergedSales,
      expenses: mergedExpenses,
      queueItems: mergedQueueItems,
    );

    return {
      'sales': mergedSales,
      'expenses': mergedExpenses,
      'queue_items': mergedQueueItems,
    };
  }

  static List<dynamic> _decodeList(dynamic value) {
    if (value == null || value == '') {
      return [];
    }

    try {
      final decoded = jsonDecode(value);
      return decoded is List ? decoded : <dynamic>[];
    } catch (_) {
      return [];
    }
  }

  static List<dynamic> _mergeData(
    List<dynamic> local,
    List<dynamic> cloud,
  ) {
    final merged = <String, dynamic>{};

    for (final item in cloud) {
      if (item is Map && item['id'] != null) {
        merged[item['id'].toString()] = item;
      }
    }

    for (final item in local) {
      if (item is Map && item['id'] != null) {
        merged[item['id'].toString()] = item;
      }
    }

    return merged.values.toList();
  }
}
